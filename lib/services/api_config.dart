// API configuration for FitTracker
// Wger API: Fully free, no auth required
// CalorieNinjas API: Free tier, requires API key from api-ninjas.com

class ApiConfig {
  ApiConfig._();

  // ─── Backend API (Node.js + Express + MongoDB) ───
  // For Chrome/desktop: use localhost
  // For physical phone: use your computer's Wi-Fi IP address
  // For Android emulator: use 10.0.2.2
  static const String backendUrl = 'http://10.163.94.214:3000/api';

  // ─── Wger (Open Source Workout API) ───
  // No API key needed!
  static const String wgerBaseUrl = 'https://wger.de/api/v2';
  static const String wgerExerciseCategories = '$wgerBaseUrl/exercisecategory/?format=json';
  static const String wgerExerciseInfo = '$wgerBaseUrl/exerciseinfo'; // /{id}/?format=json
  static const String wgerExerciseSearch = '$wgerBaseUrl/exercise/search/?format=json';
  static const String wgerMuscles = '$wgerBaseUrl/muscle/?format=json';
  static const String wgerEquipment = '$wgerBaseUrl/equipment/?format=json';

  static String wgerExercisesByCategory(int categoryId) =>
      '$wgerBaseUrl/exercise/?format=json&language=2&category=$categoryId&limit=50';

  static String wgerExerciseInfoById(int id) =>
      '$wgerBaseUrl/exerciseinfo/$id/?format=json';

  // ─── CalorieNinjas (Nutrition API) ───
  // Sign up at https://api-ninjas.com/ to get your free key
  // Replace the placeholder below with your actual key
  static const String calorieNinjasApiKey = 'YOUR_API_KEY_HERE';
  static const String calorieNinjasBaseUrl = 'https://api.api-ninjas.com/v1';
  static const String calorieNinjasNutrition = '$calorieNinjasBaseUrl/nutrition';

  static String nutritionQuery(String query) =>
      '$calorieNinjasNutrition?query=${Uri.encodeComponent(query)}';
}
