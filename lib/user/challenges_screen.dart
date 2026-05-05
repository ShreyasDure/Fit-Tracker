import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../admin/challenges_management_screen.dart';

// User challenge state
class UserChallengeState {
  final String challengeId;
  final String status; // 'available', 'accepted', 'completed'
  final double progress;

  const UserChallengeState({required this.challengeId, this.status = 'available', this.progress = 0});
}

final userChallengesProvider = StateNotifierProvider<UserChallengesNotifier, Map<String, UserChallengeState>>((ref) => UserChallengesNotifier());

class UserChallengesNotifier extends StateNotifier<Map<String, UserChallengeState>> {
  UserChallengesNotifier() : super({});

  void acceptChallenge(String id) {
    state = {...state, id: UserChallengeState(challengeId: id, status: 'accepted', progress: 0)};
  }

  void rejectChallenge(String id) {
    final updated = Map<String, UserChallengeState>.from(state);
    updated.remove(id);
    state = updated;
  }

  void updateProgress(String id, double progress) {
    if (!state.containsKey(id)) return;
    state = {
      ...state,
      id: UserChallengeState(
        challengeId: id,
        status: progress >= 1.0 ? 'completed' : 'accepted',
        progress: progress.clamp(0, 1),
      ),
    };
  }
}

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allChallenges = ref.watch(challengesProvider);
    final userStates = ref.watch(userChallengesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My active challenges
            if (userStates.isNotEmpty) ...[
              Text('My Challenges', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.neonCyan)),
              const SizedBox(height: AppSizes.sm),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: userStates.entries.map((e) {
                    final challenge = allChallenges.where((c) => c.id == e.key).firstOrNull;
                    if (challenge == null) return const SizedBox.shrink();
                    final isCompleted = e.value.status == 'completed';
                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: AppSizes.sm),
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.neonGreen.withValues(alpha: 0.08) : AppColors.neonCyan.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isCompleted ? AppColors.neonGreen.withValues(alpha: 0.3) : AppColors.neonCyan.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(isCompleted ? Icons.check_circle : Icons.emoji_events_rounded, color: isCompleted ? AppColors.neonGreen : AppColors.neonOrange, size: 16),
                              const SizedBox(width: 4),
                              Expanded(child: Text(challenge.title, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: e.value.progress,
                              backgroundColor: AppColors.surfaceLighter,
                              valueColor: AlwaysStoppedAnimation(isCompleted ? AppColors.neonGreen : AppColors.neonCyan),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(isCompleted ? 'Completed! 🎉' : '${(e.value.progress * 100).toInt()}%', style: TextStyle(color: isCompleted ? AppColors.neonGreen : AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
            ],
            Text('Available Challenges', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            Expanded(
              child: allChallenges.isEmpty
                  ? const Center(child: Text('No challenges available yet', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      itemCount: allChallenges.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                      itemBuilder: (_, i) {
                        final c = allChallenges[i];
                        final userState = userStates[c.id];
                        final isAccepted = userState != null;
                        final isCompleted = userState?.status == 'completed';
                        return _ChallengeCard(
                          challenge: c,
                          isAccepted: isAccepted,
                          isCompleted: isCompleted,
                          onAccept: () {
                            ref.read(userChallengesProvider.notifier).acceptChallenge(c.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('🎯 Challenge "${c.title}" accepted!'),
                              backgroundColor: AppColors.neonGreen,
                              behavior: SnackBarBehavior.floating,
                            ));
                          },
                          onReject: () => ref.read(userChallengesProvider.notifier).rejectChallenge(c.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeItem challenge;
  final bool isAccepted;
  final bool isCompleted;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ChallengeCard({required this.challenge, required this.isAccepted, required this.isCompleted, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final color = challenge.difficulty == 'easy' ? AppColors.neonGreen : challenge.difficulty == 'moderate' ? AppColors.neonOrange : AppColors.neonPink;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: isCompleted ? AppColors.neonGreen.withValues(alpha: 0.3) : color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.emoji_events_rounded, color: color, size: 18),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.title, style: Theme.of(context).textTheme.titleSmall),
                    Text('${challenge.targetValue} ${challenge.targetUnit} · ${challenge.durationDays} days', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text('${challenge.pointsReward} pts', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(challenge.description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSizes.md),
          if (isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              decoration: BoxDecoration(color: AppColors.neonGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('✅ Completed', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w700, fontSize: 13))),
            )
          else if (isAccepted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('🏃 In Progress', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w700, fontSize: 13))),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSizes.sm)),
                    child: const Text('Accept', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.surfaceLighter),
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                    ),
                    child: const Text('Skip', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
