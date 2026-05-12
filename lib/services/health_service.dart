import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mongodb_service.dart';

// ─── Health Data Model ───
class HealthData {
  final int steps;
  final int stepsGoal;
  final int calories;
  final int activeMinutes;
  final int heartRate;
  final double distance;
  final List<String> unlockedBadges;
  final int weeklyAverageSteps;
  final int previousWeeklyAverageSteps;
  final double weeklyPercentageChange;

  const HealthData({
    this.steps = 0,
    this.stepsGoal = 10000,
    this.calories = 0,
    this.activeMinutes = 0,
    this.heartRate = 0,
    this.distance = 0.0,
    this.unlockedBadges = const [],
    this.weeklyAverageSteps = 0,
    this.previousWeeklyAverageSteps = 0,
    this.weeklyPercentageChange = 0,
  });

  double get stepsProgress => (steps / stepsGoal).clamp(0.0, 1.0);
  int get stepsPercent => (stepsProgress * 100).toInt();

  HealthData copyWith({
    int? steps, int? stepsGoal, int? calories,
    int? activeMinutes, int? heartRate, double? distance,
    List<String>? unlockedBadges,
    int? weeklyAverageSteps,
    int? previousWeeklyAverageSteps,
    double? weeklyPercentageChange,
  }) {
    return HealthData(
      steps: steps ?? this.steps,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      calories: calories ?? this.calories,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      heartRate: heartRate ?? this.heartRate,
      distance: distance ?? this.distance,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      weeklyAverageSteps: weeklyAverageSteps ?? this.weeklyAverageSteps,
      previousWeeklyAverageSteps: previousWeeklyAverageSteps ?? this.previousWeeklyAverageSteps,
      weeklyPercentageChange: weeklyPercentageChange ?? this.weeklyPercentageChange,
    );
  }
}

// ─── SharedPreferences Keys ───
const _kSteps = 'health_steps';
const _kCalories = 'health_calories';
const _kActive = 'health_active';
const _kHr = 'health_hr';
const _kDate = 'health_date';
const _kInitialSteps = 'health_initial_steps';

class HealthController extends StateNotifier<HealthData> {
  HealthController() : super(const HealthData()) {
    _init();
  }

  StreamSubscription<StepCount>? _stepCountStream;
  Timer? _syncTimer;
  Timer? _simTimer;
  Timer? _activeMinTimer;
  int _lastMinuteSteps = 0;
  final _random = Random();
  bool _isTracking = false;
  int _initialSteps = -1;
  String _currentDate = _formatDate(DateTime.now());
  SharedPreferences? _prefs;

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromLocal();
    // Prioritize sensor over backend to avoid resets/lags reported by user
    _startPedometer();
    await _loadWeeklySummary();
    // Background sync cadence (15 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) => _syncWithBackend());
    // Active minutes tracker (every 1 minute)
    _activeMinTimer = Timer.periodic(const Duration(minutes: 1), _checkActiveMinutes);
  }

  void onAppResume() {
    _loadFromBackend();
    _loadWeeklySummary();
    _syncWithBackend();
  }

  Future<void> _loadWeeklySummary() async {
    try {
      final weekly = await MongoDbService.getWeeklyHealthSummary();
      if (weekly == null) return;
      state = state.copyWith(
        weeklyAverageSteps: (weekly['averageSteps'] as num?)?.toInt() ?? 0,
        previousWeeklyAverageSteps: (weekly['previousAverageSteps'] as num?)?.toInt() ?? 0,
        weeklyPercentageChange: (weekly['percentageChange'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      // Keep UI on existing values when weekly analytics cannot be loaded.
    }
  }

  // ─── Active Minutes Logic ───
  void _checkActiveMinutes(Timer timer) {
    if (!mounted) return;
    final stepsThisMinute = state.steps - _lastMinuteSteps;
    if (stepsThisMinute > 15) { // Threshold: > 15 steps per min = active
      state = state.copyWith(activeMinutes: state.activeMinutes + 1);
      _saveToLocal();
    }
    _lastMinuteSteps = state.steps;
  }

  // ─── Load from SharedPreferences ───
  Future<void> _loadFromLocal() async {
    final prefs = _prefs!;
    final savedDate = prefs.getString(_kDate) ?? '';
    final today = _formatDate(DateTime.now());

    if (savedDate != today) {
      // New day — reset local data
      await _clearLocal();
      return;
    }

    final steps = prefs.getInt(_kSteps) ?? 0;
    final calories = prefs.getInt(_kCalories) ?? 0;
    final active = prefs.getInt(_kActive) ?? 0;
    final hr = prefs.getInt(_kHr) ?? 0;
    _initialSteps = prefs.getInt(_kInitialSteps) ?? -1;
    final dist = double.parse((steps * 0.0007).toStringAsFixed(1));

    state = state.copyWith(steps: steps, calories: calories, activeMinutes: active, heartRate: hr, distance: dist);
    _lastMinuteSteps = steps;
  }

  // ─── Load from Backend ───
  Future<void> _loadFromBackend() async {
    try {
      final data = await MongoDbService.getTodayHealth();
      if (data != null) {
        // We only use backend HR and other fields if they are not 0.
        // We DO NOT overwrite steps if local is already tracking higher.
        final backendHr = (data['heartRate'] as num?)?.toInt() ?? 0;
        if (backendHr > 0 && state.heartRate == 0) {
          state = state.copyWith(heartRate: backendHr);
        }
      }
    } catch (_) {}
  }

  // ─── Save to SharedPreferences ───
  Future<void> _saveToLocal() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_kDate, _formatDate(DateTime.now()));
    await prefs.setInt(_kSteps, state.steps);
    await prefs.setInt(_kCalories, state.calories);
    await prefs.setInt(_kActive, state.activeMinutes);
    await prefs.setInt(_kHr, state.heartRate);
    await prefs.setInt(_kInitialSteps, _initialSteps);
  }

  Future<void> _clearLocal() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_kDate, _formatDate(DateTime.now()));
    await prefs.setInt(_kSteps, 0);
    await prefs.setInt(_kCalories, 0);
    await prefs.setInt(_kActive, 0);
    await prefs.setInt(_kHr, 0);
    await prefs.setInt(_kInitialSteps, -1);
  }

  // ─── Pedometer ───
  Future<void> _startPedometer() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (e) {
          debugPrint('Pedometer Error: $e');
        },
      );
    }
  }

  void _onStepCount(StepCount event) {
    _checkDayRollover();
    
    // Initial value capture on app start
    if (_initialSteps == -1) {
      _initialSteps = event.steps;
      _saveToLocal();
      return;
    }

    // Difference-based counting
    final sessionDelta = event.steps - _initialSteps;
    
    if (sessionDelta > 0) {
      // Filtering: Ignore micro-movements/noise (request: threshold 2)
      if (sessionDelta < 2) return;

      // Update metrics BEFORE updating baseline to ensure delta is processed correctly
      _updateMetricsFromSession(sessionDelta);
      
      // Update baseline after processing to avoid double-adding on next event
      _initialSteps = event.steps;
      _saveToLocal();
    } else if (sessionDelta < 0) {
      // Sensor reset (e.g. phone rebooted or large negative jump)
      _initialSteps = event.steps;
      _saveToLocal();
    }
  }

  void _updateMetricsFromSession(int delta) {
    final newSteps = state.steps + delta;
    final newCal = (newSteps * 0.04).toInt();
    final newDist = double.parse((newSteps * 0.0007).toStringAsFixed(1));
    final newHr = state.heartRate > 0 ? state.heartRate : (65 + _random.nextInt(15));

    state = state.copyWith(
      steps: newSteps,
      calories: newCal,
      distance: newDist,
      heartRate: newHr,
    );
    // Save locally
    _saveToLocal();
  }

  void _checkDayRollover() {
    final today = _formatDate(DateTime.now());
    if (today != _currentDate) {
      _currentDate = today;
      resetToday();
    }
  }

  // ─── Backend Sync ───
  Future<void> sync() async {
    await _syncWithBackend();
    await _loadWeeklySummary();
  }

  Future<void> _syncWithBackend() async {
    _checkDayRollover();
    try {
      final res = await MongoDbService.syncHealthData(
        steps: state.steps,
        calories: state.calories,
        activeMinutes: state.activeMinutes,
        heartRate: state.heartRate,
        date: _currentDate,
      );
      final List<String> badges = [];
      if (res['badges'] != null) {
        for (var b in res['badges']) {
          badges.add(b['badgeName'] as String);
        }
      }
      if (badges.isNotEmpty) {
        state = state.copyWith(unlockedBadges: badges);
      }
      await _loadWeeklySummary();
    } catch (_) {
      // Sync failed silently — data is safe in local storage
    }
  }

  /// Force sync (called on app background / logout)
  Future<void> forceSync() async {
    await _saveToLocal();
    await _syncWithBackend();
  }

  /// Start simulation tracking (workout mode / fallback when no pedometer)
  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkDayRollover();
      final delta = _random.nextInt(5) + 2;
      _updateMetricsFromSession(delta);
    });
  }

  void stopTracking() {
    _isTracking = false;
    _simTimer?.cancel();
  }

  bool get isTracking => _isTracking;

  Future<void> resetToday() async {
    state = state.copyWith(steps: 0, calories: 0, activeMinutes: 0, heartRate: 0, distance: 0.0);
    _initialSteps = -1;
    _lastMinuteSteps = 0;
    await _clearLocal();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    _syncTimer?.cancel();
    _simTimer?.cancel();
    _activeMinTimer?.cancel();
    super.dispose();
  }
}

final healthControllerProvider = StateNotifierProvider<HealthController, HealthData>((ref) {
  return HealthController();
});
