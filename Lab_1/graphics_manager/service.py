import logging
import uvicorn
from dotenv import dotenv_values
from sqlalchemy.orm import Session

from fastapi import FastAPI, Depends

from models import AnalyticGraph
from schemas import AnalyticGraphSchema

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

logging.basicConfig(level=logging.DEBUG)

config = dotenv_values(".env")

app = FastAPI()

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


@app.on_event("startup")
def startup_db_client():
    logging.info("Successfully connected to the Postgres database...")


@app.on_event("shutdown")
def shutdown_db_client():
    logging.info("Disconnecting from the Postgres database...")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
