import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LiveMonitoringScreen extends ConsumerWidget {
  const LiveMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Monitoring')),
      body: const Center(
        child: Text('Live stats and auto-refresh stream will be here'),
      ),
    );
  }
}

class StoresScreen extends ConsumerWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Stores')),
      body: const Center(child: Text('Stores CRUD List')),
    );
  }
}

class CamerasScreen extends ConsumerWidget {
  const CamerasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Cameras')),
      body: const Center(child: Text('Cameras CRUD List')),
    );
  }
}


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Theme and API Settings')),
    );
  }
}
