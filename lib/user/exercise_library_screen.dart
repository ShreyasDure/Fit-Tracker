import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../controllers/exercise_controller.dart';
import '../models/exercise_model.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  @override
  Widget build(BuildContext context) {
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
              onPressed: () =>
                  ref.read(selectedCategoryProvider.notifier).state = null,
              tooltip: 'Back to categories',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.lg),
          child: selectedCategory == null
              ? _buildCategoryGrid(context, categoriesAsync)
              : _buildExerciseList(context, selectedCategory),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    AsyncValue<List<ExerciseCategory>> categoriesAsync,
  ) {
    return categoriesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.neonCyan),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: TextStyle(color: AppColors.error),
        ),
      ),
      data: (categories) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Body Parts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Choose a muscle group',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.lg),

          Expanded(
            child: GridView.builder(
              itemCount: categories.length,
              padding: EdgeInsets.zero,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.md,
                mainAxisSpacing: AppSizes.md,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final cat = categories[index];

                final colors = [
                  AppColors.neonCyan,
                  AppColors.neonGreen,
                  AppColors.neonPurple,
                  AppColors.neonOrange,
                  AppColors.neonPink,
                  AppColors.neonYellow,
                  AppColors.neonCyan,
                  AppColors.neonGreen,
                ];
                final color = colors[index % colors.length];

                return _CategoryCard(
                  category: cat,
                  color: color,
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = cat.id,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context, int categoryId) {
    final exercisesAsync = ref.watch(exercisesByCategoryProvider(categoryId));

    return exercisesAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.neonCyan),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Loading exercises from Wger API...',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (exercises) {
        if (exercises.isEmpty) {
          return Center(
            child: Text(
              'No exercises found',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          );
        }

        return _ControlledExpansionList(
          exercises: exercises,
        );
      },
    );
  }
}

class _ControlledExpansionList extends StatefulWidget {
  final List<Exercise> exercises;

  const _ControlledExpansionList({
    required this.exercises,
  });

  @override
  State<_ControlledExpansionList> createState() =>
      _ControlledExpansionListState();
}

class _ControlledExpansionListState extends State<_ControlledExpansionList> {
  late List<bool> _expandedList;

  @override
  void initState() {
    super.initState();
    _expandedList =
        List<bool>.generate(widget.exercises.length, (_) => false);
  }

  @override
  void didUpdateWidget(covariant _ControlledExpansionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercises.length != widget.exercises.length) {
      _expandedList =
          List<bool>.generate(widget.exercises.length, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.exercises.length,
      itemBuilder: (context, index) {
        final ex = widget.exercises[index];

        return Padding(
          padding: EdgeInsets.only(bottom: AppSizes.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(
                color: _expandedList[index]
                    ? AppColors.neonCyan.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            child: Theme(
              // keep tile background consistent
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                initiallyExpanded: _expandedList[index],
                onExpansionChanged: (value) {
                  setState(() {
                    _expandedList[index] = value;
                  });
                },
                tilePadding: EdgeInsets.symmetric(horizontal: AppSizes.lg),
                childrenPadding: EdgeInsets.symmetric(horizontal: AppSizes.lg),
                title: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.neonCyan,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Text(
                        ex.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Icon(
                      _expandedList[index]
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppSizes.sm,
                      bottom: AppSizes.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ex.description.isNotEmpty)
                          Text(
                            ex.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (ex.muscles.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            ex.muscles.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (ex.equipment.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: AppSizes.xs,
                            children: ex.equipment
                                .take(4)
                                .map(
                                  (e) => Chip(
                                    label: Text(
                                      e,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.neonPurple,
                                      ),
                                    ),
                                    backgroundColor:
                                        AppColors.neonPurple.withValues(
                                      alpha: 0.1,
                                    ),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (ex.images.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSizes.sm),
                            child: Image.network(
                              ex.images.first,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ExerciseCategory category;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double fixedHeight = 112;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: fixedHeight,
        child: Container(
          padding: EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.sm),
                ),
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 22),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text(
                category.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to explore',
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
