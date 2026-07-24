from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class NotificationSeverity(str, Enum):
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    SUCCESS = "SUCCESS"

class NotificationType(str, Enum):
    CAMERA_OFFLINE = "Camera Offline"
    CAMERA_ONLINE = "Camera Online"
    OCCUPANCY_WARNING = "Occupancy Warning"
    REPORT_READY = "Report Ready"
    SYSTEM_INFO = "System Information"

class NotificationBase(BaseModel):
    title: str
    message: str
    type: str # From NotificationType
    severity: str # From NotificationSeverity

class NotificationInDB(NotificationBase):
    id: str = Field(alias="_id")
    createdAt: datetime
    isRead: bool = False
