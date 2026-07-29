import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/core/network/dio_client.dart';
import 'package:footfalls_app/core/config/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import 'package:footfalls_app/core/theme/app_theme.dart';

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
      // Optimistic update
      final newNotifs = state.notifications.map((n) {
        if ((n['_id'] ?? n['id']) == id) {
          return {...n, 'isRead': true};
        }
        return n;
      }).toList();
      state = NotificationState(notifications: newNotifs, isLoading: state.isLoading);
      
      await _dio.patch(ApiConstants.markNotificationRead(id));
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Refresh',
            onPressed: controller.fetchNotifications,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.fetchNotifications(),
        child: state.isLoading && state.notifications.isEmpty
          ? _buildShimmer(context)
          : state.notifications.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: state.notifications.length,
                itemBuilder: (ctx, idx) {
                  final notif = state.notifications[idx];
                  final isRead = notif['isRead'] == true;
                  final severity = notif['severity'];
                  
                  Color iconColor = colorScheme.primary;
                  IconData iconData = Icons.info_outline_rounded;
                  
                  if (severity == 'ERROR') {
                    iconColor = AppTheme.errorRed;
                    iconData = Icons.error_outline_rounded;
                  } else if (severity == 'WARNING') {
                    iconColor = AppTheme.warningOrange;
                    iconData = Icons.warning_amber_rounded;
                  }
                  
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isRead ? colorScheme.surface : colorScheme.primary.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isRead ? colorScheme.outline.withValues(alpha: 0.1) : colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(iconData, color: iconColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif['title'], 
                                  style: TextStyle(fontWeight: isRead ? FontWeight.w600 : FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif['message'], 
                                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.successGreen),
                              tooltip: 'Mark as read',
                              onPressed: () => controller.markAsRead(notif['_id'] ?? notif['id']),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.notifications_off_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('All Caught Up!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('You have no new notifications right now.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (ctx, idx) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.white, radius: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 200, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(height: 12, width: 150, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
