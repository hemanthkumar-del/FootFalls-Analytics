import cv2
import asyncio
import threading
import time
import logging
import struct
import json
from app.services.tracking_service import TrackingService
from app.services.counting_service import CountingService
from app.services.analytics_service import AnalyticsService
from app.api.websocket import video_manager

logger = logging.getLogger(__name__)

class CameraWorkerRegistry:
    def __init__(self):
        self.workers = {}
        self.lock = threading.Lock()

    def add_worker(self, camera_id: str, url: str, main_loop: asyncio.AbstractEventLoop):
        with self.lock:
            if camera_id in self.workers:
                self.stop_worker(camera_id)
            
            worker = CameraService(camera_id, url, main_loop)
            self.workers[camera_id] = worker
            worker.start()
            return True

    def stop_worker(self, camera_id: str):
        with self.lock:
            worker = self.workers.pop(camera_id, None)
            if worker:
                worker.stop()
                return True
            return False

    def get_worker(self, camera_id: str):
        return self.workers.get(camera_id)

    def stop_all(self):
        with self.lock:
            for worker in self.workers.values():
                worker.stop()
            self.workers.clear()

worker_registry = CameraWorkerRegistry()

class CameraService:
    def __init__(self, camera_id: str, url: str, main_loop: asyncio.AbstractEventLoop):
        self.camera_id = camera_id
        # Parse integers (0, 1) for local webcams, leave string for RTSP
        self.url = int(url) if url.isdigit() else url
        self.cap = None
        self.running = False
        self.main_loop = main_loop
        
        self.tracking_service = TrackingService()
        # Set line Y at 240 (assuming typical 640x480 webcam) - Actually using 640x640 now so 320
        self.counting_service = CountingService(line_y=320, deadzone=20)
        self.analytics_service = AnalyticsService()
        
        self.thread = None

    def start(self):
        if self.running:
            return
        self.running = True
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
        import numpy as np
        demo_mode = False
        self.cap = cv2.VideoCapture(self.url)
        if not self.cap.isOpened():
            if str(self.url) == "0":
                logger.warning(f"No physical webcam found at URL 0. Falling back to Demo Mode.")
                demo_mode = True
            else:
                logger.error(f"Failed to connect to camera {self.camera_id} at {self.url}. Retrying later...")
            
        prev_time = time.time()
        
        while self.running:
            if not demo_mode and (not self.cap or not self.cap.isOpened()):
                logger.warning(f"Reconnecting camera {self.camera_id}...")
                self.cap = cv2.VideoCapture(self.url)
                if not self.cap.isOpened():
                    if str(self.url) == "0":
                        logger.warning(f"Fallback to Demo Mode for {self.camera_id}.")
                        demo_mode = True
                    else:
                        time.sleep(2)
                        continue

            try:
                if demo_mode:
                    frame = np.zeros((640, 640, 3), dtype=np.uint8)
                    cv2.putText(frame, "DEMO MODE", (150, 320), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 0, 255), 3)
                    time.sleep(1/30.0) # simulate 30fps
                else:
                    ret, frame = self.cap.read()
                    if not ret:
                        logger.warning(f"[CAM_ID: {self.camera_id}] Empty frame. Stream might have dropped.")
                        self.cap.release()
                        time.sleep(1)
                        continue
                    frame = cv2.resize(frame, (640, 640))
            except cv2.error as e:
                logger.error(f"[CAM_ID: {self.camera_id}] OpenCV Error: {e}")
                self.cap.release()
                time.sleep(1)
                continue

            curr_time = time.time()
            fps = 1.0 / max((curr_time - prev_time), 0.001)
            prev_time = curr_time

            # 1. Process Frame (YOLO + ByteTrack)
            tracked_objects = self.tracking_service.process_frame(frame)

            # 2. Virtual Line Counting
            new_entries, new_exits = self.counting_service.update_counts(tracked_objects)

            # 3. Handle Events and Broadcasting
            boxes_meta = []
            total_conf = 0.0

            for obj in tracked_objects:
                track_id = obj["id"]
                bbox = obj.get("bbox")
                conf = obj.get("confidence", 0.0)
                cls_name = obj.get("class", "person")
                total_conf += conf
                
                if bbox:
                    x1, y1, x2, y2 = map(int, bbox)
                    boxes_meta.append({
                        "id": track_id,
                        "x1": x1, "y1": y1, "x2": x2, "y2": y2,
                        "confidence": conf,
                        "class": cls_name
                    })
                
                history = self.counting_service.track_history.get(track_id)
                if history and history["crossed"]:
                    direction = history.get("direction")
                    if direction:
                        history["direction"] = None 
                        asyncio.run_coroutine_threadsafe(
                            self.analytics_service.log_event(self.camera_id, direction, track_id),
                            self.main_loop
                        )

            avg_conf = total_conf / max(len(tracked_objects), 1)

            # 4. Stream video & metadata over dedicated websocket
            metadata = {
                "camera_id": self.camera_id,
                "timestamp": curr_time,
                "occupancy": self.counting_service.occupancy,
                "entries": self.analytics_service.total_entries + new_entries,
                "exits": self.analytics_service.total_exits + new_exits,
                "persons_detected": len(tracked_objects),
                "fps": fps,
                "average_detection_confidence": avg_conf,
                "boxes": boxes_meta
            }

            # Encode frame to JPEG
            encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 85]
            _, buffer = cv2.imencode('.jpg', frame, encode_param)
            jpeg_bytes = buffer.tobytes()

            json_bytes = json.dumps(metadata).encode('utf-8')
            # Custom binary protocol: 4-byte little-endian JSON length + JSON bytes + JPEG bytes
            payload = struct.pack('<I', len(json_bytes)) + json_bytes + jpeg_bytes

            asyncio.run_coroutine_threadsafe(
                video_manager.broadcast_video(self.camera_id, payload),
                self.main_loop
            )

            # 5. Broadcast general dashboard updates (throttled locally in analytics_service)
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
