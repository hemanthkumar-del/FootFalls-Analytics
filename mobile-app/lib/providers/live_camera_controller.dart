import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:footfalls_app/providers/live_camera_state.dart';
import 'package:footfalls_app/ai/person_detector.dart';
import 'package:footfalls_app/camera/camera_frame_converter.dart';
import 'package:footfalls_app/providers/detection_config_state.dart';
import 'package:footfalls_app/utils/debug_console.dart';
import 'package:footfalls_app/ai/tracking/tracker.dart';
import 'package:footfalls_app/ai/tracking/counter.dart';
import 'package:footfalls_app/ai/tracking/virtual_line.dart';
import 'package:footfalls_app/ai/detection_result.dart';
import 'dart:math';

final liveCameraControllerProvider = StateNotifierProvider.autoDispose<LiveCameraController, LiveCameraState>((ref) {
  return LiveCameraController(ref);
});

class LiveCameraController extends StateNotifier<LiveCameraState> {
  final Ref _ref;
  CameraController? _cameraController;
  final PersonDetector _personDetector = PersonDetector();
  CameraImage? _latestFrame;
  bool _isWorkerRunning = false;
  bool _isInitializing = false;
  
  final Tracker _tracker = Tracker();
  final Counter _counter = Counter();
  bool _counterInitialized = false;
  
  int _workerFrameCount = 0;
  DateTime _lastWorkerFpsTime = DateTime.now();
  double _workerFps = 0.0;
  
  int _frameCount = 0;
  DateTime _lastFpsTime = DateTime.now();

  int _framesReceived = 0;
  int _framesSkipped = 0;
  int _framesProcessed = 0;
  double _avgInferenceTime = 0.0;

  LiveCameraController(this._ref) : super(const LiveCameraState());

  CameraController? get cameraController => _cameraController;

  Future<void> initialize() async {
    if (_isInitializing) {
      DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'initialize', message: 'initialize() skipped', color: LogColor.yellow);
      return;
    }
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'initialize', message: 'initialize() skipped', color: LogColor.yellow);
      return;
    }
    
    _isInitializing = true;
    DebugConsole.updateBanner('INITIALIZING CAMERA');
    DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'initialize', message: 'initialize() called', color: LogColor.yellow);
    try {
      state = state.copyWith(errorMessage: null);
      
      await _personDetector.initialize();

      final status = await Permission.camera.request();
      if (!status.isGranted) {
        state = state.copyWith(isPermissionGranted: false, errorMessage: 'Camera permission denied. Please grant permission in device settings.');
        DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'initialize', message: 'Permission denied', color: LogColor.red);
        DebugConsole.updateBanner('PERMISSION DENIED');
        return;
      }
      
      state = state.copyWith(isPermissionGranted: true);
      
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(errorMessage: 'No cameras found on device.');
        DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'initialize', message: 'No cameras found', color: LogColor.red);
        DebugConsole.updateBanner('NO CAMERAS');
        return;
      }
      
      CameraDescription? selectedCamera;
      for (final cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.back) {
          selectedCamera = cam;
          break;
        }
      }
      selectedCamera ??= cameras.first;
      
      state = state.copyWith(cameras: cameras, selectedCamera: selectedCamera);
      await _initCameraController(selectedCamera);
    } catch (e, stack) {
      state = state.copyWith(errorMessage: 'Failed to initialize camera or AI: $e');
      DebugConsole.updateStat('lastException', e.toString());
      DebugConsole.updateBanner('INIT ERROR');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _initCameraController(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    try {
      _cameraController = CameraController(
        camera, 
        ResolutionPreset.low, 
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      DebugConsole.updateStat('resolutionPreset', 'low_bgra8888');

      await _cameraController!.initialize();
    } catch (e) {
      DebugConsole.addLog(file: 'live_camera_controller.dart', function: '_initCameraController', message: 'bgra8888 failed, falling back to yuv420', color: LogColor.yellow);
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
      
      _cameraController = CameraController(
        camera, 
        ResolutionPreset.low, 
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      DebugConsole.updateStat('resolutionPreset', 'low_yuv420');

      await _cameraController!.initialize();
    }
    state = state.copyWith(isInitialized: true);
    DebugConsole.updateStat('cameraInitialized', true);

    _cameraController!.addListener(() {
      final val = _cameraController!.value;
      debugPrint('CameraController Property Changed: isStreamingImages=${val.isStreamingImages}, isInitialized=${val.isInitialized}, hasError=${val.hasError}, errorDescription=${val.errorDescription}');
      if (!val.isStreamingImages && state.isStreamingFrames) {
        DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'addListener', message: 'isStreamingImages DROPPED TO FALSE! Error: ${val.errorDescription}', color: LogColor.red);
      }
    });

    DebugConsole.updateStat('streamCalled', true);
    DebugConsole.updateBanner('WAITING FOR STREAM');
    startImageStream();
  }

  void startImageStream() {
    DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'startImageStream', message: 'startImageStream() INVOCATION at ${DateTime.now().toIso8601String()}', color: LogColor.yellow);
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state.isStreamingFrames) {
      DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'startImageStream', message: 'startImageStream() skipped', color: LogColor.yellow);
      return;
    }
    
    DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'startImageStream', message: 'startImageStream() started', color: LogColor.yellow);
    
    _cameraController!.startImageStream((image) {
      debugPrint('CAMERA PLUGIN CALLBACK RECEIVED at ${DateTime.now().toIso8601String()} (Frame #${_framesReceived + 1})');
      _framesReceived++;
      DebugConsole.updateStat('framesReceived', _framesReceived);

      if (_latestFrame != null) {
        _framesSkipped++;
      }
      _latestFrame = image;

      _frameCount++;
      final now = DateTime.now();
      final diff = now.difference(_lastFpsTime).inMilliseconds;
      
      if (diff >= 1000) {
        final currentFps = _frameCount / (diff / 1000.0);
        _frameCount = 0;
        _lastFpsTime = now;
        if (mounted) {
          state = state.copyWith(fps: currentFps);
          DebugConsole.updateStat('fps', double.parse(currentFps.toStringAsFixed(1)));
        }
      }
    });

    state = state.copyWith(isStreamingFrames: true);
    _startWorkerLoop();
  }

  void _startWorkerLoop() async {
    if (_isWorkerRunning) return;
    _isWorkerRunning = true;
    
    while (_isWorkerRunning) {
      if (_latestFrame != null) {
        final image = _latestFrame!;
        _latestFrame = null;
        
        DebugConsole.updateStat('isProcessing', true);

        try {
          final inferenceStart = DateTime.now();
          final bool isRotated = image.format.group == ImageFormatGroup.yuv420 && image.width > image.height;
          final int inputWidth = isRotated ? image.height : image.width;
          final int inputHeight = isRotated ? image.width : image.height;
          
          final data = IsolateInferenceData(
            formatGroup: image.format.group == ImageFormatGroup.yuv420 ? 1 : (image.format.group == ImageFormatGroup.bgra8888 ? 2 : 0),
            width: image.width,
            height: image.height,
            plane0Bytes: image.planes.isNotEmpty ? image.planes[0].bytes : Uint8List(0),
            plane0BytesPerRow: image.planes.isNotEmpty ? image.planes[0].bytesPerRow : 0,
            plane1Bytes: image.planes.length > 1 ? image.planes[1].bytes : Uint8List(0),
            plane1BytesPerRow: image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
            plane1BytesPerPixel: image.planes.length > 1 ? (image.planes[1].bytesPerPixel ?? 1) : 1,
            plane2Bytes: image.planes.length > 2 ? image.planes[2].bytes : Uint8List(0),
            inputWidth: inputWidth,
            inputHeight: inputHeight,
          );
          
          DebugConsole.updateBanner('RUNNING YOLO (ISOLATE)');
          final detections = await _personDetector.detectInIsolate(data);
          final inferenceTime = DateTime.now().difference(inferenceStart).inMilliseconds;
          
          _framesProcessed++;
          _avgInferenceTime = (_avgInferenceTime * (_framesProcessed - 1) + inferenceTime) / _framesProcessed;

          if (_framesProcessed % 5 == 0) {
             debugPrint('Metrics -> Received: $_framesReceived | Skipped: $_framesSkipped | Processed: $_framesProcessed | Avg Inference: ${_avgInferenceTime.toStringAsFixed(1)} ms | Camera FPS: ${state.fps.toStringAsFixed(1)} | Worker FPS: ${_workerFps.toStringAsFixed(1)}');
          }
          
          DebugConsole.updateStat('inferenceTime', inferenceTime);
          DebugConsole.updateStat('detectionCount', detections.length);
          
          final config = _ref.read(detectionConfigProvider);
          
          DebugConsole.addLog(file: 'live_camera_controller', function: '_startWorkerLoop', message: 'Detections before ROI: ${detections.length}', color: LogColor.blue);
          
          if (!_counterInitialized) {
            _counter.addLine(VirtualLine(
              lineId: 'main_door',
              start: Point(0.0, inputHeight / 2),
              end: Point(inputWidth.toDouble(), inputHeight / 2),
            ));
            _counterInitialized = true;
          }

          // 1. Run Tracker
          final activeTracks = _tracker.update(detections);
          
          final trackedDetections = activeTracks.map((track) {
            return DetectionResult(
              boundingBox: track.boundingBox,
              confidence: track.confidence,
              label: track.label,
              classIndex: track.classIndex,
              trackId: track.trackId,
              age: track.age,
              hits: track.hits,
              lostFrames: track.timeSinceUpdate,
            );
          }).toList();
          
          // 2. Run Counter
          _counter.processTracks(activeTracks);

          // 3. Log stats
          DebugConsole.updateStat('totalEntered', _counter.totalEntered);
          DebugConsole.updateStat('totalExited', _counter.totalExited);
          DebugConsole.updateStat('activeTracks', activeTracks.length);

          for (var track in activeTracks) {
            DebugConsole.addLog(file: 'live_camera_controller.dart', function: '_startWorkerLoop', message: 'Track ${track.trackId} | Pos: ${track.currentPosition.x.toInt()},${track.currentPosition.y.toInt()} | Age: ${track.age}', color: LogColor.green);
          }

          _workerFrameCount++;
          final now = DateTime.now();
          final diff = now.difference(_lastWorkerFpsTime).inMilliseconds;
          
          if (diff >= 1000) {
            _workerFps = _workerFrameCount / (diff / 1000.0);
            _workerFrameCount = 0;
            _lastWorkerFpsTime = now;
          }

          if (mounted) {
            DebugConsole.updateStat('workerFps', double.parse(_workerFps.toStringAsFixed(1)));
            DebugConsole.updateBanner('DRAWING OVERLAY');
            state = state.copyWith(
              detections: trackedDetections,
              frameSize: Size(inputWidth.toDouble(), inputHeight.toDouble()),
              inferenceTime: inferenceTime,
            );
            DebugConsole.incrementStat('framesProcessed');
          }
        } catch (e, stack) {
          DebugConsole.addLog(file: 'live_camera_controller.dart', function: '_startWorkerLoop', message: 'FATAL EXCEPTION: $e', color: LogColor.red);
          DebugConsole.updateStat('lastException', e.toString());
          DebugConsole.updateBanner('PIPELINE STOPPED');
        } finally {
          DebugConsole.updateStat('isProcessing', false);
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<void> stopImageStream() async {
    DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'stopImageStream', message: 'stopImageStream() INVOCATION at ${DateTime.now().toIso8601String()}', color: LogColor.yellow);
    // Requirements: "4. Never stopImageStream() after processing."
    // We will leave this method for manual complete shutdown if needed, but we don't call it internally.
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
    state = state.copyWith(isStreamingFrames: false);
  }

  Future<void> switchCamera() async {
    if (state.cameras.length < 2) return;
    
    final currentDirection = state.selectedCamera?.lensDirection;
    CameraDescription? newCamera;
    
    for (final cam in state.cameras) {
      if (cam.lensDirection != currentDirection) {
        newCamera = cam;
        break;
      }
    }
    
    if (newCamera != null) {
      state = state.copyWith(isInitialized: false, selectedCamera: newCamera);
      await _initCameraController(newCamera);
    }
  }

  @override
  void dispose() {
    DebugConsole.addLog(file: 'live_camera_controller.dart', function: 'dispose', message: 'dispose() INVOCATION at ${DateTime.now().toIso8601String()}', color: LogColor.yellow);
    _isWorkerRunning = false;
    _cameraController?.dispose();
    super.dispose();
  }
}
