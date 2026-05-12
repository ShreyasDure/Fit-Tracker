import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_model.dart';
import '../services/mongodb_service.dart';
import '../services/nutrition_service.dart';

// ─── Nutrition Search State ───

class NutritionSearchState {
  final String query;
  final List<NutritionItem> results;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final List<Map<String, dynamic>> dailyItems;
  final double dailyCalories;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFat;

  const NutritionSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.dailyItems = const [],
    this.dailyCalories = 0,
    this.dailyProtein = 0,
    this.dailyCarbs = 0,
    this.dailyFat = 0,
  });

  NutritionSearchState copyWith({
    String? query,
    List<NutritionItem>? results,
    bool? isLoading,
    bool? isSaving,
    String? error,
    List<Map<String, dynamic>>? dailyItems,
    double? dailyCalories,
    double? dailyProtein,
    double? dailyCarbs,
    double? dailyFat,
  }) {
    return NutritionSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      dailyItems: dailyItems ?? this.dailyItems,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      dailyFat: dailyFat ?? this.dailyFat,
    );
  }

  // Totals across all results
  double get totalCalories => results.fold(0, (sum, r) => sum + r.calories);
  double get totalProtein => results.fold(0, (sum, r) => sum + r.protein);
  double get totalCarbs => results.fold(0, (sum, r) => sum + r.carbohydrates);
  double get totalFat => results.fold(0, (sum, r) => sum + r.totalFat);
}

class NutritionController extends StateNotifier<NutritionSearchState> {
  NutritionController() : super(const NutritionSearchState()) {
    loadTodaySummary();
  }

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
    state = state.copyWith(
      query: '',
      results: const [],
      isLoading: false,
      error: null,
    );
  }

  Future<void> loadTodaySummary() async {
    try {
      final data = await MongoDbService.getTodayNutritionSummary();
      final summary = data['summary'] as Map<String, dynamic>? ?? {};
      final items = List<Map<String, dynamic>>.from(data['items'] ?? const []);
      state = state.copyWith(
        dailyItems: items,
        dailyCalories: (summary['totalCalories'] as num?)?.toDouble() ?? 0,
        dailyProtein: (summary['totalProtein'] as num?)?.toDouble() ?? 0,
        dailyCarbs: (summary['totalCarbs'] as num?)?.toDouble() ?? 0,
        dailyFat: (summary['totalFat'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      // Keep existing state if summary fetch fails.
    }
  }

  Future<void> addIntake({
    required NutritionItem item,
    required double quantityGrams,
  }) async {
    if (quantityGrams <= 0) return;
    final multiplier = quantityGrams / 100.0;
    final calories = item.calories * multiplier;
    final protein = item.protein * multiplier;
    final carbs = item.carbohydrates * multiplier;
    final fat = item.totalFat * multiplier;

    state = state.copyWith(isSaving: true, error: null);
    try {
      final data = await MongoDbService.logNutritionIntake(
        food: item.name,
        quantity: quantityGrams,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
      final summary = data['summary'] as Map<String, dynamic>? ?? {};
      final loggedItem = Map<String, dynamic>.from(data['item'] ?? const {});
      state = state.copyWith(
        isSaving: false,
        dailyItems: [loggedItem, ...state.dailyItems],
        dailyCalories: (summary['totalCalories'] as num?)?.toDouble() ?? state.dailyCalories,
        dailyProtein: (summary['totalProtein'] as num?)?.toDouble() ?? state.dailyProtein,
        dailyCarbs: (summary['totalCarbs'] as num?)?.toDouble() ?? state.dailyCarbs,
        dailyFat: (summary['totalFat'] as num?)?.toDouble() ?? state.dailyFat,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Failed to save intake');
      rethrow;
    }
  }
}

final nutritionControllerProvider =
    StateNotifierProvider<NutritionController, NutritionSearchState>((ref) {
  return NutritionController();
});
