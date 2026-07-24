import cv2
import asyncio
import threading
import time
import logging
from app.services.tracking_service import TrackingService
from app.services.counting_service import CountingService
from app.services.analytics_service import AnalyticsService

logger = logging.getLogger(__name__)

class CameraService:
    def __init__(self, camera_id: str, url: str, main_loop: asyncio.AbstractEventLoop):
        self.camera_id = camera_id
        # Parse integers (0, 1) for local webcams, leave string for RTSP
        self.url = int(url) if url.isdigit() else url
        self.cap = None
        self.running = False
        self.main_loop = main_loop
        
        self.tracking_service = TrackingService()
        # Set line Y at 240 (assuming typical 640x480 webcam)
        self.counting_service = CountingService(line_y=240, deadzone=20)
        self.analytics_service = AnalyticsService()
        
        self.thread = None

    def start(self):
        if self.running:
            return
        self.running = True
        # Run the camera frame capture in a dedicated OS thread 
        # so it doesn't block the FastAPI async event loop.
        self.thread = threading.Thread(target=self._run_loop, daemon=True)
        self.thread.start()
        logger.info(f"Started camera worker for {self.camera_id}")

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join(timeout=2.0)
        if self.cap:
            self.cap.release()
        logger.info(f"Stopped camera worker for {self.camera_id}")

    def _run_loop(self):
        self.cap = cv2.VideoCapture(self.url)
        if not self.cap.isOpened():
            logger.error(f"Failed to connect to camera {self.camera_id} at {self.url}. Retrying later...")
            
        prev_time = time.time()
        
        while self.running:
            if not self.cap or not self.cap.isOpened():
                logger.warning(f"Reconnecting camera {self.camera_id}...")
                self.cap = cv2.VideoCapture(self.url)
                if not self.cap.isOpened():
                    time.sleep(2)
                    continue

            try:
                ret, frame = self.cap.read()
                if not ret:
                    logger.warning(f"[CAM_ID: {self.camera_id}] Empty frame. Stream might have dropped.")
                    self.cap.release()
                    time.sleep(1)
                    continue

                # OpenCV Optimization: Resize frame to 640x640 to standardize YOLO processing speed
                # Reusing a fixed resolution prevents memory bloat on 4K cameras
                frame = cv2.resize(frame, (640, 640))
            except cv2.error as e:
                logger.error(f"[CAM_ID: {self.camera_id}] OpenCV Error: {e}")
                self.cap.release()
                time.sleep(1)
                continue

            # Calculate FPS
            curr_time = time.time()
            fps = 1.0 / max((curr_time - prev_time), 0.001)
            prev_time = curr_time

            # 1. Process Frame (YOLO + ByteTrack)
            tracked_objects = self.tracking_service.process_frame(frame)

            # 2. Virtual Line Counting
            new_entries, new_exits = self.counting_service.update_counts(tracked_objects)

            # Draw virtual lines
            line_y = self.counting_service.line_y
            deadzone = self.counting_service.deadzone
            cv2.line(frame, (0, line_y - deadzone), (frame.shape[1], line_y - deadzone), (0, 0, 255), 2) # Red Exit Threshold
            cv2.line(frame, (0, line_y + deadzone), (frame.shape[1], line_y + deadzone), (0, 255, 0), 2) # Green Entry Threshold

            # 3. Handle Events and Broadcasting
            for obj in tracked_objects:
                track_id = obj["id"]
                bbox = obj.get("bbox")
                if bbox:
                    x1, y1, x2, y2 = map(int, bbox)
                    cv2.rectangle(frame, (x1, y1), (x2, y2), (255, 0, 0), 2)
                    cv2.putText(frame, f"ID: {track_id}", (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)
                
                history = self.counting_service.track_history.get(track_id)
                if history and history["crossed"]:
                    direction = history.get("direction")
                    if direction:
                        history["direction"] = None 
                        asyncio.run_coroutine_threadsafe(
                            self.analytics_service.log_event(self.camera_id, direction, track_id),
                            self.main_loop
                        )

            # Draw HUD
            cv2.putText(frame, f"Entries: {self.analytics_service.total_entries + new_entries}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            cv2.putText(frame, f"Exits: {self.analytics_service.total_exits + new_exits}", (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
            cv2.putText(frame, f"Occupancy: {self.counting_service.occupancy}", (10, 110), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 165, 0), 2)
            cv2.putText(frame, f"FPS: {fps:.1f}", (10, 150), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)

            # Broadcast updates
            asyncio.run_coroutine_threadsafe(
                self.analytics_service.aggregate_and_broadcast(
                    camera_id=self.camera_id,
                    new_entries=new_entries,
                    new_exits=new_exits,
                    current_occupancy=self.counting_service.occupancy,
                    fps=fps
                ),
                self.main_loop
            )

        if self.cap:
            self.cap.release()
