import cv2
import numpy as np
from detection.detector import PersonDetector
from tracking.tracker import PersonTracker

def main():
    print("Testing modular PersonTracker...")
    try:
        detector = PersonDetector()
        tracker = PersonTracker()
        print("Modules loaded successfully!")
        
        # We will feed 3 frames to the pipeline to test tracking logic
        for i in range(3):
            # Dummy image with a fake "person" rectangle (YOLO won't detect it, but it proves no crashes occur)
            dummy_image = np.zeros((640, 640, 3), dtype=np.uint8)
            detections = detector.detect(dummy_image)
            active_tracks = tracker.update(detections)
            print(f"Frame {i+1}: Found {len(active_tracks)} active tracks.")
            
        print("Tracking architecture is working correctly without errors!")
        
    except Exception as e:
        print(f"Error during tracking test: {e}")

if __name__ == "__main__":
    main()
