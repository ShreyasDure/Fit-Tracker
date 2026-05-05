import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analytics', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: AppSizes.lg),
              // Points earned vs spent
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Points Earned vs Spent', style: Theme.of(context).textTheme.titleSmall),
                          const Spacer(),
                          _LegendDot(color: AppColors.neonCyan, label: 'Earned'),
                          const SizedBox(width: AppSizes.sm),
                          _LegendDot(color: AppColors.neonPink, label: 'Spent'),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][v.toInt() % 7], style: const TextStyle(color: AppColors.textMuted, fontSize: 10)))),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (i) {
                              return BarChartGroupData(x: i, barRods: [
                                BarChartRodData(toY: [8, 12, 9, 15, 11, 14, 10][i].toDouble(), color: AppColors.neonCyan, width: 10, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                                BarChartRodData(toY: [5, 7, 4, 9, 6, 8, 5][i].toDouble(), color: AppColors.neonPink, width: 10, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                              ]);
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              // Active users
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Users', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSizes.md),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5), FlSpot(3, 5), FlSpot(4, 6), FlSpot(5, 5.5), FlSpot(6, 7)],
                                isCurved: true, gradient: const LinearGradient(colors: [AppColors.neonGreen, AppColors.neonCyan]), barWidth: 3, isStrokeCapRound: true,
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
              const SizedBox(height: AppSizes.sm),
              // Conversion rate
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Premium Conversion', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSizes.md),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 30,
                                  sections: [
                                    PieChartSectionData(value: 25, color: AppColors.neonPurple, radius: 20, title: '25%', titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                    PieChartSectionData(value: 75, color: AppColors.surfaceLighter, radius: 20, title: '75%', titleStyle: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.lg),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LegendDot(color: AppColors.neonPurple, label: 'Premium (25%)'),
                                const SizedBox(height: AppSizes.sm),
                                _LegendDot(color: AppColors.surfaceLighter, label: 'Free (75%)'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
