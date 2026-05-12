import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../controllers/auth_controller.dart';
import '../services/mongodb_service.dart';

// Provider for real workout history
final workoutHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await MongoDbService.getWorkouts();
  } catch (_) {
    return [];
  }
});

class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final points = user?.points ?? 0;
    final workoutsAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ─── HEADER ───
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonCyan.withOpacity(0.15),
                    AppColors.neonGreen.withOpacity(0.08),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(
                  color: AppColors.neonCyan.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.neonCyan, size: 36),
                  SizedBox(height: AppSizes.sm),
                  Text(
                    '$points',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(
                          color: AppColors.neonCyan,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text('Total Points'),
                  SizedBox(height: AppSizes.sm),
                  Text(
                    user?.levelName ?? 'Bronze',
                    style: TextStyle(
                      color: _levelColor(user?.levelName ?? 'Bronze'),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSizes.xl),

            /// ─── ACTIVITY LIST ───
            Text('Recent Activity',
                style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: AppSizes.sm),

            workoutsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => _noData(context),
              data: (workouts) {
                if (workouts.isEmpty) return _noData(context);

                return Column(
                  children: workouts.map((w) {
                    final type = w['type'] ?? 'Workout';
                    final pts = _calcPoints(
                      type,
                      (w['distance'] ?? 0).toDouble(),
                      w['duration'] ?? 0,
                    );

                    return _ActivityCard(
                      title: type,
                      points: pts,
                      icon: _workoutIcon(type),
                      color: _workoutColor(type),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ─── NO DATA UI ───
  Widget _noData(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.xl),
      child: Column(
        children: [
          Icon(Icons.info, size: 30),
          SizedBox(height: AppSizes.sm),
          Text('No activity yet'),
        ],
      ),
    );
  }

  /// ─── HELPERS ───

  int _calcPoints(String type, double dist, int dur) {
    final t = type.toLowerCase();
    if (t.contains('run')) return (dist * 30).round();
    if (t.contains('walk')) return (dist * 15).round();
    if (t.contains('bike')) return (dist * 20).round();
    if (t.contains('gym')) return 50;
    return 10;
  }

  IconData _workoutIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('run')) return Icons.directions_run;
    if (t.contains('walk')) return Icons.directions_walk;
    if (t.contains('bike')) return Icons.directions_bike;
    if (t.contains('gym')) return Icons.fitness_center;
    return Icons.sports;
  }

  Color _workoutColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('run')) return AppColors.neonCyan;
    if (t.contains('walk')) return AppColors.neonGreen;
    if (t.contains('bike')) return AppColors.neonPurple;
    if (t.contains('gym')) return AppColors.neonOrange;
    return AppColors.neonPink;
  }

  Color _levelColor(String level) {
    if (level == 'Gold') return const Color(0xFFFFD700);
    if (level == 'Silver') return const Color(0xFFC0C0C0);
    return const Color(0xFFCD7F32);
  }
}

/// ─── ACTIVITY CARD ───

class _ActivityCard extends StatelessWidget {
  final String title;
  final int points;
  final IconData icon;
  final Color color;

  const _ActivityCard({
    required this.title,
    required this.points,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.sm),
      padding: EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: AppSizes.md),
          Expanded(child: Text(title)),
          Text("+$points pts",
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}
