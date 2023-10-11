from fastapi import APIRouter, Body, Request, Response, HTTPException, status
from fastapi.encoders import jsonable_encoder
from typing import List

from models import AnalyticReport

router = APIRouter()


@router.post("/report_generation",
             response_description='Generate report and insert them into database',
             status_code=status.HTTP_201_CREATED,
             response_model=AnalyticReport)
def generate_report(request: Request, report: AnalyticReport = Body(...)):
    report = jsonable_encoder(report)
    new_report = request.app.database["reports"].insert_one(report)
    created_report_item = request.app.database["reports"].find_one({
        "_id": new_report.inserted_id
    })

    return created_report_item


@router.get("/report_retrieving",
            response_description='Retrieve reports from the DataBase',
            status_code=status.HTTP_200_OK,
            response_model=List[AnalyticReport])
def retrieve_reports(request: Request):
    existing_reports = list(request.app.database["reports"].find(limit=50))
    return existing_reports
