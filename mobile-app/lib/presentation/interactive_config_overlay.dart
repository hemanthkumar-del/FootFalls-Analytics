import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/detection_config_state.dart';

enum DragTarget { none, lineStart, lineEnd, roiCenter, roiTL, roiTR, roiBL, roiBR }

class InteractiveConfigOverlay extends ConsumerStatefulWidget {
  const InteractiveConfigOverlay({super.key});

  @override
  ConsumerState<InteractiveConfigOverlay> createState() => _InteractiveConfigOverlayState();
}

class _InteractiveConfigOverlayState extends ConsumerState<InteractiveConfigOverlay> {
  DragTarget _currentDrag = DragTarget.none;
  Offset _dragOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(detectionConfigProvider);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        if (!config.isConfigMode) {
          return CustomPaint(
            size: Size(width, height),
            painter: _ConfigPainter(config, showHandles: false),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            final pos = details.localPosition;
            _currentDrag = _hitTest(pos, width, height, config);
            if (_currentDrag == DragTarget.roiCenter) {
              final roiRect = Rect.fromLTRB(
                config.roi.left * width, config.roi.top * height,
                config.roi.right * width, config.roi.bottom * height,
              );
              _dragOffset = pos - roiRect.center;
            }
          },
          onPanUpdate: (details) {
            if (_currentDrag == DragTarget.none) return;
            
            final pos = details.localPosition;
            final normPos = Offset(
              (pos.dx / width).clamp(0.0, 1.0),
              (pos.dy / height).clamp(0.0, 1.0),
            );

            final notifier = ref.read(detectionConfigProvider.notifier);

            if (_currentDrag == DragTarget.lineStart) {
              notifier.updateLine(normPos, config.lineEnd);
            } else if (_currentDrag == DragTarget.lineEnd) {
              notifier.updateLine(config.lineStart, normPos);
            } else {
              double l = config.roi.left;
              double t = config.roi.top;
              double r = config.roi.right;
              double b = config.roi.bottom;

              if (_currentDrag == DragTarget.roiCenter) {
                final targetCenter = Offset(
                  ((pos.dx - _dragOffset.dx) / width),
                  ((pos.dy - _dragOffset.dy) / height),
                );
                final w = r - l;
                final h = b - t;
                l = (targetCenter.dx - w / 2).clamp(0.0, 1.0 - w);
                r = l + w;
                t = (targetCenter.dy - h / 2).clamp(0.0, 1.0 - h);
                b = t + h;
              } else if (_currentDrag == DragTarget.roiTL) {
                l = normPos.dx.clamp(0.0, r - 0.05);
                t = normPos.dy.clamp(0.0, b - 0.05);
              } else if (_currentDrag == DragTarget.roiTR) {
                r = normPos.dx.clamp(l + 0.05, 1.0);
                t = normPos.dy.clamp(0.0, b - 0.05);
              } else if (_currentDrag == DragTarget.roiBL) {
                l = normPos.dx.clamp(0.0, r - 0.05);
                b = normPos.dy.clamp(t + 0.05, 1.0);
              } else if (_currentDrag == DragTarget.roiBR) {
                r = normPos.dx.clamp(l + 0.05, 1.0);
                b = normPos.dy.clamp(t + 0.05, 1.0);
              }

              notifier.updateRoi(Rect.fromLTRB(l, t, r, b));
            }
          },
          onPanEnd: (_) {
            _currentDrag = DragTarget.none;
          },
          child: CustomPaint(
            size: Size(width, height),
            painter: _ConfigPainter(config, showHandles: true),
          ),
        );
      },
    );
  }

  DragTarget _hitTest(Offset pos, double width, double height, DetectionConfig config) {
    const double hitRadius = 30.0;
    
    final ls = Offset(config.lineStart.dx * width, config.lineStart.dy * height);
    final le = Offset(config.lineEnd.dx * width, config.lineEnd.dy * height);
    if ((pos - ls).distance < hitRadius) return DragTarget.lineStart;
    if ((pos - le).distance < hitRadius) return DragTarget.lineEnd;

    final roi = Rect.fromLTRB(
      config.roi.left * width, config.roi.top * height,
      config.roi.right * width, config.roi.bottom * height,
    );

    if ((pos - roi.topLeft).distance < hitRadius) return DragTarget.roiTL;
    if ((pos - roi.topRight).distance < hitRadius) return DragTarget.roiTR;
    if ((pos - roi.bottomLeft).distance < hitRadius) return DragTarget.roiBL;
    if ((pos - roi.bottomRight).distance < hitRadius) return DragTarget.roiBR;
    
    if (roi.contains(pos)) return DragTarget.roiCenter;

    return DragTarget.none;
  }
}

class _ConfigPainter extends CustomPainter {
  final DetectionConfig config;
  final bool showHandles;
  
  _ConfigPainter(this.config, {this.showHandles = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3.0;

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final handleBorder = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final roiPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final roiBorder = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final roi = Rect.fromLTRB(
      config.roi.left * w, config.roi.top * h,
      config.roi.right * w, config.roi.bottom * h,
    );
    canvas.drawRect(roi, roiPaint);
    canvas.drawRect(roi, roiBorder);

    final ls = Offset(config.lineStart.dx * w, config.lineStart.dy * h);
    final le = Offset(config.lineEnd.dx * w, config.lineEnd.dy * h);
    canvas.drawLine(ls, le, linePaint);

    if (showHandles) {
      void drawHandle(Offset center) {
        canvas.drawCircle(center, 8, handlePaint);
        canvas.drawCircle(center, 8, handleBorder);
      }

      drawHandle(ls);
      drawHandle(le);
      drawHandle(roi.topLeft);
      drawHandle(roi.topRight);
      drawHandle(roi.bottomLeft);
      drawHandle(roi.bottomRight);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfigPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.showHandles != showHandles;
  }
}
