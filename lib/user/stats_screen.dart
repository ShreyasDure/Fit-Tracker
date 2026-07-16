import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';
import '../services/mongodb_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  /// Converts "yyyy-MM-dd" → "dd/MM/yyyy"
  String _fmtDate(String iso) {
    if (iso.length < 10) return iso;
    final parts = iso.substring(0, 10).split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Stats')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: MongoDbService.getHealthHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading stats: ${snapshot.error}'));
          }
          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSizes.md),
                    const Text(
                      'No data yet, start tracking!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final spots = <FlSpot>[];
          final calSpots = <FlSpot>[];
          final activeSpots = <FlSpot>[];
          
          for (int i = 0; i < history.length; i++) {
            spots.add(FlSpot(i.toDouble(), (history[i]['steps'] ?? 0).toDouble()));
            calSpots.add(FlSpot(i.toDouble(), (history[i]['calories'] ?? 0).toDouble()));
            activeSpots.add(FlSpot(i.toDouble(), (history[i]['activeMinutes'] ?? 0).toDouble()));
          }

          return ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              _buildBarChartCard(context, 'Weekly Steps', spots, AppColors.neonCyan, history),
              const SizedBox(height: AppSizes.lg),
              _buildChartCard(context, 'Calories Trend', calSpots, AppColors.neonOrange, history),
              const SizedBox(height: AppSizes.lg),
              _buildChartCard(context, 'Active Minutes', activeSpots, AppColors.neonGreen, history),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBarChartCard(BuildContext context, String title, List<FlSpot> spots, Color color, List<Map<String, dynamic>> history) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
          const SizedBox(height: AppSizes.lg),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        int index = v.toInt();
                        if (index >= 0 && index < history.length) {
                          String dateStr = history[index]['date'] as String;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _fmtDate(dateStr),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall!.color!,
                                fontSize: 8,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: spots.map((spot) {
                  return BarChartGroupData(
                    x: spot.x.toInt(),
                    barRods: [
                      BarChartRodData(
                        toY: spot.y,
                        color: color,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, List<FlSpot> spots, Color color, List<Map<String, dynamic>> history) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
          const SizedBox(height: AppSizes.lg),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => FlLine(color: Theme.of(context).colorScheme.surfaceContainerHighest, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    int index = v.toInt();
                    if (index >= 0 && index < history.length) {
                      String dateStr = history[index]['date'] as String;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(_fmtDate(dateStr), style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 8)),
                      );
                    }
                    return const Text('');
                  })),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: color, strokeWidth: 0)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

