import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_model.dart';
import '../services/exercise_service.dart';

// ─── Exercise Categories Provider ───

final exerciseCategoriesProvider = FutureProvider<List<ExerciseCategory>>((ref) async {
  return ExerciseService.getCategories();
});

// ─── Exercises by Category Provider ───

final selectedCategoryProvider = StateProvider<int?>((ref) => null);

final exercisesByCategoryProvider = FutureProvider.family<List<Exercise>, int>((ref, categoryId) async {
  return ExerciseService.getExercisesByCategory(categoryId);
});
