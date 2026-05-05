import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../widgets/stat_card.dart';
import '../models/user_model.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminControllerProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Panel', style: Theme.of(context).textTheme.displayMedium),
                        Text('Welcome, ${user?.name ?? 'Admin'}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(adminControllerProvider.notifier).refreshUsers(),
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.neonCyan),
                    tooltip: 'Refresh from database',
                  ),
                  IconButton(
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  ),
                ],
              ),
              if (admin.error != null) ...[
                const SizedBox(height: AppSizes.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.neonOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neonOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.neonOrange, size: 16),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(child: Text(admin.error!, style: const TextStyle(color: AppColors.neonOrange, fontSize: 11))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.lg),
              // 2x2 stat grid — clickable
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Users',
                              value: '${admin.totalUsers}',
                              icon: Icons.people_rounded,
                              iconColor: AppColors.neonCyan,
                              subtitle: '+5%',
                              onTap: () => _showUserList(context, 'All Users', admin.users),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: StatCard(
                              title: 'Active Users',
                              value: '${admin.activeUsers}',
                              icon: Icons.person_rounded,
                              iconColor: AppColors.neonGreen,
                              subtitle: '${admin.totalUsers > 0 ? ((admin.activeUsers / admin.totalUsers) * 100).toInt() : 0}%',
                              onTap: () => _showUserList(context, 'Active Users', admin.users.where((u) => u.isActive).toList()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Premium',
                              value: '${admin.premiumUsers}',
                              icon: Icons.workspace_premium_rounded,
                              iconColor: AppColors.neonPurple,
                              subtitle: 'Gold+',
                              gradient: LinearGradient(
                                colors: [AppColors.neonPurple.withValues(alpha: 0.12), AppColors.surface],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => _showUserList(context, 'Premium Users', admin.users.where((u) => u.levelName == 'Gold' || u.levelName == 'Platinum').toList()),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: StatCard(
                              title: 'Total Points',
                              value: _formatNumber(admin.totalPoints),
                              icon: Icons.star_rounded,
                              iconColor: AppColors.neonOrange,
                              gradient: LinearGradient(
                                colors: [AppColors.neonOrange.withValues(alpha: 0.08), AppColors.surface],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => _showLeaderboard(context, admin.users),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              // User Growth chart
              Expanded(
                flex: 3,
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
                      Text('User Growth', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSizes.md),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, _) {
                                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                    if (value % 1 != 0) {
                                      return const SizedBox.shrink();
                                    }
                                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                                      return Text(days[value.toInt()], style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w600));
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  reservedSize: 22,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [FlSpot(0, 2), FlSpot(1, 3), FlSpot(2, 3.5), FlSpot(3, 5), FlSpot(4, 4.8), FlSpot(5, 6), FlSpot(6, 8)],
                                isCurved: true,
                                gradient: AppColors.primaryGradient,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.neonCyan.withValues(alpha: 0.2), AppColors.neonCyan.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
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
              // Engagement chart
              Expanded(
                flex: 3,
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
                      Text('Engagement', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSizes.md),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                                      return Text(days[value.toInt()], style: const TextStyle(color: AppColors.neonOrange, fontSize: 10, fontWeight: FontWeight.w600));
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  reservedSize: 22,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (i) {
                              return BarChartGroupData(x: i, barRods: [
                                BarChartRodData(toY: [4, 6, 5, 8, 7, 9, 8][i].toDouble(), gradient: AppColors.primaryGradient, width: 16, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6))),
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
        ),
      ),
    );
  }

  void _showUserList(BuildContext context, String title, List<UserModel> users) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceLighter, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('${users.length}', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Expanded(
                child: users.isEmpty
                    ? const Center(child: Text('No users found', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.separated(
                        controller: scrollCtrl,
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                        itemBuilder: (_, i) {
                          final u = users[i];
                          return Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: u.isActive ? AppColors.neonCyan.withValues(alpha: 0.15) : AppColors.surfaceLighter,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(child: Text(u.name.substring(0, 1), style: TextStyle(color: u.isActive ? AppColors.neonCyan : AppColors.textMuted, fontWeight: FontWeight.w800))),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(u.name, style: Theme.of(context).textTheme.titleSmall),
                                      Text(u.email, style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${u.points} pts', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w700, fontSize: 12)),
                                    Text('Lv.${u.level}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaderboard(BuildContext context, List<UserModel> users) {
    final sorted = List<UserModel>.from(users)..sort((a, b) => b.points.compareTo(a.points));
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceLighter, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  const Icon(Icons.leaderboard_rounded, color: AppColors.neonOrange, size: 22),
                  const SizedBox(width: AppSizes.sm),
                  Text('Points Leaderboard', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (_, i) {
                    final u = sorted[i];
                    final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '#${i + 1}';
                    final isTop3 = i < 3;
                    return Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: isTop3 ? AppColors.neonOrange.withValues(alpha: 0.06) : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: isTop3 ? Border.all(color: AppColors.neonOrange.withValues(alpha: 0.2)) : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Text(medal, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center)),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w500)),
                                Text(u.levelName, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Text('${u.points}', style: TextStyle(color: isTop3 ? AppColors.neonOrange : AppColors.neonCyan, fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(width: 4),
                          const Text('pts', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
