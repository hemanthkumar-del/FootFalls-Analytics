import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:footfalls_app/ai/detection_result.dart';

class LiveCameraState {
  final bool isInitialized;
  final bool isPermissionGranted;
  final List<CameraDescription> cameras;
  final CameraDescription? selectedCamera;
  final String? errorMessage;
  final bool isStreamingFrames;
  final List<DetectionResult> detections;
  final Size frameSize;
  final double fps;
  final int inferenceTime;

  const LiveCameraState({
    this.isInitialized = false,
    this.isPermissionGranted = false,
    this.cameras = const [],
    this.selectedCamera,
    this.errorMessage,
    this.isStreamingFrames = false,
    this.detections = const [],
    this.frameSize = Size.zero,
    this.fps = 0.0,
    this.inferenceTime = 0,
  });

  LiveCameraState copyWith({
    bool? isInitialized,
    bool? isPermissionGranted,
    List<CameraDescription>? cameras,
    CameraDescription? selectedCamera,
    String? errorMessage,
    bool? isStreamingFrames,
    List<DetectionResult>? detections,
    Size? frameSize,
    double? fps,
    int? inferenceTime,
  }) {
    return LiveCameraState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      cameras: cameras ?? this.cameras,
      selectedCamera: selectedCamera ?? this.selectedCamera,
      errorMessage: errorMessage, 
      isStreamingFrames: isStreamingFrames ?? this.isStreamingFrames,
      detections: detections ?? this.detections,
      frameSize: frameSize ?? this.frameSize,
      fps: fps ?? this.fps,
      inferenceTime: inferenceTime ?? this.inferenceTime,
    );
  }
}
