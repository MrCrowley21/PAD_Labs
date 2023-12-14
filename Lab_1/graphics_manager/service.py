import os
import logging
import uvicorn
import requests
from typing import List
from datetime import datetime
from dotenv import dotenv_values
from fastapi.encoders import jsonable_encoder
from pymongo import MongoClient
from fastapi import APIRouter, Body, Request, Response, HTTPException, status

from fastapi import FastAPI, Depends, Request

from models import AnalyticGraph

logging.basicConfig(level=logging.DEBUG)

config = dotenv_values(".env")

SERVICE_DISCOVERY_HOSTNAME = os.getenv('SERVICE_DISCOVERY_HOST') or 'localhost'
SERVICE_DISCOVERY_PORT = os.getenv('SERVICE_DISCOVERY_PORT') or 4000
PORT = os.getenv('SELF_PORT') or 8002

HOST = os.environ["HOSTNAME"]
if not HOST:
    HOST = 'localhost'

TIMEOUT_SECOND = 5

app = FastAPI()

load = 0
reset_time = datetime.now()


@app.get("/status")
def test_fast_api():
    return {"status": "ok",
            "message": "Test Graphics Manager Service"}


@app.get("/health")
def read_status():
    return {
        "data_base": "connected",
        "load": load,
    }


@app.get("/data_visualization",
         response_description='Create diagram to visualize',
         status_code=status.HTTP_200_OK,
         response_model=List[AnalyticGraph])
def read_status(request: Request):
    logging.info("Start diagram retrieving...")
    graphs = list(request.app.database["graphs"].find(limit=50))
    return graphs


@app.post("/diagram_generation",
          response_description='Create new diagram image',
          status_code=status.HTTP_200_OK,
          response_model=AnalyticGraph)
def generate_diagram(request: Request, diagram: AnalyticGraph = Body(...)):
    logging.info("Start report generation...")
    report = jsonable_encoder(diagram)
    new_report = request.app.database["graphs"].insert_one(report)
    logging.info("Inserted")
    created_report_item = request.app.database["graphs"].find_one({
        "_id": new_report.inserted_id
    })
    return created_report_item


@app.delete("/report_generation",
            response_description='Delete report and insert them into database',
            status_code=status.HTTP_201_CREATED)
def generate_report(request: Request, report: AnalyticGraph = Body(...)):
    logging.info("Start report generation...")
    report = jsonable_encoder(report)
    logging.info("Deleting...")
    created_report_item = request.app.database["graphs"].delete({
        "_id": report.id
    })
    # request.app.redis.set(created_report_item["connectionId"], created_report_item["report"])
    logging.info("Set the redis")
    return created_report_item


@app.middleware("http")
async def count_requests_middleware(request: Request, call_next):
    global load, reset_time

    now = datetime.now()
    if (now - reset_time).total_seconds() >= 60:
        load = 0
        reset_time = now

    load += 1

    response = await call_next(request)
    return response


@app.on_event("startup")
async def startup_db_client():
    logging.info("Successfully connected to the MongoDB database...")
    app.mongodb_client = MongoClient(host=f"mongodb://host.docker.internal:27017/")
    app.database = app.mongodb_client[config["DB_NAME"]]
    logging.info("Successfully connected to the MongoDB database...")
    data = {"service_type": "graphic_service",
            "address": HOST,
            "inner_port": PORT,
            "extern_port": 8002
            }
    response = requests.post(f"http://{SERVICE_DISCOVERY_HOSTNAME}:{SERVICE_DISCOVERY_PORT}/register", json=data)
    # http://service_discovery_container:4000/register {SERVICE_DISCOVERY_HOSTNAME}:{SERVICE_DISCOVERY_PORT}/register
    if response.status_code != 200:
        raise Exception(f"Failed to register into Service Discovery...")
    else:
        logging.info("Successfully registered into Service Discovery...")


@app.on_event("shutdown")
def shutdown_db_client():
    logging.info("Disconnecting from the Postgres database...")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(PORT))
