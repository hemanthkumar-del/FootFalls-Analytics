import time
from collections import deque

class FPSCounter:
    def __init__(self, max_samples: int = 30):
        """
        Initializes the FPS counter.
        Args:
            max_samples: Number of frames to average the FPS over.
        """
        self.max_samples = max_samples
        self.frame_times = deque(maxlen=max_samples)
        self.start_time = time.time()
        self.current_fps = 0.0

    def update(self):
        """Updates the FPS counter with the current frame time."""
        current_time = time.time()
        self.frame_times.append(current_time)
        
        if len(self.frame_times) > 1:
            time_diff = self.frame_times[-1] - self.frame_times[0]
            if time_diff > 0:
                self.current_fps = (len(self.frame_times) - 1) / time_diff
        else:
            self.current_fps = 0.0

    def get_fps(self) -> float:
        """Returns the calculated FPS."""
        return self.current_fps
