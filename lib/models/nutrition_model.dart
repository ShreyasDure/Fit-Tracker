class NutritionItem {
  final String name;
  final double calories;
  final double servingSize; // grams
  final double totalFat;
  final double saturatedFat;
  final double protein;
  final double sodium; // mg
  final double potassium; // mg
  final double cholesterol; // mg
  final double carbohydrates;
  final double fiber;
  final double sugar;

  const NutritionItem({
    required this.name,
    required this.calories,
    this.servingSize = 0,
    this.totalFat = 0,
    this.saturatedFat = 0,
    this.protein = 0,
    this.sodium = 0,
    this.potassium = 0,
    this.cholesterol = 0,
    this.carbohydrates = 0,
    this.fiber = 0,
    this.sugar = 0,
  });

  factory NutritionItem.fromJson(Map<String, dynamic> json) {
    return NutritionItem(
      name: json['name'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      servingSize: (json['serving_size_g'] ?? 0).toDouble(),
      totalFat: (json['fat_total_g'] ?? 0).toDouble(),
      saturatedFat: (json['fat_saturated_g'] ?? 0).toDouble(),
      protein: (json['protein_g'] ?? 0).toDouble(),
      sodium: (json['sodium_mg'] ?? 0).toDouble(),
      potassium: (json['potassium_mg'] ?? 0).toDouble(),
      cholesterol: (json['cholesterol_mg'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates_total_g'] ?? 0).toDouble(),
      fiber: (json['fiber_g'] ?? 0).toDouble(),
      sugar: (json['sugar_g'] ?? 0).toDouble(),
    );
  }
}
