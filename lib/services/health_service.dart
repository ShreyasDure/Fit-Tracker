import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simulated health data service that produces realistic live-updating metrics.
/// Architecture is ready to swap to Google Fit / HealthKit.

class HealthData {
  final int steps;
  final int stepsGoal;
  final int calories;
  final int activeMinutes;
  final int heartRate;
  final double distance; // km

  const HealthData({
    this.steps = 0,
    this.stepsGoal = 10000,
    this.calories = 0,
    this.activeMinutes = 0,
    this.heartRate = 72,
    this.distance = 0.0,
  });

  double get stepsProgress => (steps / stepsGoal).clamp(0.0, 1.0);
  int get stepsPercent => (stepsProgress * 100).toInt();

  HealthData copyWith({
    int? steps,
    int? stepsGoal,
    int? calories,
    int? activeMinutes,
    int? heartRate,
    double? distance,
  }) {
    return HealthData(
      steps: steps ?? this.steps,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      calories: calories ?? this.calories,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      heartRate: heartRate ?? this.heartRate,
      distance: distance ?? this.distance,
    );
  }
}

class HealthController extends StateNotifier<HealthData> {
  HealthController() : super(const HealthData(
    steps: 6840,
    calories: 412,
    activeMinutes: 38,
    heartRate: 74,
    distance: 4.8,
  )) {
    _startSimulation();
  }

  Timer? _timer;
  final _random = Random();

  void _startSimulation() {
    // Update every 3 seconds to simulate live data
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final newSteps = state.steps + _random.nextInt(15) + 5;
      final newCal = (newSteps * 0.06).toInt();
      final newActive = (newSteps / 180).toInt();
      final newDist = double.parse((newSteps * 0.0007).toStringAsFixed(1));
      final newHr = 68 + _random.nextInt(16); // 68-83 bpm resting range

      state = state.copyWith(
        steps: newSteps,
        calories: newCal,
        activeMinutes: newActive,
        heartRate: newHr,
        distance: newDist,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final healthControllerProvider =
    StateNotifierProvider<HealthController, HealthData>((ref) {
  return HealthController();
});
