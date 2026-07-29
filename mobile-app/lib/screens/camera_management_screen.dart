import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/camera_controller.dart';
import 'package:footfalls_app/models/camera_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:footfalls_app/core/theme/app_theme.dart';

class CameraManagementScreen extends ConsumerWidget {
  const CameraManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraControllerProvider);
    final controller = ref.read(cameraControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchCameras(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.fetchCameras(),
        child: _buildBody(context, cameraState, controller),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBottomSheet(context, controller),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Camera'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildBody(BuildContext context, CameraState state, CameraController controller) {
    if (state.isLoading && state.cameras.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(backgroundColor: Colors.white, radius: 24),
              title: Container(color: Colors.white, height: 16, width: double.infinity),
              subtitle: Container(color: Colors.white, height: 12, width: 100, margin: const EdgeInsets.only(top: 8)),
            ),
          ),
        ),
      );
    }

    if (state.error != null && state.cameras.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 80, color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              Text('Failed to Load Cameras', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(state.error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => controller.fetchCameras(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              )
            ],
          ),
        ),
      );
    }

    if (state.cameras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.videocam_off_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('No Cameras Found', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Add a new camera to start monitoring.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: state.cameras.length,
      itemBuilder: (context, index) {
        final CameraModel cam = state.cameras[index];
        final isRunning = cam.isRunningInMemory;
        final colorScheme = Theme.of(context).colorScheme;
        
        return Dismissible(
          key: Key(cam.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppTheme.errorRed, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
          ),
          onDismissed: (dir) => controller.deleteCamera(cam.id),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isRunning ? AppTheme.successGreen.withValues(alpha: 0.5) : colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: isRunning ? AppTheme.successGreen.withValues(alpha: 0.1) : (cam.isEnabled ? AppTheme.warningOrange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
                child: Icon(
                  isRunning ? Icons.videocam_rounded : Icons.videocam_off_rounded, 
                  color: isRunning ? AppTheme.successGreen : (cam.isEnabled ? AppTheme.warningOrange : Colors.grey),
                ),
              ),
              title: Text(cam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  isRunning ? 'Online • ${cam.fps.toStringAsFixed(1)} FPS' : (cam.isEnabled ? 'Starting...' : 'Offline'),
                  style: TextStyle(color: isRunning ? AppTheme.successGreen : (cam.isEnabled ? AppTheme.warningOrange : Colors.grey)),
                ),
              ),
              trailing: Switch(
                value: cam.isEnabled,
                activeTrackColor: AppTheme.successGreen.withValues(alpha: 0.5),
                activeThumbColor: AppTheme.successGreen,
                onChanged: (val) {
                  if (val) {
                    controller.enableCamera(cam.id);
                  } else {
                    controller.disableCamera(cam.id);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddBottomSheet(BuildContext context, CameraController controller) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add New Camera", style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl, 
              decoration: const InputDecoration(labelText: "Camera Name", prefixIcon: Icon(Icons.label_outline_rounded)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl, 
              decoration: const InputDecoration(labelText: "RTSP URL or Video Index", prefixIcon: Icon(Icons.link_rounded)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                    controller.addCamera(nameCtrl.text, urlCtrl.text);
                    Navigator.pop(ctx);
                  }
                }, 
                child: const Text("Save Camera"),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
