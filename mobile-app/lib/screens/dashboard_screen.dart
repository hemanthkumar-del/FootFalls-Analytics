import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footfalls_app/providers/auth_controller.dart';
import 'package:footfalls_app/providers/profile_controller.dart';
import 'package:footfalls_app/providers/dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final profileState = ref.watch(profileControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FootFalls Analytics'),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null ? const Icon(Icons.person) : null,
            ),
            onPressed: () => context.go('/dashboard/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          )
        ],
      ),
      body: dashboardState.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : dashboardState.error != null
              ? Center(child: Text('Failed to load data: ${dashboardState.error}'))
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(dashboardControllerProvider.notifier).fetchInitialData();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Welcome to ${profileState.storeName}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildLiveStatusCard(context, dashboardState),
                      const SizedBox(height: 16),
                      _buildMetricRow(
                        dashboardState.metrics.todayEntries + dashboardState.metrics.todayExits, // Approximation of total visitor flow
                        dashboardState.metrics.currentOccupancy, 
                        dashboardState.metrics.peakHour
                      ),
                      const SizedBox(height: 20),
                      _buildNavigationGrid(context),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLiveStatusCard(BuildContext context, DashboardState state) {
    final m = state.metrics;
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sensors, size: 32, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('Live Occupancy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text('${m.currentOccupancy}', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Text('People Currently Inside', style: TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSmallStat(Icons.login, Colors.green, '${m.todayEntries}', 'Entries'),
                _buildSmallStat(Icons.logout, Colors.orange, '${m.todayExits}', 'Exits'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat(IconData icon, Color color, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: color),
        Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMetricRow(int totalFlow, int occupancy, String peakHour) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard(Icons.people, Colors.orange, '$totalFlow', 'Total Flow Today')),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricCard(Icons.access_time, Colors.purple, peakHour, 'Peak Hour')),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, Color iconColor, String value, String label) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildNavCard(context, 'Live View', Icons.videocam, '/dashboard/live'),
        _buildNavCard(context, 'Cameras', Icons.camera_alt, '/dashboard/cameras'),
        _buildNavCard(context, 'Reports', Icons.bar_chart, '/dashboard/reports'), // stub
        _buildNavCard(context, 'Settings', Icons.settings, '/dashboard/settings'), // stub
      ],
    );
  }

  Widget _buildNavCard(BuildContext context, String title, IconData icon, String route) {
    return InkWell(
      onTap: () => context.go(route),
      child: Card(
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
