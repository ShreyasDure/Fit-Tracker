import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/mongodb_service.dart';
import '../controllers/auth_controller.dart';

// Real social feed data model
class SocialPost {
  final String id;
  final String userName;
  final String workoutType;
  final int duration;
  final double distance;
  final int points;
  int likes;
  bool isLiked;
  final DateTime createdAt;

  SocialPost({
    required this.id,
    required this.userName,
    required this.workoutType,
    required this.duration,
    this.distance = 0,
    required this.points,
    this.likes = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json, String currentUserId) {
    final likedBy = (json['likedBy'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return SocialPost(
      id: json['id'] ?? '',
      userName: json['name'] ?? 'User',
      workoutType: json['activityType'] ?? 'Workout',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      isLiked: likedBy.contains(currentUserId),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String get formattedDuration {
    if (duration >= 3600) {
      final h = duration ~/ 3600;
      final m = (duration % 3600) ~/ 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${duration ~/ 60} min';
  }
}

final socialFeedProvider = StateNotifierProvider<SocialFeedNotifier, AsyncValue<List<SocialPost>>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  return SocialFeedNotifier(user?.id ?? '');
});

class SocialFeedNotifier extends StateNotifier<AsyncValue<List<SocialPost>>> {
  final String currentUserId;

  SocialFeedNotifier(this.currentUserId) : super(const AsyncValue.loading()) {
    loadFeed();
  }

  Future<void> loadFeed() async {
    try {
      state = const AsyncValue.loading();
      final data = await MongoDbService.getSocialFeed();
      final posts = data.map((json) => SocialPost.fromJson(json, currentUserId)).toList();
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleLike(String postId) async {
    if (state.value == null) return;
    
    // Optimistic UI update
    final oldState = state.value!;
    final index = oldState.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = oldState[index];
    final wasLiked = post.isLiked;
    
    final updatedPost = SocialPost(
      id: post.id, userName: post.userName, workoutType: post.workoutType,
      duration: post.duration, distance: post.distance, points: post.points,
      createdAt: post.createdAt,
      isLiked: !wasLiked,
      likes: wasLiked ? post.likes - 1 : post.likes + 1,
    );

    final newState = List<SocialPost>.from(oldState);
    newState[index] = updatedPost;
    state = AsyncValue.data(newState);

    // Network request
    try {
      final res = await MongoDbService.toggleSocialLike(postId);
      // Confirm with server response
      final confirmedState = List<SocialPost>.from(state.value!);
      final confirmedIndex = confirmedState.indexWhere((p) => p.id == postId);
      if (confirmedIndex != -1) {
        final currentPost = confirmedState[confirmedIndex];
        confirmedState[confirmedIndex] = SocialPost(
          id: currentPost.id, userName: currentPost.userName, workoutType: currentPost.workoutType,
          duration: currentPost.duration, distance: currentPost.distance, points: currentPost.points,
          createdAt: currentPost.createdAt,
          isLiked: res['liked'],
          likes: res['likes'],
        );
        state = AsyncValue.data(confirmedState);
      }
    } catch (e) {
      // Revert on failure
      state = AsyncValue.data(oldState);
    }
  }
}

class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(socialFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Feed'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: feedState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load feed', style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => ref.read(socialFeedProvider.notifier).loadFeed(),
                child: const Text('Retry', style: TextStyle(color: AppColors.neonCyan)),
              ),
            ],
          ),
        ),
        data: (feed) => RefreshIndicator(
          onRefresh: () => ref.read(socialFeedProvider.notifier).loadFeed(),
          color: AppColors.neonCyan,
          backgroundColor: Theme.of(context).cardColor,
          child: Column(
            children: [
              // Friends count banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSizes.md),
                margin: EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 0),
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
                    Text('${feed.length} activities', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              // Feed
              Expanded(
                child: feed.isEmpty
                  ? Center(child: Text('No activities yet. Go do a workout!', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!)))
                  : ListView.separated(
                  padding: EdgeInsets.all(AppSizes.lg),
                  itemCount: feed.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (_, i) {
                    final post = feed[i];
                    final String typeStr = post.workoutType.toLowerCase();
                    final typeIcon = typeStr.contains('run') ? Icons.directions_run_rounded 
                                   : typeStr.contains('walk') ? Icons.directions_walk_rounded 
                                   : typeStr.contains('bike') ? Icons.directions_bike_rounded 
                                   : Icons.fitness_center_rounded;
                                   
                    final typeColor = typeStr.contains('run') ? AppColors.neonCyan 
                                    : typeStr.contains('walk') ? AppColors.neonGreen 
                                    : typeStr.contains('bike') ? AppColors.neonPurple 
                                    : AppColors.neonOrange;

                    return Container(
                      padding: EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                        border: Border.all(color: typeColor.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                                child: Center(child: Text(post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U', style: TextStyle(color: typeColor, fontWeight: FontWeight.w800))),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post.userName, style: Theme.of(context).textTheme.titleSmall),
                                    Text(post.timeAgo, style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 10)),
                                  ],
                                ),
                              ),
                              Icon(typeIcon, color: typeColor, size: 18),
                            ],
                          ),
                          const SizedBox(height: AppSizes.sm),
                          // Workout details
                          Container(
                            padding: EdgeInsets.all(AppSizes.sm),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _FeedStat(label: 'Type', value: post.workoutType, color: typeColor),
                                _FeedStat(label: 'Duration', value: post.formattedDuration, color: AppColors.neonCyan),
                                if (post.distance > 0) _FeedStat(label: 'Distance', value: '${post.distance} km', color: AppColors.neonGreen),
                                _FeedStat(label: 'Points', value: '+${post.points}', color: AppColors.neonOrange),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          // Actions
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => ref.read(socialFeedProvider.notifier).toggleLike(post.id),
                                child: Row(
                                  children: [
                                    Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, color: post.isLiked ? AppColors.neonPink : Theme.of(context).textTheme.bodySmall!.color!, size: 18),
                                    const SizedBox(width: 4),
                                    Text('${post.likes}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSizes.lg),
                              Icon(Icons.chat_bubble_outline, color: Theme.of(context).textTheme.bodySmall!.color!, size: 16),
                              const SizedBox(width: 4),
                              Text('Comment', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 12)),
                              const Spacer(),
                              Icon(Icons.share_outlined, color: Theme.of(context).textTheme.bodySmall!.color!, size: 16),
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
}

class _FeedStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _FeedStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 9)),
    ]);
  }
}
