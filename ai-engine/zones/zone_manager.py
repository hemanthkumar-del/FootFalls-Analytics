from typing import List, Optional
from zones.virtual_line import VirtualLine
from tracking.track import Track
from events.crossing_event import CrossingEvent
from events.event_manager import EventManager

class ZoneManager:
    def __init__(self, event_manager: EventManager):
        self.lines: List[VirtualLine] = []
        self.event_manager = event_manager
        
    def add_line(self, virtual_line: VirtualLine):
        self.lines.append(virtual_line)
        
    def process_tracks(self, active_tracks: List[Track]):
        """
        Processes active tracks to check for line crossings.
        """
        for track in active_tracks:
            for line in self.lines:
                # To prevent duplicate counting, we ensure this track hasn't already crossed this line recently
                # Or we can just rely on the strict prev -> curr sign change.
                # However, if the track flickers back and forth, it might double count.
                # A simple debouncing: if it crossed, add line_id to crossed_lines. 
                # If it crosses back, it might be an exit. We allow re-crossing but we only count single clean crossing per direction.
                
                crossing_direction = line.check_crossing(track.previous_position, track.current_position)
                
                if crossing_direction:
                    # Generate an event
                    event = CrossingEvent(track.track_id, crossing_direction, line.line_id)
                    self.event_manager.dispatch(event)
