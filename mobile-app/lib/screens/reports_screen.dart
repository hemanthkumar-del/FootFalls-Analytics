import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footfalls_app/providers/analytics_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('BI Dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Trends'),
              Tab(text: 'AI Insights'),
              Tab(text: 'Heatmap'),
              Tab(text: 'Export'),
            ],
          ),
        ),
        body: state.isLoading
            ? _buildShimmerLoading()
            : state.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Failed to load data: ${state.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => controller.fetchData(),
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  )
                : state.advancedData == null
                    ? const Center(child: Text('No data available'))
                    : TabBarView(
                        children: [
                          _buildTrendsTab(state.advancedData!),
                          _buildInsightsTab(state.advancedData!),
                          _buildHeatmapTab(state.heatmapData ?? {}),
                          _buildExportTab(context, state, controller),
                        ],
                      ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(color: Colors.white, height: 24, width: 150),
              const SizedBox(height: 16),
              Container(
                height: 250,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              ),
              const SizedBox(height: 32),
              Container(color: Colors.white, height: 24, width: 200),
              const SizedBox(height: 16),
              Container(
                height: 250,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsTab(Map<String, dynamic> data) {
    final hourly = List<Map<String, dynamic>>.from(data['hourly'] ?? []);
    final daily = List<Map<String, dynamic>>.from(data['daily'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Today\'s Hourly Traffic', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: hourly.isEmpty 
            ? const Center(child: Text("Not enough hourly data")) 
            : LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: hourly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['entries'] as int).toDouble())).toList(),
                  isCurved: true,
                  color: Colors.green,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: hourly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['exits'] as int).toDouble())).toList(),
                  isCurved: true,
                  color: Colors.red,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text('7-Day Daily Traffic', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: daily.isEmpty 
            ? const Center(child: Text("Not enough daily data")) 
            : BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              titlesData: const FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: daily.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(toY: (e.value['entries'] as int).toDouble(), color: Colors.green, width: 12),
                    BarChartRodData(toY: (e.value['exits'] as int).toDouble(), color: Colors.red, width: 12),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsTab(Map<String, dynamic> data) {
    final insights = List<String>.from(data['insights'] ?? []);
    final dwell = data['dwell'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Text('AI Business Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                ...insights.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(i, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDwellCard('Avg Dwell', '${dwell['avg_minutes']}m', Colors.purple)),
            const SizedBox(width: 8),
            Expanded(child: _buildDwellCard('Longest', '${dwell['longest_minutes']}m', Colors.orange)),
          ],
        )
      ],
    );
  }

  Widget _buildDwellCard(String title, String val, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapTab(Map<String, dynamic> data) {
    final zones = List<Map<String, dynamic>>.from(data['zones'] ?? []);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Store Heatmap (Live View)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8)
              ),
              child: CustomPaint(
                painter: HeatmapPainter(zones: zones),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab(BuildContext context, AnalyticsState state, AnalyticsController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Export Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Download raw data or AI-generated PDF briefs.'),
          const SizedBox(height: 24),
          if (state.isExporting)
            const Center(child: CircularProgressIndicator())
          else ...[
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export Daily Brief (PDF)'),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () async {
                final path = await controller.exportReport('pdf');
                if (path != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
                }
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export Raw Data (CSV)'),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () async {
                final path = await controller.exportReport('csv');
                if (path != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
                }
              },
            ),
          ]
        ],
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
        ..color = Colors.red.withValues(alpha: weight * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(Offset(x, y), 30 + (weight * 20), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
