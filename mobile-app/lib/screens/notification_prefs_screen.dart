import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple provider to manage preferences locally
final notificationPrefsProvider = StateNotifierProvider<NotificationPrefsNotifier, Map<String, bool>>((ref) {
  return NotificationPrefsNotifier();
});

class NotificationPrefsNotifier extends StateNotifier<Map<String, bool>> {
  NotificationPrefsNotifier() : super({
    'push': true,
    'email': true,
    'daily': false,
    'weekly': true,
  }) {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = {
      'push': prefs.getBool('notif_push') ?? true,
      'email': prefs.getBool('notif_email') ?? true,
      'daily': prefs.getBool('notif_daily') ?? false,
      'weekly': prefs.getBool('notif_weekly') ?? true,
    };
  }

  Future<void> togglePref(String key, bool value) async {
    state = {...state, key: value};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_$key', value);
  }
}

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('General Notifications', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
            child: Column(
              children: [
                _buildSwitch(
                  context,
                  title: 'Push Notifications',
                  subtitle: 'Receive alerts on your device',
                  icon: Icons.smartphone_rounded,
                  value: prefs['push'] ?? true,
                  onChanged: (val) => ref.read(notificationPrefsProvider.notifier).togglePref('push', val),
                ),
                Divider(height: 1, indent: 64, color: colorScheme.outline.withValues(alpha: 0.1)),
                _buildSwitch(
                  context,
                  title: 'Email Notifications',
                  subtitle: 'Receive alerts via email',
                  icon: Icons.email_rounded,
                  value: prefs['email'] ?? true,
                  onChanged: (val) => ref.read(notificationPrefsProvider.notifier).togglePref('email', val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Reports', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
            child: Column(
              children: [
                _buildSwitch(
                  context,
                  title: 'Daily Reports',
                  subtitle: 'End of day traffic summary',
                  icon: Icons.today_rounded,
                  value: prefs['daily'] ?? false,
                  onChanged: (val) => ref.read(notificationPrefsProvider.notifier).togglePref('daily', val),
                ),
                Divider(height: 1, indent: 64, color: colorScheme.outline.withValues(alpha: 0.1)),
                _buildSwitch(
                  context,
                  title: 'Weekly Reports',
                  subtitle: 'Comprehensive weekly analytics',
                  icon: Icons.date_range_rounded,
                  value: prefs['weekly'] ?? true,
                  onChanged: (val) => ref.read(notificationPrefsProvider.notifier).togglePref('weekly', val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(BuildContext context, {required String title, required String subtitle, required IconData icon, required bool value, required ValueChanged<bool> onChanged}) {
    final colorScheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6))),
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: colorScheme.primary),
      ),
      activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
      activeThumbColor: colorScheme.primary,
    );
  }
}
