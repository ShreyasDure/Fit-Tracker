class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "user" or "admin"
  final int points;
  final int level;
  final int streak;
  final bool isActive;
  final bool pushNotifications;
  final bool emailReminders;
  final bool isOnline;
  final DateTime? lastActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.points = 0,
    this.level = 1,
    this.streak = 0,
    this.isActive = true,
    this.pushNotifications = true,
    this.emailReminders = true,
    this.isOnline = false,
    this.lastActive,
  });

  // ── Static thresholds (backward compat fallbacks) ──
  String get levelName {
    if (points >= 5000) return 'Gold';
    if (points >= 2000) return 'Silver';
    return 'Bronze';
  }

  double get levelProgress {
    if (points >= 5000) return 1.0;
    if (points >= 2000) return (points - 2000) / 3000;
    return points / 2000;
  }

  int get pointsToNextLevel {
    if (points >= 5000) return 0;
    if (points >= 2000) return 5000 - points;
    return 2000 - points;
  }

  // ── Dynamic threshold-aware methods (uses MongoDB settings) ──

  String levelNameWith(int silverMin, int goldMin) {
    if (points >= goldMin) return 'Gold';
    if (points >= silverMin) return 'Silver';
    return 'Bronze';
  }

  double levelProgressWith(int silverMin, int goldMin) {
    if (points >= goldMin) return 1.0;
    if (points >= silverMin) return (points - silverMin) / (goldMin - silverMin);
    return silverMin > 0 ? points / silverMin : 0.0;
  }

  int pointsToNextLevelWith(int silverMin, int goldMin) {
    if (points >= goldMin) return 0;
    if (points >= silverMin) return goldMin - points;
    return silverMin - points;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    int? points,
    int? level,
    int? streak,
    bool? isActive,
    bool? pushNotifications,
    bool? emailReminders,
    bool? isOnline,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      points: points ?? this.points,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      isActive: isActive ?? this.isActive,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailReminders: emailReminders ?? this.emailReminders,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'points': points,
      'level': level,
      'streak': streak,
      'isActive': isActive,
      'pushNotifications': pushNotifications,
      'emailReminders': emailReminders,
      'isOnline': isOnline,
      'lastActive': lastActive?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      points: (map['points'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
      pushNotifications: map['pushNotifications'] ?? true,
      emailReminders: map['emailReminders'] ?? true,
      isOnline: map['isOnline'] ?? false,
      lastActive: map['lastActive'] != null ? DateTime.tryParse(map['lastActive']) : null,
    );
  }
}
