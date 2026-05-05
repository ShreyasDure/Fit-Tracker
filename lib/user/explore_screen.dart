import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'exercise_library_screen.dart';
import 'nutrition_screen.dart';
import 'challenges_screen.dart';
import 'social_screen.dart';
import 'points_screen.dart';
import 'settings_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explore', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: AppSizes.sm),
              Text('Discover new features', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSizes.xl),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSizes.md,
                  crossAxisSpacing: AppSizes.md,
                  childAspectRatio: 1.5,
                  children: [
                    _ExploreCard(
                      icon: Icons.fitness_center_rounded,
                      title: 'Workouts',
                      subtitle: 'Exercise Library',
                      color: AppColors.neonCyan,
                      badge: 'API',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen())),
                    ),
                    _ExploreCard(
                      icon: Icons.restaurant_rounded,
                      title: 'Nutrition',
                      subtitle: 'Food Lookup',
                      color: AppColors.neonGreen,
                      badge: 'API',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionScreen())),
                    ),
                    _ExploreCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Challenges',
                      subtitle: '3 active',
                      color: AppColors.neonOrange,
                      badge: 'Hot',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengesScreen())),
                    ),
                    _ExploreCard(
                      icon: Icons.people_rounded,
                      title: 'Social',
                      subtitle: 'Activity Feed',
                      color: AppColors.neonPurple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialScreen())),
                    ),
                    _ExploreCard(
                      icon: Icons.star_rounded,
                      title: 'Points',
                      subtitle: 'Earn & Track',
                      color: AppColors.neonYellow,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen())),
                    ),
                    _ExploreCard(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      subtitle: 'Preferences',
                      color: AppColors.textMuted,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
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
}

class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;

  const _ExploreCard({required this.icon, required this.title, required this.subtitle, required this.color, this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppSizes.xs)),
                    child: Text(badge!, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
