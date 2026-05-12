import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';
import '../services/mongodb_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: MongoDbService.getAdminAnalytics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_outlined, color: Colors.white24, size: 48),
                    const SizedBox(height: 16),
                    Text('Failed to load analytics', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            
            // 🛡️ SAFE PARSING: Prevent type cast crashes
            final rawActiveUsers = data['activeUsers'];
            final List<dynamic> activeUsersData = rawActiveUsers is List ? rawActiveUsers : [];
            
            final rawUserGrowth = data['userGrowth'];
            final List<dynamic> userGrowthData = rawUserGrowth is List ? rawUserGrowth : [];

            final activeSpots = <FlSpot>[];
            try {
              for (int i = 0; i < activeUsersData.length; i++) {
                final count = activeUsersData[i]['count'];
                activeSpots.add(FlSpot(i.toDouble(), (count is num ? count : 0).toDouble()));
              }
            } catch (e) {
              debugPrint('Error parsing active spots: $e');
            }
            
            if (activeSpots.isEmpty) activeSpots.add(const FlSpot(0, 0));

            return Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics Dashboard', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: AppSizes.lg),
                  // Active Users
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trending_up_rounded, color: AppColors.neonGreen, size: 18),
                              const SizedBox(width: 8),
                              Text('Daily Active Users', style: Theme.of(context).textTheme.titleSmall),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          Expanded(
                            child: activeUsersData.isEmpty 
                              ? const Center(child: Text('No activity data available', style: TextStyle(color: Colors.white24, fontSize: 12)))
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                                        if (v.toInt() >= 0 && v.toInt() < activeUsersData.length) {
                                          final dateStr = activeUsersData[v.toInt()]['date'];
                                          if (dateStr is String && dateStr.length >= 10) {
                                            return Text(dateStr.substring(5), style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 10)); // MM-DD
                                          }
                                        }
                                        return const Text('');
                                      })),
                                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: activeSpots,
                                        isCurved: true, 
                                        gradient: const LinearGradient(colors: [AppColors.neonGreen, AppColors.neonCyan]), 
                                        barWidth: 3, 
                                        isStrokeCapRound: true,
                                        belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.neonGreen.withValues(alpha: 0.2), AppColors.neonGreen.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                                        dotData: FlDotData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  // User Growth
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bar_chart_rounded, color: AppColors.neonCyan, size: 18),
                              const SizedBox(width: 8),
                              Text('User Growth', style: Theme.of(context).textTheme.titleSmall),
                              const Spacer(),
                              Text('Total: ${data['totalUsers'] ?? 0}', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          Expanded(
                            child: userGrowthData.isEmpty
                              ? const Center(child: Text('No growth data available', style: TextStyle(color: Colors.white24, fontSize: 12)))
                              : BarChart(
                                  BarChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                                        if (v.toInt() >= 0 && v.toInt() < userGrowthData.length) {
                                          final dateStr = userGrowthData[v.toInt()]['date'];
                                          if (dateStr is String && dateStr.length >= 10) {
                                            return Text(dateStr.substring(5), style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 10)); // MM-DD
                                          }
                                        }
                                        return const Text('');
                                      })),
                                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: List.generate(userGrowthData.length, (i) {
                                      final count = userGrowthData[i]['count'];
                                      return BarChartGroupData(x: i, barRods: [
                                        BarChartRodData(
                                          toY: (count is num ? count : 0).toDouble(), 
                                          color: AppColors.neonCyan, 
                                          width: 12, 
                                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                                        ),
                                      ]);
                                    }),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

