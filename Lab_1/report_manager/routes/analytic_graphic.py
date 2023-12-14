import logging
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
    logging.info("Start report generation...")
    report = jsonable_encoder(report)
    new_report = request.app.database["reports"].insert_one(report)
    logging.info("Inserted")
    created_report_item = request.app.database["reports"].find_one({
        "_id": new_report.inserted_id
    })
    # request.app.redis.set(created_report_item["connectionId"], created_report_item["report"])
    logging.info("Set the redis")
    return created_report_item


@router.delete("/report_generation",
               response_description='Delete report and insert them into database',
               status_code=status.HTTP_201_CREATED)
def generate_report(request: Request, report: AnalyticReport = Body(...)):
    logging.info("Start report generation...")
    report = jsonable_encoder(report)
    logging.info("Deleting...")
    created_report_item = request.app.database["reports"].delete({
        "_id": report.id
    })
    # request.app.redis.set(created_report_item["connectionId"], created_report_item["report"])
    logging.info("Set the redis")
    return created_report_item


@router.get("/report_retrieving",
            response_description='Retrieve reports from the DataBase',
            status_code=status.HTTP_200_OK,
            response_model=List[AnalyticReport])
def retrieve_reports(request: Request):
    logging.info("Start report retrieving...")
    existing_reports = list(request.app.database["reports"].find(limit=50))
    return existing_reports


@router.get("/download_latest",
            response_description='Retrieve reports from the Cache',
            status_code=status.HTTP_200_OK)
def download_latest_reports(request: Request, connectionId: str = ''):
    logging.info("Start report retrieving...")
    # report = jsonable_encoder(report)
    # logging.info(report)
    # response = list(request.app.database["reports"].find(limit=50))
    try:
        response = request.app.redis.get(connectionId)
        logging.info(response)
        return response
    except:
        return {"pass": "no"}
