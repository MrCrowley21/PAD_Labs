from datetime import datetime
from pydantic import BaseModel


class AnalyticGraph(BaseModel):
    id: int
    connection_id: str
    created_at: datetime
    diagram: str
