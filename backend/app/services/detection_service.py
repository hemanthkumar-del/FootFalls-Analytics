import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

class DetectionService:
    _instance = None
    _model = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DetectionService, cls).__new__(cls)
            logger.info("YOLO inference has been moved to the ai-engine.")
        return cls._instance

    @property
    def model(self):
        return None

    def track_frame(self, frame):
        # AI inference is now handled by the ai-engine.
        return []
