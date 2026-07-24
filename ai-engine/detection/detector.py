import cv2
import supervision as sv
from ultralytics import YOLO
from config.settings import settings
import numpy as np

class PersonDetector:
    def __init__(self, model_path: str = settings.YOLO_MODEL_PATH, conf_threshold: float = settings.CONFIDENCE_THRESHOLD):
        """
        Initializes the YOLO model for person detection.
        """
        self.model = YOLO(model_path)
        self.conf_threshold = conf_threshold
        self.person_class_id = settings.PERSON_CLASS_ID

    def detect(self, frame: np.ndarray) -> sv.Detections:
        """
        Detects people in a given frame.
        
        Args:
            frame: A numpy array representing the image frame.
            
        Returns:
            A supervision Detections object containing only the filtered people.
        """
        results = self.model(frame, verbose=False)[0]
        detections = sv.Detections.from_ultralytics(results)
        
        # Filter for only person class and above confidence threshold
        mask = (detections.class_id == self.person_class_id) & (detections.confidence >= self.conf_threshold)
        filtered_detections = detections[mask]
        
        return filtered_detections
