import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:footfalls_app/providers/live_camera_state.dart';
import 'package:footfalls_app/ai/person_detector.dart';
import 'package:footfalls_app/camera/camera_frame_converter.dart';

final liveCameraControllerProvider = StateNotifierProvider.autoDispose<LiveCameraController, LiveCameraState>((ref) {
  return LiveCameraController();
});

class LiveCameraController extends StateNotifier<LiveCameraState> {
  CameraController? _cameraController;
  final PersonDetector _personDetector = PersonDetector();
  bool _isProcessingFrame = false;

  LiveCameraController() : super(const LiveCameraState());

  CameraController? get cameraController => _cameraController;

  Future<void> initialize() async {
    try {
      state = state.copyWith(errorMessage: null);
      
      // Initialize AI Detector
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

    // Automatically start processing frames for AI
    startImageStream();
  }

  void startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state.isStreamingFrames) return;
    
    _cameraController!.startImageStream((image) async {
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;

      try {
        // 1. Convert frame to float32 tensor
        final float32List = CameraFrameConverter.convertCameraImageToFloat32(image, image.width, image.height);
        
        // 2. Run inference
        final detections = await _personDetector.detect(float32List, image.width, image.height);
        
        // 3. Update state for UI overlay
        if (mounted) {
          state = state.copyWith(
            detections: detections,
            frameSize: Size(image.width.toDouble(), image.height.toDouble()),
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
