from datetime import datetime
import uuid
from pydantic import BaseModel, Field


class AnalyticReport(BaseModel):
    id: str = Field(default_factory=uuid.uuid4, alias="_id")
    connectionId: str
    created_at: datetime = datetime.utcnow()
    report: str
