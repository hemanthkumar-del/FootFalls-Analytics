from typing import Dict, Any

def create_event_document(event_id: str, track_id: int, direction: str, timestamp: float, camera_id: str = "main_cam") -> Dict[str, Any]:
    return {
        "event_id": event_id,
        "track_id": track_id,
        "direction": direction,
        "timestamp": timestamp,
        "camera_id": camera_id
    }

def create_statistics_document(entered: int, exited: int, occupancy: int, last_updated: float) -> Dict[str, Any]:
    return {
        "_id": "current_stats", # Singleton document
        "total_entered": entered,
        "total_exited": exited,
        "occupancy": occupancy,
        "last_updated": last_updated
    }
