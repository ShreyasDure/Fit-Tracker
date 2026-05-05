import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';

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
  ChallengesNotifier() : super(_defaultChallenges);

  static final List<ChallengeItem> _defaultChallenges = [
    const ChallengeItem(id: '1', title: '5K Runner', description: 'Run 5 kilometers in a week', difficulty: 'easy', pointsReward: 200, durationDays: 7, targetValue: 5, targetUnit: 'km', participantCount: 12, completedCount: 4),
    const ChallengeItem(id: '2', title: 'Gym Warrior', description: 'Complete 10 gym sessions', difficulty: 'moderate', pointsReward: 500, durationDays: 14, targetValue: 10, targetUnit: 'sessions', participantCount: 8, completedCount: 2),
    const ChallengeItem(id: '3', title: 'Iron Beast', description: 'Burn 5000 calories this month', difficulty: 'hard', pointsReward: 1000, durationDays: 30, targetValue: 5000, targetUnit: 'kcal', participantCount: 5, completedCount: 0),
  ];

  void addChallenge(ChallengeItem c) {
    state = [c, ...state];
  }

  void removeChallenge(String id) {
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
          padding: const EdgeInsets.all(AppSizes.lg),
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
                      padding: const EdgeInsets.all(AppSizes.sm),
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
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (_, i) => _ChallengeCard(challenge: challenges[i], onDelete: () => ref.read(challengesProvider.notifier).removeChallenge(challenges[i].id), onTap: () => _showChallengeDetail(context, challenges[i])),
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

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: AppSizes.lg), decoration: BoxDecoration(color: AppColors.surfaceLighter, borderRadius: BorderRadius.circular(2))),
                Text('Create Challenge', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSizes.lg),
                TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.emoji_events_rounded, color: AppColors.textMuted))),
                const SizedBox(height: AppSizes.md),
                TextField(controller: descCtrl, style: const TextStyle(color: Colors.white), maxLines: 2, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_rounded, color: AppColors.textMuted))),
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
                    Expanded(child: TextField(controller: pointsCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Points Reward'))),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(child: TextField(controller: targetCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Target'))),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: unit == u ? AppColors.neonCyan.withValues(alpha: 0.15) : AppColors.surfaceLighter,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(u, style: TextStyle(color: unit == u ? AppColors.neonCyan : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSizes.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty) return;
                      ref.read(challengesProvider.notifier).addChallenge(
                        ChallengeItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          difficulty: difficulty,
                          pointsReward: int.tryParse(pointsCtrl.text) ?? 200,
                          targetValue: int.tryParse(targetCtrl.text) ?? 1,
                          targetUnit: unit,
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Create Challenge'),
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceLighter, borderRadius: BorderRadius.circular(2))),
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
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    Text('${c.participantCount}', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w800, fontSize: 18)),
                    const Text('Joined', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ]),
                  Container(width: 1, height: 30, color: AppColors.surfaceLighter),
                  Column(children: [
                    Text('${c.participantCount - c.completedCount}', style: const TextStyle(color: AppColors.neonOrange, fontWeight: FontWeight.w800, fontSize: 18)),
                    const Text('In Progress', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ]),
                  Container(width: 1, height: 30, color: AppColors.surfaceLighter),
                  Column(children: [
                    Text('${c.completedCount}', style: const TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w800, fontSize: 18)),
                    const Text('Completed', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
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
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        padding: const EdgeInsets.all(AppSizes.md),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceLighter,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? color : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
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
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
    ]);
  }
}
