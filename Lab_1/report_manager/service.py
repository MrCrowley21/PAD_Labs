import logging
import uvicorn
from pymongo import MongoClient
from dotenv import dotenv_values

from fastapi import FastAPI

from routes.analytic_graphic import router as report_router

logging.basicConfig(level=logging.DEBUG)

config = dotenv_values(".env")

app = FastAPI()


@app.on_event("startup")
def startup_db_client():
    app.mongodb_client = MongoClient(config["MONGODB_CONNECTION_URI"])
    app.database = app.mongodb_client[config["DB_NAME"]]
    logging.info("Successfully connected to the MongoDB database...")


@app.on_event("shutdown")
def shutdown_db_client():
    logging.info("Disconnecting from the MongoDB database...")
    app.mongodb_client.close()


@app.get("/")
def test_fast_api():
    return {"Test Report Manager Service"}


@app.get("/health")
def read_status():
    return {
              "data_base": "connected",
              "load": "ok"
            }


app.include_router(report_router, tags=["reports"], prefix="/reports")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
