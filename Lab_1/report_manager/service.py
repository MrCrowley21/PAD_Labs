import os
import logging
import uvicorn
import requests
from datetime import datetime
from pymongo import MongoClient
from dotenv import dotenv_values
from redis.cluster import RedisCluster

from fastapi import FastAPI, Request

from routes.analytic_graphic import router as report_router

logging.basicConfig(level=logging.DEBUG)

config = dotenv_values(".env")

SERVICE_DISCOVERY_HOSTNAME = os.getenv('SERVICE_DISCOVERY_HOST') or 'localhost'
SERVICE_DISCOVERY_PORT = os.getenv('SERVICE_DISCOVERY_PORT') or 4000
PORT = os.getenv('SELF_PORT') or 8001

HOST = os.environ["HOSTNAME"]
if not HOST:
    HOST = 'localhost'

TIMEOUT_SECOND = 5

app = FastAPI()

load = 0
reset_time = datetime.now()

status_codes = {
  200: 0,
  400: 0,
  304: 0,
  404: 0,
  500: 0
}


@app.on_event("startup")
async def startup_db_client():
    app.mongodb_client = MongoClient(host=f"mongodb://host.docker.internal:27017/")
    app.database = app.mongodb_client[config["DB_NAME"]]
    logging.info("Successfully connected to the MongoDB database...")
    data = {"service_type": "report_service",
            "address": HOST,
            "inner_port": PORT,
            "extern_port": 8001
            }
    # startup_nodes = [{"host": "redis_node_1", "port": 6379}, {"host": "redis_node_2", "port": 6379},
    #                  {"host": "redis_node_3", "port": 6379}]
    # try:
    # app.redis = RedisCluster(host="redis_node_1", port=6379)
    # logging.info(f"Successfully connected to Redis Cluster")
    # logging.info("Keys:", app.redis.keys("*"))
    # except Exception as e:
    #     logging.info(f"Failed to connect to Redis Cluster: {e}")
    response = requests.post(f"http://{SERVICE_DISCOVERY_HOSTNAME}:{SERVICE_DISCOVERY_PORT}/register", json=data)
    # http://service_discovery_container:4000/register
    if response.status_code != 200:
        raise Exception(f"Failed to register into Service Discovery...")
    else:
        logging.info("Successfully registered into Service Discovery...")


@app.on_event("shutdown")
def shutdown_db_client():
    logging.info("Disconnecting from the MongoDB database...")
    app.mongodb_client.close()


@app.get("/status")
def test_fast_api():
    return {"status": "ok",
            "message": "Test Report Manager Service"}


@app.middleware("http")
async def count_requests_middleware(request: Request, call_next):
    global load, reset_time

    now = datetime.now()
    if (now - reset_time).total_seconds() >= 60:
        load = 0
        reset_time = now

    load += 1

    response = await call_next(request)

    status_code = response.status_code
    if request.url.path != '/metrics':
        if status_code in status_codes:
            status_codes[status_code] += 1
        else:
            status_codes[status_code] = 1

    return response


@app.get("/health")
def read_status():
    global load
    return {
              "data_base": "connected",
              "load": load,
            }


app.include_router(report_router, tags=["reports"], prefix="/reports")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(PORT))
