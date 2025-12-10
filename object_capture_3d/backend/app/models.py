from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class SessionCreate(BaseModel):
    name: Optional[str] = "Untitled Session"

class SessionResponse(BaseModel):
    session_id: str
    name: str
    created_at: datetime
    image_count: int
    status: str  # created, processing, completed, failed
    model_url: Optional[str] = None

class ProcessingStatus(BaseModel):
    status: str
    message: str
    progress: float
