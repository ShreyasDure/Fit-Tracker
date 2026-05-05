import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Workout State ───

enum WorkoutType { run, walk, bike, gym }

class WorkoutState {
  final WorkoutType selectedType;
  final bool isActive;
  final int elapsedSeconds;
  final double distance; // km
  final double pace; // min/km
  final int cadence; // steps/min
  final int heartRate; // bpm
  final int calories;
  // Gym-specific
  final int reps;
  final int sets;
  final double weight; // kg

  const WorkoutState({
    this.selectedType = WorkoutType.run,
    this.isActive = false,
    this.elapsedSeconds = 0,
    this.distance = 0.0,
    this.pace = 0.0,
    this.cadence = 0,
    this.heartRate = 0,
    this.calories = 0,
    this.reps = 0,
    this.sets = 0,
    this.weight = 0.0,
  });

  bool get isGym => selectedType == WorkoutType.gym;

  String get formattedTime {
    final mins = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String get formattedDuration {
    final mins = elapsedSeconds ~/ 60;
    return '$mins min';
  }

  WorkoutState copyWith({
    WorkoutType? selectedType,
    bool? isActive,
    int? elapsedSeconds,
    double? distance,
    double? pace,
    int? cadence,
    int? heartRate,
    int? calories,
    int? reps,
    int? sets,
    double? weight,
  }) {
    return WorkoutState(
      selectedType: selectedType ?? this.selectedType,
      isActive: isActive ?? this.isActive,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distance: distance ?? this.distance,
      pace: pace ?? this.pace,
      cadence: cadence ?? this.cadence,
      heartRate: heartRate ?? this.heartRate,
      calories: calories ?? this.calories,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      weight: weight ?? this.weight,
    );
  }
}

class WorkoutController extends StateNotifier<WorkoutState> {
  WorkoutController() : super(const WorkoutState());

  Timer? _timer;

  void selectType(WorkoutType type) {
    state = state.copyWith(selectedType: type);
  }

  void toggleWorkout() {
    if (state.isActive) {
      _stopWorkout();
    } else {
      _startWorkout();
    }
  }

  void _startWorkout() {
    state = state.copyWith(
      isActive: true,
      elapsedSeconds: 0,
      distance: 0,
      pace: 0,
      cadence: 0,
      heartRate: 72,
      calories: 0,
      reps: 0,
      sets: state.isGym ? 1 : 0,
      weight: state.isGym ? 20.0 : 0,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = state.elapsedSeconds + 1;

      if (state.isGym) {
        // Gym simulation: reps every 3 sec, sets every 30 sec
        final totalReps = (elapsed / 3).floor();
        final currentSets = (elapsed / 30).floor() + 1;
        final hr = 72 + (elapsed * 0.4).toInt().clamp(0, 80);
        final cal = (elapsed * 0.12).toInt();

        state = state.copyWith(
          elapsedSeconds: elapsed,
          heartRate: hr,
          calories: cal,
          reps: totalReps,
          sets: currentSets,
          weight: 20.0 + (currentSets * 2.5),
        );
      } else {
        // Running/Walk/Bike simulation
        final speedFactor = state.selectedType == WorkoutType.run
            ? 0.0028
            : state.selectedType == WorkoutType.bike
                ? 0.0055
                : 0.0014;
        final dist = elapsed * speedFactor;
        final hr = 72 + (elapsed * 0.5).toInt().clamp(0, 100);
        final cad = state.selectedType == WorkoutType.run
            ? 160 + (elapsed % 20)
            : state.selectedType == WorkoutType.walk
                ? 100 + (elapsed % 10)
                : 80 + (elapsed % 15);
        final cal = (elapsed * 0.15).toInt();
        final p = dist > 0 ? (elapsed / 60) / dist : 0.0;

        state = state.copyWith(
          elapsedSeconds: elapsed,
          distance: double.parse(dist.toStringAsFixed(2)),
          heartRate: hr,
          cadence: cad,
          calories: cal,
          pace: double.parse(p.toStringAsFixed(1)),
        );
      }
    });
  }

  void _stopWorkout() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isActive: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final workoutControllerProvider =
    StateNotifierProvider<WorkoutController, WorkoutState>((ref) {
  return WorkoutController();
});
