import 'dart:math';
import 'package:flutter/material.dart';

class BipartiteMatcher {
  static double iou(Rect a, Rect b) {
    double left = max(a.left, b.left);
    double top = max(a.top, b.top);
    double right = min(a.right, b.right);
    double bottom = min(a.bottom, b.bottom);

    if (left >= right || top >= bottom) {
      return 0.0;
    }

    double intersection = (right - left) * (bottom - top);
    double areaA = a.width * a.height;
    double areaB = b.width * b.height;

    return intersection / (areaA + areaB - intersection);
  }

  /// Greedy matcher based on cost matrix.
  /// Cost is 1.0 - IOU, so lower is better.
  /// Returns a tuple of (matchedIndices, unmatchedA, unmatchedB)
  /// matchedIndices is a map of indexA -> indexB
  static MatchResult match(
    List<Rect> boxesA,
    List<Rect> boxesB,
    double iouThreshold,
  ) {
    int numA = boxesA.length;
    int numB = boxesB.length;

    List<CostTuple> costs = [];

    for (int i = 0; i < numA; i++) {
      for (int j = 0; j < numB; j++) {
        double overlap = iou(boxesA[i], boxesB[j]);
        if (overlap >= iouThreshold) {
          costs.add(CostTuple(i, j, 1.0 - overlap));
        }
      }
    }

    // Sort by cost ascending
    costs.sort((a, b) => a.cost.compareTo(b.cost));

    Map<int, int> matchedA = {};
    Set<int> matchedB = {};

    for (var costTuple in costs) {
      if (!matchedA.containsKey(costTuple.i) && !matchedB.contains(costTuple.j)) {
        matchedA[costTuple.i] = costTuple.j;
        matchedB.add(costTuple.j);
      }
    }

    List<int> unmatchedA = [];
    for (int i = 0; i < numA; i++) {
      if (!matchedA.containsKey(i)) {
        unmatchedA.add(i);
      }
    }

    List<int> unmatchedB = [];
    for (int j = 0; j < numB; j++) {
      if (!matchedB.contains(j)) {
        unmatchedB.add(j);
      }
    }

    return MatchResult(matchedA, unmatchedA, unmatchedB);
  }
}

class CostTuple {
  final int i;
  final int j;
  final double cost;

  CostTuple(this.i, this.j, this.cost);
}

class MatchResult {
  final Map<int, int> matchedIndices; // index in A -> index in B
  final List<int> unmatchedA;
  final List<int> unmatchedB;

  MatchResult(this.matchedIndices, this.unmatchedA, this.unmatchedB);
}
