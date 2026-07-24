import time
from typing import List, Tuple, Dict
from collections import deque
from config.settings import settings

class Track:
    def __init__(self, track_id: int, bbox: List[int], confidence: float):
        """
        Represents a single tracked object (person).
        """
        self.track_id = track_id
        self.bbox = bbox
        self.confidence = confidence
        
        # Positions
        self.current_position = self._get_center(bbox)
        self.previous_position = self.current_position
        
        # Trajectory History
        self.trajectory = deque(maxlen=settings.MAX_TRAJECTORY_LENGTH)
        self.trajectory.append(self.current_position)
        
        # Timings
        now = time.time()
        self.creation_time = now
        self.last_seen_time = now
        
        # Status
        self.is_active = True
        
        # Zone tracking (stores which side of a line this track is on)
        self.zone_states: Dict[str, int] = {}
        # Stores lines already crossed to prevent duplicates
        self.crossed_lines: set = set()

    def _get_center(self, bbox: List[int]) -> Tuple[int, int]:
        """Calculates the center point of the bounding box bottom edge for better line crossing accuracy."""
        x1, y1, x2, y2 = bbox
        return (int((x1 + x2) / 2), int(y2))

    def update(self, bbox: List[int], confidence: float):
        """Updates the track with new detection data."""
        self.bbox = bbox
        self.confidence = confidence
        
        self.previous_position = self.current_position
        self.current_position = self._get_center(bbox)
        self.trajectory.append(self.current_position)
        
        self.last_seen_time = time.time()
        self.is_active = True

    def mark_inactive(self):
        """Marks the track as inactive."""
        self.is_active = False
