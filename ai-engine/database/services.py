from database.repositories import EventRepository, StatisticsRepository
from database.models import create_event_document, create_statistics_document
import time

class DatabaseService:
    def __init__(self):
        self.event_repo = EventRepository()
        self.stats_repo = StatisticsRepository()

    def record_crossing_event(self, event_id: str, track_id: int, direction: str, entered: int, exited: int, occupancy: int):
        """
        Saves the event and updates aggregated statistics.
        """
        timestamp = time.time()
        
        # 1. Save to events collection
        event_doc = create_event_document(event_id, track_id, direction, timestamp)
        self.event_repo.insert_event(event_doc)
        
        # 2. Update statistics collection
        stats_doc = create_statistics_document(entered, exited, occupancy, timestamp)
        self.stats_repo.update_statistics(stats_doc)
        
    def get_recent_events(self, limit: int = 100):
        return self.event_repo.get_recent_events(limit)
        
    def get_statistics(self):
        stats = self.stats_repo.get_statistics()
        if stats is None:
            return {"total_entered": 0, "total_exited": 0, "current_occupancy": 0}
        return {
            "total_entered": stats.get("total_entered", 0),
            "total_exited": stats.get("total_exited", 0),
            "current_occupancy": stats.get("occupancy", 0)
        }
        
    def get_camera_info(self, live_fps: float, live_connected: bool):
        # We can upsert this to DB and return it, but for simplicity we just return a dict
        # matching what the API expects and upsert to MongoDB
        cam_repo = db_connection.get_collection("cameras")
        doc = {
            "_id": "main_cam",
            "camera_source": "0",
            "resolution": "640x480",
            "fps": live_fps,
            "connection_state": "connected" if live_connected else "disconnected",
            "last_seen": time.time()
        }
        if cam_repo is not None:
            cam_repo.replace_one({"_id": "main_cam"}, doc, upsert=True)
        return doc
        
    def get_config(self):
        from config.settings import settings
        config_repo = db_connection.get_collection("settings")
        doc = {
            "_id": "runtime_config",
            "confidence_threshold": settings.CONFIDENCE_THRESHOLD,
            "tracker_type": settings.TRACKER_TYPE,
            "max_lost_frames": settings.MAX_LOST_FRAMES,
            "virtual_line_start": list(settings.LINE_START),
            "virtual_line_end": list(settings.LINE_END),
            "updated_at": time.time()
        }
        if config_repo is not None:
            config_repo.replace_one({"_id": "runtime_config"}, doc, upsert=True)
        return doc
        
    def reset_database(self):
        self.event_repo.delete_all()
        stats_doc = create_statistics_document(0, 0, 0, time.time())
        self.stats_repo.update_statistics(stats_doc)

db_service = DatabaseService()
