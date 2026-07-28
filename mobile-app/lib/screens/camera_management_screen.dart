import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/camera_controller.dart';
import 'package:footfalls_app/models/camera_model.dart';
import 'package:shimmer/shimmer.dart';

class CameraManagementScreen extends ConsumerWidget {
  const CameraManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraControllerProvider);
    final controller = ref.read(cameraControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchCameras(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchCameras,
        child: _buildBody(cameraState, controller),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, controller),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(CameraState state, CameraController controller) {
    if (state.isLoading && state.cameras.isEmpty) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.white),
              title: Container(color: Colors.white, height: 16, width: double.infinity),
              subtitle: Container(color: Colors.white, height: 12, width: 100),
            ),
          ),
        ),
      );
    }

    if (state.error != null && state.cameras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.fetchCameras(),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (state.cameras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No cameras configured.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.fetchCameras(),
              child: const Text('Refresh'),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.cameras.length,
      itemBuilder: (context, index) {
        final CameraModel cam = state.cameras[index];
        
        return Dismissible(
          key: Key(cam.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (dir) => controller.deleteCamera(cam.id),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cam.isRunningInMemory ? Colors.green : (cam.isEnabled ? Colors.orange : Colors.grey),
                child: Icon(cam.isRunningInMemory ? Icons.videocam : Icons.videocam_off, color: Colors.white),
              ),
              title: Text(cam.name),
              subtitle: Text('FPS: ${cam.fps.toStringAsFixed(1)} • Status: ${cam.isRunningInMemory ? "Online" : "Offline"}'),
              trailing: Switch(
                value: cam.isEnabled,
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

  void _showAddDialog(BuildContext context, CameraController controller) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Add Camera"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
          TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: "RTSP URL / Index")),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
              controller.addCamera(nameCtrl.text, urlCtrl.text);
              Navigator.pop(ctx);
            }
          }, 
          child: const Text("Add")
        )
      ],
    ));
  }
}
