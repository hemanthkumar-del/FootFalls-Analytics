from app.database import get_database
from app.schemas.analytics import AnalyticsEvent
from datetime import datetime, timezone

class AnalyticsRepository:
    def __init__(self):
        self.events_collection = get_database().get_collection("events")
        self.daily_collection = get_database().get_collection("daily_analytics")
        
        # Background index creation for fast queries
        self.events_collection.create_index([("camera_id", 1)])
        self.events_collection.create_index([("tracking_id", 1)])
        self.events_collection.create_index([("timestamp", -1)])
        self.daily_collection.create_index([("date", -1)], unique=True)

    async def save_event(self, event: AnalyticsEvent):
        doc = event.model_dump()
        await self.events_collection.insert_one(doc)

    async def get_today_summary(self, date_str: str):
        doc = await self.daily_collection.find_one({"date": date_str})
        if not doc:
            return {
                "date": date_str,
                "total_entries": 0,
                "total_exits": 0,
                "peak_occupancy": 0,
                "peak_hour": "N/A"
            }
        return doc

    async def update_daily_summary(self, date_str: str, entries: int, exits: int, occupancy: int, hour: str):
        await self.daily_collection.update_one(
            {"date": date_str},
            {
                "$inc": {"total_entries": entries, "total_exits": exits},
                "$max": {"peak_occupancy": occupancy},
                "$set": {"peak_hour": hour}
            },
            upsert=True
        )
