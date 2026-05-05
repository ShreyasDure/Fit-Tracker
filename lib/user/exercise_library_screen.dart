import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../controllers/exercise_controller.dart';
import '../models/exercise_model.dart';

class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: () => ref.read(selectedCategoryProvider.notifier).state = null,
              tooltip: 'Back to categories',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: selectedCategory == null
              ? _buildCategoryGrid(context, ref, categoriesAsync)
              : _buildExerciseList(context, ref, selectedCategory),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, WidgetRef ref, AsyncValue<List<ExerciseCategory>> categoriesAsync) {
    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      data: (categories) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Body Parts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Choose a muscle group', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSizes.lg),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppSizes.md,
              crossAxisSpacing: AppSizes.md,
              childAspectRatio: 1.3,
              children: categories.map((cat) {
                final colors = [
                  AppColors.neonCyan, AppColors.neonGreen, AppColors.neonPurple, AppColors.neonOrange,
                  AppColors.neonPink, AppColors.neonYellow, AppColors.neonCyan, AppColors.neonGreen,
                ];
                final color = colors[categories.indexOf(cat) % colors.length];
                return _CategoryCard(
                  category: cat,
                  color: color,
                  onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat.id,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context, WidgetRef ref, int categoryId) {
    final exercisesAsync = ref.watch(exercisesByCategoryProvider(categoryId));

    return exercisesAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.neonCyan),
            SizedBox(height: AppSizes.lg),
            Text('Loading exercises from Wger API...', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      data: (exercises) {
        if (exercises.isEmpty) {
          return const Center(child: Text('No exercises found', style: TextStyle(color: AppColors.textMuted)));
        }
        return ListView.separated(
          itemCount: exercises.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
          itemBuilder: (context, index) => _ExerciseCard(exercise: exercises[index]),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ExerciseCategory category;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.sm),
              ),
              child: Text(category.icon, style: const TextStyle(fontSize: 22)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: Theme.of(context).textTheme.titleSmall),
                Text('Tap to explore', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: _expanded ? AppColors.neonCyan.withValues(alpha: 0.3) : AppColors.surfaceLighter),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: AppColors.neonCyan, size: 20),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name, style: Theme.of(context).textTheme.titleSmall),
                      if (ex.muscles.isNotEmpty)
                        Text(ex.muscles.join(' · '), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            if (_expanded && ex.description.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              Text(ex.description, style: Theme.of(context).textTheme.bodyMedium),
              if (ex.equipment.isNotEmpty) ...[
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.xs,
                  children: ex.equipment.map((e) => Chip(
                    label: Text(e, style: const TextStyle(fontSize: 10, color: AppColors.neonPurple)),
                    backgroundColor: AppColors.neonPurple.withValues(alpha: 0.1),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
              if (ex.images.isNotEmpty) ...[
                const SizedBox(height: AppSizes.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.sm),
                  child: Image.network(
                    ex.images.first,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
