import cv2
from config.settings import settings
from utils.camera import Camera
from utils.fps import FPSCounter
from utils.drawing import draw_bounding_box, draw_fps, draw_virtual_line, draw_statistics
from detection.detector import PersonDetector
from tracking.tracker import PersonTracker
from events.event_manager import EventManager
from zones.virtual_line import VirtualLine
from zones.zone_manager import ZoneManager
from counting.counter import CounterEngine

class FootFallsPipeline:
    def __init__(self):
        """
        Initializes the entire processing pipeline: Camera -> Detection -> Tracking -> Counting.
        """
        self.camera = Camera()
        self.detector = PersonDetector()
        self.tracker = PersonTracker()
        self.fps_counter = FPSCounter()
        
        # Counting & Events
        self.event_manager = EventManager()
        self.counter_engine = CounterEngine()
        self.zone_manager = ZoneManager(self.event_manager)
        
        # Create default line
        line = VirtualLine("main_entrance", settings.LINE_START, settings.LINE_END)
        self.zone_manager.add_line(line)
        
        # Connect EventManager to CounterEngine
        self.event_manager.add_listener(self.counter_engine.handle_crossing_event)
        
        self.is_running = False

    def run(self):
        """
        Starts the pipeline execution loop.
        """
        self.is_running = True
        print("Starting FootFalls Pipeline. Press 'q' to exit.")
        while self.is_running:
            ret, frame = self.camera.read_frame()
            if not ret or frame is None:
                print("Warning: Could not read frame from camera or stream ended.")
                break
                
            # 1. Detection
            detections = self.detector.detect(frame)
            
            # 2. Tracking
            active_tracks = self.tracker.update(detections)
            
            # 3. Zone Management (Crossing Detection)
            self.zone_manager.process_tracks(active_tracks)
            
            # 4. Drawing
            draw_virtual_line(frame, settings.LINE_START, settings.LINE_END)
            
            for track in active_tracks:
                label = f"Person #{track.track_id}"
                bbox_int = [int(x) for x in track.bbox]
                draw_bounding_box(frame, bbox_int, track.confidence, label=label)
                
            # 5. Statistics & FPS Display
            self.fps_counter.update()
            draw_fps(frame, self.fps_counter.get_fps())
            
            draw_statistics(
                frame,
                self.counter_engine.total_entered,
                self.counter_engine.total_exited,
                self.counter_engine.get_occupancy()
            )
            
            # 6. Display
            cv2.imshow("FootFalls - Engine", frame)
            
            if cv2.waitKey(1) & 0xFF == ord('q'):
                print("Exiting pipeline...")
                break
                
        self.cleanup()

    def cleanup(self):
        """Releases resources."""
        self.camera.release()
        cv2.destroyAllWindows()
