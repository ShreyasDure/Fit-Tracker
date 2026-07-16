import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/constants.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/mongodb_service.dart';
import 'exercise_library_screen.dart';
import 'home_screen.dart';
import 'points_screen.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late AnimationController _hudController;

  bool get _isTesting {
    try {
      return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(vsync: this, duration: const Duration(seconds: 60));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _hudController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    if (!_isTesting) {
      _timerController.repeat();
      _pulseController.repeat(reverse: true);
      _hudController.repeat();
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    _hudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(workoutControllerProvider);
    final controller = ref.read(workoutControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Stack(
        children: [
          // 1. Futuristic Background HUD
          _buildBackgroundHUD(),
          
          SafeArea(
            child: Column(
              children: [
                // 2. Immersive Header
                _buildHeader(context, workout),
                
                // 3. Type Selector (Horizontal Pills)
                _buildTypeSelector(workout, controller),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        // 4. Circular Futuristic Timer
                        _buildFuturisticTimer(workout),
                        
                        const SizedBox(height: 40),
                        
                        // 5. Metrics Dashboard (Grid)
                        _buildMetricsGrid(workout),
                        
                        const SizedBox(height: 120), // Bottom controls padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 7. Floating Pill Controls
          _buildFloatingControls(workout, controller),
        ],
      ),
    );
  }

  Widget _buildBackgroundHUD() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF0A0A25), Color(0xFF050510)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _hudController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.03,
                child: CustomPaint(
                  painter: _HUDGridPainter(_hudController.value),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkoutState workout) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workout Hub',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workout.isActive ? 'Push Your Limits 🚀' : 'Ready To Start? 💪',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen())),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.menu_book_rounded, color: AppColors.neonPurple, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(WorkoutState workout, WorkoutController controller) {
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: WorkoutType.values.map((type) {
          final isSelected = workout.selectedType == type;
          final icons = {
            WorkoutType.run: Icons.directions_run_rounded,
            WorkoutType.walk: Icons.directions_walk_rounded,
            WorkoutType.bike: Icons.directions_bike_rounded,
            WorkoutType.gym: Icons.fitness_center_rounded,
          };
          final labels = {
            WorkoutType.run: 'RUN',
            WorkoutType.walk: 'WALK',
            WorkoutType.bike: 'BIKE',
            WorkoutType.gym: 'GYM',
          };
          return GestureDetector(
            onTap: () => controller.selectType(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonCyan.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.1), blurRadius: 10),
                ] : [],
              ),
              child: Row(
                children: [
                  Icon(icons[type], color: isSelected ? AppColors.neonCyan : Colors.white24, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    labels[type]!,
                    style: TextStyle(
                      color: isSelected ? AppColors.neonCyan : Colors.white24,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFuturisticTimer(WorkoutState workout) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Rings
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.05 * _pulseController.value),
                    width: 20,
                  ),
                ),
              );
            },
          ),
          // Animated Progress Ring
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: workout.isActive ? null : 1.0,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                workout.isActive ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Timer Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                workout.isActive ? 'ACTIVE MISSION' : 'SYSTEM STANDBY',
                style: TextStyle(
                  color: workout.isActive ? AppColors.neonGreen : Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                workout.formattedTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppColors.neonOrange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${(math.Random().nextInt(200) + 50)} KCAL',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(WorkoutState workout) {
    final metrics = workout.isGym ? [
      {'label': 'REPS', 'value': '${workout.reps}', 'icon': Icons.repeat_rounded, 'color': AppColors.neonCyan},
      {'label': 'SETS', 'value': '${workout.sets}', 'icon': Icons.layers_rounded, 'color': AppColors.neonGreen},
      {'label': 'WEIGHT', 'value': '${workout.weight}kg', 'icon': Icons.fitness_center_rounded, 'color': AppColors.neonOrange},
      {'label': 'HEART', 'value': '${workout.heartRate}bpm', 'icon': Icons.favorite_rounded, 'color': AppColors.neonPink},
    ] : [
      {'label': 'DISTANCE', 'value': '${workout.distance}km', 'icon': Icons.straighten_rounded, 'color': AppColors.neonCyan},
      {'label': 'PACE', 'value': '${workout.pace}', 'icon': Icons.speed_rounded, 'color': AppColors.neonGreen},
      {'label': 'CADENCE', 'value': '${workout.cadence}', 'icon': Icons.accessibility_new_rounded, 'color': AppColors.neonPurple},
      {'label': 'HEART', 'value': '${workout.heartRate}bpm', 'icon': Icons.favorite_rounded, 'color': AppColors.neonPink},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        final color = m['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(m['icon'] as IconData, color: color, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    m['label'] as String,
                    style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                m['value'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildFloatingControls(WorkoutState workout, WorkoutController controller) {
    return Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 10)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                // Reset Button
                _buildControlButton(
                  icon: Icons.refresh_rounded,
                  color: Colors.white38,
                  onTap: () => controller.reset(),
                ),
                // Main Start/Pause Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.toggleWorkout(),
                    child: Container(
                      height: 54,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: workout.isActive 
                            ? [AppColors.neonOrange, const Color(0xFFFF8C42)]
                            : [AppColors.neonCyan, AppColors.neonGreen],
                        ),
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: (workout.isActive ? AppColors.neonOrange : AppColors.neonCyan).withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(workout.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            workout.isActive ? 'PAUSE' : 'START WORKOUT',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Stop Button
                _buildControlButton(
                  icon: Icons.stop_rounded,
                  color: AppColors.error,
                  onTap: () {
                    if (workout.elapsedSeconds > 0) {
                      _showSaveWorkoutDialog(workout, controller);
                    } else {
                      controller.reset();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSaveWorkoutDialog(WorkoutState workout, WorkoutController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.neonCyan, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.neonYellow, size: 24),
              SizedBox(width: 8),
              Text('Workout Completed!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type: ${workout.selectedType.name.toUpperCase()}',
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Duration: ${workout.formattedDuration}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (!workout.isGym) ...[
                const SizedBox(height: 4),
                Text(
                  'Distance: ${workout.distance} km',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Avg Pace: ${workout.pace} min/km',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Calories burned: ${workout.calories} kcal',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Would you like to save this workout and claim your points?',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.reset();
              },
              child: const Text('Discard', style: TextStyle(color: AppColors.error)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        ),
                        SizedBox(width: 12),
                        Text('Saving workout to MongoDB...'),
                      ],
                    ),
                    backgroundColor: AppColors.neonCyan,
                    duration: Duration(seconds: 10),
                  ),
                );

                try {
                  final result = await MongoDbService.saveWorkout(
                    type: workout.selectedType.name,
                    duration: workout.elapsedSeconds,
                    distance: workout.distance,
                    calories: workout.calories,
                    heartRateAvg: workout.heartRate,
                    pace: workout.pace,
                  );

                  final pointsEarned = result['pointsEarned'] ?? 0;
                  
                  ref.invalidate(userActivitiesProvider);
                  ref.invalidate(workoutHistoryProvider);
                  await ref.read(authControllerProvider.notifier).refreshProfile();

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Workout saved! +$pointsEarned points earned!'),
                      backgroundColor: AppColors.neonGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save workout: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } finally {
                  controller.reset();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save & Finish', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _HUDGridPainter extends CustomPainter {
  final double animationValue;
  _HUDGridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.neonCyan..strokeWidth = 0.5;
    final spacing = 50.0;
    final offset = animationValue * spacing;
    
    for (double i = offset; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = offset; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
