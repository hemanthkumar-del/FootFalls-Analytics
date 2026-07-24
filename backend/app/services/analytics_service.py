import asyncio
import time
import logging
from datetime import datetime, timezone
from app.repositories.analytics_repository import AnalyticsRepository
from app.schemas.analytics import AnalyticsEvent
from app.websocket.connection_manager import manager

logger = logging.getLogger(__name__)

class AnalyticsService:
    def __init__(self):
        self.repo = AnalyticsRepository()
        self.total_entries = 0
        self.total_exits = 0
        self.occupancy = 0
        self.last_sync = time.time()
        
        # In a real app, these initial values would be pulled from MongoDB on boot
        # so the daily accumulation continues smoothly if the app restarts.

    async def log_event(self, camera_id: str, event_type: str, track_id: int):
        event = AnalyticsEvent(
            event_type=event_type,
            camera_id=camera_id,
            tracking_id=track_id,
            timestamp=datetime.now(timezone.utc)
        )
        logger.info(f"Event Logged: Camera={camera_id}, Type={event_type}, PersonID={track_id}")
        await self.repo.save_event(event)

    async def aggregate_and_broadcast(self, camera_id: str, new_entries: int, new_exits: int, current_occupancy: int, fps: int):
        self.total_entries += new_entries
        self.total_exits += new_exits
        self.occupancy = current_occupancy

        now = time.time()
        has_changed = (new_entries > 0 or new_exits > 0)
        
        # Throttle to max 5 updates per second (0.2s interval)
        time_since_last = now - self.last_sync
        should_broadcast = has_changed or (time_since_last > 0.2)

        if should_broadcast:
            payload = {
                "camera_id": camera_id,
                "entries": self.total_entries,
                "exits": self.total_exits,
                "occupancy": self.occupancy,
                "fps": round(fps, 1),
                "camera_status": "online"
            }
            await manager.broadcast(payload)
            self.last_sync = now

            if has_changed:
                logger.info(f"[CAM_ID: {camera_id}] WebSocket Broadcast: Occupancy={self.occupancy} (Delta E={new_entries}, X={new_exits})")

        # Sync to MongoDB on every count change to ensure persistence
        if has_changed:
            date_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
            hour_str = datetime.now(timezone.utc).strftime("%H:00")
            
            await self.repo.update_daily_summary(
                date_str=date_str,
                entries=new_entries, 
                exits=new_exits,     
                occupancy=self.occupancy,
                hour=hour_str
            )
            logger.debug(f"[CAM_ID: {camera_id}] MongoDB Synced.")
