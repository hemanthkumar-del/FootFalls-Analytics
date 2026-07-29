import 'dart:ui';

class DetectionResult {
  final Rect boundingBox;
  final double confidence;
  final String label;
  final int classIndex;

  DetectionResult({
    required this.boundingBox,
    required this.confidence,
    required this.label,
    required this.classIndex,
  });

  @override
  String toString() {
    return 'DetectionResult(label: $label, confidence: $confidence, boundingBox: $boundingBox)';
  }
}
