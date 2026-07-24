import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/auth_controller.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: false, // Wire up theme provider later
            onChanged: (val) {},
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            title: const Text('Notification Preferences'),
            leading: const Icon(Icons.notifications),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('About'),
            leading: const Icon(Icons.info),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/dashboard/about'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            onTap: () {
              ref.read(authProvider.notifier).signOut();
            },
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
    return Scaffold(
      appBar: AppBar(title: const Text('About FootFalls')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Icon(Icons.analytics, size: 80, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('FootFalls Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Version 1.0.0 (Phase 4 Production)', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Technology Stack', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildTechRow('Frontend', 'Flutter & Riverpod'),
            _buildTechRow('Backend', 'FastAPI (Python)'),
            _buildTechRow('Database', 'MongoDB & Firebase'),
            _buildTechRow('AI Engine', 'YOLOv8 & OpenCV'),
            const Spacer(),
            const Center(child: Text('© 2026 FootFalls Analytics', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _buildTechRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blueAccent)),
        ],
      ),
    );
  }
}
