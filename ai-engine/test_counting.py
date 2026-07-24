import time
from events.crossing_event import CrossingEvent
from events.event_manager import EventManager
from counting.counter import CounterEngine
from tracking.track import Track
from zones.virtual_line import VirtualLine
from zones.zone_manager import ZoneManager

def main():
    print("Testing counting logic...")
    
    event_manager = EventManager()
    counter_engine = CounterEngine()
    event_manager.add_listener(counter_engine.handle_crossing_event)
    
    zone_manager = ZoneManager(event_manager)
    line = VirtualLine("test_line", (100, 320), (500, 320))
    zone_manager.add_line(line)
    
    # Simulate a track moving from above the line to below the line (Entering)
    print("Scenario: Person enters")
    track1 = Track(1, [200, 250, 250, 300], 0.9) # Center y: 300 (Above line)
    zone_manager.process_tracks([track1])
    
    track1.update([200, 280, 250, 330], 0.9) # Center y: 330 (Crossed line, Below line)
    zone_manager.process_tracks([track1])
    
    # Simulate duplicate crossing due to flickering (should be ignored)
    print("Scenario: Flickering/duplicate crossing")
    track1.update([200, 290, 250, 340], 0.9)
    zone_manager.process_tracks([track1])
    track1.update([200, 270, 250, 310], 0.9) # Moved back above line (exiting)
    zone_manager.process_tracks([track1])
    track1.update([200, 280, 250, 330], 0.9) # Moved below line again (Entering, ignored by debouncer unless it officially exited... wait, if they exit, they can enter again!)
    zone_manager.process_tracks([track1])
    
    print(f"Final Count -> Entered: {counter_engine.total_entered}, Exited: {counter_engine.total_exited}, Occupancy: {counter_engine.get_occupancy()}")

if __name__ == "__main__":
    main()
