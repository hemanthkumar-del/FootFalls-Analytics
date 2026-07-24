from app.services.detection_service import DetectionService

class TrackingService:
    def __init__(self):
        self.detection_service = DetectionService()

    def process_frame(self, frame):
        """
        Processes a frame and returns tracking objects with consistent IDs.
        Ultralytics's ByteTrack handles the actual association logic.
        """
        results = self.detection_service.track_frame(frame)
        
        tracked_objects = []
        if results and len(results) > 0 and results[0].boxes:
            boxes = results[0].boxes
            
            # Check if tracking IDs are present (sometimes None if not tracked yet)
            if boxes.id is not None:
                track_ids = boxes.id.int().cpu().tolist()
                bboxes = boxes.xyxy.cpu().tolist()
                
                for track_id, bbox in zip(track_ids, bboxes):
                    # Calculate centroid
                    x1, y1, x2, y2 = bbox
                    cx = (x1 + x2) / 2
                    cy = (y1 + y2) / 2
                    
                    tracked_objects.append({
                        "id": track_id,
                        "centroid": (cx, cy),
                        "bbox": bbox
                    })
        return tracked_objects
