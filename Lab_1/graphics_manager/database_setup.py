from dotenv import dotenv_values

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

config = dotenv_values(".env")

engine = create_engine(config["POSTGRESQL_CONNECTION_URI"], connect_args={}, future=True)
session_local = sessionmaker(autocommit=False, autoflush=False, bind=engine, future=True)
base = declarative_base


def get_db():
    database = session_local()
    try:
        yield database
    finally:
        database.close()
