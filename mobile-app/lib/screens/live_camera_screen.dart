import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/live_camera_controller.dart';
import 'package:footfalls_app/presentation/detection_overlay.dart';
import 'package:footfalls_app/presentation/interactive_config_overlay.dart';
import 'package:footfalls_app/presentation/debug_overlay.dart';
import 'package:footfalls_app/providers/detection_config_state.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveCameraScreen extends ConsumerStatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  ConsumerState<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends ConsumerState<LiveCameraScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveCameraControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = ref.read(liveCameraControllerProvider.notifier).cameraController;
    
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
    } else if (state == AppLifecycleState.resumed) {
      if (cameraController != null && cameraController.value.isInitialized) {
        ref.read(liveCameraControllerProvider.notifier).initialize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveCameraControllerProvider);
    final controller = ref.watch(liveCameraControllerProvider.notifier).cameraController;
    final configState = ref.watch(detectionConfigProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live View'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: Icon(configState.isConfigMode ? Icons.check : Icons.settings),
            onPressed: () {
              ref.read(detectionConfigProvider.notifier).toggleConfigMode();
            },
            tooltip: 'Configure Line & ROI',
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _buildBody(context, state, controller),
      floatingActionButton: state.isInitialized && state.cameras.length > 1
          ? FloatingActionButton(
              onPressed: () {
                ref.read(liveCameraControllerProvider.notifier).switchCamera();
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.flip_camera_android),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, state, CameraController? controller) {
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (!state.isPermissionGranted) {
                    openAppSettings();
                  } else {
                    ref.read(liveCameraControllerProvider.notifier).initialize();
                  }
                },
                child: Text(!state.isPermissionGranted ? 'Open Settings' : 'Retry'),
              )
            ],
          ),
        ),
      );
    }

    if (!state.isInitialized || controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 1 / controller.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            
            if (state.detections.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: DetectionOverlay(
                    detections: state.detections,
                    frameSize: state.frameSize,
                  ),
                ),
              ),
              
            const Positioned.fill(
              child: InteractiveConfigOverlay(),
            ),
            
            const DebugOverlay(),
          ],
        ),
      ),
    );
  }
}
