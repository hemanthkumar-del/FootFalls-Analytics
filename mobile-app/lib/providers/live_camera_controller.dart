import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:footfalls_app/providers/live_camera_state.dart';
import 'package:footfalls_app/ai/person_detector.dart';
import 'package:footfalls_app/camera/camera_frame_converter.dart';
import 'package:footfalls_app/providers/detection_config_state.dart';

final liveCameraControllerProvider = StateNotifierProvider.autoDispose<LiveCameraController, LiveCameraState>((ref) {
  return LiveCameraController(ref);
});

class LiveCameraController extends StateNotifier<LiveCameraState> {
  final Ref _ref;
  CameraController? _cameraController;
  final PersonDetector _personDetector = PersonDetector();
  bool _isProcessingFrame = false;
  
  int _frameCount = 0;
  DateTime _lastFpsTime = DateTime.now();

  LiveCameraController(this._ref) : super(const LiveCameraState());

  CameraController? get cameraController => _cameraController;

  Future<void> initialize() async {
    try {
      state = state.copyWith(errorMessage: null);
      
      await _personDetector.initialize();

      final status = await Permission.camera.request();
      if (!status.isGranted) {
        state = state.copyWith(isPermissionGranted: false, errorMessage: 'Camera permission denied. Please grant permission in device settings.');
        return;
      }
      
      state = state.copyWith(isPermissionGranted: true);
      
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(errorMessage: 'No cameras found on device.');
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
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to initialize camera or AI: $e');
    }
  }

  Future<void> _initCameraController(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    _cameraController = CameraController(
      camera, 
      ResolutionPreset.medium, 
      enableAudio: false,
    );

    await _cameraController!.initialize();
    state = state.copyWith(isInitialized: true);

    startImageStream();
  }

  void startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state.isStreamingFrames) return;
    
    _cameraController!.startImageStream((image) async {
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;

      debugPrint('Frame received: ${image.width}x${image.height}');

      try {
        final float32List = CameraFrameConverter.convertCameraImageToFloat32(image, 640, 640);
        
        final inferenceStart = DateTime.now();
        final detections = await _personDetector.detect(float32List, image.width, image.height);
        final inferenceTime = DateTime.now().difference(inferenceStart).inMilliseconds;
        
        final config = _ref.read(detectionConfigProvider);
        
        // Filter detections by ROI
        final filteredDetections = detections.where((det) {
          final center = det.boundingBox.center;
          final normalizedCenter = Offset(center.dx / image.width, center.dy / image.height);
          return config.roi.contains(normalizedCenter);
        }).toList();

        _frameCount++;
        final now = DateTime.now();
        final diff = now.difference(_lastFpsTime).inMilliseconds;
        double currentFps = state.fps;
        
        if (diff >= 1000) {
          currentFps = _frameCount / (diff / 1000.0);
          _frameCount = 0;
          _lastFpsTime = now;
        }

        if (mounted) {
          state = state.copyWith(
            detections: filteredDetections,
            frameSize: Size(image.width.toDouble(), image.height.toDouble()),
            fps: currentFps,
            inferenceTime: inferenceTime,
          );
        }
      } catch (e) {
        debugPrint('Error processing frame: $e');
      } finally {
        _isProcessingFrame = false;
      }
    });

    state = state.copyWith(isStreamingFrames: true);
  }

  Future<void> stopImageStream() async {
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
    _cameraController?.dispose();
    super.dispose();
  }
}
