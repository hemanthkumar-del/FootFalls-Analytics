import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/profile_controller.dart';
import 'package:footfalls_app/providers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          )
        ],
      ),
      body: profileState.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null ? const Icon(Icons.store, size: 50) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(profileState.storeName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(profileState.storeAddress, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Admin: ${user?.email ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  const SizedBox(height: 24),
                  
                  // Camera Card
                  Card(
                    color: Colors.blue.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.videocam, color: Colors.blue, size: 40),
                      title: Text('${profileState.camerasInstalled} Cameras Installed', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('AI Analysis Active'),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Lifetime Stats Grid
                  const Align(alignment: Alignment.centerLeft, child: Text('Store Traffic Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(Icons.people, Colors.blue, '${profileState.todayVisitors}', 'Today\'s Visitors'),
                      _buildStatCard(Icons.calendar_view_week, Colors.green, '${profileState.weeklyVisitors}', 'Weekly Visitors'),
                      _buildStatCard(Icons.calendar_month, Colors.orange, '${profileState.monthlyVisitors}', 'Monthly Visitors'),
                      _buildStatCard(Icons.analytics, Colors.purple, '${profileState.totalVisitors}', 'Total All-Time'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.redAccent),
                      title: const Text('Peak Hour'),
                      trailing: Text(profileState.peakHour, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(IconData icon, Color color, String value, String label) {
    return Card(
      elevation: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
