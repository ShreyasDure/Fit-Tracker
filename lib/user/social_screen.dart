import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';

// Demo social feed data
class SocialPost {
  final String userName;
  final String workoutType;
  final String duration;
  final String distance;
  final int points;
  final int likes;
  final String timeAgo;
  bool isLiked;

  SocialPost({required this.userName, required this.workoutType, required this.duration, this.distance = '', required this.points, this.likes = 0, required this.timeAgo, this.isLiked = false});
}

final socialFeedProvider = StateNotifierProvider<SocialFeedNotifier, List<SocialPost>>((ref) => SocialFeedNotifier());

class SocialFeedNotifier extends StateNotifier<List<SocialPost>> {
  SocialFeedNotifier() : super([
    SocialPost(userName: 'Alex Runner', workoutType: 'Run', duration: '32 min', distance: '5.2 km', points: 150, likes: 12, timeAgo: '15m ago'),
    SocialPost(userName: 'Maya Fitness', workoutType: 'Gym', duration: '45 min', points: 200, likes: 8, timeAgo: '1h ago'),
    SocialPost(userName: 'Jake Strong', workoutType: 'Bike', duration: '1h 10m', distance: '22 km', points: 300, likes: 15, timeAgo: '2h ago'),
    SocialPost(userName: 'Sarah Walk', workoutType: 'Walk', duration: '25 min', distance: '2.1 km', points: 80, likes: 5, timeAgo: '3h ago'),
    SocialPost(userName: 'Chris Power', workoutType: 'Gym', duration: '55 min', points: 250, likes: 20, timeAgo: '4h ago'),
    SocialPost(userName: 'Emma Cycle', workoutType: 'Bike', duration: '40 min', distance: '15 km', points: 220, likes: 9, timeAgo: '5h ago'),
  ]);

  void toggleLike(int index) {
    final post = state[index];
    post.isLiked = !post.isLiked;
    post.isLiked ? post.likes + 1 : post.likes - 1;
    state = [...state];
  }
}

class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(socialFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // Friends count banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            margin: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.neonPurple.withValues(alpha: 0.12), AppColors.neonCyan.withValues(alpha: 0.06)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_rounded, color: AppColors.neonPurple, size: 20),
                const SizedBox(width: AppSizes.sm),
                Text('Activity Feed', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text('${feed.length} activities', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          // Feed
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.lg),
              itemCount: feed.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (_, i) {
                final post = feed[i];
                final typeIcon = {
                  'Run': Icons.directions_run_rounded,
                  'Walk': Icons.directions_walk_rounded,
                  'Bike': Icons.directions_bike_rounded,
                  'Gym': Icons.fitness_center_rounded,
                }[post.workoutType] ?? Icons.fitness_center_rounded;
                final typeColor = {
                  'Run': AppColors.neonCyan,
                  'Walk': AppColors.neonGreen,
                  'Bike': AppColors.neonPurple,
                  'Gym': AppColors.neonOrange,
                }[post.workoutType] ?? AppColors.neonCyan;

                return Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User header
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(post.userName[0], style: TextStyle(color: typeColor, fontWeight: FontWeight.w800))),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.userName, style: Theme.of(context).textTheme.titleSmall),
                                Text(post.timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              ],
                            ),
                          ),
                          Icon(typeIcon, color: typeColor, size: 18),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      // Workout details
                      Container(
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _FeedStat(label: 'Type', value: post.workoutType, color: typeColor),
                            _FeedStat(label: 'Duration', value: post.duration, color: AppColors.neonCyan),
                            if (post.distance.isNotEmpty) _FeedStat(label: 'Distance', value: post.distance, color: AppColors.neonGreen),
                            _FeedStat(label: 'Points', value: '+${post.points}', color: AppColors.neonOrange),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      // Actions
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => ref.read(socialFeedProvider.notifier).toggleLike(i),
                            child: Row(
                              children: [
                                Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, color: post.isLiked ? AppColors.neonPink : AppColors.textMuted, size: 18),
                                const SizedBox(width: 4),
                                Text('${post.likes}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.lg),
                          const Icon(Icons.chat_bubble_outline, color: AppColors.textMuted, size: 16),
                          const SizedBox(width: 4),
                          const Text('Comment', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          const Spacer(),
                          const Icon(Icons.share_outlined, color: AppColors.textMuted, size: 16),
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
    );
  }
}

class _FeedStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _FeedStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
    ]);
  }
}
