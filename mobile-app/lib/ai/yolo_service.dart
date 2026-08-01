import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:footfalls_app/ai/detection_result.dart';
import 'package:footfalls_app/utils/debug_console.dart';

class YoloService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.05;

  Future<void> initialize() async {
    try {
      // Load labels
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final options = InterpreterOptions()..threads = 4;
      List<String> delegates = [];
      
      if (Platform.isAndroid) {
        try {
          options.addDelegate(GpuDelegateV2());
          delegates.add('GPU');
        } catch (e) {
          try {
            options.useNnApiForAndroid = true;
            delegates.add('NNAPI');
          } catch (e) {
            try {
              options.addDelegate(XNNPackDelegate());
              delegates.add('XNNPACK');
            } catch (e) {
              delegates.add('None (Fallback to CPU)');
            }
          }
        }
      }

      _interpreter = await Interpreter.fromAsset('assets/models/yolov8n_float32.tflite', options: options);
      
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initialize', message: 'Model loaded successfully. Threads: 4 | Delegates: ${delegates.join(", ")}', color: LogColor.green);
      final inShape = _interpreter!.getInputTensor(0).shape;
      final outShape = _interpreter!.getOutputTensor(0).shape;
      DebugConsole.updateStat('tensorInput', inShape.toString());
      DebugConsole.updateStat('tensorOutput', outShape.toString());
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initialize', message: 'Input: $inShape | Output: $outShape', color: LogColor.blue);
      
    } catch (e) {
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initialize', message: 'Failed to load model: $e', color: LogColor.red);
    }
  }

  void initializeFromBuffer(Uint8List modelBytes, List<String> labels) {
    try {
      _labels = labels;

      final options = InterpreterOptions()..threads = 4;
      List<String> delegates = [];
      
      if (Platform.isAndroid) {
        try {
          options.addDelegate(GpuDelegateV2());
          delegates.add('GPU');
        } catch (e) {
          try {
            options.useNnApiForAndroid = true;
            delegates.add('NNAPI');
          } catch (e) {
            try {
              options.addDelegate(XNNPackDelegate());
              delegates.add('XNNPACK');
            } catch (e) {
              delegates.add('None (Fallback to CPU)');
            }
          }
        }
      }

      _interpreter = Interpreter.fromBuffer(modelBytes, options: options);
      
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initializeFromBuffer', message: 'Model loaded successfully from buffer. Threads: 4 | Delegates: ${delegates.join(", ")}', color: LogColor.green);
      final inShape = _interpreter!.getInputTensor(0).shape;
      final outShape = _interpreter!.getOutputTensor(0).shape;
      DebugConsole.updateStat('tensorInput', inShape.toString());
      DebugConsole.updateStat('tensorOutput', outShape.toString());
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initializeFromBuffer', message: 'Input: $inShape | Output: $outShape', color: LogColor.blue);
      
    } catch (e) {
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initializeFromBuffer', message: 'Failed to load model from buffer: $e', color: LogColor.red);
    }
  }

  List<DetectionResult> infer(Float32List inputTensor, int imageWidth, int imageHeight) {
    if (_interpreter == null) return [];

    // Check actual output shape of the model to avoid OutOfBounds
    final outShape = _interpreter!.getOutputTensor(0).shape;
    // Expected [1, 84, 8400]
    final d1 = outShape.length > 1 ? outShape[1] : 84;
    final d2 = outShape.length > 2 ? outShape[2] : 8400;

    var output = List.generate(1, (i) => List.generate(d1, (j) => List.filled(d2, 0.0)));
    
    // Reshape input float list into [1, 640, 640, 3] depending on the model expected shape
    var input = inputTensor.reshape([1, inputSize, inputSize, 3]);

    try {
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'infer', pipelineId: 'PIPELINE 07', message: 'BEFORE interpreter.run()', color: LogColor.yellow);
      final stopwatch = Stopwatch()..start();
      _interpreter!.run(input, output);
      stopwatch.stop();
      final inferenceMs = stopwatch.elapsedMilliseconds;
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'infer', pipelineId: 'PIPELINE 08', message: 'AFTER interpreter.run() [${inferenceMs}ms]', color: LogColor.green);

      stopwatch.reset();
      stopwatch.start();
      final parsed = _parseYOLOv8Output(output[0], imageWidth, imageHeight);
      stopwatch.stop();
      final parsingMs = stopwatch.elapsedMilliseconds;
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'infer', message: 'Output parsing: ${parsingMs}ms', color: LogColor.blue);
      
      return parsed;
    } catch (e, stack) {
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'infer', message: 'FATAL EXCEPTION: $e', color: LogColor.red);
      return [];
    }
  }

  List<DetectionResult> _parseYOLOv8Output(List<List<double>> output, int imageWidth, int imageHeight) {
    List<DetectionResult> results = [];
    
    bool isTranspose = false;
    int numAnchors = 0;
    int numClassesAndCoords = 0;

    if (output.length == 84) {
      isTranspose = false;
      numClassesAndCoords = 84;
      numAnchors = output[0].length;
    } else {
      isTranspose = true;
      numAnchors = output.length;
      numClassesAndCoords = output.isNotEmpty ? output[0].length : 84;
    }

    double overallMaxConf = 0.0;
    int candidateCount = 0;

    for (int i = 0; i < numAnchors; i++) {
      double maxClassConf = 0;
      int classIndex = -1;
      
      for (int c = 0; c < 80; c++) {
        if (4 + c >= numClassesAndCoords) break;
        
        double conf = isTranspose ? output[i][4 + c] : output[4 + c][i];
        if (conf > maxClassConf) {
          maxClassConf = conf;
          classIndex = c;
        }
      }

      if (maxClassConf > overallMaxConf) {
        overallMaxConf = maxClassConf;
      }

      // No confidence threshold, just check if it's class 0
      if (classIndex == 0) {
        candidateCount++;
        double cx = isTranspose ? output[i][0] : output[0][i];
        double cy = isTranspose ? output[i][1] : output[1][i];
        double w = isTranspose ? output[i][2] : output[2][i];
        double h = isTranspose ? output[i][3] : output[3][i];

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

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    for (int k = 0; k < (results.length > 20 ? 20 : results.length); k++) {
       final r = results[k];
       double w = r.boundingBox.width * inputSize / imageWidth;
       double h = r.boundingBox.height * inputSize / imageHeight;
       double cx = (r.boundingBox.left * inputSize / imageWidth) + w / 2;
       double cy = (r.boundingBox.top * inputSize / imageHeight) + h / 2;
       
       debugPrint('TOP DETECT $k -> cx: ${cx.toStringAsFixed(2)}, cy: ${cy.toStringAsFixed(2)}, w: ${w.toStringAsFixed(2)}, h: ${h.toStringAsFixed(2)}, class: ${r.classIndex}, conf: ${r.confidence.toStringAsFixed(4)}');
    }

    debugPrint('STEP 7: output shape is [1, ${output.length}, ${output.isNotEmpty ? output[0].length : 0}]');
    debugPrint('STEP 7: maximum confidence across all anchors: $overallMaxConf');
    debugPrint('STEP 7: number of candidate boxes (class 0): $candidateCount');
    
    return results; // NO NMS FILTERING
  }

  List<DetectionResult> _applyNMS(List<DetectionResult> boxes) {
    // Non-Maximum Suppression implementation
    // Standard IoU-based filtering
    if (boxes.isEmpty) return [];
    
    // TEMPORARILY DISABLED NMS for debugging
    return boxes;
    
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
