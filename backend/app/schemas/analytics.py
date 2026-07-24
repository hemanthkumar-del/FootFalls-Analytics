from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class AnalyticsEvent(BaseModel):
    event_type: str # "entry" or "exit"
    camera_id: str
    tracking_id: int
    timestamp: datetime

class DailySummary(BaseModel):
    date: str # YYYY-MM-DD
    total_entries: int
    total_exits: int
    peak_occupancy: int
    peak_hour: str

class AnalyticsDashboardResponse(BaseModel):
    today_entries: int
    today_exits: int
    current_occupancy: int
    peak_hour: str
    active_cameras: int
