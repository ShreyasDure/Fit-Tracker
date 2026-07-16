import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/points_config.dart';
import '../services/mongodb_service.dart';

// ─── Admin State ───

class AdminDashboardState {
  final List<UserModel> users;
  final PointsConfig pointsConfig;
  final LevelsConfig levelsConfig;
  final List<PremiumPlan> premiumPlans;
  final Map<String, dynamic> liveAnalytics;
  final List<Map<String, dynamic>> activityLogs;
  final bool isLoading;
  final String? error;

  const AdminDashboardState({
    this.users = const [],
    this.pointsConfig = const PointsConfig(),
    this.levelsConfig = const LevelsConfig(),
    this.premiumPlans = const [],
    this.liveAnalytics = const {},
    this.activityLogs = const [],
    this.isLoading = false,
    this.error,
  });

  int get totalUsers => (liveAnalytics['totalUsers'] as num?)?.toInt() ?? users.length;
  int get activeUsers => (liveAnalytics['activeUsers'] as num?)?.toInt() ?? 0;
  int get premiumUsers => (liveAnalytics['premiumUsers'] as num?)?.toInt() ?? 0;
  int get totalPoints => (liveAnalytics['totalPoints'] as num?)?.toInt() ?? 0;

  AdminDashboardState copyWith({
    List<UserModel>? users,
    PointsConfig? pointsConfig,
    LevelsConfig? levelsConfig,
    Map<String, dynamic>? liveAnalytics,
    List<Map<String, dynamic>>? activityLogs,
    List<PremiumPlan>? premiumPlans,
    bool? isLoading,
    String? error,
  }) {
    return AdminDashboardState(
      users: users ?? this.users,
      pointsConfig: pointsConfig ?? this.pointsConfig,
      levelsConfig: levelsConfig ?? this.levelsConfig,
      premiumPlans: premiumPlans ?? this.premiumPlans,
      liveAnalytics: liveAnalytics ?? this.liveAnalytics,
      activityLogs: activityLogs ?? this.activityLogs,
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

  // ignore: unused_field
  final Ref _ref;

  DateTime? _startDate;
  DateTime? _endDate;

  bool get hasDateFilter => _startDate != null || _endDate != null;

  void setDateFilter(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    _loadFromBackend();
  }

  void clearDateFilter() {
    _startDate = null;
    _endDate = null;
    _loadFromBackend();
  }

  Future<void> deleteUser(String userId) async {
    try {
      await MongoDbService.deleteUser(userId);
      _loadFromBackend();
    } catch (_) {}
  }

  /// Load real users from MongoDB backend
  Future<void> _loadFromBackend() async {
    if (!MongoDbService.isAuthenticated) {
      state = state.copyWith(error: 'Not authenticated — token not set. Try logging in again.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final usersData = await MongoDbService.getUsers(startDate: _startDate, endDate: _endDate);
      final users = usersData.map((u) {
        if (u['_id'] != null && u['id'] == null) {
          u['id'] = u['_id'].toString();
        }
        return UserModel.fromMap(u);
      }).toList();
      
      final analytics = await MongoDbService.getAdminAnalytics();
      final logs = await MongoDbService.getAdminActivity();

      // Load saved settings from MongoDB
      final savedSettings = await MongoDbService.getLevelSettings();
      final loadedLevels = LevelsConfig.fromMap(savedSettings);

      state = state.copyWith(
        users: users,
        liveAnalytics: analytics,
        activityLogs: logs,
        levelsConfig: loadedLevels,
        isLoading: false,
        error: users.isEmpty ? 'No users registered yet.' : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Refresh everything
  Future<void> refreshAll() async => _loadFromBackend();

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

  void toggleUserActive(String userId, [String reason = '']) async {
    final users = state.users.map((u) {
      if (u.id == userId) return u.copyWith(isActive: !u.isActive);
      return u;
    }).toList();
    state = state.copyWith(users: users);
    try { 
      await MongoDbService.toggleUserActive(userId, reason: reason);
      refreshAll(); 
    } catch (_) {}
  }

  Future<void> massRewardUsers({
    required List<String> userIds,
    required String achievement,
    required int points,
    int xpBonus = 0,
  }) async {
    try {
      await MongoDbService.rewardUsers(
        userIds: userIds,
        achievementName: achievement,
        points: points,
        xpBonus: xpBonus,
      );
      refreshAll();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createChallenge({
    required String title,
    required String description,
    required String difficulty,
    required int reward,
    required double target,
    required String type,
    int durationDays = 7,
  }) async {
    try {
      await MongoDbService.createAdminChallenge(
        title: title,
        description: description,
        difficulty: difficulty,
        reward: reward,
        target: target,
        type: type,
        durationDays: durationDays,
      );
      refreshAll();
    } catch (e) {
      rethrow;
    }
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
