from events.event import Event

class CrossingEvent(Event):
    def __init__(self, track_id: int, direction: str, line_id: str):
        """
        direction: 'in' or 'out'
        """
        super().__init__(track_id)
        self.direction = direction
        self.line_id = line_id
