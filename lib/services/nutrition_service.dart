import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nutrition_model.dart';
import 'api_config.dart';

class NutritionService {
  static final Map<String, List<NutritionItem>> _queryCache = {};

  /// Search nutrition info using CalorieNinjas API
  /// Supports natural language: "2 eggs and toast", "chicken breast 200g"
  static Future<List<NutritionItem>> searchNutrition(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    final cached = _queryCache[normalized];
    if (cached != null) return cached;

    // If API key is not set, return demo data
    if (ApiConfig.calorieNinjasApiKey == 'YOUR_API_KEY_HERE') {
      final demo = _getDemoResults(query);
      _queryCache[normalized] = demo;
      return demo;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.nutritionQuery(query)),
        headers: {
          'X-Api-Key': ApiConfig.calorieNinjasApiKey,
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final parsed = data.map((e) => NutritionItem.fromJson(e)).toList();
        _queryCache[normalized] = parsed;
        return parsed;
      }
      final demo = _getDemoResults(query);
      _queryCache[normalized] = demo;
      return demo;
    } catch (e) {
      final demo = _getDemoResults(query);
      _queryCache[normalized] = demo;
      return demo;
    }
  }

  /// Demo data when API key is not configured
  static List<NutritionItem> _getDemoResults(String query) {
    final q = query.toLowerCase();

    // Common food database for demo
    final Map<String, NutritionItem> foods = {
      'chicken': const NutritionItem(name: 'Chicken Breast', calories: 165, protein: 31, carbohydrates: 0, totalFat: 3.6, fiber: 0, sugar: 0, servingSize: 100, sodium: 74, potassium: 256),
      'rice': const NutritionItem(name: 'White Rice', calories: 130, protein: 2.7, carbohydrates: 28, totalFat: 0.3, fiber: 0.4, sugar: 0, servingSize: 100, sodium: 1, potassium: 35),
      'egg': const NutritionItem(name: 'Egg (Large)', calories: 155, protein: 13, carbohydrates: 1.1, totalFat: 11, fiber: 0, sugar: 1.1, servingSize: 100, sodium: 124, potassium: 126),
      'banana': const NutritionItem(name: 'Banana', calories: 89, protein: 1.1, carbohydrates: 23, totalFat: 0.3, fiber: 2.6, sugar: 12, servingSize: 118, sodium: 1, potassium: 358),
      'apple': const NutritionItem(name: 'Apple', calories: 52, protein: 0.3, carbohydrates: 14, totalFat: 0.2, fiber: 2.4, sugar: 10, servingSize: 182, sodium: 1, potassium: 107),
      'oatmeal': const NutritionItem(name: 'Oatmeal', calories: 389, protein: 17, carbohydrates: 66, totalFat: 7, fiber: 11, sugar: 0, servingSize: 100, sodium: 2, potassium: 429),
      'salmon': const NutritionItem(name: 'Salmon', calories: 208, protein: 20, carbohydrates: 0, totalFat: 13, fiber: 0, sugar: 0, servingSize: 100, sodium: 59, potassium: 363),
      'broccoli': const NutritionItem(name: 'Broccoli', calories: 34, protein: 2.8, carbohydrates: 7, totalFat: 0.4, fiber: 2.6, sugar: 1.7, servingSize: 100, sodium: 33, potassium: 316),
      'milk': const NutritionItem(name: 'Whole Milk', calories: 61, protein: 3.2, carbohydrates: 4.8, totalFat: 3.3, fiber: 0, sugar: 5, servingSize: 100, sodium: 43, potassium: 132),
      'bread': const NutritionItem(name: 'White Bread', calories: 265, protein: 9, carbohydrates: 49, totalFat: 3.2, fiber: 2.7, sugar: 5, servingSize: 100, sodium: 491, potassium: 115),
      'pasta': const NutritionItem(name: 'Pasta (Cooked)', calories: 131, protein: 5, carbohydrates: 25, totalFat: 1.1, fiber: 1.8, sugar: 0.6, servingSize: 100, sodium: 1, potassium: 44),
      'steak': const NutritionItem(name: 'Beef Steak', calories: 271, protein: 26, carbohydrates: 0, totalFat: 18, fiber: 0, sugar: 0, servingSize: 100, sodium: 54, potassium: 315),
      'avocado': const NutritionItem(name: 'Avocado', calories: 160, protein: 2, carbohydrates: 9, totalFat: 15, fiber: 7, sugar: 0.7, servingSize: 100, sodium: 7, potassium: 485),
      'yogurt': const NutritionItem(name: 'Greek Yogurt', calories: 59, protein: 10, carbohydrates: 3.6, totalFat: 0.4, fiber: 0, sugar: 3.2, servingSize: 100, sodium: 36, potassium: 141),
      'pizza': const NutritionItem(name: 'Pizza (1 Slice)', calories: 266, protein: 11, carbohydrates: 33, totalFat: 10, fiber: 2.3, sugar: 3.6, servingSize: 107, sodium: 640, potassium: 172),
      'toast': const NutritionItem(name: 'Toast', calories: 313, protein: 11, carbohydrates: 55, totalFat: 5, fiber: 3, sugar: 5, servingSize: 100, sodium: 522, potassium: 131),
    };

    final results = <NutritionItem>[];
    for (final entry in foods.entries) {
      if (q.contains(entry.key)) {
        results.add(entry.value);
      }
    }

    // If no match, return a few popular items
    if (results.isEmpty) {
      return [
        foods['chicken']!,
        foods['rice']!,
        foods['banana']!,
        foods['egg']!,
        foods['oatmeal']!,
      ];
    }

    return results;
  }
}
