import os
import logging
import uvicorn
import requests
from datetime import datetime
from dotenv import dotenv_values
from sqlalchemy.orm import Session

from fastapi import FastAPI, Depends, Request

from models import AnalyticGraph
from schemas import AnalyticGraphSchema

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

logging.basicConfig(level=logging.DEBUG)

config = dotenv_values(".env")

SERVICE_DISCOVERY_HOSTNAME = os.getenv('SERVICE_DISCOVERY_HOST') or 'localhost'
SERVICE_DISCOVERY_PORT = os.getenv('SERVICE_DISCOVERY_PORT') or '4000'

HOST = os.getenv('HOSTNAME') or 'localhost'
PORT = os.getenv('SELF_PORT') or '8002'
TIMEOUT_SECOND = 5

app = FastAPI()

load = 0
reset_time = datetime.now()

engine = create_engine(config["POSTGRESQL_CONNECTION_URI"], connect_args={}, future=True)
session_local = sessionmaker(autocommit=False, autoflush=False, bind=engine, future=True)
base = declarative_base


def get_db():
    app.db = session_local()
    try:
        yield app.db
    finally:
        app.db.close()


@app.get("/")
def test_fast_api():
    return {"Test Graphic Manager Service"}


@app.get("/health")
def read_status():
    return {
              "data_base": "connected",
              "load": "ok"
            }


@app.get("/data_visualization")
def read_status(db: Session = Depends(get_db)):
    graphs = db.query(AnalyticGraphSchema).all()
    return [AnalyticGraph(graph) for graph in graphs]


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
    data = {"service_type": "graphic_service",
            "address": HOST,
            "inner_port": PORT,
            "extern_port": 8002
            }
    response = requests.post("http://localhost:4000/register", json=data)
    # http://service_discovery_container:4000/register
    if response.status_code != 200:
        raise Exception(f"Failed to register into Service Discovery...")
    else:
        logging.info("Successfully registered into Service Discovery...")


@app.on_event("shutdown")
def shutdown_db_client():
    logging.info("Disconnecting from the Postgres database...")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
