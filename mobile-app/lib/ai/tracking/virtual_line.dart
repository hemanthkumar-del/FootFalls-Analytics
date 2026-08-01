import 'dart:math';

class VirtualLine {
  final String lineId;
  final Point<double> start;
  final Point<double> end;

  VirtualLine({
    required this.lineId,
    required this.start,
    required this.end,
  });

  int _computeSide(Point<double> point) {
    /*
        Determines which side of the line a point is on using the cross product.
        Returns:
            1 for one side
            -1 for the other side
            0 if exactly on the line
    */
    double x = point.x;
    double y = point.y;
    double x1 = start.x;
    double y1 = start.y;
    double x2 = end.x;
    double y2 = end.y;

    double crossProduct = (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1);

    if (crossProduct > 0) {
      return 1;
    } else if (crossProduct < 0) {
      return -1;
    }
    return 0;
  }

  String? checkCrossing(Point<double> prevPoint, Point<double> currPoint) {
    /*
        Checks if the movement from prevPoint to currPoint crosses the line.
        Returns:
            'in' if crossing in one direction
            'out' if crossing in the opposite direction
            null if no crossing occurred
    */
    int prevSide = _computeSide(prevPoint);
    int currSide = _computeSide(currPoint);

    if (prevSide != 0 && currSide != 0 && prevSide != currSide) {
      // A crossing occurred!
      if (prevSide == 1 && currSide == -1) {
        return 'in';
      } else if (prevSide == -1 && currSide == 1) {
        return 'out';
      }
    }
    return null;
  }
}
