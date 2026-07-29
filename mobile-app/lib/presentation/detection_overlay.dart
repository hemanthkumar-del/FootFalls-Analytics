import 'package:flutter/material.dart';
import 'package:footfalls_app/ai/detection_result.dart';

class DetectionOverlay extends CustomPainter {
  final List<DetectionResult> detections;
  final Size frameSize;

  DetectionOverlay({
    required this.detections,
    required this.frameSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty || frameSize.width == 0 || frameSize.height == 0) return;

    final double scaleX = size.width / frameSize.width;
    final double scaleY = size.height / frameSize.height;

    final Paint boxPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Paint textBackgroundPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    for (var det in detections) {
      // Scale bounding box to the current screen size
      final Rect scaledBox = Rect.fromLTRB(
        det.boundingBox.left * scaleX,
        det.boundingBox.top * scaleY,
        det.boundingBox.right * scaleX,
        det.boundingBox.bottom * scaleY,
      );

      // Draw bounding box
      canvas.drawRect(scaledBox, boxPaint);

      // Draw label and confidence
      final text = '${det.label} ${(det.confidence * 100).toStringAsFixed(1)}%';
      const textStyle = TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      );
      
      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw text background
      final textBgRect = Rect.fromLTWH(
        scaledBox.left,
        scaledBox.top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      
      // Ensure text isn't drawn off-screen at the top
      if (textBgRect.top < 0) {
        final adjustedBgRect = Rect.fromLTWH(
          scaledBox.left,
          scaledBox.top,
          textPainter.width + 8,
          textPainter.height + 4,
        );
        canvas.drawRect(adjustedBgRect, textBackgroundPaint);
        textPainter.paint(canvas, Offset(adjustedBgRect.left + 4, adjustedBgRect.top + 2));
      } else {
        canvas.drawRect(textBgRect, textBackgroundPaint);
        textPainter.paint(canvas, Offset(textBgRect.left + 4, textBgRect.top + 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant DetectionOverlay oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.frameSize != frameSize;
  }
}
