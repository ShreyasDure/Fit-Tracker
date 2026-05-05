import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/points_config.dart';
import '../services/mongodb_service.dart';
import 'auth_controller.dart';

// ─── Admin State ───

class AdminDashboardState {
  final List<UserModel> users;
  final PointsConfig pointsConfig;
  final LevelsConfig levelsConfig;
  final List<PremiumPlan> premiumPlans;
  final bool isLoading;
  final String? error;

  const AdminDashboardState({
    this.users = const [],
    this.pointsConfig = const PointsConfig(),
    this.levelsConfig = const LevelsConfig(),
    this.premiumPlans = const [],
    this.isLoading = false,
    this.error,
  });

  int get totalUsers => users.length;
  int get activeUsers => users.where((u) => u.isActive).length;
  int get premiumUsers => users.where((u) => u.points >= 5000).length;
  int get totalPoints => users.fold(0, (sum, u) => sum + u.points);

  AdminDashboardState copyWith({
    List<UserModel>? users,
    PointsConfig? pointsConfig,
    LevelsConfig? levelsConfig,
    List<PremiumPlan>? premiumPlans,
    bool? isLoading,
    String? error,
  }) {
    return AdminDashboardState(
      users: users ?? this.users,
      pointsConfig: pointsConfig ?? this.pointsConfig,
      levelsConfig: levelsConfig ?? this.levelsConfig,
      premiumPlans: premiumPlans ?? this.premiumPlans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminController extends StateNotifier<AdminDashboardState> {
  AdminController(this._ref) : super(const AdminDashboardState(
    premiumPlans: [
      PremiumPlan(name: 'Weekly', days: 7, pointsRequired: 500),
      PremiumPlan(name: 'Monthly', days: 30, pointsRequired: 1500),
      PremiumPlan(name: 'Quarterly', days: 90, pointsRequired: 3500),
    ],
  )) {
    // Wait a moment for token to be ready, then load
    Future.delayed(const Duration(milliseconds: 500), () => _loadFromBackend());
  }

  final Ref _ref;

  /// Load real users from MongoDB backend
  Future<void> _loadFromBackend() async {
    if (!MongoDbService.isAuthenticated) {
      state = state.copyWith(error: 'Not authenticated — token not set. Try logging in again.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final usersData = await MongoDbService.getUsers();
      final users = usersData.map((u) {
        if (u['_id'] != null && u['id'] == null) {
          u['id'] = u['_id'].toString();
        }
        return UserModel.fromMap(u);
      }).toList();
      state = state.copyWith(
        users: users,
        isLoading: false,
        error: users.isEmpty ? 'No users registered yet. Register a user account first!' : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Refresh users from database
  Future<void> refreshUsers() async => _loadFromBackend();

  void addPoints(String userId, int amount) async {
    final users = state.users.map((u) {
      if (u.id == userId) return u.copyWith(points: u.points + amount);
      return u;
    }).toList();
    state = state.copyWith(users: users);
    try { await MongoDbService.updateUserPoints(userId, amount); } catch (_) {}
  }

  void removePoints(String userId, int amount) async {
    final users = state.users.map((u) {
      if (u.id == userId) return u.copyWith(points: (u.points - amount).clamp(0, 999999));
      return u;
    }).toList();
    state = state.copyWith(users: users);
    try { await MongoDbService.updateUserPoints(userId, -amount); } catch (_) {}
  }

  void toggleUserActive(String userId) async {
    final users = state.users.map((u) {
      if (u.id == userId) return u.copyWith(isActive: !u.isActive);
      return u;
    }).toList();
    state = state.copyWith(users: users);
    try { await MongoDbService.toggleUserActive(userId); } catch (_) {}
  }

  void updatePointsConfig(PointsConfig config) {
    state = state.copyWith(pointsConfig: config);
    _saveSettings();
  }

  void updateLevelsConfig(LevelsConfig config) {
    state = state.copyWith(levelsConfig: config);
    _saveSettings();
  }

  void updatePremiumPlan(int index, PremiumPlan plan) {
    final plans = List<PremiumPlan>.from(state.premiumPlans);
    plans[index] = plan;
    state = state.copyWith(premiumPlans: plans);
    _saveSettings();
  }

  void togglePremiumPlan(int index) {
    final plans = List<PremiumPlan>.from(state.premiumPlans);
    plans[index] = plans[index].copyWith(isEnabled: !plans[index].isEnabled);
    state = state.copyWith(premiumPlans: plans);
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      await MongoDbService.updateSettings({
        'pointsPerMinute': state.pointsConfig.pointsPerMinute,
        'streakBonus': state.pointsConfig.streakBonus,
        'bonusMultiplier': state.pointsConfig.bonusMultiplier,
        'dailyEarningLimit': state.pointsConfig.dailyEarningLimit,
        'silverMinPoints': state.levelsConfig.silverMinPoints,
        'goldMinPoints': state.levelsConfig.goldMinPoints,
        'bronzeBenefits': state.levelsConfig.bronzeBenefits,
        'silverBenefits': state.levelsConfig.silverBenefits,
        'goldBenefits': state.levelsConfig.goldBenefits,
        'premiumPlans': state.premiumPlans.map((p) => p.toMap()).toList(),
      });
    } catch (_) {}
  }
}

final adminControllerProvider =
    StateNotifierProvider<AdminController, AdminDashboardState>((ref) {
  return AdminController(ref);
});
