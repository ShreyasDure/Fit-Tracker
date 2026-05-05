import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../core/constants.dart';
import '../controllers/auth_controller.dart';
import '../services/health_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/compact_grid.dart';
import '../services/notification_service.dart';
import 'notification_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final health = ref.watch(healthControllerProvider);
    final notifState = ref.watch(notificationControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${user?.name.split(' ').first ?? 'User'}! 👋', style: Theme.of(context).textTheme.titleMedium),
                        Text('Let\'s crush your goals today', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs),
                    decoration: BoxDecoration(
                      color: AppColors.neonOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, color: AppColors.neonOrange, size: 16),
                        const SizedBox(width: 4),
                        Text('${user?.streak ?? 0}', style: const TextStyle(color: AppColors.neonOrange, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  // Notification bell
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPanel())),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSizes.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSizes.sm),
                          ),
                          child: const Icon(Icons.notifications_rounded, color: AppColors.textSecondary, size: 20),
                        ),
                        if (notifState.unreadCount > 0)
                          Positioned(
                            right: 0, top: 0,
                            child: Container(
                              width: 16, height: 16,
                              decoration: const BoxDecoration(color: AppColors.neonPink, shape: BoxShape.circle),
                              child: Center(child: Text('${notifState.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              // Circular Progress + Points — LIVE DATA
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Expanded(child: _buildStepsCard(context, size, health)),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(child: _buildPointsLevelColumn(context, user)),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              const SectionHeader(title: 'Today\'s Stats', icon: Icons.bar_chart_rounded),
              // Live stat cards
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Calories',
                        value: '${health.calories}',
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.neonOrange,
                        subtitle: 'kcal',
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: StatCard(
                        title: 'Active Min',
                        value: '${health.activeMinutes}',
                        icon: Icons.timer_rounded,
                        iconColor: AppColors.neonGreen,
                        subtitle: '${((health.activeMinutes / 60) * 100).toInt()}%',
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: StatCard(
                        title: 'Heart Rate',
                        value: '${health.heartRate}',
                        icon: Icons.favorite_rounded,
                        iconColor: AppColors.neonPink,
                        subtitle: 'bpm',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepsCard(BuildContext context, Size size, HealthData health) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size.width * 0.28, height: size.width * 0.28,
            child: CustomPaint(
              painter: _CircularProgressPainter(progress: health.stepsProgress, strokeWidth: 10),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatSteps(health.steps), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text('steps', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text('${health.stepsPercent}% of daily goal', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.neonGreen)),
        ],
      ),
    );
  }

  Widget _buildPointsLevelColumn(BuildContext context, user) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.neonCyan.withValues(alpha: 0.15), AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  const Icon(Icons.star_rounded, color: AppColors.neonCyan, size: 18),
                  const SizedBox(width: 4),
                  Text('${user?.points ?? 0}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.neonCyan)),
                ]),
                const SizedBox(height: 2),
                Text('Points', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSizes.sm),
                GradientProgressBar(value: user?.levelProgress ?? 0, height: 6),
                const SizedBox(height: 4),
                Text('${user?.levelName ?? 'Bronze'} → next', style: Theme.of(context).textTheme.labelSmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  const Icon(Icons.emoji_events_rounded, color: AppColors.neonPurple, size: 18),
                  const SizedBox(width: 4),
                  Text('Lv. ${user?.level ?? 1}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.neonPurple)),
                ]),
                const SizedBox(height: 2),
                Text(user?.levelName ?? 'Bronze', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return '$steps';
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  _CircularProgressPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final bgPaint = Paint()..color = AppColors.surfaceLighter..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..shader = const SweepGradient(startAngle: 0, endAngle: 2 * pi, colors: [AppColors.neonCyan, AppColors.neonGreen, AppColors.neonCyan]).createShader(rect)
      ..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) => old.progress != progress;
}
