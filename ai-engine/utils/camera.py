import cv2
import sys
from config.settings import settings
from typing import Tuple, Optional
import numpy as np

class Camera:
    def __init__(self, source=None):
        """
        Initializes the camera capture.
        Defaults to CAMERA_ID or CAMERA_URL from settings if source is None.
        """
        if source is None:
            source = settings.CAMERA_URL if settings.CAMERA_URL else settings.CAMERA_ID
            
        self.source = source
        self.cap = cv2.VideoCapture(self.source)
        
        if not self.is_opened():
            print(f"Error: Could not open camera source {self.source}")
            sys.exit(1)

    def is_opened(self) -> bool:
        """Returns True if the camera is successfully opened."""
        return self.cap.isOpened()

    def read_frame(self) -> Tuple[bool, Optional[np.ndarray]]:
        """
        Reads a frame from the camera.
        Returns (success, frame).
        """
        if not self.is_opened():
            return False, None
            
        ret, frame = self.cap.read()
        return ret, frame

    def release(self):
        """Releases the camera resources."""
        if self.cap:
            self.cap.release()
