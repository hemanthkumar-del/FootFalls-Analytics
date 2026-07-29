import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/auth_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:footfalls_app/core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Preferences', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  value: isDarkMode,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.dark_mode_rounded, color: colorScheme.primary),
                  ),
                  activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
                  activeThumbColor: colorScheme.primary,
                ),
                Divider(height: 1, indent: 64, color: colorScheme.outline.withValues(alpha: 0.1)),
                ListTile(
                  title: const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.w600)),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.warningOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.notifications_active_rounded, color: AppTheme.warningOrange),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => context.push('/dashboard/notifications_prefs'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Information', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
            child: ListTile(
              title: const Text('About FootFalls', style: TextStyle(fontWeight: FontWeight.w600)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.secondaryCyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.info_outline_rounded, color: AppTheme.secondaryCyan),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () => context.push('/dashboard/about'),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 0,
            color: AppTheme.errorRed.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.2))),
            child: ListTile(
              title: const Text('Log Out', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.errorRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
              ),
              onTap: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About FootFalls'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.analytics_rounded, size: 80, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 24),
                  Text('FootFalls Analytics', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.successGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Version 1.0.0 (Production)', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  Text('AI-Powered Visitor Intelligence App', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text('Technology Stack', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTechRow(context, 'Frontend', 'Flutter & Riverpod', Icons.phone_android_rounded),
                    Divider(height: 24, color: colorScheme.outline.withValues(alpha: 0.1)),
                    _buildTechRow(context, 'Backend', 'FastAPI (Python)', Icons.dns_rounded),
                    Divider(height: 24, color: colorScheme.outline.withValues(alpha: 0.1)),
                    _buildTechRow(context, 'Database', 'MongoDB & Firebase', Icons.storage_rounded),
                    Divider(height: 24, color: colorScheme.outline.withValues(alpha: 0.1)),
                    _buildTechRow(context, 'AI Engine', 'YOLOv8 & OpenCV', Icons.auto_awesome_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTechRow(context, 'Developer', 'FootFalls Team', Icons.code_rounded),
                    Divider(height: 24, color: colorScheme.outline.withValues(alpha: 0.1)),
                    _buildTechRow(context, 'GitHub', 'github.com/footfalls', Icons.link_rounded),
                    Divider(height: 24, color: colorScheme.outline.withValues(alpha: 0.1)),
                    _buildTechRow(context, 'Privacy Policy', 'https://footfalls.app/privacy', Icons.privacy_tip_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text('© 2026 FootFalls Analytics', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTechRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Expanded(child: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold), textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
