import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../controllers/user_controller.dart';
import '../widgets/stat_card.dart';
import 'exercise_library_screen.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutControllerProvider);
    final controller = ref.read(workoutControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Workout', style: Theme.of(context).textTheme.displayMedium)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.sm),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_rounded, color: AppColors.neonPurple, size: 16),
                          SizedBox(width: 4),
                          Text('Exercises', style: TextStyle(color: AppColors.neonPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              // Activity selector
              Row(
                children: WorkoutType.values.map((type) {
                  final isSelected = workout.selectedType == type;
                  final icons = {
                    WorkoutType.run: Icons.directions_run_rounded,
                    WorkoutType.walk: Icons.directions_walk_rounded,
                    WorkoutType.bike: Icons.directions_bike_rounded,
                    WorkoutType.gym: Icons.fitness_center_rounded,
                  };
                  final labels = {
                    WorkoutType.run: 'Run',
                    WorkoutType.walk: 'Walk',
                    WorkoutType.bike: 'Bike',
                    WorkoutType.gym: 'Gym',
                  };
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectType(type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.neonCyan.withValues(alpha: 0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                          border: Border.all(
                            color: isSelected ? AppColors.neonCyan : AppColors.surfaceLighter,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(icons[type], color: isSelected ? AppColors.neonCyan : AppColors.textMuted, size: 24),
                            const SizedBox(height: 4),
                            Text(labels[type]!, style: TextStyle(color: isSelected ? AppColors.neonCyan : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.xl),
              // Timer display
              Center(
                child: Column(
                  children: [
                    Text(workout.formattedTime, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 56, fontWeight: FontWeight.w900, color: workout.isActive ? AppColors.neonCyan : AppColors.textPrimary, letterSpacing: 4)),
                    const SizedBox(height: 4),
                    Text(workout.isActive ? 'In Progress' : 'Ready', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: workout.isActive ? AppColors.neonGreen : AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              // Mode-specific metrics
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSizes.sm,
                  crossAxisSpacing: AppSizes.sm,
                  childAspectRatio: 1.6,
                  children: workout.isGym ? _gymMetrics(workout) : _cardioMetrics(workout),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 64, height: 64,
        child: FloatingActionButton(
          onPressed: () => controller.toggleWorkout(),
          backgroundColor: workout.isActive ? AppColors.error : AppColors.neonCyan,
          shape: const CircleBorder(),
          child: Icon(workout.isActive ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Widget> _cardioMetrics(WorkoutState w) {
    return [
      GlowingStatCard(title: 'Distance', value: '${w.distance} km', icon: Icons.straighten_rounded, accentColor: AppColors.neonCyan),
      GlowingStatCard(title: 'Pace', value: '${w.pace} min/km', icon: Icons.speed_rounded, accentColor: AppColors.neonGreen),
      GlowingStatCard(title: 'Cadence', value: '${w.cadence} spm', icon: Icons.accessibility_new_rounded, accentColor: AppColors.neonPurple),
      GlowingStatCard(title: 'Heart Rate', value: '${w.heartRate} bpm', icon: Icons.favorite_rounded, accentColor: AppColors.neonPink),
    ];
  }

  List<Widget> _gymMetrics(WorkoutState w) {
    return [
      GlowingStatCard(title: 'Reps', value: '${w.reps}', icon: Icons.repeat_rounded, accentColor: AppColors.neonCyan),
      GlowingStatCard(title: 'Sets', value: '${w.sets}', icon: Icons.layers_rounded, accentColor: AppColors.neonGreen),
      GlowingStatCard(title: 'Weight', value: '${w.weight.toStringAsFixed(1)} kg', icon: Icons.fitness_center_rounded, accentColor: AppColors.neonOrange),
      GlowingStatCard(title: 'Heart Rate', value: '${w.heartRate} bpm', icon: Icons.favorite_rounded, accentColor: AppColors.neonPink),
    ];
  }
}
