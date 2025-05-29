from contextlib import asynccontextmanager
import os
import json
from fastapi import Depends, HTTPException, status, FastAPI, Request
from motor.motor_asyncio import AsyncIOMotorClient
from schemas import ConfCreate, ConfResponse, ConfDeleteResponse
from pymongo.errors import DuplicateKeyError
import httpx
from typing import List
from auth import validate_token
import aioredis

DATABASE_URL = os.getenv("DATABASE_URL")
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user_service:8003")
REPORT_URL = os.getenv("REPORT_URL")
fake_db_id = 4
fake_conf_db = []

initial_data = [
    {"id": 1, "name": "Название 1", "start_date": "12.12.2012", "users": [1, 2], "reports": [1], "created_by": 3},
    {"id": 2, "name": "Название 2", "start_date": "12.12.2012", "users": [2], "reports": [1,2,3], "created_by": 1},
    {"id": 3, "name": "Название 3", "start_date": "12.12.2012", "users": [1], "reports": [1, 4], "created_by": 2}
]

@asynccontextmanager
async def lifespan(app: FastAPI):
    app.mongodb_client = AsyncIOMotorClient(DATABASE_URL)
    app.redis = await aioredis.from_url("redis://redis:6379", encoding="utf-8", decode_responses=True)
    app.mongodb = app.mongodb_client['conf']

    await app.mongodb.conf.create_index([("id", 1)], unique=True)
    
    if await app.mongodb.conf.count_documents({}) == 0:
        try:
            await app.mongodb.conf.insert_many(initial_data)
        except DuplicateKeyError:
            pass
    
    yield

    app.mongodb_client.close()
    await app.redis.close()

app = FastAPI(lifespan=lifespan)


async def get_users(user_ids: List[int], token: str):
    async with httpx.AsyncClient() as client:
        try:
            users = []
            for user_id in user_ids:
                response = await client.get(
                    f"{USER_SERVICE_URL}/{user_id}",
                    headers={"Authorization": f"Bearer {token}"}
                )
                if response.status_code != 200:
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"User {user_id} not found"
                    )
                users.append(response.json())
            return users
        except httpx.ConnectError:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="User service unavailable"
            )
        
async def get_reports(ids, cur_user):
    async with httpx.AsyncClient() as client:
        try:
            token = cur_user["token"]
            response = await client.get(
                f"{REPORT_URL}/reports/get_reports",
                headers={"Authorization": f"Bearer {token}"},
                params= {"ids": ids}
            )
            
            return response.json()
        
        except httpx.HTTPStatusError as e:
            raise HTTPException(
                status_code=e.response.status_code,
                detail=f"Auth service error: {e.response.text}"
            )
        except httpx.ConnectError:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="GeoPoint service unavailable"
            )

@app.post('/create_conf', response_model=ConfResponse)
async def create_new_conf(conf: ConfCreate, request: Request, cur_user = Depends(validate_token)):
    collection = request.app.mongodb['conf']
    if await collection.find_one({"name": conf.name}):
        raise HTTPException(status_code=400, detail="Conf with this name already registered")
    
    global fake_db_id

    reports = await get_reports(conf.reports, cur_user)
    print(reports)
    
    result = await collection.insert_one({
        "id": fake_db_id,
        "name": conf.name,
        "start_date": conf.start_date,
        "users": conf.users,
        "reports": conf.reports,
        "created_by": cur_user["id"]
    })

    db_conf = await collection.find_one({"id": fake_db_id})
    
    conf_response = ConfResponse(
        id=fake_db_id,
        users=db_conf["users"],
        reports=db_conf["reports"]
    )
    
    await request.app.redis.setex(
        f"conf:{conf_response.id}", 
        600,
        json.dumps(conf_response.model_dump())
    )
    fake_db_id += 1

    
    return conf_response


@app.get('/')
async def get_all_conf(request: Request, cur_user: dict = Depends(validate_token)):
    collection = request.app.mongodb['conf']
    confs = []
    async for conf in collection.find():
        confs.append(ConfResponse(
            id=conf["id"],
            users=conf["users"],
            reports=conf["reports"]
        ))
    return confs


@app.get('/{conf_id}', response_model=ConfResponse)
async def get_conf_by_id(conf_id: int, request: Request, cur_user: dict = Depends(validate_token)):

    global fake_db_id
    
    cached_data = await request.app.redis.get(f"conf:{conf_id}")
    if cached_data:
        return json.loads(cached_data)
    
    collection = request.app.mongodb['conf']
    db_conf = await collection.find_one({"id": conf_id})

    conf_response = ConfResponse(
            id=db_conf["id"],
            users=db_conf["users"],
            reports=db_conf["reports"]
    )

    await request.app.redis.setex(
        f"conf:{conf_id}", 
        600,
        json.dumps(conf_response.dict())
    )
    
    return conf_response


@app.delete('/{conf_id}', response_model=ConfDeleteResponse)
async def delete_conf(conf_id: int, request: Request,  _: dict = Depends(validate_token)):
    
    collection = request.app.mongodb['conf']
    
    db_conf = await collection.find_one_and_delete({"id": conf_id})
    
    if not db_conf:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conf not found"
        )

    await request.app.redis.delete(f"conf:{conf_id}")
    
    return {
        "message": "Conf deleted successfully",
    }