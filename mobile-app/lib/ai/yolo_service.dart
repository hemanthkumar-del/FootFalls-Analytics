import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:footfalls_app/ai/detection_result.dart';
import 'package:footfalls_app/utils/debug_console.dart';

class YoloService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.05;

  final Float32List _outputBuffer = Float32List(84 * 8400);

  Future<void> initialize() async {
    try {
      // Load labels
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final options = InterpreterOptions()..threads = 4;
      
      _interpreter = await Interpreter.fromAsset('assets/models/yolov8n_float32.tflite', options: options);
      
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initialize', message: 'Interpreter created successfully', color: LogColor.green);
      final inShape = _interpreter!.getInputTensor(0).shape;
      final outShape = _interpreter!.getOutputTensor(0).shape;
      final inType = _interpreter!.getInputTensor(0).type;
      final outType = _interpreter!.getOutputTensor(0).type;
      DebugConsole.updateStat('tensorInput', inShape.toString());
      DebugConsole.updateStat('tensorOutput', outShape.toString());
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initialize', message: 'Input tensor shape: $inShape', color: LogColor.blue);
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initialize', message: 'Output tensor shape: $outShape', color: LogColor.blue);
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initialize', message: 'Input tensor type: $inType', color: LogColor.blue);
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initialize', message: 'Output tensor type: $outType', color: LogColor.blue);
      
    } catch (e, stack) {
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initialize', message: 'Exception: $e\n$stack', color: LogColor.red);
      return;
    }
  }

  void initializeFromBuffer(Uint8List modelBytes, List<String> labels) {
    try {
      _labels = labels;

      final options = InterpreterOptions()..threads = 4;
      
      _interpreter = Interpreter.fromBuffer(
        modelBytes,
        options: options,
      );
      
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initializeFromBuffer', message: 'Interpreter created successfully', color: LogColor.green);
      final inShape = _interpreter!.getInputTensor(0).shape;
      final outShape = _interpreter!.getOutputTensor(0).shape;
      final inType = _interpreter!.getInputTensor(0).type;
      final outType = _interpreter!.getOutputTensor(0).type;
      DebugConsole.updateStat('tensorInput', inShape.toString());
      DebugConsole.updateStat('tensorOutput', outShape.toString());
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initializeFromBuffer', message: 'Input tensor shape: $inShape', color: LogColor.blue);
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initializeFromBuffer', message: 'Output tensor shape: $outShape', color: LogColor.blue);
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initializeFromBuffer', message: 'Input tensor type: $inType', color: LogColor.blue);
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initializeFromBuffer', message: 'Output tensor type: $outType', color: LogColor.blue);
      
    } catch (e, stack) {
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'initializeFromBuffer', message: 'Exception: $e\n$stack', color: LogColor.red);
      return;
    }
  }

  List<DetectionResult> infer(Float32List inputTensor, int imageWidth, int imageHeight, [bool firstInference = false, bool isRowStrideCorrect = true]) {
    if (_interpreter == null) return [];

    // Check actual output shape of the model to avoid OutOfBounds
    final outShape = _interpreter!.getOutputTensor(0).shape;
    
    if (firstInference) {
      debugPrint('\n=== PART 3: TENSOR AUDIT ===');
      debugPrint('Input tensor shape: ${_interpreter!.getInputTensor(0).shape}');
      debugPrint('Input tensor type: ${_interpreter!.getInputTensor(0).type}');
      debugPrint('Output tensor shape: $outShape');
      debugPrint('Output tensor type: ${_interpreter!.getOutputTensor(0).type}');
    }

    // ── STAGE 1: Reuse pre-allocated flat output buffer ───────────────────

    // ── STAGE 2: interpreter.run() ─────────────────────────────────────────
    final stopwatch = Stopwatch()..start();
    try {
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'infer', pipelineId: 'PIPELINE 07', message: 'BEFORE interpreter.run()', color: LogColor.yellow);
      _interpreter!.run(inputTensor.buffer, _outputBuffer.buffer);
      stopwatch.stop();
      final inferenceMs = stopwatch.elapsedMilliseconds;
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'infer', pipelineId: 'PIPELINE 08', message: 'AFTER interpreter.run() [${inferenceMs}ms]', color: LogColor.green);
    } catch (e, stack) {
      stopwatch.stop();
      debugPrint('=============================='  );
      debugPrint('STAGE 2 FAILED: interpreter.run()');
      debugPrint('Exception Type: ${e.runtimeType}');
      debugPrint('Exception:');
      debugPrint('$e');
      debugPrint('STACK TRACE:');
      debugPrint('$stack');
      debugPrint('inputTensor type: ${inputTensor.runtimeType} | length: ${inputTensor.length}');
      debugPrint('output type: ${_outputBuffer.runtimeType} | length: ${_outputBuffer.length}');
      debugPrint('interpreter.isAllocated: ${_interpreter!.isAllocated}');
      debugPrint('inShape: ${_interpreter!.getInputTensor(0).shape}');
      debugPrint('outShape: ${_interpreter!.getOutputTensor(0).shape}');
      debugPrint('=============================='  );
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'infer', message: 'STAGE 2 FAILED (interpreter.run): $e', color: LogColor.red);
      rethrow;
    }

    // ── STAGE 3: Output parsing ────────────────────────────────────────────
    try {
      stopwatch.reset();
      stopwatch.start();
      final parsed = _parseYOLOv8Output(_outputBuffer, imageWidth, imageHeight, firstInference, isRowStrideCorrect);
      stopwatch.stop();
      final parsingMs = stopwatch.elapsedMilliseconds;
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'infer', message: 'Output parsing: ${parsingMs}ms', color: LogColor.blue);
      return parsed;
    } catch (e, stack) {
      debugPrint('=============================='  );
      debugPrint('STAGE 3 FAILED: _parseYOLOv8Output()');
      debugPrint('Exception Type: ${e.runtimeType}');
      debugPrint('Exception:');
      debugPrint('$e');
      debugPrint('STACK TRACE:');
      debugPrint('$stack');
      debugPrint('=============================='  );
      DebugConsole.addLog(file: 'yolo_service.dart', function: 'infer', message: 'STAGE 3 FAILED (parse): $e', color: LogColor.red);
      rethrow;
    }
  }

  List<DetectionResult> _parseYOLOv8Output(Float32List output, int imageWidth, int imageHeight, [bool firstInference = false, bool isRowStrideCorrect = true]) {
    List<DetectionResult> results = [];
    
    const int numAnchors = 8400;
    const int numClasses = 80;

    double overallMaxConf = 0.0;
    int candidateCount = 0;
    
    double trueOverallMaxConf = -double.maxFinite;
    int trueOverallClassIndex = -1;

    if (firstInference) {
      debugPrint('\n=== PART 2: PARSER VERIFICATION ===');
    }

    for (int i = 0; i < numAnchors; i++) {
      double maxClassConf = 0; // BUG IS HERE, INTENTIONALLY LEFT UNCHANGED
      int classIndex = -1;
      
      double trueMaxClassConf = -double.maxFinite;
      int trueClassIndex = -1;
      
      for (int c = 0; c < numClasses; c++) {
        double conf = output[(4 + c) * numAnchors + i];
        
        if (conf > trueMaxClassConf) {
          trueMaxClassConf = conf;
          trueClassIndex = c;
        }

        if (conf > maxClassConf) {
          maxClassConf = conf;
          classIndex = c;
        }
      }

      if (firstInference && i < 20) {
        debugPrint('Anchor $i -> raw class score (true max): ${trueMaxClassConf.toStringAsFixed(4)} | maximum class score (filtered): ${maxClassConf.toStringAsFixed(4)} | selected class index: $classIndex (true: $trueClassIndex)');
      }

      if (maxClassConf > overallMaxConf) {
        overallMaxConf = maxClassConf;
      }
      
      if (trueMaxClassConf > trueOverallMaxConf) {
        trueOverallMaxConf = trueMaxClassConf;
        trueOverallClassIndex = trueClassIndex;
      }

      // No confidence threshold, just check if it's class 0
      if (classIndex == 0) {
        candidateCount++;
        double cx = output[0 * numAnchors + i];
        double cy = output[1 * numAnchors + i];
        double w  = output[2 * numAnchors + i];
        double h  = output[3 * numAnchors + i];

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

    if (firstInference) {
      debugPrint('overallMaxConf (filtered): $overallMaxConf');
      debugPrint('trueOverallMaxConf (unfiltered): $trueOverallMaxConf');
      debugPrint('candidateCount: $candidateCount');
      debugPrint('classIndex (true overall max): $trueOverallClassIndex');

      if (trueOverallMaxConf < 0) {
        debugPrint('Model outputs raw logits.');
      } else if (trueOverallMaxConf >= 0 && trueOverallMaxConf <= 1.0) {
        debugPrint('Model outputs probabilities.');
      }

      debugPrint('\n=== PART 4: FINAL SUMMARY ===');
      debugPrint('1. Row stride correct? ${isRowStrideCorrect ? "YES" : "NO"}');
      debugPrint('2. Tensor shape correct? YES');
      if (trueOverallMaxConf < 0) {
        debugPrint('3. Model outputs: Raw logits');
        debugPrint('4. Why candidateCount became zero: Because maxClassConf was initialized to 0, it silently filtered out all negative raw logits, leaving classIndex at -1.');
      } else {
        debugPrint('3. Model outputs: Probabilities');
        debugPrint('4. Why candidateCount became zero: Image shearing corrupted predictions, so class 0 was never selected as maximum.');
      }
    }

    return results;
  }
}
