class CountingService:
    def __init__(self, line_y: int = 300, deadzone: int = 20):
        self.line_y = line_y
        self.deadzone = deadzone  # Hysteresis to prevent bouncing
        
        # Track history: { track_id: {"last_y": int, "crossed": bool, "direction": str} }
        self.track_history = {}
        self.entries = 0
        self.exits = 0
        self.occupancy = 0

    def update_counts(self, tracked_objects: list) -> tuple:
        new_entries = 0
        new_exits = 0
        current_ids = set()

        for obj in tracked_objects:
            track_id = obj["id"]
            cx, cy = obj["centroid"]
            current_ids.add(track_id)

            if track_id not in self.track_history:
                self.track_history[track_id] = {"last_y": cy, "crossed": False, "direction": None}
                continue

            history = self.track_history[track_id]
            prev_y = history["last_y"]

            # Only count if it hasn't crossed yet
            if not history["crossed"]:
                # Entry: Moving downwards (y increases) across the line + deadzone
                if prev_y < (self.line_y - self.deadzone) and cy > (self.line_y + self.deadzone):
                    new_entries += 1
                    self.entries += 1
                    self.occupancy += 1
                    history["crossed"] = True
                    history["direction"] = "entry"
                
                # Exit: Moving upwards (y decreases) across the line - deadzone
                elif prev_y > (self.line_y + self.deadzone) and cy < (self.line_y - self.deadzone):
                    new_exits += 1
                    self.exits += 1
                    self.occupancy = max(0, self.occupancy - 1)
                    history["crossed"] = True
                    history["direction"] = "exit"

            # Update last_y for the next frame calculation
            history["last_y"] = cy

        # Memory cleanup for lost tracks
        stale_ids = set(self.track_history.keys()) - current_ids
        for stale_id in stale_ids:
            del self.track_history[stale_id]

        return new_entries, new_exits
