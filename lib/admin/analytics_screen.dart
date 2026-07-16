import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';
import '../services/mongodb_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _touchedPieIndex = -1;

  /// Converts "yyyy-MM-dd" → compact "dd MMM"
  String _fmtLabel(String iso) {
    if (iso.length < 10) return iso;
    final parts = iso.substring(0, 10).split('-');
    if (parts.length != 3) return iso;
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${parts[2]} ${m >= 1 && m <= 12 ? months[m] : parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: MongoDbService.getAdminAnalytics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.neonCyan));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_outlined,
                        color: Colors.white24, size: 48),
                    const SizedBox(height: 16),
                    Text('Failed to load analytics',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            final totalUsers = (data['totalUsers'] as num? ?? 0).toInt();
            final activeUsers = (data['activeUsers'] as num? ?? 0).toInt();
            final inactiveUsers = (totalUsers - activeUsers).clamp(0, totalUsers);
            final totalPoints = (data['totalPoints'] as num? ?? 0).toInt();

            final rawUserGrowth = data['userGrowth'] ??
                (data['charts'] is Map ? data['charts']['userGrowth'] : null);
            final List<dynamic> userGrowthData =
                rawUserGrowth is List ? rawUserGrowth : [];

            // Build cumulative growth spots
            final growthSpots = <FlSpot>[];
            int cumulative = 0;
            for (int i = 0; i < userGrowthData.length; i++) {
              final count = userGrowthData[i]['count'];
              cumulative += (count is num ? count : 0).toInt();
              growthSpots.add(FlSpot(i.toDouble(), cumulative.toDouble()));
            }
            if (growthSpots.isEmpty) growthSpots.add(const FlSpot(0, 0));

            int labelStep(int total) {
              if (total <= 4) return 1;
              if (total <= 8) return 2;
              return 3;
            }

            final step = labelStep(userGrowthData.length);

            return SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics Dashboard',
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 20),

                  // ── Stat Pills Row ────────────────────────────────────────
                  Row(
                    children: [
                      _statPill('Total Users', '$totalUsers',
                          AppColors.neonCyan, Icons.people_alt_rounded),
                      const SizedBox(width: 10),
                      _statPill('Active Now', '$activeUsers',
                          AppColors.neonGreen, Icons.circle),
                      const SizedBox(width: 10),
                      _statPill('Total Pts',
                          _fmtBigNum(totalPoints),
                          AppColors.neonYellow, Icons.stars_rounded),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── 1. DONUT CHART — User Activity Distribution ───────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          BorderRadius.circular(AppSizes.cardRadius),
                      border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.donut_large_rounded,
                                color: AppColors.neonCyan, size: 18),
                            const SizedBox(width: 8),
                            Text('User Activity Split',
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: totalUsers == 0
                              ? const Center(
                                  child: Text('No users yet',
                                      style: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 12)))
                              : Row(
                                  children: [
                                    // Pie chart — constrained width so segments never reach legend
                                    SizedBox(
                                      width: 170,
                                      child: PieChart(
                                        PieChartData(
                                          pieTouchData: PieTouchData(
                                            touchCallback: (event, resp) {
                                              setState(() {
                                                _touchedPieIndex = resp
                                                            ?.touchedSection
                                                            ?.touchedSectionIndex ??
                                                        -1;
                                              });
                                            },
                                          ),
                                          centerSpaceRadius: 54,
                                          sectionsSpace: 3,
                                          sections: [
                                            _pieSection(
                                              'Active',
                                              activeUsers.toDouble(),
                                              AppColors.neonGreen,
                                              0,
                                            ),
                                            _pieSection(
                                              'Inactive',
                                              inactiveUsers.toDouble(),
                                              Colors.white.withValues(
                                                  alpha: 0.12),
                                              1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16), // gap prevents bleed
                                    // Legend + stats — fixed space
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$totalUsers',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: -1,
                                                ),
                                              ),
                                              Text(
                                                'Total Users',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.35),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          _legendRow(AppColors.neonGreen,
                                              'Active', '$activeUsers'),
                                          const SizedBox(height: 10),
                                          _legendRow(
                                              Colors.white38,
                                              'Inactive',
                                              '$inactiveUsers'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 2. SMOOTH LINE CHART — Cumulative User Growth ─────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          BorderRadius.circular(AppSizes.cardRadius),
                      border: Border.all(
                          color: AppColors.neonPurple.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.show_chart_rounded,
                                color: AppColors.neonPurple, size: 18),
                            const SizedBox(width: 8),
                            Text('Cumulative User Growth',
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.neonPurple
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.neonPurple
                                        .withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                '$totalUsers total',
                                style: const TextStyle(
                                  color: AppColors.neonPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 190,
                          child: userGrowthData.isEmpty
                              ? const Center(
                                  child: Text('No growth data available',
                                      style: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 12)))
                              : LineChart(
                                  LineChartData(
                                    lineTouchData:
                                        const LineTouchData(enabled: false),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 1,
                                      getDrawingHorizontalLine: (_) => FlLine(
                                        color: Colors.white
                                            .withValues(alpha: 0.04),
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                            reservedSize: 26,
                                            interval: 1,
                                            getTitlesWidget: (v, meta) {
                                              final idx = v.toInt();
                                              // Skip first label (idx==0) to avoid overlap with Y-axis/dot
                                              if (idx == 0 || idx % step != 0) {
                                                return const SizedBox.shrink();
                                              }
                                            if (idx >= 0 &&
                                                idx < userGrowthData.length) {
                                              final dateStr =
                                                  userGrowthData[idx]['date'];
                                              if (dateStr is String) {
                                                return SideTitleWidget(
                                                  meta: meta,
                                                  space: 4,
                                                  child: Text(
                                                    _fmtLabel(dateStr),
                                                    style: const TextStyle(
                                                      color: Colors.white38,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 32,
                                          getTitlesWidget: (v, meta) {
                                            // Only show min and max
                                            if (v != meta.min && v != meta.max) {
                                              return const SizedBox.shrink();
                                            }
                                            return SideTitleWidget(
                                              meta: meta,
                                              space: 4,
                                              child: Text(
                                                '${v.toInt()}',
                                                style: const TextStyle(
                                                  color: Colors.white24,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: growthSpots,
                                        isCurved: true,
                                        curveSmoothness: 0.4,
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.neonPurple,
                                            AppColors.neonCyan,
                                          ],
                                        ),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.neonPurple
                                                  .withValues(alpha: 0.25),
                                              AppColors.neonPurple
                                                  .withValues(alpha: 0.0),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, bar, index) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: AppColors.neonCyan,
                                              strokeWidth: 2,
                                              strokeColor:
                                                  const Color(0xFF0F0F1A),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PieChartSectionData _pieSection(
      String title, double value, Color color, int index) {
    final isTouched = index == _touchedPieIndex;
    final radius = isTouched ? 52.0 : 44.0;
    return PieChartSectionData(
      value: value <= 0 ? 0.001 : value,
      color: color,
      radius: radius,
      showTitle: false,
      borderSide: isTouched
          ? BorderSide(color: color, width: 2)
          : const BorderSide(color: Colors.transparent),
    );
  }

  Widget _legendRow(Color color, String label, String count) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ),
        Text(count,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _statPill(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  String _fmtBigNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
