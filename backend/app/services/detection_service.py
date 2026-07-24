import logging
from ultralytics import YOLO
from app.core.config import settings

logger = logging.getLogger(__name__)

class DetectionService:
    _instance = None
    _model = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DetectionService, cls).__new__(cls)
            try:
                logger.info(f"Loading YOLO model from {settings.YOLO_MODEL_PATH}...")
                # We load YOLO into memory exactly once.
                cls._model = YOLO(settings.YOLO_MODEL_PATH)
                logger.info("YOLO model loaded successfully.")
            except Exception as e:
                logger.error(f"Failed to load YOLO model: {e}")
        return cls._instance

    @property
    def model(self):
        return self._model

    def track_frame(self, frame):
        if not self._model:
            return None
            
        # native ByteTrack via tracker="bytetrack.yaml"
        # classes=[0] ensures we ONLY detect "person"
        results = self._model.track(
            frame, 
            persist=True, 
            classes=[0], 
            conf=settings.CONFIDENCE_THRESHOLD,
            tracker="bytetrack.yaml",
            verbose=False
        )
        return results
