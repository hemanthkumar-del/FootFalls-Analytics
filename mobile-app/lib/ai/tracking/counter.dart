import 'dart:math';
import 'package:flutter/foundation.dart';
import 'track.dart';
import 'virtual_line.dart';

class Counter {
  int totalEntered = 0;
  int totalExited = 0;

  final Map<int, String> lastCrossings = {};
  final List<VirtualLine> lines = [];

  Counter();

  void addLine(VirtualLine line) {
    lines.add(line);
  }

  void processTracks(List<Track> activeTracks) {
    for (var track in activeTracks) {
      if (track.trajectory.length < 2) continue;

      for (var line in lines) {
        String? direction = line.checkCrossing(track.previousPosition, track.currentPosition);

        if (direction != null) {
          _handleCrossing(track.trackId, direction);
        }
      }
    }
  }

  void _handleCrossing(int trackId, String direction) {
    // Prevent duplicate counts (debounce)
    if (lastCrossings[trackId] == direction) {
      return;
    }

    lastCrossings[trackId] = direction;

    if (direction == 'in') {
      totalEntered += 1;
      debugPrint("Track $trackId entered. Total In: $totalEntered");
    } else if (direction == 'out') {
      totalExited += 1;
      debugPrint("Track $trackId exited. Total Out: $totalExited");
    }
  }

  int getOccupancy() {
    return max(0, totalEntered - totalExited);
  }

  void reset() {
    totalEntered = 0;
    totalExited = 0;
    lastCrossings.clear();
  }
}
