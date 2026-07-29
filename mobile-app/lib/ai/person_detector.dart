import 'dart:typed_data';
import 'package:footfalls_app/ai/yolo_service.dart';
import 'package:footfalls_app/ai/detection_result.dart';
import 'package:flutter/foundation.dart';

class PersonDetector {
  final YoloService _yoloService;

  PersonDetector() : _yoloService = YoloService();

  Future<void> initialize() async {
    await _yoloService.initialize();
  }

  // Detects persons from a float32 tensor representing an image
  // This can be run in a compute function if processing is heavy,
  // but tflite_flutter's run() is typically fast if delegated correctly.
  // We'll wrap it in a Future to avoid blocking the main thread synchronously.
  Future<List<DetectionResult>> detect(Float32List frameTensor, int width, int height) async {
    // For robust performance, we could use compute() here, but passing large Float32List
    // between isolates can incur overhead. For YOLOv8n, on-thread async is often okay if C++ backend handles it,
    // but the parsing logic takes time. Let's use compute if needed, but for now run locally.
    
    // To prevent UI stutter, one could do:
    // return compute(_detectInIsolate, {'tensor': frameTensor, 'width': width, 'height': height});
    // But since _interpreter isn't transferable easily, we keep inference here.
    
    return _yoloService.infer(frameTensor, width, height);
  }
}
