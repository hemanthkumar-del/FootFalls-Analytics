import os
from app.services.detection_service import DetectionService

class TrackingService:
    def __init__(self):
        self.detection_service = DetectionService()
        self.tracker_config_path = "custom_tracker.yaml"
        self._ensure_tracker_config()

    def _ensure_tracker_config(self):
        if not os.path.exists(self.tracker_config_path):
            try:
                import yaml
                from pathlib import Path
                import ultralytics
                
                # Load the exact default config from the installed Ultralytics version
                default_tracker_path = Path(ultralytics.__file__).parent / "cfg/trackers/bytetrack.yaml"
                with open(default_tracker_path, 'r') as f:
                    config = yaml.safe_load(f)
                
                # Update with our custom stability parameters
                config["track_buffer"] = 120
                config["match_thresh"] = 0.95
                config["track_high_thresh"] = 0.4
                
                with open(self.tracker_config_path, "w") as f:
                    yaml.dump(config, f)
            except Exception as e:
                import logging
                logging.getLogger(__name__).warning(f"Failed to dynamically generate tracker config: {e}")
                # Fallback to the bare minimum
                config_str = "tracker_type: bytetrack\ntrack_high_thresh: 0.4\ntrack_low_thresh: 0.1\nnew_track_thresh: 0.5\ntrack_buffer: 120\nmatch_thresh: 0.95\n"
                with open(self.tracker_config_path, "w") as f:
                    f.write(config_str)

    def process_frame(self, frame):
        """
        Processes a frame and returns tracking objects with consistent IDs.
        Uses a custom ByteTrack config for higher stability (longer lost-track buffer).
        """
        results = self.detection_service.track_frame(
            frame, 
            tracker=self.tracker_config_path,
            conf=0.35,  # Lower confidence threshold slightly to keep IDs alive during occlusions
            iou=0.5
        )
        
        tracked_objects = []
        if results and len(results) > 0 and results[0].boxes:
            boxes = results[0].boxes
            
            # Check if tracking IDs are present (sometimes None if not tracked yet)
            if boxes.id is not None:
                track_ids = boxes.id.int().cpu().tolist()
                bboxes = boxes.xyxy.cpu().tolist()
                confs = boxes.conf.cpu().tolist()
                classes = boxes.cls.int().cpu().tolist()
                
                for track_id, bbox, conf, cls_id in zip(track_ids, bboxes, confs, classes):
                    # Calculate centroid
                    x1, y1, x2, y2 = bbox
                    cx = (x1 + x2) / 2
                    cy = (y1 + y2) / 2
                    
                    cls_name = results[0].names[cls_id]
                    
                    tracked_objects.append({
                        "id": track_id,
                        "centroid": (cx, cy),
                        "bbox": bbox,
                        "confidence": float(conf),
                        "class": cls_name
                    })
        return tracked_objects
