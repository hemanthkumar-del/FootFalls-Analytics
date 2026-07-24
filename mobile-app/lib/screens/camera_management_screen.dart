import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

final cameraListProvider = StateNotifierProvider.autoDispose<CameraController, List<Map<String, dynamic>>>((ref) {
  return CameraController(ref.watch(dioProvider));
});

class CameraController extends StateNotifier<List<Map<String, dynamic>>> {
  final Dio _dio;

  CameraController(this._dio) : super([]) {
    fetchCameras();
  }

  Future<void> fetchCameras() async {
    try {
      final res = await _dio.get('/cameras/status');
      state = List<Map<String, dynamic>>.from(res.data);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleCamera(String id, bool enable) async {
    try {
      await _dio.patch('/cameras/$id/${enable ? "enable" : "disable"}');
      await fetchCameras();
    } catch (e) {
      // error
    }
  }

  Future<void> deleteCamera(String id) async {
    try {
      await _dio.delete('/cameras/$id');
      await fetchCameras();
    } catch (e) {
      // error
    }
  }
  
  Future<void> addCamera(String name, String url) async {
    try {
      await _dio.post('/cameras/', data: {"name": name, "url": url});
      await fetchCameras();
    } catch (e) {
      // error
    }
  }
}

class CameraManagementScreen extends ConsumerWidget {
  const CameraManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameras = ref.watch(cameraListProvider);
    final controller = ref.read(cameraListProvider.notifier);

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
        child: cameras.isEmpty 
          ? const Center(child: Text("No cameras configured.")) 
          : ListView.builder(
          itemCount: cameras.length,
          itemBuilder: (context, index) {
            final cam = cameras[index];
            final isEnabled = cam['isEnabled'] == true;
            final isRunning = cam['is_running_in_memory'] == true;
            
            return Dismissible(
              key: Key(cam['id']),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (dir) => controller.deleteCamera(cam['id']),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRunning ? Colors.green : (isEnabled ? Colors.orange : Colors.grey),
                    child: Icon(isRunning ? Icons.videocam : Icons.videocam_off, color: Colors.white),
                  ),
                  title: Text(cam['name']),
                  subtitle: Text('FPS: ${cam['fps'].toStringAsFixed(1)} • Status: ${isRunning ? "Online" : "Offline"}'),
                  trailing: Switch(
                    value: isEnabled,
                    onChanged: (val) => controller.toggleCamera(cam['id'], val),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, controller),
        child: const Icon(Icons.add),
      ),
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
