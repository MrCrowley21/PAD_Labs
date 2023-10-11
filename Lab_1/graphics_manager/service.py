import logging
import uvicorn
from dotenv import dotenv_values
from sqlalchemy.orm import Session

from fastapi import FastAPI, Depends

from database_setup import get_db

from models import AnalyticGraph
from schemas import AnalyticGraphSchema

logging.basicConfig(level=logging.DEBUG)

config = dotenv_values(".env")

app = FastAPI()

app.db = get_db()


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
def read_status(db: Session = Depends(app.db)):
    graphs = db.query(AnalyticGraphSchema).get()
    return [AnalyticGraph(graph) for graph in graphs]


@app.on_event("startup")
def startup_db_client():
    logging.info("Successfully connected to the Postgres database...")


@app.on_event("shutdown")
def shutdown_db_client():
    logging.info("Disconnecting from the Postgres database...")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
