import cv2
import numpy as np
from config.constants import COLOR_BBOX, COLOR_TEXT, COLOR_BG_TEXT, COLOR_LINE, COLOR_STATS_BG, FONT_SCALE, FONT_THICKNESS, BBOX_THICKNESS, LINE_THICKNESS
from typing import Tuple

def draw_bounding_box(frame: np.ndarray, bbox: list, confidence: float, label: str = "Person"):
    """
    Draws a bounding box and label on the given frame.
    """
    x1, y1, x2, y2 = bbox
    
    # Draw bounding box
    cv2.rectangle(frame, (x1, y1), (x2, y2), COLOR_BBOX, BBOX_THICKNESS)
    
    # Draw center point
    center_x = int((x1 + x2) / 2)
    center_y = int(y2)
    cv2.circle(frame, (center_x, center_y), 4, COLOR_WARNING, -1)
    
    # Text label
    text = f"{label} {confidence:.2f}"
    
    # Get text size
    (text_width, text_height), baseline = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, FONT_SCALE, FONT_THICKNESS)
    
    # Draw text background
    cv2.rectangle(frame, (x1, y1 - text_height - baseline - 5), (x1 + text_width, y1), COLOR_BG_TEXT, cv2.FILLED)
    
    # Draw text
    cv2.putText(frame, text, (x1, y1 - 5), cv2.FONT_HERSHEY_SIMPLEX, FONT_SCALE, COLOR_TEXT, FONT_THICKNESS)

def draw_fps(frame: np.ndarray, fps: float):
    """
    Draws the FPS counter on the frame.
    """
    text = f"FPS: {fps:.1f}"
    cv2.putText(frame, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1.0, COLOR_BBOX, 2)

def draw_virtual_line(frame: np.ndarray, start: Tuple[int, int], end: Tuple[int, int]):
    """
    Draws the virtual counting line.
    """
    cv2.line(frame, start, end, COLOR_LINE, LINE_THICKNESS)
    # Draw IN/OUT indicators assuming entering means crossing down/right
    # For horizontal line (y roughly equal):
    if abs(start[1] - end[1]) < 50:
        cv2.putText(frame, "IN v", (start[0] + 10, start[1] + 20), cv2.FONT_HERSHEY_SIMPLEX, 0.6, COLOR_LINE, 2)
        cv2.putText(frame, "OUT ^", (start[0] + 10, start[1] - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, COLOR_LINE, 2)

def draw_statistics(frame: np.ndarray, entered: int, exited: int, occupancy: int):
    """
    Draws the counting statistics overlay on the frame.
    """
    overlay_text = [
        f"Entered: {entered}",
        f"Exited: {exited}",
        f"Occupancy: {occupancy}"
    ]
    
    y0 = 60
    dy = 30
    for i, line in enumerate(overlay_text):
        y = y0 + i * dy
        # Background block for text
        cv2.rectangle(frame, (10, y - 20), (200, y + 5), COLOR_STATS_BG, -1)
        cv2.putText(frame, line, (15, y), cv2.FONT_HERSHEY_SIMPLEX, 0.7, COLOR_TEXT, 2)
