import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../controllers/auth_controller.dart';
import '../services/mongodb_service.dart';

// ─── Provider: fetches live level thresholds from MongoDB Settings ───

/// Holds the live silverMinPoints and goldMinPoints from MongoDB Settings.
/// Used across all user-facing screens to show dynamic level thresholds.
final levelSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return MongoDbService.getLevelSettings();
});

/// Convenience provider for the workout/activity history list
final workoutHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await MongoDbService.getUserActivities();
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
    final levelSettingsAsync = ref.watch(levelSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        title: const Text('Points & Level'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.lg),
        child: levelSettingsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            ),
          ),
          error: (_, __) => _buildContent(context, user, points, workoutsAsync, 2000, 5000),
          data: (settings) {
            final silverMin = (settings['silverMinPoints'] as num? ?? 2000).toInt();
            final goldMin = (settings['goldMinPoints'] as num? ?? 5000).toInt();
            return _buildContent(context, user, points, workoutsAsync, silverMin, goldMin);
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic user,
    int points,
    AsyncValue<List<Map<String, dynamic>>> workoutsAsync,
    int silverMin,
    int goldMin,
  ) {
    final levelName = user?.levelNameWith(silverMin, goldMin) ?? 'Bronze';
    final levelProgress = user?.levelProgressWith(silverMin, goldMin) ?? 0.0;
    final pointsToNext = user?.pointsToNextLevelWith(silverMin, goldMin) ?? silverMin;
    final levelColor = _levelColor(levelName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ─── HEADER: Points + Level ───
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSizes.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                levelColor.withValues(alpha: 0.15),
                AppColors.neonCyan.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(color: levelColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: levelColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_levelIcon(levelName), color: levelColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      levelName.toUpperCase(),
                      style: TextStyle(
                        color: levelColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Points
              Icon(Icons.star_rounded, color: levelColor, size: 36),
              SizedBox(height: AppSizes.sm),
              Text(
                '$points',
                style: TextStyle(
                  color: levelColor,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
              Text(
                'Total Points',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
              const SizedBox(height: 20),
              // Progress to next level
              if (levelName != 'Gold') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      levelName,
                      style: TextStyle(color: levelColor, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      levelName == 'Bronze' ? 'Silver' : 'Gold',
                      style: TextStyle(
                        color: levelName == 'Bronze'
                            ? const Color(0xFFC0C0C0)
                            : const Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: levelProgress.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [levelColor, AppColors.neonCyan]),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: levelColor.withValues(alpha: 0.5), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$pointsToNext pts to ${levelName == 'Bronze' ? 'Silver ($silverMin pts required)' : 'Gold ($goldMin pts required)'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '🏆 Maximum Level Reached!',
                    style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: AppSizes.lg),

        /// ─── LEVEL THRESHOLDS INFO ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEVEL THRESHOLDS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTierChip('Bronze', '0+', const Color(0xFFCD7F32)),
                  const SizedBox(width: 8),
                  _buildTierChip('Silver', '$silverMin+', const Color(0xFFC0C0C0)),
                  const SizedBox(width: 8),
                  _buildTierChip('Gold', '$goldMin+', const Color(0xFFFFD700)),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: AppSizes.xl),

        /// ─── ACTIVITY LIST ───
        Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        SizedBox(height: AppSizes.sm),

        workoutsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            ),
          ),
          error: (_, __) => _noData(context),
          data: (activities) {
            if (activities.isEmpty) return _noData(context);
            return Column(
              children: activities.map((act) {
                final type = act['type'] ?? '';
                final title = act['title'] ?? 'Activity';
                final pts = act['points'] ?? 0;
                return _ActivityCard(
                  title: title,
                  points: pts,
                  icon: _activityIcon(type),
                  color: _activityColor(type),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTierChip(String tier, String threshold, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(tier, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(threshold, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _noData(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.xl),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 30, color: Colors.white24),
          SizedBox(height: AppSizes.sm),
          Text('No activity yet', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  IconData _levelIcon(String level) {
    if (level == 'Gold') return Icons.emoji_events_rounded;
    if (level == 'Silver') return Icons.military_tech_rounded;
    return Icons.shield_rounded;
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'workout_completed': return Icons.directions_run_rounded;
      case 'achievement_unlocked': return Icons.emoji_events_rounded;
      case 'points_earned': return Icons.star_rounded;
      case 'diet_plan_created': return Icons.restaurant_rounded;
      case 'challenge_status': return Icons.flag_rounded;
      case 'ai_recommendation': return Icons.insights_rounded;
      case 'ai_chat': return Icons.question_answer_rounded;
      default: return Icons.offline_bolt_rounded;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'workout_completed': return AppColors.neonCyan;
      case 'achievement_unlocked': return AppColors.neonPurple;
      case 'points_earned': return AppColors.neonYellow;
      case 'diet_plan_created': return AppColors.neonOrange;
      case 'challenge_status': return AppColors.neonPink;
      case 'ai_recommendation': return AppColors.neonGreen;
      case 'ai_chat': return Colors.tealAccent;
      default: return Colors.white70;
    }
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
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          if (points > 0)
            Text(
              '+$points pts',
              style: const TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w900, fontSize: 12),
            )
          else
            const Text('Synced', style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }
}
