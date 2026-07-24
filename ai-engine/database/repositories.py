from typing import List, Dict, Any, Optional
from database.connection import db_connection

class BaseRepository:
    def __init__(self, collection_name: str):
        self.collection_name = collection_name
        
    @property
    def collection(self):
        return db_connection.get_collection(self.collection_name)

class EventRepository(BaseRepository):
    def __init__(self):
        super().__init__("events")
        
    def insert_event(self, event_doc: Dict[str, Any]):
        coll = self.collection
        if coll is not None:
            try:
                # Prevent duplicate inserting if event_id exists
                coll.update_one(
                    {"event_id": event_doc["event_id"]}, 
                    {"$setOnInsert": event_doc}, 
                    upsert=True
                )
            except Exception as e:
                print(f"Failed to insert event: {e}")

    def get_recent_events(self, limit: int = 100) -> List[Dict[str, Any]]:
        coll = self.collection
        if coll is not None:
            try:
                return list(coll.find({}, {"_id": 0}).sort("timestamp", -1).limit(limit))
            except Exception:
                pass
        return []
        
    def delete_all(self):
        coll = self.collection
        if coll is not None:
            coll.delete_many({})

class StatisticsRepository(BaseRepository):
    def __init__(self):
        super().__init__("statistics")
        
    def update_statistics(self, stats_doc: Dict[str, Any]):
        coll = self.collection
        if coll is not None:
            try:
                coll.replace_one({"_id": stats_doc["_id"]}, stats_doc, upsert=True)
            except Exception as e:
                print(f"Failed to update statistics: {e}")
                
    def get_statistics(self) -> Optional[Dict[str, Any]]:
        coll = self.collection
        if coll is not None:
            try:
                return coll.find_one({"_id": "current_stats"})
            except Exception:
                pass
        return None
