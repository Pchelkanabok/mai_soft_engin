import os
from typing import List
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, Query, status, Request
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.errors import DuplicateKeyError
from auth import validate_token
from fake_reports import fake_reps
from schemas import ReportResponse, ReporCreate, DeleteReportResponse
from bson.errors import InvalidId
from bson import ObjectId

DATABASE_URL = os.getenv("DATABASE_URL")
report_id = 6
@asynccontextmanager
async def lifespan(app: FastAPI):
    app.mongodb_client = AsyncIOMotorClient(DATABASE_URL)
    app.mongodb = app.mongodb_client["reports"]
    await app.mongodb.reports.create_index([("id", 1)], unique=True)
    if await app.mongodb.reports.count_documents({}) == 0:
        try:
            await app.mongodb.reports.insert_many(fake_reps)
        except DuplicateKeyError:
            pass
    
    yield
    app.mongodb_client.close()

app = FastAPI(lifespan=lifespan)

@app.get("/reports/", response_model=List[ReportResponse])
async def get_all_reports(_: dict = Depends(validate_token)):
    db_points = await app.mongodb.reports.find({}, {"_id": 0}).to_list(1000)
    return db_points

@app.get("/reports/get_reports", response_model=List[ReportResponse])
async def get_reports_by_id(ids: list[int] = Query(..., description="Массив ID докладов"), _: dict = Depends(validate_token)):
    db_points = await app.mongodb.reports.find({"id": {"$in": ids}}, {"_id": 0}).to_list(None)
    if len(db_points) != len(ids):
        raise HTTPException(
				status_code=status.HTTP_400_BAD_REQUEST,
				detail="One or more reports were not found")
    return db_points

@app.get("/reports/{id}", response_model=ReportResponse)
async def get_report_by_id(id: int, _: dict = Depends(validate_token)):
    db_points = await app.mongodb.reports.find_one({"id": id}, {"_id": 0})
    if not db_points:
        raise HTTPException(
				status_code=status.HTTP_400_BAD_REQUEST,
				detail="Report were not found")
    return db_points

@app.post("/reports/create_report", response_model=ReportResponse)
async def create_new_report(report: ReporCreate, request: Request, cur_user = Depends(validate_token)):
    collection = request.app.mongodb["reports"]
    response = {}
    global report_id
    if await collection.find_one({"name": report.name}):
        raise HTTPException(status_code=400, detail="Report with this name already registered")
    
    report_id += 1
    result = await collection.insert_one({
        "id": report_id,
        "autor": report.autor,
        "name": report.name,
        "text": report.text,
        "date": report.date
    })
    

    db_report = await collection.find_one({"id": report_id})
    print(db_report)
    report_response = ReportResponse(
        id=int(db_report["id"]),
        autor=db_report["autor"],
        name=db_report["name"],
        text=db_report["text"],
        date=db_report["date"]
    )
    
    return report_response

@app.delete("/reports/{report_id_}", response_model=DeleteReportResponse)
async def delete_user(report_id_: int, request: Request,  _: dict = Depends(validate_token)):
    
    collection = request.app.mongodb["reports"]
    
    db_report = await collection.find_one_and_delete({"id": report_id_})
    
    if not db_report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    return {
        "message": "Report deleted successfully",
    }