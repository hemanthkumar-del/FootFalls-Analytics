import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footfalls_app/providers/auth_controller.dart';
import 'package:footfalls_app/providers/profile_controller.dart';
import 'package:footfalls_app/providers/dashboard_controller.dart';
import 'package:shimmer/shimmer.dart';
import 'package:footfalls_app/core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
    final user = ref.watch(authProvider).user;
    final profileState = ref.watch(profileControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final imageProvider = _getProfileImageProvider(user?.photoUrl);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5))),
            Text(profileState.storeName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/dashboard/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: InkWell(
              onTap: () => context.go('/dashboard/profile'),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: imageProvider,
                child: imageProvider == null ? Icon(Icons.person, color: colorScheme.primary) : null,
              ),
            ),
          ),
        ],
      ),
      body: dashboardState.isLoading && dashboardState.metrics.currentOccupancy == 0
          ? _buildShimmerLoading(context)
          : dashboardState.error != null
              ? _buildErrorState(context, ref, dashboardState.error!)
              : RefreshIndicator(
                  onRefresh: () => ref.read(dashboardControllerProvider.notifier).fetchInitialData(),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildLiveStatusCard(context, dashboardState),
                      const SizedBox(height: 24),
                      Text('Today\'s Insights', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildMetricRow(
                        dashboardState.metrics.todayEntries + dashboardState.metrics.todayExits, 
                        dashboardState.metrics.peakHour,
                        context,
                      ),
                      const SizedBox(height: 32),
                      Text('Quick Actions', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildNavigationGrid(context),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLiveStatusCard(BuildContext context, DashboardState state) {
    final m = state.metrics;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: () => context.go('/dashboard/live'),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.sensors, size: 24, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text('Live Occupancy', style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                          SizedBox(width: 6),
                          Text('Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: m.currentOccupancy),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Text('$value', style: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, height: 1));
                  },
                ),
                const SizedBox(height: 4),
                Text('People Currently Inside', style: textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAnimatedStat(context, Icons.login, AppTheme.successGreen, m.todayEntries, 'Entries'),
                      Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                      _buildAnimatedStat(context, Icons.logout, AppTheme.warningOrange, m.todayExits, 'Exits'),
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

  Widget _buildAnimatedStat(BuildContext context, IconData icon, Color color, int val, String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: val),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white));
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildMetricRow(int totalFlow, String peakHour, BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard(context, Icons.people_alt_rounded, AppTheme.secondaryCyan, '$totalFlow', 'Total Flow Today')),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(context, Icons.access_time_filled_rounded, Colors.purpleAccent, peakHour, 'Peak Hour')),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, IconData icon, Color iconColor, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6))),
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
      childAspectRatio: 1.1,
      children: [
        _buildNavCard(context, 'Live View', Icons.videocam_rounded, '/dashboard/live', AppTheme.primaryBlue),
        _buildNavCard(context, 'Cameras', Icons.camera_alt_rounded, '/dashboard/cameras', AppTheme.secondaryCyan),
        _buildNavCard(context, 'Reports', Icons.bar_chart_rounded, '/dashboard/reports', Colors.purple),
        _buildNavCard(context, 'Settings', Icons.settings_rounded, '/dashboard/settings', Colors.blueGrey),
      ],
    );
  }

  Widget _buildNavCard(BuildContext context, String title, IconData icon, String route, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 80, color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text('Oops! Data Unavailable', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => ref.read(dashboardControllerProvider.notifier).fetchInitialData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(height: 260, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 40),
          Container(height: 28, width: 150, color: Colors.white),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
              const SizedBox(width: 16),
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
            ],
          ),
          const SizedBox(height: 40),
          Container(height: 28, width: 150, color: Colors.white),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: List.generate(4, (index) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
          )
        ],
      ),
    );
  }
}
