import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exercise_model.dart';
import 'api_config.dart';

class ExerciseService {
  /// Fetch all exercise categories (Abs, Arms, Back, etc.)
  static Future<List<ExerciseCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.wgerExerciseCategories),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((e) => ExerciseCategory.fromJson(e)).toList();
      }
      return _fallbackCategories();
    } catch (e) {
      return _fallbackCategories();
    }
  }

  /// Fetch exercises by category ID
  static Future<List<Exercise>> getExercisesByCategory(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.wgerExercisesByCategory(categoryId)),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        // For each exercise, fetch the full info with translations
        final exercises = <Exercise>[];
        // Fetch first 12 to avoid too many requests
        final ids = results.take(12).map((e) => e['id'] as int).toList();

        final futures = ids.map((id) => _fetchExerciseInfo(id));
        final infos = await Future.wait(futures);
        exercises.addAll(infos.where((e) => e != null).cast<Exercise>());

        return exercises;
      }
      return _fallbackExercises(categoryId);
    } catch (e) {
      return _fallbackExercises(categoryId);
    }
  }

  /// Fetch single exercise info by ID
  static Future<Exercise?> _fetchExerciseInfo(int id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.wgerExerciseInfoById(id)),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Exercise.fromExerciseInfo(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fallback data if API is unreachable
  static List<ExerciseCategory> _fallbackCategories() {
    return const [
      ExerciseCategory(id: 10, name: 'Abs'),
      ExerciseCategory(id: 8, name: 'Arms'),
      ExerciseCategory(id: 12, name: 'Back'),
      ExerciseCategory(id: 14, name: 'Calves'),
      ExerciseCategory(id: 15, name: 'Cardio'),
      ExerciseCategory(id: 11, name: 'Chest'),
      ExerciseCategory(id: 9, name: 'Legs'),
      ExerciseCategory(id: 13, name: 'Shoulders'),
    ];
  }

  static List<Exercise> _fallbackExercises(int categoryId) {
    final Map<int, List<Exercise>> fallback = {
      10: [
        const Exercise(id: 1, name: 'Crunches', categoryName: 'Abs', muscles: ['Abs'], description: 'Lie on your back with knees bent. Curl your upper body toward your knees.'),
        const Exercise(id: 2, name: 'Plank', categoryName: 'Abs', muscles: ['Abs', 'Shoulders'], description: 'Hold a push-up position with your body in a straight line.'),
        const Exercise(id: 3, name: 'Leg Raises', categoryName: 'Abs', muscles: ['Abs'], description: 'Lie flat and raise your legs to a 90-degree angle.'),
      ],
      8: [
        const Exercise(id: 4, name: 'Bicep Curls', categoryName: 'Arms', muscles: ['Biceps'], description: 'Stand with dumbbells and curl them toward your shoulders.'),
        const Exercise(id: 5, name: 'Tricep Dips', categoryName: 'Arms', muscles: ['Triceps'], description: 'Use a bench to lower your body by bending your arms.'),
        const Exercise(id: 6, name: 'Hammer Curls', categoryName: 'Arms', muscles: ['Biceps', 'Brachialis'], description: 'Like bicep curls but with palms facing each other.'),
      ],
      11: [
        const Exercise(id: 7, name: 'Bench Press', categoryName: 'Chest', muscles: ['Chest', 'Triceps'], description: 'Lie on a bench and press a barbell upward.'),
        const Exercise(id: 8, name: 'Push-Ups', categoryName: 'Chest', muscles: ['Chest', 'Shoulders'], description: 'Classic push-up from the floor.'),
        const Exercise(id: 9, name: 'Chest Fly', categoryName: 'Chest', muscles: ['Chest'], description: 'Lie on a bench with dumbbells and open your arms wide.'),
      ],
      12: [
        const Exercise(id: 10, name: 'Pull-Ups', categoryName: 'Back', muscles: ['Lats', 'Biceps'], description: 'Hang from a bar and pull yourself up.'),
        const Exercise(id: 11, name: 'Deadlift', categoryName: 'Back', muscles: ['Back', 'Glutes', 'Hamstrings'], description: 'Lift a barbell from the ground with a hip hinge.'),
        const Exercise(id: 12, name: 'Bent Over Row', categoryName: 'Back', muscles: ['Lats', 'Biceps'], description: 'Bend at the waist and row a barbell to your chest.'),
      ],
      9: [
        const Exercise(id: 13, name: 'Squats', categoryName: 'Legs', muscles: ['Quads', 'Glutes'], description: 'Stand with feet shoulder-width apart and squat down.'),
        const Exercise(id: 14, name: 'Lunges', categoryName: 'Legs', muscles: ['Quads', 'Glutes'], description: 'Step forward and lower your body until both knees are at 90 degrees.'),
        const Exercise(id: 15, name: 'Leg Press', categoryName: 'Legs', muscles: ['Quads', 'Hamstrings'], description: 'Push weight away from you using a leg press machine.'),
      ],
      13: [
        const Exercise(id: 16, name: 'Overhead Press', categoryName: 'Shoulders', muscles: ['Shoulders', 'Triceps'], description: 'Press a barbell or dumbbells overhead.'),
        const Exercise(id: 17, name: 'Lateral Raises', categoryName: 'Shoulders', muscles: ['Shoulders'], description: 'Raise dumbbells out to the sides.'),
        const Exercise(id: 18, name: 'Front Raises', categoryName: 'Shoulders', muscles: ['Shoulders'], description: 'Raise dumbbells in front of you.'),
      ],
      14: [
        const Exercise(id: 19, name: 'Calf Raises', categoryName: 'Calves', muscles: ['Calves'], description: 'Stand and raise up on your toes.'),
        const Exercise(id: 20, name: 'Seated Calf Raise', categoryName: 'Calves', muscles: ['Calves', 'Soleus'], description: 'Sit and raise your heels against resistance.'),
      ],
      15: [
        const Exercise(id: 21, name: 'Running', categoryName: 'Cardio', muscles: ['Full Body'], description: 'Steady state or interval running.'),
        const Exercise(id: 22, name: 'Jumping Jacks', categoryName: 'Cardio', muscles: ['Full Body'], description: 'Jump while spreading arms and legs.'),
        const Exercise(id: 23, name: 'Burpees', categoryName: 'Cardio', muscles: ['Full Body'], description: 'Squat, jump back to plank, push-up, jump up.'),
      ],
    };
    return fallback[categoryId] ?? [];
  }
}
