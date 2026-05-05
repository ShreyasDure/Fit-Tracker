import 'package:flutter/material.dart';
import '../core/constants.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.neonPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.sm),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.neonPurple, size: 22),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Insights', style: Theme.of(context).textTheme.displayMedium),
                        Text('Personalized for you', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _InsightCard(
                      icon: Icons.flag_rounded,
                      title: 'Goal Suggestion',
                      subtitle: 'Based on your recent activity',
                      description: 'Increase your daily step target to 10,000. You\'ve been averaging 7,500 steps this week — you\'re ready for more!',
                      color: AppColors.neonCyan,
                      actionLabel: 'Update Goal',
                    ),
                    const SizedBox(height: AppSizes.md),
                    _InsightCard(
                      icon: Icons.trending_up_rounded,
                      title: 'Intensity Advice',
                      subtitle: 'Optimize your workouts',
                      description: 'Try adding 2 HIIT sessions per week. Your cardiovascular endurance has improved 15% this month.',
                      color: AppColors.neonGreen,
                      actionLabel: 'See Plan',
                    ),
                    const SizedBox(height: AppSizes.md),
                    _InsightCard(
                      icon: Icons.bedtime_rounded,
                      title: 'Sleep Insight',
                      subtitle: 'Rest & recovery',
                      description: 'Your average sleep is 6.5 hours. Aim for 7-8 hours to improve muscle recovery and performance by up to 20%.',
                      color: AppColors.neonPurple,
                      actionLabel: 'Sleep Tips',
                    ),
                    const SizedBox(height: AppSizes.md),
                    _InsightCard(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Streak Reminder',
                      subtitle: 'Keep your momentum!',
                      description: 'You\'re on a 12-day streak! Complete today\'s workout to earn a 50-point streak bonus.',
                      color: AppColors.neonOrange,
                      actionLabel: 'Start Workout',
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

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final String actionLabel;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 16, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppSizes.sm)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSizes.md),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
              child: Text(actionLabel, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
