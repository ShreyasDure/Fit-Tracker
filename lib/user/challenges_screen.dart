import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/mongodb_service.dart';
import '../services/health_service.dart';
import '../controllers/auth_controller.dart';

// User Challenge Model
class UserChallengeItem {
  final String id;
  final String? challengeId;
  final String title;
  final String difficulty;
  final String type;
  final int target;
  final int reward;
  final double progress;
  final bool completed;

  UserChallengeItem({
    required this.id, required this.challengeId, required this.title, required this.difficulty, required this.type,
    required this.target, required this.reward, required this.progress, required this.completed,
  });

  factory UserChallengeItem.fromJson(Map<String, dynamic> json) {
    return UserChallengeItem(
      id: json['_id'],
      challengeId: json['challengeId']?.toString(),
      title: json['title'],
      difficulty: (json['difficulty'] ?? 'moderate').toString(),
      type: (json['type'] ?? 'steps').toString(),
      target: (json['target'] as num?)?.toInt() ?? 1,
      reward: (json['reward'] as num?)?.toInt() ?? 100,
      progress: (json['progress'] ?? 0).toDouble(),
      completed: json['completed'] ?? false,
    );
  }
}

final userChallengesProvider = StateNotifierProvider<UserChallengesNotifier, AsyncValue<List<UserChallengeItem>>>((ref) => UserChallengesNotifier(ref));

final globalChallengesProvider = FutureProvider<List<dynamic>>((ref) async {
  return await MongoDbService.getChallenges(activeOnly: true);
});

class UserChallengesNotifier extends StateNotifier<AsyncValue<List<UserChallengeItem>>> {
  final Ref ref;
  UserChallengesNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadChallenges();
  }

  Future<void> loadChallenges() async {
    try {
      state = const AsyncValue.loading();
      final data = await MongoDbService.getUserChallenges();
      state = AsyncValue.data(data.map((json) => UserChallengeItem.fromJson(json)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> skipChallenge(String id) async {
    if (state.value == null) return;
    try {
      await MongoDbService.skipUserChallenge(id);
      state = AsyncValue.data(state.value!.where((c) => c.id != id).toList());
    } catch (e) {
      // Show error
    }
  }

  Future<void> generateAiChallenge(String difficulty) async {
    try {
      final health = ref.read(healthControllerProvider);
      // We assume for now AI challenges are step-based by default
      final newChallenge = await MongoDbService.generateAiChallenge(difficulty, currentProgress: health.steps.toDouble());
      if (state.value != null) {
        state = AsyncValue.data([...state.value!, UserChallengeItem.fromJson(newChallenge)]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinGlobalChallenge(String challengeId, String type) async {
    try {
      final health = ref.read(healthControllerProvider);
      double current = 0;
      if (type == 'calories') current = health.calories.toDouble();
      else if (type == 'distance') current = health.distance;
      else current = health.steps.toDouble();

      final newChallenge = await MongoDbService.joinChallenge(challengeId, currentProgress: current);
      if (state.value != null) {
        state = AsyncValue.data([...state.value!, UserChallengeItem.fromJson(newChallenge)]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProgress(String id, double progress) async {
    if (state.value == null) return;
    try {
      final updated = await MongoDbService.updateUserChallengeProgress(id, progress);
      final updatedItem = UserChallengeItem.fromJson(updated);
      final newState = state.value!.map((c) => c.id == id ? updatedItem : c).toList();
      state = AsyncValue.data(newState);
      
      if (updatedItem.completed) {
        final authCtrl = ref.read(authControllerProvider.notifier);
        final user = ref.read(authControllerProvider).user;
        if (user != null) {
          authCtrl.updateUser(user.copyWith(points: user.points + updatedItem.reward));
        }
      }
    } catch (e) {
      // Keep UI stable if progress sync fails temporarily.
    }
  }
}

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesState = ref.watch(userChallengesProvider);
    final health = ref.watch(healthControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: challengesState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, _) => Center(child: Text('Failed to load: $e', style: TextStyle(color: AppColors.error))),
        data: (challenges) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GlobalChallengesList(),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, 0),
                child: Text('My Active Challenges', style: Theme.of(context).textTheme.titleMedium),
              ),
              Expanded(
                child: challenges.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events_outlined, size: 64, color: Theme.of(context).textTheme.bodySmall!.color!.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text('No active challenges', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!)),
                            const SizedBox(height: 8),
                            Text('Generate an AI challenge below to get started!', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(AppSizes.lg),
                        itemCount: challenges.length,
                        itemBuilder: (context, index) {
                          final c = challenges[index];
                          
                          final metricProgress = _metricProgress(c.type, health);
                          if (!c.completed && metricProgress > c.progress) {
                            Future.microtask(
                              () => ref.read(userChallengesProvider.notifier).updateProgress(c.id, metricProgress),
                            );
                          }
                          
                          final progressPercent = (c.progress / c.target).clamp(0.0, 1.0);
                          final color = c.difficulty == 'easy' ? AppColors.neonGreen 
                                      : c.difficulty == 'moderate' ? AppColors.neonOrange 
                                      : AppColors.neonPink;

                          return Container(
                            margin: EdgeInsets.only(bottom: AppSizes.md),
                            padding: EdgeInsets.all(AppSizes.md),
                            constraints: const BoxConstraints(minHeight: 120),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                              border: Border.all(color: color.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.stars_rounded, color: color, size: 24),
                                    const SizedBox(width: AppSizes.md),
                                    Flexible(
                                      child: Text(
                                        c.title, 
                                        style: Theme.of(context).textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text('${c.reward} pts', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.lg),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progressPercent,
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation(color),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.sm),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${c.progress.toStringAsFixed(c.type == 'distance' ? 1 : 0)} / ${c.target} ${_unitLabel(c.type)}',
                                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 12),
                                    ),
                                    if (c.completed)
                                      const Text('✅ Completed', style: TextStyle(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.w700))
                                    else
                                      GestureDetector(
                                        onTap: () => ref.read(userChallengesProvider.notifier).skipChallenge(c.id),
                                        child: const Text('Skip', style: TextStyle(color: AppColors.error, fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              
              // Bottom Sheet Generator Action
              Container(
                padding: EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const Text('✨ Ask AI for a new challenge', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _DiffButton(label: 'Easy', color: AppColors.neonGreen, ref: ref),
                        _DiffButton(label: 'Moderate', color: AppColors.neonOrange, ref: ref),
                        _DiffButton(label: 'Hard', color: AppColors.neonPink, ref: ref),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DiffButton extends StatefulWidget {
  final String label;
  final Color color;
  final WidgetRef ref;

  const _DiffButton({required this.label, required this.color, required this.ref});

  @override
  State<_DiffButton> createState() => _DiffButtonState();
}

class _DiffButtonState extends State<_DiffButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: widget.color, strokeWidth: 2))
        : OutlinedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await widget.ref.read(userChallengesProvider.notifier).generateAiChallenge(widget.label.toLowerCase());
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✨ ${widget.label} challenge generated!'), backgroundColor: widget.color));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.color,
              side: BorderSide(color: widget.color.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(widget.label),
          );
  }
}

class _GlobalChallengesList extends ConsumerWidget {
  const _GlobalChallengesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalAsync = ref.watch(globalChallengesProvider);
    final joinedChallenges = ref.watch(userChallengesProvider).value ?? const <UserChallengeItem>[];
    final joinedIds = joinedChallenges.map((c) => c.challengeId).whereType<String>().toSet();
    return globalAsync.when(
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppColors.neonPurple))),
      error: (e, st) => const SizedBox.shrink(),
      data: (globals) {
        if (globals.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.sm),
              child: Text('Community Challenges', style: Theme.of(context).textTheme.titleMedium),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                itemCount: globals.length,
                itemBuilder: (context, i) {
                  final gc = globals[i];
                  final gcId = gc['_id']?.toString() ?? '';
                  final isJoined = joinedIds.contains(gcId);
                  return Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: AppSizes.md),
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                      border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gc['title'] ?? 'Challenge', style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Target: ${gc['target']} ${gc['type'] ?? ''}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 12)),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${gc['reward']} pts', style: const TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.bold)),
                            ElevatedButton(
                              onPressed: isJoined
                                  ? null
                                  : () async {
                                      try {
                                        await ref.read(userChallengesProvider.notifier).joinGlobalChallenge(gc['_id'], gc['type'] ?? 'steps');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Joined challenge!'), backgroundColor: AppColors.neonGreen),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString().replaceAll('Exception: ', '')),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isJoined ? Colors.grey.shade700 : AppColors.neonPurple,
                                foregroundColor: isJoined ? Colors.white : Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                isJoined ? 'Joined ✓' : 'Join',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

double _metricProgress(String type, HealthData health) {
  switch (type) {
    case 'calories':
      return health.calories.toDouble();
    case 'distance':
      return health.distance;
    case 'steps':
    default:
      return health.steps.toDouble();
  }
}

String _unitLabel(String type) {
  switch (type) {
    case 'calories':
      return 'kcal';
    case 'distance':
      return 'km';
    case 'steps':
    default:
      return 'steps';
  }
}


