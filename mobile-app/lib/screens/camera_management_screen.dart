import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/camera_controller.dart';

class CameraManagementScreen extends ConsumerStatefulWidget {
  const CameraManagementScreen({super.key});

  @override
  ConsumerState<CameraManagementScreen> createState() => _CameraManagementScreenState();
}

class _CameraManagementScreenState extends ConsumerState<CameraManagementScreen> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  void _showAddCameraDialog() {
    _nameController.clear();
    _urlController.clear();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Camera Stream'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Camera Name (e.g. Front Door)'),
              ),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'Stream URL (rtsp://... or 0)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text;
                final url = _urlController.text;
                if (name.isNotEmpty && url.isNotEmpty) {
                  ref.read(cameraControllerProvider.notifier).addCamera(name, url);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(cameraControllerProvider.notifier).fetchCameras(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCameraDialog,
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)))
              : state.cameras.isEmpty
                  ? const Center(child: Text('No cameras configured.'))
                  : ListView.builder(
                      itemCount: state.cameras.length,
                      itemBuilder: (context, index) {
                        final cam = state.cameras[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.videocam,
                              color: cam.status == 'online' ? Colors.green : Colors.grey,
                            ),
                            title: Text(cam.name),
                            subtitle: Text(cam.url),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ref.read(cameraControllerProvider.notifier).deleteCamera(cam.id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
