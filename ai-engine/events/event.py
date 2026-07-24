import time
import uuid

class Event:
    def __init__(self, track_id: int):
        self.event_id = str(uuid.uuid4())
        self.track_id = track_id
        self.timestamp = time.time()
