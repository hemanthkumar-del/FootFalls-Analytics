import 'dart:typed_data';

class BoundingBox {
  final int id;
  final int x1;
  final int y1;
  final int x2;
  final int y2;
  final double confidence;
  final String className;

  BoundingBox({
    required this.id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.className,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      id: json['id'] ?? 0,
      x1: json['x1'] ?? 0,
      y1: json['y1'] ?? 0,
      x2: json['x2'] ?? 0,
      y2: json['y2'] ?? 0,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      className: json['class'] ?? 'person',
    );
  }
}

class VideoMetadata {
  final String cameraId;
  final double timestamp;
  final int occupancy;
  final int entries;
  final int exits;
  final int personsDetected;
  final double fps;
  final double averageDetectionConfidence;
  final List<BoundingBox> boxes;

  VideoMetadata({
    required this.cameraId,
    required this.timestamp,
    required this.occupancy,
    required this.entries,
    required this.exits,
    required this.personsDetected,
    required this.fps,
    required this.averageDetectionConfidence,
    required this.boxes,
  });

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      cameraId: json['camera_id'] ?? '',
      timestamp: (json['timestamp'] ?? 0.0).toDouble(),
      occupancy: json['occupancy'] ?? 0,
      entries: json['entries'] ?? 0,
      exits: json['exits'] ?? 0,
      personsDetected: json['persons_detected'] ?? 0,
      fps: (json['fps'] ?? 0.0).toDouble(),
      averageDetectionConfidence: (json['average_detection_confidence'] ?? 0.0).toDouble(),
      boxes: (json['boxes'] as List?)?.map((e) => BoundingBox.fromJson(e)).toList() ?? [],
    );
  }
}

class VideoFrame {
  final VideoMetadata metadata;
  final Uint8List imageBytes;

  VideoFrame({
    required this.metadata,
    required this.imageBytes,
  });
}
