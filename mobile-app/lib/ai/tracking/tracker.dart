import 'dart:ui';
import 'track.dart';
import 'track_state.dart';
import 'bipartite_matcher.dart';
import '../detection_result.dart';

class Tracker {
  final double trackActivationThreshold;
  final int maxLostFrames;
  final double matchIouThreshold;

  final List<Track> tracks = [];
  int _nextTrackId = 1;

  Tracker({
    this.trackActivationThreshold = 0.25,
    this.maxLostFrames = 60, // 2 seconds at 30 fps
    this.matchIouThreshold = 0.2, // corresponds to supervision's 0.8 cost
  });

  List<Track> update(List<DetectionResult> detections) {
    // 1. Predict new locations for all tracks
    for (var t in tracks) {
      if (t.state != TrackState.removed) {
        t.predict();
      }
    }

    // 2. Split detections into high and low score
    List<DetectionResult> highScoreDetections = [];
    List<DetectionResult> lowScoreDetections = [];

    for (var d in detections) {
      if (d.confidence >= trackActivationThreshold) {
        highScoreDetections.add(d);
      } else {
        lowScoreDetections.add(d);
      }
    }

    // Active and lost tracks
    List<Track> activeTracks = tracks.where((t) => t.state == TrackState.tracked).toList();
    List<Track> lostTracks = tracks.where((t) => t.state == TrackState.lost).toList();
    List<Track> unconfirmedTracks = tracks.where((t) => t.state == TrackState.newTrack).toList();

    List<Track> trackPool = [...activeTracks, ...lostTracks];

    // --- First Association: High Score Detections ---
    List<Rect> trackPoolBoxes = trackPool.map((t) => t.getPredictedBoundingBox()).toList();
    List<Rect> highDetBoxes = highScoreDetections.map((d) => d.boundingBox).toList();

    var match1 = BipartiteMatcher.match(trackPoolBoxes, highDetBoxes, matchIouThreshold);

    List<Track> matchedTracks = [];
    List<Track> unmatchedTracks1 = [];
    List<DetectionResult> unmatchedDetections1 = [];

    match1.matchedIndices.forEach((trackIdx, detIdx) {
      Track t = trackPool[trackIdx];
      DetectionResult d = highScoreDetections[detIdx];
      t.update(d);
      d.trackId = t.trackId;
      d.age = t.age;
      d.hits = t.hits;
      d.lostFrames = t.timeSinceUpdate;
      matchedTracks.add(t);
    });

    for (int idx in match1.unmatchedA) {
      unmatchedTracks1.add(trackPool[idx]);
    }
    for (int idx in match1.unmatchedB) {
      unmatchedDetections1.add(highScoreDetections[idx]);
    }

    // --- Second Association: Low Score Detections vs Unmatched Tracks ---
    // ByteTrack associates low score detections with remaining tracks
    List<Track> trackPool2 = unmatchedTracks1.where((t) => t.state == TrackState.tracked).toList();
    List<Rect> trackPool2Boxes = trackPool2.map((t) => t.getPredictedBoundingBox()).toList();
    List<Rect> lowDetBoxes = lowScoreDetections.map((d) => d.boundingBox).toList();

    var match2 = BipartiteMatcher.match(trackPool2Boxes, lowDetBoxes, 0.5); // Stricter IOU for low score

    match2.matchedIndices.forEach((trackIdx, detIdx) {
      Track t = trackPool2[trackIdx];
      DetectionResult d = lowScoreDetections[detIdx];
      t.update(d);
      d.trackId = t.trackId;
      d.age = t.age;
      d.hits = t.hits;
      d.lostFrames = t.timeSinceUpdate;
      matchedTracks.add(t);
    });

    List<Track> unmatchedTracks2 = [];
    for (int idx in match2.unmatchedA) {
      unmatchedTracks2.add(trackPool2[idx]);
    }

    // The remaining tracks from unmatchedTracks1 that were not tracked (e.g. lost tracks) 
    // are also carried over as unmatched
    List<Track> remainingLostTracks = unmatchedTracks1.where((t) => t.state != TrackState.tracked).toList();
    unmatchedTracks2.addAll(remainingLostTracks);


    // --- Third Association: Unconfirmed tracks vs remaining high score detections ---
    List<Rect> unconfirmedBoxes = unconfirmedTracks.map((t) => t.getPredictedBoundingBox()).toList();
    List<Rect> remainingHighDetBoxes = unmatchedDetections1.map((d) => d.boundingBox).toList();
    
    var match3 = BipartiteMatcher.match(unconfirmedBoxes, remainingHighDetBoxes, 0.7);

    match3.matchedIndices.forEach((trackIdx, detIdx) {
      Track t = unconfirmedTracks[trackIdx];
      DetectionResult d = unmatchedDetections1[detIdx];
      t.update(d);
      d.trackId = t.trackId;
      d.age = t.age;
      d.hits = t.hits;
      d.lostFrames = t.timeSinceUpdate;
      matchedTracks.add(t);
    });

    for (int idx in match3.unmatchedA) {
      unconfirmedTracks[idx].markRemoved();
    }

    List<DetectionResult> completelyUnmatchedDetections = [];
    for (int idx in match3.unmatchedB) {
      completelyUnmatchedDetections.add(unmatchedDetections1[idx]);
    }


    // --- Create New Tracks ---
    for (var d in completelyUnmatchedDetections) {
      if (d.confidence >= trackActivationThreshold) {
        Track newTrack = Track(trackId: _nextTrackId++, detection: d);
        d.trackId = newTrack.trackId;
        d.age = newTrack.age;
        d.hits = newTrack.hits;
        d.lostFrames = newTrack.timeSinceUpdate;
        tracks.add(newTrack);
      }
    }

    // --- Update Lost Tracks ---
    for (var t in unmatchedTracks2) {
      if (t.state != TrackState.lost) {
        t.markLost();
      }
    }

    // --- Remove old tracks ---
    for (var t in tracks) {
      if (t.state == TrackState.lost && t.timeSinceUpdate > maxLostFrames) {
        t.markRemoved();
      }
    }

    // Cleanup removed tracks
    tracks.removeWhere((t) => t.state == TrackState.removed);

    // Return all currently active tracks for rendering and crossing logic
    return tracks.where((t) => t.state == TrackState.tracked || t.state == TrackState.newTrack).toList();
  }
}
