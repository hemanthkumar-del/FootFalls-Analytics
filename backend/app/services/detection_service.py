import logging
import os
from ultralytics import YOLO

logger = logging.getLogger(__name__)

class DetectionService:
    _instance = None
    _model = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DetectionService, cls).__new__(cls)
            try:
                logger.info("Initializing YOLO model directly inside backend...")
                model_path = os.getenv("YOLO_MODEL_PATH", "yolov8n.pt")
                # Try to load the model, fall back to default if not found
                if not os.path.exists(model_path):
                    logger.warning(f"Model path {model_path} not found. Attempting to download default yolov8n.pt")
                cls._model = YOLO(model_path)
                logger.info("YOLO model successfully loaded!")
            except Exception as e:
                logger.error(f"Failed to load YOLO model: {e}")
                cls._model = None
        return cls._instance

    @property
    def model(self):
        return self._model

    def track_frame(self, frame, **kwargs):
        """
        Runs YOLO object detection and tracking on a single frame.
        Uses tracking class '0' which corresponds to 'person' in COCO dataset.
        """
        if self._model is None:
            return []
            
        try:
            # We track only persons (classes=[0]) to reduce noise and optimize speed
            results = self.model.track(frame, persist=True, classes=[0], verbose=False, **kwargs)
            return results
        except Exception as e:
            logger.error(f"Error during YOLO tracking: {e}")
            return []
