import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/mongodb_service.dart';

// Local challenge model for admin
class ChallengeItem {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int pointsReward;
  final int durationDays;
  final int targetValue;
  final String targetUnit;
  final bool isActive;
  final int participantCount;
  final int completedCount;

  const ChallengeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.pointsReward,
    this.durationDays = 7,
    this.targetValue = 1,
    this.targetUnit = 'workouts',
    this.isActive = true,
    this.participantCount = 0,
    this.completedCount = 0,
  });
}

// Provider for challenges
final challengesProvider = StateNotifierProvider<ChallengesNotifier, List<ChallengeItem>>((ref) => ChallengesNotifier());

class ChallengesNotifier extends StateNotifier<List<ChallengeItem>> {
  ChallengesNotifier() : super([]) {
    loadFromDb();
  }

  Future<void> loadFromDb() async {
    try {
      if (!MongoDbService.isAuthenticated) return;
      final data = await MongoDbService.getChallenges();
      state = data.map((c) {
        final participants = c['participants'];
        final List<dynamic> pList = participants is List ? participants : [];
        
        return ChallengeItem(
          id: c['_id']?.toString() ?? '',
          title: c['title'] ?? 'Untitled Challenge',
          description: c['description'] ?? '',
          difficulty: c['difficulty'] ?? 'moderate',
          pointsReward: (c['reward'] as num?)?.toInt() ?? 0,
          durationDays: (c['durationDays'] as num?)?.toInt() ?? 7,
          targetValue: (c['target'] as num?)?.round() ?? 1,
          targetUnit: c['type'] ?? 'steps',
          isActive: c['isActive'] ?? true,
          participantCount: pList.length,
          completedCount: pList.where((p) => p is Map && p['status'] == 'completed').length,
        );
      }).toList();
    } catch (e) {
      debugPrint('Load challenges error: $e');
    }
  }

  Future<void> addChallenge({
    required String title,
    required String description,
    required String difficulty,
    required int pointsReward,
    required double targetValue,
    required String targetUnit,
  }) async {
    final created = await MongoDbService.createChallenge(
      title: title,
      description: description,
      difficulty: difficulty,
      reward: pointsReward,
      target: targetValue,
      type: targetUnit,
    );
    final c = ChallengeItem(
      id: created['_id']?.toString() ?? '',
      title: created['title'] ?? title,
      description: created['description'] ?? description,
      difficulty: created['difficulty'] ?? difficulty,
      pointsReward: (created['reward'] as num?)?.toInt() ?? pointsReward,
      durationDays: (created['durationDays'] as num?)?.toInt() ?? 7,
      targetValue: (created['target'] as num?)?.round() ?? targetValue.round(),
      targetUnit: created['type'] ?? targetUnit,
      isActive: created['isActive'] ?? true,
      participantCount: (created['participants'] is List) ? (created['participants'] as List).length : 0,
      completedCount: (created['participants'] is List) 
          ? (created['participants'] as List).where((p) => p is Map && p['status'] == 'completed').length 
          : 0,
    );
    state = [c, ...state];
  }

  Future<void> removeChallenge(String id) async {
    await MongoDbService.deleteChallenge(id);
    state = state.where((c) => c.id != id).toList();
  }

  void updateChallenge(String id, ChallengeItem updated) {
    state = state.map((c) => c.id == id ? updated : c).toList();
  }
}

class ChallengesManagementScreen extends ConsumerWidget {
  const ChallengesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(challengesProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Challenges', style: Theme.of(context).textTheme.displayMedium),
                        Text('${challenges.length} total', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCreateDialog(context, ref),
                    child: Container(
                      padding: EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.black, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              // Stats row
              Row(
                children: [
                  _MiniStat(label: 'Easy', value: '${challenges.where((c) => c.difficulty == 'easy').length}', color: AppColors.neonGreen),
                  const SizedBox(width: AppSizes.sm),
                  _MiniStat(label: 'Moderate', value: '${challenges.where((c) => c.difficulty == 'moderate').length}', color: AppColors.neonOrange),
                  const SizedBox(width: AppSizes.sm),
                  _MiniStat(label: 'Hard', value: '${challenges.where((c) => c.difficulty == 'hard').length}', color: AppColors.neonPink),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: challenges.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (_, i) => _ChallengeCard(
                    challenge: challenges[i],
                    onDelete: () async {
                      try {
                        await ref.read(challengesProvider.notifier).removeChallenge(challenges[i].id);
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
                    onTap: () => _showChallengeDetail(context, challenges[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '200');
    final targetCtrl = TextEditingController(text: '5');
    String difficulty = 'easy';
    String unit = 'workouts';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(AppSizes.xl, AppSizes.xl, AppSizes.xl, MediaQuery.of(ctx).viewInsets.bottom + AppSizes.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: AppSizes.lg), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(2))),
                Text('Create Challenge', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSizes.lg),
                TextField(controller: titleCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.emoji_events_rounded, color: Theme.of(context).textTheme.bodySmall!.color!))),
                const SizedBox(height: AppSizes.md),
                TextField(controller: descCtrl, style: TextStyle(color: Colors.white), maxLines: 2, decoration: InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_rounded, color: Theme.of(context).textTheme.bodySmall!.color!))),
                const SizedBox(height: AppSizes.md),
                // Difficulty
                Text('Difficulty', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    _DifficultyChip(label: 'Easy', isSelected: difficulty == 'easy', color: AppColors.neonGreen, onTap: () => setModalState(() => difficulty = 'easy')),
                    const SizedBox(width: AppSizes.sm),
                    _DifficultyChip(label: 'Moderate', isSelected: difficulty == 'moderate', color: AppColors.neonOrange, onTap: () => setModalState(() => difficulty = 'moderate')),
                    const SizedBox(width: AppSizes.sm),
                    _DifficultyChip(label: 'Hard', isSelected: difficulty == 'hard', color: AppColors.neonPink, onTap: () => setModalState(() => difficulty = 'hard')),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(child: TextField(controller: pointsCtrl, keyboardType: TextInputType.number, style: TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Points Reward'))),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(child: TextField(controller: targetCtrl, keyboardType: TextInputType.number, style: TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Target'))),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                // Unit selector
                Row(
                  children: [
                    Text('Unit: ', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(width: AppSizes.sm),
                    for (final u in ['workouts', 'km', 'kcal', 'sessions', 'minutes']) ...[
                      GestureDetector(
                        onTap: () => setModalState(() => unit = u),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: unit == u ? AppColors.neonCyan.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(u, style: TextStyle(color: unit == u ? AppColors.neonCyan : Theme.of(context).textTheme.bodySmall!.color!, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSizes.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
                            setModalState(() => isSaving = true);
                            try {
                              await ref.read(challengesProvider.notifier).addChallenge(
                                    title: titleCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    difficulty: difficulty,
                                    pointsReward: int.tryParse(pointsCtrl.text) ?? 200,
                                    targetValue: double.tryParse(targetCtrl.text) ?? 1,
                                    targetUnit: unit,
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } finally {
                              if (ctx.mounted) setModalState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Create Challenge'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChallengeDetail(BuildContext context, ChallengeItem c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: _diffColor(c.difficulty), size: 28),
                const SizedBox(width: AppSizes.sm),
                Expanded(child: Text(c.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                _DiffBadge(difficulty: c.difficulty),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(c.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DetailItem(label: 'Reward', value: '${c.pointsReward} pts', color: AppColors.neonCyan),
                _DetailItem(label: 'Target', value: '${c.targetValue} ${c.targetUnit}', color: AppColors.neonGreen),
                _DetailItem(label: 'Duration', value: '${c.durationDays} days', color: AppColors.neonOrange),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Container(
              padding: EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    Text('${c.participantCount}', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w800, fontSize: 18)),
                    Text('Joined', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 11)),
                  ]),
                  Container(width: 1, height: 30, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  Column(children: [
                    Text('${c.participantCount - c.completedCount}', style: TextStyle(color: AppColors.neonOrange, fontWeight: FontWeight.w800, fontSize: 18)),
                    Text('In Progress', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 11)),
                  ]),
                  Container(width: 1, height: 30, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  Column(children: [
                    Text('${c.completedCount}', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w800, fontSize: 18)),
                    Text('Completed', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 11)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }

  Color _diffColor(String d) {
    switch (d) {
      case 'easy': return AppColors.neonGreen;
      case 'moderate': return AppColors.neonOrange;
      case 'hard': return AppColors.neonPink;
      default: return AppColors.neonCyan;
    }
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeItem challenge;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _ChallengeCard({required this.challenge, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _diffColor(challenge.difficulty);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.emoji_events_rounded, color: color, size: 20),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(challenge.title, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: AppSizes.xs),
                      _DiffBadge(difficulty: challenge.difficulty),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${challenge.pointsReward} pts · ${challenge.participantCount} joined', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18), onPressed: onDelete),
          ],
        ),
      ),
    );
  }

  Color _diffColor(String d) {
    switch (d) { case 'easy': return AppColors.neonGreen; case 'moderate': return AppColors.neonOrange; case 'hard': return AppColors.neonPink; default: return AppColors.neonCyan; }
  }
}

class _DiffBadge extends StatelessWidget {
  final String difficulty;
  const _DiffBadge({required this.difficulty});
  @override
  Widget build(BuildContext context) {
    final color = difficulty == 'easy' ? AppColors.neonGreen : difficulty == 'moderate' ? AppColors.neonOrange : AppColors.neonPink;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(difficulty[0].toUpperCase() + difficulty.substring(1), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.15))),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ]),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _DifficultyChip({required this.label, required this.isSelected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? color : Theme.of(context).textTheme.bodySmall!.color!, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DetailItem({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 10)),
    ]);
  }
}


