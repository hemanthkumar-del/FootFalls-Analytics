from app.firebase import get_firestore
from app.schemas.analytics import AnalyticsEvent
from datetime import datetime, timezone
from google.cloud import firestore

class AnalyticsRepository:
    def __init__(self):
        pass
        
    @property
    def events_collection(self):
        return get_firestore().collection("events")
        
    @property
    def daily_collection(self):
        return get_firestore().collection("daily_analytics")

    async def save_event(self, event: AnalyticsEvent):
        doc = event.model_dump()
        doc["timestamp"] = doc["timestamp"].isoformat() if isinstance(doc["timestamp"], datetime) else doc["timestamp"]
        
        new_ref = self.events_collection.document()
        await new_ref.set(doc)

    async def get_today_summary(self, date_str: str):
        doc_ref = self.daily_collection.document(date_str)
        doc = await doc_ref.get()
        if not doc.exists:
            return {
                "date": date_str,
                "total_entries": 0,
                "total_exits": 0,
                "peak_occupancy": 0,
                "peak_hour": "N/A"
            }
        return doc.to_dict()

    async def update_daily_summary(self, date_str: str, entries: int, exits: int, occupancy: int, hour: str):
        doc_ref = self.daily_collection.document(date_str)
        doc = await doc_ref.get()
        
        if doc.exists:
            current_data = doc.to_dict()
            new_peak = max(current_data.get("peak_occupancy", 0), occupancy)
            new_hour = hour if occupancy > current_data.get("peak_occupancy", 0) else current_data.get("peak_hour", "N/A")
            
            await doc_ref.update({
                "total_entries": firestore.Increment(entries),
                "total_exits": firestore.Increment(exits),
                "peak_occupancy": new_peak,
                "peak_hour": new_hour
            })
        else:
            await doc_ref.set({
                "date": date_str,
                "total_entries": entries,
                "total_exits": exits,
                "peak_occupancy": occupancy,
                "peak_hour": hour
            })

    async def get_hourly_trends(self, date_str: str):
        try:
            start_dt = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc).isoformat()
            end_dt = datetime.strptime(date_str + " 23:59:59", "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc).isoformat()
        except ValueError:
            return []

        query = self.events_collection.where(filter=firestore.FieldFilter("timestamp", ">=", start_dt)).where(filter=firestore.FieldFilter("timestamp", "<=", end_dt))
        
        buckets = {f"{i:02d}:00": {"entries": 0, "exits": 0} for i in range(24)}
        
        async for doc in query.stream():
            data = doc.to_dict()
            ts_str = data.get("timestamp")
            if ts_str:
                try:
                    ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                    hour_key = f"{ts.hour:02d}:00"
                    event_type = data.get("event_type")
                    if event_type == "enter":
                        buckets[hour_key]["entries"] += 1
                    elif event_type == "exit":
                        buckets[hour_key]["exits"] += 1
                except Exception:
                    pass
                    
        return [{"hour": k, "entries": v["entries"], "exits": v["exits"]} for k, v in buckets.items()]

    async def get_daily_trends(self, days: int = 7):
        query = self.daily_collection.order_by("date", direction=firestore.Query.DESCENDING).limit(days)
        docs = []
        async for doc in query.stream():
            docs.append(doc.to_dict())
            
        docs.reverse()
        return [{"date": d.get("date"), "entries": d.get("total_entries", 0), "exits": d.get("total_exits", 0)} for d in docs]

    async def get_dwell_time_stats(self):
        # Fetch recent events (e.g., last 1000 events) to compute dwell time in-memory
        query = self.events_collection.order_by("timestamp", direction=firestore.Query.DESCENDING).limit(2000)
        
        trackings = {}
        async for doc in query.stream():
            data = doc.to_dict()
            t_id = data.get("tracking_id")
            ts_str = data.get("timestamp")
            if not t_id or not ts_str:
                continue
                
            try:
                ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                if t_id not in trackings:
                    trackings[t_id] = {"min_time": ts, "max_time": ts, "events_count": 1}
                else:
                    if ts < trackings[t_id]["min_time"]:
                        trackings[t_id]["min_time"] = ts
                    if ts > trackings[t_id]["max_time"]:
                        trackings[t_id]["max_time"] = ts
                    trackings[t_id]["events_count"] += 1
            except Exception:
                pass
                
        durations = []
        for t_id, stats in trackings.items():
            if stats["events_count"] >= 2:
                duration = (stats["max_time"] - stats["min_time"]).total_seconds() * 1000
                durations.append(duration)
                
        if not durations:
            return {"avg_minutes": 0, "longest_minutes": 0, "shortest_minutes": 0}
            
        return {
            "avg_minutes": round((sum(durations)/len(durations)) / 60000, 1),
            "longest_minutes": round(max(durations) / 60000, 1),
            "shortest_minutes": round(min(durations) / 60000, 1)
        }

