import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'mongodb_service.dart';

class AIService {
  /// Routes AI requests through the local Node.js backend
  /// Passes real user stats for personalized responses
  static Future<String> generateText(String message, {Map<String, dynamic>? userData}) async {
    final url = Uri.parse('${ApiConfig.backendUrl}/ai/chat');
    
    debugPrint("[AIService] Routing via Backend: $url");

    try {
      final token = MongoDbService.token;
      
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "message": message,
          "userData": userData ?? {
            "name": "User",
            "steps": 0,
            "calories": 0,
            "activeMinutes": 0,
            "goal": 10000
          }
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint("[AIService] Backend Error ${response.statusCode}: ${response.body}");
        return "⚠️ AI Coach is currently offline. Please try again later.";
      }

      final data = jsonDecode(response.body);
      return data["reply"] ?? "I'm here to help! What's on your mind?";
    } catch (e) {
      debugPrint("[AIService] Backend Connection Error: $e");
      return "⚠️ Unable to connect to FitTracker AI. Please check your server.";
    }
  }

  /// Specialized method for diet generation via backend
  static Future<String> generateDiet({
    required String name,
    required int steps,
    required int activeMinutes,
    required int calories,
    required String goal,
    required double bmi,
  }) async {
    final url = Uri.parse('${ApiConfig.backendUrl}/ai/diet');
    
    try {
      final token = MongoDbService.token;
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "bmi": bmi,
          "category": goal,
          "activity": activeMinutes,
          "steps": steps,
          "calories": calories
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) throw Exception("Backend diet error");

      final data = jsonDecode(response.body);
      final dietPlan = data["dietPlan"] as String;
      final summary = data["summary"] ?? {"calories": 2000, "protein": 120};

      // Convert the plain text diet plan from backend into the expected JSON format for the UI
      return jsonEncode({
        "breakfast": [dietPlan.split('\n').firstWhere((s) => s.contains('Breakfast'), orElse: () => 'Healthy Breakfast').replaceAll('Breakfast:', '').trim()],
        "lunch": [dietPlan.split('\n').firstWhere((s) => s.contains('Lunch'), orElse: () => 'Healthy Lunch').replaceAll('Lunch:', '').trim()],
        "dinner": [dietPlan.split('\n').firstWhere((s) => s.contains('Dinner'), orElse: () => 'Healthy Dinner').replaceAll('Dinner:', '').trim()],
        "snacks": [dietPlan.split('\n').firstWhere((s) => s.contains('Snack'), orElse: () => 'Healthy Snack').replaceAll('Snack:', '').trim()],
        "summary": summary
      });
    } catch (e) {
      debugPrint("[AIService] Backend Diet Error: $e. Using local fallback.");
      return jsonEncode({
        "breakfast": ["Oats with nuts", "1 cup tea"],
        "lunch": ["Grilled chicken/Paneer", "Brown rice", "Salad"],
        "dinner": ["Mixed vegetable soup", "1 Roti"],
        "snacks": ["Apple", "Handful of almonds"],
        "summary": {"calories": 1800, "protein": 100}
      });
    }
  }
}
