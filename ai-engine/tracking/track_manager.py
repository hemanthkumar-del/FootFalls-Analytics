import time
from typing import Dict, List, Optional, Tuple
from tracking.track import Track
from config.settings import settings

class TrackManager:
    def __init__(self, max_lost_frames_time: float = 2.0):
        """
        Manages all active tracks and handles expiration of lost tracks.
        Args:
            max_lost_frames_time: Time in seconds before a track is considered expired and removed.
        """
        self.tracks: Dict[int, Track] = {}
        # Max lost time before a track is completely deleted from memory (e.g., 2 seconds)
        # ByteTrack handles internal frame matching, but TrackManager cleans up our high-level Track objects
        self.max_lost_frames_time = max_lost_frames_time 

    def update_tracks(self, tracked_data: List[Tuple[int, List[int], float]]):
        """
        Updates the manager with the latest data from the tracking engine.
        Args:
            tracked_data: List of tuples (track_id, bbox, confidence).
        """
        current_time = time.time()
        
        # Track IDs seen in the current frame
        seen_track_ids = set()
        
        for track_id, bbox, conf in tracked_data:
            seen_track_ids.add(track_id)
            
            if track_id in self.tracks:
                # Update existing track
                self.tracks[track_id].update(bbox, conf)
            else:
                # Create new track
                self.tracks[track_id] = Track(track_id, bbox, conf)
                
        # Clean up tracks that have not been seen for a while
        expired_ids = []
        for track_id, track in self.tracks.items():
            if track_id not in seen_track_ids:
                if (current_time - track.last_seen_time) > self.max_lost_frames_time:
                    expired_ids.append(track_id)
                else:
                    track.mark_inactive()
                    
        for track_id in expired_ids:
            del self.tracks[track_id]

    def get_active_tracks(self) -> List[Track]:
        """Returns a list of tracks that are currently active (seen in recent frames)."""
        return [track for track in self.tracks.values() if track.is_active]

    def get_track(self, track_id: int) -> Optional[Track]:
        """Looks up a track by its ID."""
        return self.tracks.get(track_id)
