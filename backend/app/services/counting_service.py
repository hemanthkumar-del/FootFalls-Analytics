class CountingService:
    def __init__(self, line_y: int = 300, deadzone: int = 20):
        self.line_y = line_y
        self.deadzone = deadzone

        # Track history:
        # {
        #   track_id: {
        #       "last_y": float,
        #       "crossed": bool,
        #       "direction": str | None
        #   }
        # }
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
            _, cy = obj["centroid"]
            current_ids.add(track_id)

            # First time seeing this person
            if track_id not in self.track_history:
                self.track_history[track_id] = {
                    "last_y": cy,
                    "crossed": False,
                    "direction": None,
                }
                print(f"[NEW TRACK] ID={track_id} | y={cy:.2f}")
                continue

            history = self.track_history[track_id]
            prev_y = history["last_y"]

            # Determine which side of the counting line
            prev_side = prev_y < self.line_y
            curr_side = cy < self.line_y

            # Debug every frame
            print(
                f"[TRACK] ID={track_id} | "
                f"PrevY={prev_y:.2f} | CurrY={cy:.2f} | "
                f"PrevSide={'TOP' if prev_side else 'BOTTOM'} | "
                f"CurrSide={'TOP' if curr_side else 'BOTTOM'}"
            )

            # Crossing detected
            if prev_side != curr_side:

                print(f"***** CROSSING DETECTED for ID={track_id} *****")

                if not history["crossed"]:

                    # Moving downward
                    if cy > prev_y:
                        new_entries += 1
                        self.entries += 1
                        self.occupancy += 1

                        history["direction"] = "entry"
                        history["crossed"] = True

                        print(
                            f"✅ ENTRY | "
                            f"Entries={self.entries} | "
                            f"Occupancy={self.occupancy}"
                        )

                    # Moving upward
                    else:
                        new_exits += 1
                        self.exits += 1
                        self.occupancy = max(0, self.occupancy - 1)

                        history["direction"] = "exit"
                        history["crossed"] = True

                        print(
                            f"⬆ EXIT | "
                            f"Exits={self.exits} | "
                            f"Occupancy={self.occupancy}"
                        )

            # Update last position
            history["last_y"] = cy

        # Cleanup disappeared tracks
        stale_ids = set(self.track_history.keys()) - current_ids

        for stale_id in stale_ids:
            print(f"[REMOVE TRACK] ID={stale_id}")
            del self.track_history[stale_id]

        return new_entries, new_exits