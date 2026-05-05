class PointsConfig {
  final double pointsPerMinute;
  final double streakBonus;
  final double bonusMultiplier;
  final int dailyEarningLimit;

  const PointsConfig({
    this.pointsPerMinute = 2.0,
    this.streakBonus = 50.0,
    this.bonusMultiplier = 1.5,
    this.dailyEarningLimit = 500,
  });

  PointsConfig copyWith({
    double? pointsPerMinute,
    double? streakBonus,
    double? bonusMultiplier,
    int? dailyEarningLimit,
  }) {
    return PointsConfig(
      pointsPerMinute: pointsPerMinute ?? this.pointsPerMinute,
      streakBonus: streakBonus ?? this.streakBonus,
      bonusMultiplier: bonusMultiplier ?? this.bonusMultiplier,
      dailyEarningLimit: dailyEarningLimit ?? this.dailyEarningLimit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pointsPerMinute': pointsPerMinute,
      'streakBonus': streakBonus,
      'bonusMultiplier': bonusMultiplier,
      'dailyEarningLimit': dailyEarningLimit,
    };
  }

  factory PointsConfig.fromMap(Map<String, dynamic> map) {
    return PointsConfig(
      pointsPerMinute: (map['pointsPerMinute'] ?? 2.0).toDouble(),
      streakBonus: (map['streakBonus'] ?? 50.0).toDouble(),
      bonusMultiplier: (map['bonusMultiplier'] ?? 1.5).toDouble(),
      dailyEarningLimit: map['dailyEarningLimit'] ?? 500,
    );
  }
}

class LevelsConfig {
  final int silverMinPoints;
  final int goldMinPoints;
  final String bronzeBenefits;
  final String silverBenefits;
  final String goldBenefits;

  const LevelsConfig({
    this.silverMinPoints = 2000,
    this.goldMinPoints = 5000,
    this.bronzeBenefits = 'Basic tracking, Community access',
    this.silverBenefits = 'AI insights, Priority support',
    this.goldBenefits = 'All features, Custom plans, 2x points',
  });

  LevelsConfig copyWith({
    int? silverMinPoints,
    int? goldMinPoints,
    String? bronzeBenefits,
    String? silverBenefits,
    String? goldBenefits,
  }) {
    return LevelsConfig(
      silverMinPoints: silverMinPoints ?? this.silverMinPoints,
      goldMinPoints: goldMinPoints ?? this.goldMinPoints,
      bronzeBenefits: bronzeBenefits ?? this.bronzeBenefits,
      silverBenefits: silverBenefits ?? this.silverBenefits,
      goldBenefits: goldBenefits ?? this.goldBenefits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'silverMinPoints': silverMinPoints,
      'goldMinPoints': goldMinPoints,
      'bronzeBenefits': bronzeBenefits,
      'silverBenefits': silverBenefits,
      'goldBenefits': goldBenefits,
    };
  }

  factory LevelsConfig.fromMap(Map<String, dynamic> map) {
    return LevelsConfig(
      silverMinPoints: map['silverMinPoints'] ?? 2000,
      goldMinPoints: map['goldMinPoints'] ?? 5000,
      bronzeBenefits: map['bronzeBenefits'] ?? 'Basic tracking, Community access',
      silverBenefits: map['silverBenefits'] ?? 'AI insights, Priority support',
      goldBenefits: map['goldBenefits'] ?? 'All features, Custom plans, 2x points',
    );
  }
}

class PremiumPlan {
  final String name;
  final int days;
  final int pointsRequired;
  final bool isEnabled;

  const PremiumPlan({
    required this.name,
    required this.days,
    required this.pointsRequired,
    this.isEnabled = true,
  });

  PremiumPlan copyWith({
    String? name,
    int? days,
    int? pointsRequired,
    bool? isEnabled,
  }) {
    return PremiumPlan(
      name: name ?? this.name,
      days: days ?? this.days,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'days': days,
      'pointsRequired': pointsRequired,
      'isEnabled': isEnabled,
    };
  }

  factory PremiumPlan.fromMap(Map<String, dynamic> map) {
    return PremiumPlan(
      name: map['name'] ?? '',
      days: map['days'] ?? 0,
      pointsRequired: map['pointsRequired'] ?? 0,
      isEnabled: map['isEnabled'] ?? true,
    );
  }
}
