import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:footfalls_app/core/config/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';

final notificationProvider = StateNotifierProvider.autoDispose<NotificationController, NotificationState>((ref) {
  return NotificationController(ref.watch(dioProvider));
});

class NotificationState {
  final List<dynamic> notifications;
  final bool isLoading;

  NotificationState({this.notifications = const [], this.isLoading = false});
}

class NotificationController extends StateNotifier<NotificationState> {
  final Dio _dio;

  NotificationController(this._dio) : super(NotificationState(isLoading: true)) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      state = NotificationState(notifications: state.notifications, isLoading: true);
      final res = await _dio.get(ApiConstants.getNotifications);
      state = NotificationState(notifications: res.data, isLoading: false);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      state = NotificationState(notifications: state.notifications, isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch(ApiConstants.markNotificationRead(id));
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
    final state = ref.watch(notificationProvider);
    final controller = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: controller.fetchNotifications)
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
        ? _buildShimmer()
        : state.notifications.isEmpty
          ? const Center(child: Text("All caught up!"))
          : ListView.builder(
              itemCount: state.notifications.length,
              itemBuilder: (ctx, idx) {
                final notif = state.notifications[idx];
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
                    onPressed: () => controller.markAsRead(notif['_id'] ?? notif['id']),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (ctx, idx) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.white),
          title: Container(height: 16, color: Colors.white),
          subtitle: Container(height: 12, color: Colors.white, margin: const EdgeInsets.only(top: 8)),
        ),
      ),
    );
  }
}
