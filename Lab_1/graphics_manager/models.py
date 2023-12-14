from datetime import datetime
from pydantic import BaseModel


class AnalyticGraph(BaseModel):
    id: int
    connectionId: str
    created_at: datetime
    diagram: str
