import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # Camera Settings
    CAMERA_ID = int(os.getenv("CAMERA_ID", 0))
    CAMERA_URL = os.getenv("CAMERA_URL", "")

    # YOLO Settings
    YOLO_MODEL_PATH = os.getenv("YOLO_MODEL_PATH", "models/yolov8n.pt")
    CONFIDENCE_THRESHOLD = float(os.getenv("CONFIDENCE_THRESHOLD", 0.5))

    # General
    PERSON_CLASS_ID = 0

    # Tracking Settings
    TRACKER_TYPE = os.getenv("TRACKER_TYPE", "bytetrack")
    MAX_LOST_FRAMES = int(os.getenv("MAX_LOST_FRAMES", 30))
    FRAME_RATE = int(os.getenv("FRAME_RATE", 30))
    MAX_TRAJECTORY_LENGTH = int(os.getenv("MAX_TRAJECTORY_LENGTH", 60))
    
    # Zone & Counting Settings
    # Default virtual line: horizontal across the middle of a 640x640 frame
    LINE_START = tuple(map(int, os.getenv("LINE_START", "100,320").split(',')))
    LINE_END = tuple(map(int, os.getenv("LINE_END", "540,320").split(',')))

    # Database Settings
    MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    DATABASE_NAME = os.getenv("DATABASE_NAME", "footfalls_db")

settings = Settings()
