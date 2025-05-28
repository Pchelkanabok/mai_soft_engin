from pydantic import ConfigDict, BaseModel

class ReportBase(BaseModel):
    id: int
    autor: str
    name: str
    text: str
    date: str

class ReporCreate(BaseModel):
    autor: str
    name: str
    text: str
    date: str

class DeleteReportResponse(BaseModel):
    message: str

class ReportResponse(ReportBase):
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "id": 1,
                "autor": "Ivanov I.I.",
                "name": "Biography",
                "text": "It is my life. Is is my deth",
                "date": "12.12.2012"
            }
        }
    )