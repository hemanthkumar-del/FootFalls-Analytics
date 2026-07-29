import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/analytics_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:footfalls_app/core/theme/app_theme.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('BI Dashboard'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [
              Tab(text: 'Trends'),
              Tab(text: 'AI Insights'),
              Tab(text: 'Heatmap'),
              Tab(text: 'Export'),
            ],
          ),
        ),
        body: state.isLoading
            ? _buildShimmerLoading(context)
            : state.error != null
                ? _buildErrorState(context, state.error!, controller)
                : state.advancedData == null
                    ? _buildEmptyState(context)
                    : TabBarView(
                        children: [
                          _buildTrendsTab(context, state.advancedData!),
                          _buildInsightsTab(context, state.advancedData!),
                          _buildHeatmapTab(context, state.heatmapData ?? {}),
                          _buildExportTab(context, state, controller),
                        ],
                      ),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(color: Colors.white, height: 28, width: 150),
              const SizedBox(height: 16),
              Container(height: 280, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
              const SizedBox(height: 40),
              Container(color: Colors.white, height: 28, width: 200),
              const SizedBox(height: 16),
              Container(height: 280, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error, AnalyticsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats_rounded, size: 80, color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text('Analytics Unavailable', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => controller.fetchData(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload Dashboard'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined_rounded, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text('No Data Yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Analytics will appear here once cameras start tracking.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(BuildContext context, Map<String, dynamic> data) {
    final hourly = List<Map<String, dynamic>>.from(data['hourly'] ?? []);
    final daily = List<Map<String, dynamic>>.from(data['daily'] ?? []);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Icon(Icons.today_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text('Today\'s Hourly Traffic', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 280,
          child: hourly.isEmpty 
            ? _buildChartPlaceholder(context, "Waiting for hourly data") 
            : _buildLineChart(hourly, colorScheme),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            Icon(Icons.date_range_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text('7-Day Daily Traffic', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 280,
          child: daily.isEmpty 
            ? _buildChartPlaceholder(context, "Waiting for daily data") 
            : _buildBarChart(daily, colorScheme),
        ),
      ],
    );
  }

  Widget _buildChartPlaceholder(BuildContext context, String message) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
      ),
      alignment: Alignment.center,
      child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> hourly, ColorScheme colorScheme) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(color: colorScheme.outline.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2,
              getTitlesWidget: (val, meta) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${val.toInt()}h', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: hourly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['entries'] as int).toDouble())).toList(),
            isCurved: true,
            color: AppTheme.successGreen,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.successGreen.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: hourly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['exits'] as int).toDouble())).toList(),
            isCurved: true,
            color: AppTheme.warningOrange,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> daily, ColorScheme colorScheme) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) => FlLine(color: colorScheme.outline.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('D${val.toInt() + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: daily.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value['entries'] as int).toDouble(), 
                color: AppTheme.successGreen, 
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4))
              ),
              BarChartRodData(
                toY: (e.value['exits'] as int).toDouble(), 
                color: AppTheme.warningOrange, 
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4))
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightsTab(BuildContext context, Map<String, dynamic> data) {
    final insights = List<String>.from(data['insights'] ?? []);
    final dwell = data['dwell'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(child: _buildDwellCard(context, 'Avg Dwell', '${dwell['avg_minutes']}m', AppTheme.primaryBlue, Icons.timer_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildDwellCard(context, 'Longest Stay', '${dwell['longest_minutes']}m', AppTheme.secondaryCyan, Icons.hourglass_top_rounded)),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.purple),
            const SizedBox(width: 8),
            Text('Smart Insights', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        ...insights.map((i) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(i, style: const TextStyle(fontSize: 15, height: 1.4))),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildDwellCard(BuildContext context, String title, String val, Color color, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapTab(BuildContext context, Map<String, dynamic> data) {
    final zones = List<Map<String, dynamic>>.from(data['zones'] ?? []);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Store Heatmap', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Live tracking of high-density areas.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(24)
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: zones.isEmpty 
                  ? const Center(child: Text("Waiting for heatmap data..."))
                  : CustomPaint(painter: HeatmapPainter(zones: zones)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab(BuildContext context, AnalyticsState state, AnalyticsController controller) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Row(
          children: [
            Icon(Icons.file_download_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Export Reports', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Download raw data or AI-generated executive summaries.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 32),
        if (state.isExporting)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _buildExportTile(
            context,
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.redAccent,
            title: 'Executive PDF Brief',
            subtitle: 'AI-generated summary of today\'s traffic',
            onTap: () async {
              final path = await controller.exportReport('pdf');
              if (path != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path'), backgroundColor: AppTheme.successGreen));
              }
            },
          ),
          const SizedBox(height: 16),
          _buildExportTile(
            context,
            icon: Icons.table_chart_rounded,
            color: AppTheme.successGreen,
            title: 'Raw Data (CSV)',
            subtitle: 'Complete hourly entry/exit logs',
            onTap: () async {
              final path = await controller.exportReport('csv');
              if (path != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path'), backgroundColor: AppTheme.successGreen));
              }
            },
          ),
        ]
      ],
    );
  }

  Widget _buildExportTile(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class HeatmapPainter extends CustomPainter {
  final List<Map<String, dynamic>> zones;

  HeatmapPainter({required this.zones});

  @override
  void paint(Canvas canvas, Size size) {
    for (var zone in zones) {
      final x = (zone['x'] as double) * size.width;
      final y = (zone['y'] as double) * size.height;
      final weight = (zone['weight'] as double);

      final paint = Paint()
        ..color = AppTheme.errorRed.withValues(alpha: weight * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(Offset(x, y), 30 + (weight * 20), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
