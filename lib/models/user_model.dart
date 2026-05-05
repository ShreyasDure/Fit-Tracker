class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "user" or "admin"
  final int points;
  final int level;
  final int streak;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.points = 0,
    this.level = 1,
    this.streak = 0,
    this.isActive = true,
  });

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

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    int? points,
    int? level,
    int? streak,
    bool? isActive,
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
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      points: map['points'] ?? 0,
      level: map['level'] ?? 1,
      streak: map['streak'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }
}
