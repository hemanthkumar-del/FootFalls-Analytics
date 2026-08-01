import 'dart:ui';

class DetectionResult {
  final Rect boundingBox;
  final double confidence;
  final String label;
  final int classIndex;
  
  int? trackId;
  int age;
  int hits;
  int lostFrames;

  DetectionResult({
    required this.boundingBox,
    required this.confidence,
    required this.label,
    required this.classIndex,
    this.trackId,
    this.age = 0,
    this.hits = 0,
    this.lostFrames = 0,
  });

  @override
  String toString() {
    return 'DetectionResult(trackId: $trackId, label: $label, confidence: $confidence, boundingBox: $boundingBox, age: $age, hits: $hits, lostFrames: $lostFrames)';
  }
}
