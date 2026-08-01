import 'dart:typed_data';
import 'dart:isolate';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:footfalls_app/ai/yolo_service.dart';
import 'package:footfalls_app/ai/detection_result.dart';
import 'package:footfalls_app/utils/debug_console.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';

class IsolateInferenceData {
  final int formatGroup;
  final int width;
  final int height;
  final TransferableTypedData plane0BytesTransferable;
  final int plane0BytesPerRow;
  final TransferableTypedData plane1BytesTransferable;
  final int plane1BytesPerRow;
  final int plane1BytesPerPixel;
  final TransferableTypedData plane2BytesTransferable;
  final int inputWidth;
  final int inputHeight;

  IsolateInferenceData({
    required this.formatGroup,
    required this.width,
    required this.height,
    required Uint8List plane0Bytes,
    required this.plane0BytesPerRow,
    required Uint8List plane1Bytes,
    required this.plane1BytesPerRow,
    required this.plane1BytesPerPixel,
    required Uint8List plane2Bytes,
    required this.inputWidth,
    required this.inputHeight,
  })  : plane0BytesTransferable = TransferableTypedData.fromList([plane0Bytes]),
        plane1BytesTransferable = TransferableTypedData.fromList([plane1Bytes]),
        plane2BytesTransferable = TransferableTypedData.fromList([plane2Bytes]);
}

class _InferenceRequest {
  final IsolateInferenceData data;
  final SendPort replyPort;

  _InferenceRequest(this.data, this.replyPort);
}

class PersonDetector {
  Isolate? _isolate;
  SendPort? _sendPort;
  final Completer<void> _isolateReady = Completer<void>();

  Future<void> initialize() async {
    if (_isolate != null) return;
    
    // 1. Load model bytes and labels on the main isolate
    final modelData = await rootBundle.load('assets/models/yolov8n_float32.tflite');
    final modelBytes = modelData.buffer.asUint8List();
    
    final labelsData = await rootBundle.loadString('assets/models/labels.txt');
    final labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // 2. Spawn isolate and pass the loaded assets
    final receivePort = ReceivePort();
    
    _isolate = await Isolate.spawn(_isolateEntryPoint, {
      'sendPort': receivePort.sendPort,
      'modelBytes': modelBytes,
      'labels': labels,
    });
    
    _sendPort = await receivePort.first as SendPort;
    _isolateReady.complete();
  }

  Future<List<DetectionResult>> detectInIsolate(IsolateInferenceData data) async {
    await _isolateReady.future;
    
    final responsePort = ReceivePort();
    try {
      _sendPort!.send(_InferenceRequest(data, responsePort.sendPort));
      
      final results = await responsePort.first.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException("Worker isolate did not reply within 20 seconds.");
        },
      );
      
      return results as List<DetectionResult>;
    } catch (e, stack) {
      DebugConsole.addLog(
        file: 'person_detector.dart',
        function: 'detectInIsolate',
        message: 'Exception: $e\n$stack',
        color: LogColor.red,
      );
      return [];
    } finally {
      responsePort.close();
    }
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}

Future<void> _isolateEntryPoint(Map<String, dynamic> message) async {
  final mainSendPort = message['sendPort'] as SendPort;
  final modelBytes = message['modelBytes'] as Uint8List;
  final labels = message['labels'] as List<String>;
  
  final isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  final yolo = YoloService();
  yolo.initializeFromBuffer(modelBytes, labels);

  try {
    await for (final msg in isolateReceivePort) {
      if (msg is _InferenceRequest) {
        try {
          final data = msg.data;
          
          final plane0Bytes = data.plane0BytesTransferable.materialize().asUint8List();
          final plane1Bytes = data.plane1BytesTransferable.materialize().asUint8List();
          final plane2Bytes = data.plane2BytesTransferable.materialize().asUint8List();

          img.Image? rgbImage;

          final preprocStart = DateTime.now();

          if (data.formatGroup == 1) { // yuv420 (fallback)
            final image = img.Image(data.width, data.height);

            for (int w = 0; w < data.width; w++) {
              for (int h = 0; h < data.height; h++) {
                final uvIndex = data.plane1BytesPerPixel * (w / 2).floor() + data.plane1BytesPerRow * (h / 2).floor();
                final index = h * data.plane0BytesPerRow + w;

                final y = plane0Bytes[index];
                final u = plane1Bytes[uvIndex];
                final v = plane2Bytes[uvIndex];

                int r = (y + 1.402 * (v - 128)).round();
                int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).round();
                int b = (y + 1.772 * (u - 128)).round();

                image.setPixelRgba(w, h, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
              }
            }
            rgbImage = image;
            if (rgbImage.width > rgbImage.height) {
              rgbImage = img.copyRotate(rgbImage, 90);
            }
          } else if (data.formatGroup == 2) { // bgra8888 (native fast path)
            rgbImage = img.Image.fromBytes(
              data.width,
              data.height,
              plane0Bytes,
              format: img.Format.bgra,
            );
            if (rgbImage.width > rgbImage.height) {
              rgbImage = img.copyRotate(rgbImage, 90);
            }
          }

          Float32List float32List;
          if (rgbImage != null) {
            TensorImage tensorImage = TensorImage.fromImage(rgbImage);
            ImageProcessor imageProcessor = ImageProcessorBuilder()
                .add(ResizeOp(640, 640, ResizeMethod.bilinear))
                .build();
            
            tensorImage = imageProcessor.process(tensorImage);
            
            final uint8List = tensorImage.buffer.asUint8List();
            float32List = Float32List(uint8List.length);
            for (int i = 0; i < uint8List.length; i++) {
              float32List[i] = uint8List[i] / 255.0;
            }
          } else {
            float32List = Float32List(640 * 640 * 3);
          }
          
          final preprocTime = DateTime.now().difference(preprocStart).inMilliseconds;

          final inferenceStart = DateTime.now();
          final results = yolo.infer(float32List, data.inputWidth, data.inputHeight);
          final inferenceTime = DateTime.now().difference(inferenceStart).inMilliseconds;
          
          DebugConsole.addLog(
            file: 'person_detector.dart',
            function: 'worker',
            message: 'Preprocessing: ${preprocTime}ms, Inference: ${inferenceTime}ms',
            color: LogColor.green,
          );
          msg.replyPort.send(results);
        } catch (e, stack) {
          DebugConsole.addLog(
            file: 'person_detector.dart',
            function: '_isolateEntryPoint (frame processing)',
            message: 'Exception: $e\n$stack',
            color: LogColor.red,
          );
          msg.replyPort.send(<DetectionResult>[]);
        }
      }
    }
  } catch (e, stack) {
    DebugConsole.addLog(
      file: 'person_detector.dart',
      function: '_isolateEntryPoint (main loop)',
      message: 'Fatal isolate loop exception: $e\n$stack',
      color: LogColor.red,
    );
  }
}
