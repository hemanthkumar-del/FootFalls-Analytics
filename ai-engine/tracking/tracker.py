import supervision as sv
from typing import List, Tuple
from config.settings import settings
from tracking.track_manager import TrackManager
from tracking.track import Track

class PersonTracker:
    def __init__(self):
        """
        Initializes the ByteTrack tracker and the internal TrackManager.
        """
        self.tracker = sv.ByteTrack(
            track_activation_threshold=0.25,
            lost_track_buffer=settings.MAX_LOST_FRAMES,
            minimum_matching_threshold=0.8,
            frame_rate=settings.FRAME_RATE
        )
        self.track_manager = TrackManager(max_lost_frames_time=2.0)

    def update(self, detections: sv.Detections) -> List[Track]:
        """
        Updates the tracker with new detections.
        
        Args:
            detections: A supervision Detections object containing person detections.
            
        Returns:
            A list of active Track objects.
        """
        # Pass detections through ByteTrack
        tracked_detections = self.tracker.update_with_detections(detections)
        
        # Extract tracked data into a format for TrackManager
        # tracked_detections contains .tracker_id, .xyxy, .confidence
        tracked_data = []
        if tracked_detections.tracker_id is not None:
            for i in range(len(tracked_detections)):
                bbox = tracked_detections.xyxy[i].tolist()
                conf = float(tracked_detections.confidence[i]) if tracked_detections.confidence is not None else 1.0
                track_id = int(tracked_detections.tracker_id[i])
                tracked_data.append((track_id, bbox, conf))
                
        # Update TrackManager
        self.track_manager.update_tracks(tracked_data)
        
        # Return currently active high-level tracks
        return self.track_manager.get_active_tracks()
