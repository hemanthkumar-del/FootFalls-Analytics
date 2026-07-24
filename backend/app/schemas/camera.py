from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class CameraBase(BaseModel):
    name: str
    url: str # RTSP URL or USB index (e.g. "0")
    status: str = "offline"

class CameraCreate(CameraBase):
    pass

class CameraUpdate(BaseModel):
    name: Optional[str] = None
    url: Optional[str] = None
    status: Optional[str] = None

class CameraInDB(CameraBase):
    id: str = Field(alias="_id")
    created_at: datetime
    updated_at: datetime

    class Config:
        populate_by_name = True
