from pydantic import BaseModel, Field
from typing import List, Optional

class HealthResponse(BaseModel):
    status: str = Field(..., description="Overall service status")
    ai_engine_status: str
    camera_status: str
    yolo_model_status: str
    tracker_status: str
    timestamp: float

class StatusResponse(BaseModel):
    total_entered: int
    total_exited: int
    current_occupancy: int
    fps: float
    camera_connected: bool

class EventResponse(BaseModel):
    event_id: str
    track_id: int
    direction: str
    timestamp: float

class EventsListResponse(BaseModel):
    events: List[EventResponse]

class CameraInfoResponse(BaseModel):
    camera_source: str
    resolution: Optional[str] = None
    fps: float
    connection_state: str

class ConfigResponse(BaseModel):
    confidence_threshold: float
    tracker_type: str
    max_lost_frames: int
    virtual_line_start: List[int]
    virtual_line_end: List[int]

class VersionResponse(BaseModel):
    project_name: str
    version: str
    build_date: str
    ai_model: str
    tracker: str

class MessageResponse(BaseModel):
    message: str
