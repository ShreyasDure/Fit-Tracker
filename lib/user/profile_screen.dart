import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../controllers/auth_controller.dart';
import '../widgets/compact_grid.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              // Avatar + Name
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.3), blurRadius: 20)],
                ),
                child: Center(
                  child: Text(user?.name.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 28)),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(user?.name ?? 'User', style: Theme.of(context).textTheme.titleLarge),
              Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSizes.xl),
              // Horizontal stat cards
              Row(
                children: [
                  Expanded(child: _MiniStat(label: 'Points', value: '${user?.points ?? 0}', icon: Icons.star_rounded, color: AppColors.neonCyan)),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(child: _MiniStat(label: 'Streak', value: '${user?.streak ?? 0}d', icon: Icons.local_fire_department, color: AppColors.neonOrange)),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(child: _MiniStat(label: 'Level', value: '${user?.level ?? 1}', icon: Icons.emoji_events_rounded, color: AppColors.neonPurple)),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              // Progress to next level
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress to ${_nextLevel(user?.levelName)}', style: Theme.of(context).textTheme.titleSmall),
                        Text('${((user?.levelProgress ?? 0) * 100).toInt()}%', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.neonCyan)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    GradientProgressBar(value: user?.levelProgress ?? 0),
                    const SizedBox(height: AppSizes.xs),
                    Text('${user?.pointsToNextLevel ?? 0} points to go', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              // Badges
              const SectionHeader(title: 'Badges', icon: Icons.military_tech_rounded),
              const SizedBox(height: AppSizes.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Badge(icon: Icons.directions_run_rounded, label: '5K', earned: true, color: AppColors.neonCyan),
                  _Badge(icon: Icons.local_fire_department, label: '7-Day', earned: true, color: AppColors.neonOrange),
                  _Badge(icon: Icons.fitness_center_rounded, label: '100 Wkt', earned: false, color: AppColors.neonPurple),
                  _Badge(icon: Icons.star_rounded, label: '1K Pts', earned: true, color: AppColors.neonGreen),
                  _Badge(icon: Icons.emoji_events_rounded, label: 'Gold', earned: false, color: AppColors.neonYellow),
                ],
              ),
              const Spacer(),
              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
          ),
        ),
      ),
    );
  }

  String _nextLevel(String? current) {
    if (current == 'Gold') return 'Max';
    if (current == 'Silver') return 'Gold';
    return 'Silver';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSizes.xs),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool earned;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.earned, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: earned ? color.withValues(alpha: 0.15) : AppColors.surfaceLighter,
            borderRadius: BorderRadius.circular(14),
            border: earned ? Border.all(color: color.withValues(alpha: 0.3)) : null,
          ),
          child: Icon(icon, color: earned ? color : AppColors.textMuted, size: 22),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: earned ? color : AppColors.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
