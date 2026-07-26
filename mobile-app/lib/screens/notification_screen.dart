import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

final notificationProvider = StateNotifierProvider.autoDispose<NotificationController, List<dynamic>>((ref) {
  return NotificationController(ref.watch(dioProvider));
});

class NotificationController extends StateNotifier<List<dynamic>> {
  final Dio _dio;

  NotificationController(this._dio) : super([]) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final res = await _dio.get('/notifications');
      state = res.data;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
      await fetchNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final controller = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: controller.fetchNotifications)
        ],
      ),
      body: notifications.isEmpty
        ? const Center(child: Text("All caught up!"))
        : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (ctx, idx) {
              final notif = notifications[idx];
              final isRead = notif['isRead'] == true;
              return ListTile(
                leading: Icon(
                  notif['severity'] == 'ERROR' ? Icons.error : (notif['severity'] == 'WARNING' ? Icons.warning : Icons.info),
                  color: notif['severity'] == 'ERROR' ? Colors.red : (notif['severity'] == 'WARNING' ? Colors.orange : Colors.blue),
                ),
                title: Text(notif['title'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(notif['message']),
                trailing: isRead ? null : IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => controller.markAsRead(notif['_id']),
                ),
              );
            },
          ),
    );
  }
}
