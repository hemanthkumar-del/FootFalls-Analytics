from typing import List, Dict
from events.crossing_event import CrossingEvent
from database.services import db_service

class CounterEngine:
    def __init__(self):
        # Initialize from database if exists
        stats = db_service.get_statistics()
        self.total_entered = stats.get("total_entered", 0)
        self.total_exited = stats.get("total_exited", 0)
        
        # Debouncing: track_id -> last direction ('in' or 'out')
        self.last_crossings: Dict[int, str] = {}
        
    def handle_crossing_event(self, event: CrossingEvent):
        """Callback to handle a crossing event."""
        track_id = event.track_id
        direction = event.direction
        
        # Prevent duplicate counts
        last_dir = self.last_crossings.get(track_id)
        if last_dir == direction:
            return
            
        self.last_crossings[track_id] = direction
        
        if direction == 'in':
            self.total_entered += 1
            print(f"Track {track_id} entered. Total In: {self.total_entered}")
        elif direction == 'out':
            self.total_exited += 1
            print(f"Track {track_id} exited. Total Out: {self.total_exited}")
            
        # Persist to DB
        db_service.record_crossing_event(
            event.event_id, 
            track_id, 
            direction, 
            self.total_entered, 
            self.total_exited, 
            self.get_occupancy()
        )

    def get_occupancy(self) -> int:
        """Returns the current occupancy (cannot be negative)."""
        occ = self.total_entered - self.total_exited
        return max(0, occ)

    def reset(self):
        """Resets the counting statistics both in memory and DB."""
        self.total_entered = 0
        self.total_exited = 0
        self.last_crossings.clear()
        db_service.reset_database()
