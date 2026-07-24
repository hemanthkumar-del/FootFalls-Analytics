from ultralytics import YOLO
import numpy as np
import cv2

def main():
    print("Loading YOLOv8n model...")
    # This will automatically download the yolo11n.pt or yolov8n.pt model if not present.
    # YOLOv8 is the latest stable standard, so we'll use yolov8n.pt for fast performance.
    model = YOLO("yolov8n.pt")
    print("Model loaded successfully!")
    
    print("Running a basic inference test on a dummy image...")
    # Create a dummy image (e.g., 640x640 black image)
    dummy_image = np.zeros((640, 640, 3), dtype=np.uint8)
    
    # Run inference
    results = model(dummy_image)
    
    print("Inference completed successfully!")
    print(f"Number of detections in dummy image: {len(results[0].boxes)}")
    print("YOLO installation and inference test passed.")

if __name__ == "__main__":
    main()
