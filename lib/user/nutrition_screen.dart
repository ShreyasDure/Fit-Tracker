import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../controllers/nutrition_controller.dart';
import '../models/nutrition_model.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      ref.read(nutritionControllerProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = ref.watch(nutritionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Lookup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.neonGreen.withValues(alpha: 0.14), Theme.of(context).cardColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroSummary(label: 'Calories', value: nutrition.dailyCalories.toStringAsFixed(0), unit: 'kcal', color: AppColors.neonOrange),
                    _MacroSummary(label: 'Protein', value: nutrition.dailyProtein.toStringAsFixed(1), unit: 'g', color: AppColors.neonCyan),
                    _MacroSummary(label: 'Carbs', value: nutrition.dailyCarbs.toStringAsFixed(1), unit: 'g', color: AppColors.neonPurple),
                    _MacroSummary(label: 'Fat', value: nutrition.dailyFat.toStringAsFixed(1), unit: 'g', color: AppColors.neonPink),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
              // Search bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. "2 eggs and toast"',
                        prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).textTheme.bodySmall!.color!),
                        suffixIcon: nutrition.query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Theme.of(context).textTheme.bodySmall!.color!, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref.read(nutritionControllerProvider.notifier).clear();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _search(),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  GestureDetector(
                    onTap: _search,
                    child: Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan,
                        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                      ),
                      child: const Icon(Icons.search, color: Colors.black, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              if (nutrition.isSaving)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: Row(
                    children: const [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan)),
                      SizedBox(width: 8),
                      Text('Saving intake...'),
                    ],
                  ),
                ),

              // Loading
              if (nutrition.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
                )
              // Error
              else if (nutrition.error != null)
                Expanded(
                  child: Center(
                    child: Text(nutrition.error!, style: TextStyle(color: AppColors.error)),
                  ),
                )
              // Results
              else if (nutrition.results.isNotEmpty) ...[
                Text('${nutrition.results.length} item(s) found', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: AppSizes.sm),
                // Food items
                Expanded(
                  child: ListView.separated(
                    itemCount: nutrition.results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
                    itemBuilder: (context, index) {
                      final item = nutrition.results[index];
                      return Container(
                        padding: EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.neonGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.restaurant_rounded, color: AppColors.neonGreen, size: 18),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: Theme.of(context).textTheme.titleSmall),
                                      Text('${item.servingSize.toStringAsFixed(0)}g serving', style: Theme.of(context).textTheme.labelSmall),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.calories.toStringAsFixed(0)} kcal',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppColors.neonOrange,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.sm),
                            Row(
                              children: [
                                _MacroChip(label: 'Protein', value: '${item.protein.toStringAsFixed(1)}g', color: AppColors.neonCyan),
                                const SizedBox(width: AppSizes.xs),
                                _MacroChip(label: 'Carbs', value: '${item.carbohydrates.toStringAsFixed(1)}g', color: AppColors.neonPurple),
                                const SizedBox(width: AppSizes.xs),
                                _MacroChip(label: 'Fat', value: '${item.totalFat.toStringAsFixed(1)}g', color: AppColors.neonPink),
                                const SizedBox(width: AppSizes.xs),
                                _MacroChip(label: 'Fiber', value: '${item.fiber.toStringAsFixed(1)}g', color: AppColors.neonGreen),
                              ],
                            ),
                            const SizedBox(height: AppSizes.sm),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showQuantityDialog(item),
                                icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.neonGreen),
                                label: const Text('Add consumed quantity', style: TextStyle(color: AppColors.neonGreen)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.neonGreen.withValues(alpha: 0.3)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ]
              // Empty state
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu_rounded, color: Theme.of(context).textTheme.bodySmall!.color!.withValues(alpha: 0.3), size: 64),
                        const SizedBox(height: AppSizes.md),
                        Text('Search for any food', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).textTheme.bodySmall!.color!)),
                        const SizedBox(height: AppSizes.xs),
                        Text('Try "chicken breast" or "2 eggs and toast"', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQuantityDialog(NutritionItem item) async {
    final qtyCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Consumed Quantity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How much quantity did you consume (grams)?', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantity (g)',
                hintText: 'e.g. 50',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (qty <= 0) return;
              try {
                await ref.read(nutritionControllerProvider.notifier).addIntake(item: item, quantityGrams: qty);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to today\'s diet'), backgroundColor: AppColors.neonGreen),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save intake'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _MacroSummary extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _MacroSummary({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
        Text(unit, style: Theme.of(context).textTheme.labelSmall),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9)),
          ],
        ),
      ),
    );
  }
}


