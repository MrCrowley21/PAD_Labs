from uuid import uuid4
from sqlalchemy import Column, Integer, String, DateTime, UUID
from sqlalchemy.ext.declarative import declarative_base
import datetime

Base = declarative_base()


class AnalyticGraphSchema(Base):
    __tablename__ = 'graphs'
    id = Column(UUID(as_uuid=True),
                primary_key=True,
                default=uuid4,)
    connection_id = Column(String(64), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    diagram = Column(String(255), nullable=False)
