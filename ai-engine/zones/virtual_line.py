from typing import Tuple

class VirtualLine:
    def __init__(self, line_id: str, start: Tuple[int, int], end: Tuple[int, int]):
        self.line_id = line_id
        self.start = start
        self.end = end
        
    def _compute_side(self, point: Tuple[int, int]) -> int:
        """
        Determines which side of the line a point is on using the cross product.
        Returns:
            1 for one side
            -1 for the other side
            0 if exactly on the line
        """
        x, y = point
        x1, y1 = self.start
        x2, y2 = self.end
        
        cross_product = (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1)
        
        if cross_product > 0:
            return 1
        elif cross_product < 0:
            return -1
        return 0

    def check_crossing(self, prev_point: Tuple[int, int], curr_point: Tuple[int, int]) -> str:
        """
        Checks if the movement from prev_point to curr_point crosses the line.
        Returns:
            'in' if crossing in one direction
            'out' if crossing in the opposite direction
            None if no crossing occurred
        """
        prev_side = self._compute_side(prev_point)
        curr_side = self._compute_side(curr_point)
        
        if prev_side != 0 and curr_side != 0 and prev_side != curr_side:
            # A crossing occurred!
            if prev_side == 1 and curr_side == -1:
                return 'in'
            elif prev_side == -1 and curr_side == 1:
                return 'out'
                
        return None
