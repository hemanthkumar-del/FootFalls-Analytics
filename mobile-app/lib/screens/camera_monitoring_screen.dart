import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/models/camera_model.dart';
import 'package:footfalls_app/models/video_frame_model.dart';
import 'package:footfalls_app/providers/monitoring_controller.dart';
import 'package:go_router/go_router.dart';

class CameraMonitoringScreen extends ConsumerWidget {
  const CameraMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringControllerProvider);
    final controller = ref.read(monitoringControllerProvider.notifier);

    return Scaffold(
      appBar: state.isFullScreen
          ? null
          : AppBar(
              title: const Text('Live Monitoring'),
              actions: [
                if (state.availableCameras.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButton<CameraModel>(
                      value: state.selectedCamera,
                      underline: const SizedBox(),
                      onChanged: (CameraModel? newValue) {
                        if (newValue != null) {
                          controller.selectCamera(newValue);
                        }
                      },
                      items: state.availableCameras
                          .map<DropdownMenuItem<CameraModel>>((CameraModel cam) {
                        return DropdownMenuItem<CameraModel>(
                          value: cam,
                          child: Text(cam.name),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.selectedCamera == null
              ? const Center(child: Text("No cameras available"))
              : _buildVideoView(context, state, controller),
    );
  }

  Widget _buildVideoView(BuildContext context, MonitoringState state, MonitoringController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player Area
        Container(
          color: Colors.black,
          child: Center(
            child: state.latestFrame != null
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return Image.memory(
                        state.latestFrame!.imageBytes,
                        gaplessPlayback: true,
                        fit: BoxFit.contain,
                      );
                    }
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
        ),

        // Connection Status Indicator
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  state.isConnected ? Icons.circle : Icons.error,
                  color: state.isConnected ? Colors.green : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  state.isConnected ? 'Online' : 'Reconnecting...',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // HUD / Analytics Overlay
        if (state.latestFrame != null)
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow('Occupancy', state.latestFrame!.metadata.occupancy.toString(), Colors.orange),
                  _buildStatRow('Entries', state.latestFrame!.metadata.entries.toString(), Colors.green),
                  _buildStatRow('Exits', state.latestFrame!.metadata.exits.toString(), Colors.red),
                  const SizedBox(height: 8),
                  _buildStatRow('Persons', state.latestFrame!.metadata.personsDetected.toString(), Colors.white),
                  _buildStatRow('FPS', state.latestFrame!.metadata.fps.toStringAsFixed(1), Colors.grey),
                  _buildStatRow('Confidence', '${(state.latestFrame!.metadata.averageDetectionConfidence * 100).toStringAsFixed(1)}%', Colors.blueAccent),
                ],
              ),
            ),
          ),

        // Full Screen Toggle
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.black54,
            onPressed: () => controller.toggleFullScreen(),
            child: Icon(
              state.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
