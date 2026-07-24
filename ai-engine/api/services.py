import threading
import time
from core.pipeline import FootFallsPipeline

class AIEngineService:
    _instance = None
    _lock = threading.Lock()
    
    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(AIEngineService, cls).__new__(cls)
                cls._instance.pipeline = None
                cls._instance.thread = None
        return cls._instance

    def start(self):
        """Starts the AI engine in a background thread."""
        if self.pipeline is None:
            self.pipeline = FootFallsPipeline()
            
        if self.thread is None or not self.thread.is_alive():
            self.thread = threading.Thread(target=self.pipeline.run, daemon=True)
            self.thread.start()
            # Give it a moment to initialize the camera
            time.sleep(2)
            
    def stop(self):
        """Stops the AI engine."""
        if self.pipeline:
            self.pipeline.is_running = False
        if self.thread:
            self.thread.join(timeout=2.0)
            
    def get_pipeline(self) -> FootFallsPipeline:
        return self.pipeline

engine_service = AIEngineService()
