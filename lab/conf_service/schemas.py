from typing import List, Dict
from datetime import datetime
from pydantic import BaseModel


class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    full_name: str


class ReportResponse(BaseModel):
    id: int
    autor: str
    name: str
    text: str
    date: str

class ConfCreate(BaseModel):
    name: str
    start_date: datetime
    users: List[int]
    reports: List[int]


class ConfBase(BaseModel):
    id: int
    name: str
    start_date: datetime
    users: List[int]
    reports: List[int]
    created_by: int

class ConfResponse(BaseModel):
    id: int
    users: List[int]
    reports: List[int]

class ConfUpdate(BaseModel):
    users: List[int]
    reports: List[int]

class ConfDeleteResponse(BaseModel):
    message: str