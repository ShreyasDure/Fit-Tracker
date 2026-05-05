import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_model.dart';
import '../services/nutrition_service.dart';

// ─── Nutrition Search State ───

class NutritionSearchState {
  final String query;
  final List<NutritionItem> results;
  final bool isLoading;
  final String? error;

  const NutritionSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  NutritionSearchState copyWith({
    String? query,
    List<NutritionItem>? results,
    bool? isLoading,
    String? error,
  }) {
    return NutritionSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Totals across all results
  double get totalCalories => results.fold(0, (sum, r) => sum + r.calories);
  double get totalProtein => results.fold(0, (sum, r) => sum + r.protein);
  double get totalCarbs => results.fold(0, (sum, r) => sum + r.carbohydrates);
  double get totalFat => results.fold(0, (sum, r) => sum + r.totalFat);
}

class NutritionController extends StateNotifier<NutritionSearchState> {
  NutritionController() : super(const NutritionSearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const NutritionSearchState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);

    try {
      final results = await NutritionService.searchNutrition(query);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch nutrition data',
      );
    }
  }

  void clear() {
    state = const NutritionSearchState();
  }
}

final nutritionControllerProvider =
    StateNotifierProvider<NutritionController, NutritionSearchState>((ref) {
  return NutritionController();
});
