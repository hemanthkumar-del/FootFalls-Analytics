import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footfalls_app/providers/profile_controller.dart';
import 'package:footfalls_app/providers/auth_controller.dart';
import 'package:footfalls_app/core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  ImageProvider? _getProfileImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    }
    final file = File(photoUrl);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final user = ref.watch(authProvider).user;
    final colorScheme = Theme.of(context).colorScheme;

    final imageProvider = _getProfileImageProvider(user?.photoUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/dashboard/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          )
        ],
      ),
      body: profileState.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: imageProvider,
                      child: imageProvider == null ? Icon(Icons.storefront_rounded, size: 56, color: colorScheme.primary) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user?.displayName ?? profileState.storeName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  if (profileState.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(profileState.bio, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8), fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 16),
                  
                  // Store & Contact Info
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (profileState.storeName.isNotEmpty && profileState.storeName != 'Unknown Store') ...[
                            Row(
                              children: [
                                Icon(Icons.store_rounded, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(child: Text(profileState.storeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                              ],
                            ),
                            const Divider(height: 24),
                          ],
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 20, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(child: Text(profileState.storeAddress)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Icon(Icons.email_rounded, size: 20, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(child: Text(user?.email ?? '')),
                            ],
                          ),
                          if (profileState.phoneNumber.isNotEmpty) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                Icon(Icons.phone_rounded, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(child: Text(profileState.phoneNumber)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Camera Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.videocam_rounded, color: AppTheme.primaryBlue, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${profileState.camerasInstalled} Cameras Installed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                const Text('AI Analysis Active', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 28),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Lifetime Stats Grid
                  Align(
                    alignment: Alignment.centerLeft, 
                    child: Row(
                      children: [
                        Icon(Icons.analytics_rounded, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Store Traffic Analytics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(context, Icons.people_alt_rounded, AppTheme.primaryBlue, '${profileState.todayVisitors}', 'Today\'s Visitors'),
                      _buildStatCard(context, Icons.calendar_view_week_rounded, AppTheme.successGreen, '${profileState.weeklyVisitors}', 'Weekly Visitors'),
                      _buildStatCard(context, Icons.calendar_month_rounded, AppTheme.warningOrange, '${profileState.monthlyVisitors}', 'Monthly Visitors'),
                      _buildStatCard(context, Icons.leaderboard_rounded, Colors.purple, '${profileState.totalVisitors}', 'Total All-Time'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.errorRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.access_time_filled_rounded, color: AppTheme.errorRed),
                      ),
                      title: const Text('Peak Hour', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text(profileState.peakHour, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, Color color, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  label, 
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)), 
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
