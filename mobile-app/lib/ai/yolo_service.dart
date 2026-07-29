import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:footfalls_app/ai/detection_result.dart';

class YoloService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.5;

  Future<void> initialize() async {
    try {
      // Load labels
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // Attempt to load the real TFLite model
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset('assets/models/yolov8n_float32.tflite', options: options);
    } catch (e) {
      debugPrint('YoloService: Failed to load real model. Error: $e');
    }
  }

  List<DetectionResult> infer(Float32List inputTensor, int imageWidth, int imageHeight) {
    if (_interpreter == null) return [];

    // YOLOv8n output shape is usually [1, 84, 8400]
    // 84 = 4 bounding box coordinates (cx, cy, w, h) + 80 class confidences
    // 8400 = anchor boxes
    
    // We prepare the output tensor
    var output = List.generate(1, (i) => List.generate(84, (j) => List.filled(8400, 0.0)));
    
    // Reshape input float list into [1, 640, 640, 3] depending on the model expected shape
    var input = inputTensor.reshape([1, inputSize, inputSize, 3]);

    _interpreter!.run(input, output);

    return _parseYOLOv8Output(output[0], imageWidth, imageHeight);
  }

  List<DetectionResult> _parseYOLOv8Output(List<List<double>> output, int imageWidth, int imageHeight) {
    List<DetectionResult> results = [];
    
    // output is [84, 8400]
    for (int i = 0; i < 8400; i++) {
      // Find the class with the highest confidence
      double maxClassConf = 0;
      int classIndex = -1;
      
      for (int c = 0; c < 80; c++) {
        double conf = output[4 + c][i];
        if (conf > maxClassConf) {
          maxClassConf = conf;
          classIndex = c;
        }
      }

      // We only care about person (class 0)
      if (classIndex == 0 && maxClassConf > confidenceThreshold) {
        double cx = output[0][i];
        double cy = output[1][i];
        double w = output[2][i];
        double h = output[3][i];

        // YOLO coords are normalized to model input size (640), scale them back
        double xMin = (cx - w / 2) / inputSize * imageWidth;
        double yMin = (cy - h / 2) / inputSize * imageHeight;
        double width = (w) / inputSize * imageWidth;
        double height = (h) / inputSize * imageHeight;

        results.add(
          DetectionResult(
            boundingBox: Rect.fromLTWH(xMin, yMin, width, height),
            confidence: maxClassConf,
            label: _labels.isNotEmpty ? _labels[0] : 'person',
            classIndex: 0,
          )
        );
      }
    }

    return _applyNMS(results);
  }

  List<DetectionResult> _applyNMS(List<DetectionResult> boxes) {
    // Non-Maximum Suppression implementation
    // Standard IoU-based filtering
    if (boxes.isEmpty) return [];
    
    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
    List<DetectionResult> selected = [];
    
    for (var box in boxes) {
      bool shouldSelect = true;
      for (var sBox in selected) {
        if (_calculateIoU(box.boundingBox, sBox.boundingBox) > 0.45) {
          shouldSelect = false;
          break;
        }
      }
      if (shouldSelect) {
        selected.add(box);
      }
    }
    
    return selected;
  }

  double _calculateIoU(Rect a, Rect b) {
    final intersection = a.intersect(b);
    if (intersection.width < 0 || intersection.height < 0) return 0.0;
    
    final intersectionArea = intersection.width * intersection.height;
    final unionArea = a.width * a.height + b.width * b.height - intersectionArea;
    return intersectionArea / unionArea;
  }
}
