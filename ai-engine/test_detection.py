import cv2
import numpy as np
from detection.detector import PersonDetector

def main():
    print("Testing modular PersonDetector...")
    try:
        detector = PersonDetector()
        print("PersonDetector loaded successfully!")
        
        # Dummy image
        dummy_image = np.zeros((640, 640, 3), dtype=np.uint8)
        
        detections = detector.detect(dummy_image)
        print(f"Detections run successfully. Found {len(detections)} people in empty image.")
        print("Modular architecture is working correctly!")
        
    except Exception as e:
        print(f"Error during detection test: {e}")

if __name__ == "__main__":
    main()
