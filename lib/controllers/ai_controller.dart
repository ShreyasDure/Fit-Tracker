import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIController extends ChangeNotifier {
  bool isLoading = false;

  Map<String, dynamic> diet = {
    "breakfast": [],
    "lunch": [],
    "dinner": [],
    "snacks": [],
  };

  Future<void> regenerate({
    required String name,
    required int steps,
    required int activeMinutes,
    required int calories,
    required String goal,
    required double bmi,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final plan = await AIService.generateDiet(
        name: name,
        steps: steps,
        activeMinutes: activeMinutes,
        calories: calories,
        goal: goal,
        bmi: bmi,
      );

      // AIService currently returns plain text; keep UI-model shape stable.
      diet = {
        "breakfast": [plan],
        "lunch": [],
        "dinner": [],
        "snacks": [],
      };
    } catch (e) {
      debugPrint("AI ERROR: $e");
    }

    isLoading = false;
    notifyListeners();
  }
}
