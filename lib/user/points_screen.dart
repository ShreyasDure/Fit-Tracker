import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../controllers/auth_controller.dart';

class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final points = user?.points ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Points'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total points header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.neonCyan.withValues(alpha: 0.15), AppColors.neonGreen.withValues(alpha: 0.08)]),
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.neonCyan, size: 36),
                  const SizedBox(height: AppSizes.sm),
                  Text('$points', style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppColors.neonCyan, fontWeight: FontWeight.w900)),
                  Text('Total Points', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSizes.sm),
                  Text(user?.levelName ?? 'Bronze', style: TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            // Points earning rates
            Text('Earning Rates', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            _RateCard(icon: Icons.directions_run_rounded, activity: 'Running', rate: '30 pts / km', color: AppColors.neonCyan),
            _RateCard(icon: Icons.directions_walk_rounded, activity: 'Walking', rate: '15 pts / km', color: AppColors.neonGreen),
            _RateCard(icon: Icons.directions_bike_rounded, activity: 'Cycling', rate: '20 pts / km', color: AppColors.neonPurple),
            _RateCard(icon: Icons.fitness_center_rounded, activity: 'Gym Session', rate: '50 pts / session', color: AppColors.neonOrange),
            _RateCard(icon: Icons.emoji_events_rounded, activity: 'Challenge', rate: '200-1000 pts', color: AppColors.neonPink),
            _RateCard(icon: Icons.local_fire_department, activity: 'Streak Bonus', rate: '10 pts × streak day', color: AppColors.neonYellow),
            const SizedBox(height: AppSizes.xl),
            // Points history
            Text('Recent Activity', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            _HistoryItem(activity: 'Morning Run', points: 90, time: 'Today, 7:30 AM', icon: Icons.directions_run_rounded, color: AppColors.neonCyan),
            _HistoryItem(activity: 'Gym Session', points: 50, time: 'Today, 6:00 PM', icon: Icons.fitness_center_rounded, color: AppColors.neonOrange),
            _HistoryItem(activity: '7-Day Streak', points: 70, time: 'Yesterday', icon: Icons.local_fire_department, color: AppColors.neonPink),
            _HistoryItem(activity: '5K Challenge', points: 200, time: '2 days ago', icon: Icons.emoji_events_rounded, color: AppColors.neonGreen),
            _HistoryItem(activity: 'Evening Walk', points: 30, time: '3 days ago', icon: Icons.directions_walk_rounded, color: AppColors.neonPurple),
          ],
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final IconData icon;
  final String activity, rate;
  final Color color;
  const _RateCard({required this.icon, required this.activity, required this.rate, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(child: Text(activity, style: Theme.of(context).textTheme.titleSmall)),
          Text(rate, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String activity, time;
  final int points;
  final IconData icon;
  final Color color;
  const _HistoryItem({required this.activity, required this.points, required this.time, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity, style: Theme.of(context).textTheme.titleSmall),
                Text(time, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Text('+$points', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(width: 2),
          const Text('pts', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}
