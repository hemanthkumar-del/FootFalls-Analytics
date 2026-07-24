from typing import List, Callable
from events.event import Event
from collections import deque

class EventManager:
    def __init__(self, max_history: int = 1000):
        self.events: List[Event] = []
        self.listeners: List[Callable[[Event], None]] = []
        self.history = deque(maxlen=max_history)
        
    def add_listener(self, callback: Callable[[Event], None]):
        self.listeners.append(callback)
        
    def dispatch(self, event: Event):
        self.events.append(event)
        self.history.append(event)
        for listener in self.listeners:
            listener(event)
            
    def get_recent_events(self) -> List[Event]:
        return list(self.history)
        
    def clear_history(self):
        self.history.clear()
        self.events.clear()
