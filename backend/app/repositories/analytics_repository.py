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

    async def get_hourly_trends(self, date_str: str):
        # We parse the date to set range
        try:
            start_dt = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc)
            end_dt = datetime.strptime(date_str + " 23:59:59", "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
        except ValueError:
            return []

        pipeline = [
            {"$match": {"timestamp": {"$gte": start_dt, "$lte": end_dt}}},
            {"$group": {
                "_id": {"$hour": "$timestamp"},
                "entries": {"$sum": {"$cond": [{"$eq": ["$event_type", "enter"]}, 1, 0]}},
                "exits": {"$sum": {"$cond": [{"$eq": ["$event_type", "exit"]}, 1, 0]}}
            }},
            {"$sort": {"_id": 1}}
        ]
        
        cursor = self.events_collection.aggregate(pipeline)
        return [{"hour": f"{doc['_id']:02d}:00", "entries": doc["entries"], "exits": doc["exits"]} async for doc in cursor]

    async def get_daily_trends(self, days: int = 7):
        # Simplistic: return the last N days sorted
        cursor = self.daily_collection.find({}).sort("date", -1).limit(days)
        docs = [doc async for doc in cursor]
        docs.reverse()
        return [{"date": d["date"], "entries": d.get("total_entries", 0), "exits": d.get("total_exits", 0)} for d in docs]

    async def get_dwell_time_stats(self):
        pipeline = [
            {"$group": {
                "_id": "$tracking_id",
                "min_time": {"$min": "$timestamp"},
                "max_time": {"$max": "$timestamp"},
                "events_count": {"$sum": 1}
            }},
            # Only consider complete visits (at least an enter and exit, or multi-pings)
            {"$match": {"events_count": {"$gte": 2}}},
            {"$project": {
                "duration_ms": {"$dateDiff": {"startDate": "$min_time", "endDate": "$max_time", "unit": "millisecond"}}
            }},
            {"$group": {
                "_id": None,
                "avg_duration": {"$avg": "$duration_ms"},
                "max_duration": {"$max": "$duration_ms"},
                "min_duration": {"$min": "$duration_ms"}
            }}
        ]
        
        cursor = self.events_collection.aggregate(pipeline)
        docs = [doc async for doc in cursor]
        if not docs:
            return {"avg_minutes": 0, "longest_minutes": 0, "shortest_minutes": 0}
            
        return {
            "avg_minutes": round((docs[0].get("avg_duration", 0) or 0) / 60000, 1),
            "longest_minutes": round((docs[0].get("max_duration", 0) or 0) / 60000, 1),
            "shortest_minutes": round((docs[0].get("min_duration", 0) or 0) / 60000, 1)
        }
