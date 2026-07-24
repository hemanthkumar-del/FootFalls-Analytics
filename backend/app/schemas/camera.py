from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class CameraBase(BaseModel):
    name: str
    url: str # RTSP URL or USB index (e.g. "0")
    location: Optional[str] = None
    status: str = "offline"
    isEnabled: bool = True
    isStreaming: bool = False

class CameraCreate(CameraBase):
    pass

class CameraUpdate(BaseModel):
    name: Optional[str] = None
    url: Optional[str] = None
    location: Optional[str] = None
    status: Optional[str] = None
    isEnabled: Optional[bool] = None
    isStreaming: Optional[bool] = None

class CameraInDB(CameraBase):
    id: str = Field(alias="_id")
    fps: float = 0.0
    uptime: int = 0
    lastFrameTime: Optional[datetime] = None
    lastHeartbeat: Optional[datetime] = None
    errorMessage: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        populate_by_name = True
