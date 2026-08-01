import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'track_state.dart';
import 'kalman_filter.dart';
import '../detection_result.dart';

class Track {
  final int trackId;
  Rect boundingBox;
  double confidence;
  String label;
  int classIndex;

  late Point<double> currentPosition;
  late Point<double> previousPosition;
  final List<Point<double>> trajectory = [];
  static const int maxTrajectoryLength = 60;

  TrackState state;
  int hits = 1;
  int age = 1;
  int timeSinceUpdate = 0;

  final KalmanFilter kf;

  // Timings
  final DateTime creationTime = DateTime.now();
  DateTime lastSeenTime = DateTime.now();

  Track({
    required this.trackId,
    required DetectionResult detection,
  })  : boundingBox = detection.boundingBox,
        confidence = detection.confidence,
        label = detection.label,
        classIndex = detection.classIndex,
        state = TrackState.newTrack,
        kf = KalmanFilter() {
    
    currentPosition = _getCenter(boundingBox);
    previousPosition = currentPosition;
    trajectory.add(currentPosition);

    kf.initiate([
      boundingBox.center.dx,
      boundingBox.center.dy,
      boundingBox.width / boundingBox.height,
      boundingBox.height
    ]);
  }

  Point<double> _getCenter(Rect bbox) {
    // Bottom center for crossing accuracy
    return Point(bbox.center.dx, bbox.bottom);
  }

  void predict() {
    kf.predict();
    age += 1;
    timeSinceUpdate += 1;
  }

  void update(DetectionResult detection) {
    boundingBox = detection.boundingBox;
    confidence = detection.confidence;

    previousPosition = currentPosition;
    currentPosition = _getCenter(boundingBox);
    trajectory.add(currentPosition);
    if (trajectory.length > maxTrajectoryLength) {
      trajectory.removeAt(0);
    }

    lastSeenTime = DateTime.now();
    hits += 1;
    timeSinceUpdate = 0;

    if (state == TrackState.newTrack && hits >= 1) { // Normally 3, but keeping it responsive
      state = TrackState.tracked;
    }
    if (state == TrackState.lost) {
      state = TrackState.tracked;
    }

    kf.update([
      boundingBox.center.dx,
      boundingBox.center.dy,
      boundingBox.width / boundingBox.height,
      boundingBox.height
    ]);
  }

  void markLost() {
    if (state == TrackState.tracked) {
      state = TrackState.lost;
    }
  }

  void markRemoved() {
    state = TrackState.removed;
  }

  /// Returns the bounding box predicted by the Kalman filter.
  Rect getPredictedBoundingBox() {
    if (timeSinceUpdate > 0) {
      List<double> stateObj = kf.getState();
      double cx = stateObj[0];
      double cy = stateObj[1];
      double a = stateObj[2];
      double h = stateObj[3];

      double w = a * h;
      return Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    }
    return boundingBox;
  }

  bool get isActive => state == TrackState.tracked;
}
