import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/login_screen.dart';
import 'controllers/auth_controller.dart';
import 'user/user_shell.dart';
import 'admin/admin_shell.dart';
import 'user/settings_screen.dart';
import 'user/notification_permission_screen.dart';
import 'user/workout_screen.dart';
import 'user/ai_screen.dart';
import 'user/nutrition_screen.dart';
import 'user/challenges_screen.dart';
import 'user/social_screen.dart';
import 'user/points_screen.dart';
import 'user/stats_screen.dart';
import 'user/health_screen.dart';
import 'user/profile_screen.dart';

// Track if notification permission has been shown
final notifPermissionShownProvider = StateProvider<bool>((ref) => false);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FitTrackerApp()));
}

class FitTrackerApp extends ConsumerWidget {
  const FitTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeProvider);
    final notifShown = ref.watch(notifPermissionShownProvider);

    return MaterialApp(
      title: 'FitTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routes: {
        '/workouts': (context) => const WorkoutScreen(),
        '/ai': (context) => const AiScreen(),
        '/nutrition': (context) => const NutritionScreen(),
        '/challenges': (context) => const ChallengesScreen(),
        '/social': (context) => const SocialScreen(),
        '/points': (context) => const PointsScreen(),
        '/stats': (context) => const StatsScreen(),
        '/health': (context) => const HealthScreen(),
        '/bmi': (context) => const HealthScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      home: _buildHome(authState, notifShown, ref),
    );
  }

  Widget _buildHome(AuthState authState, bool notifShown, WidgetRef ref) {
    switch (authState.status) {
      case AuthStatus.authenticated:
        if (authState.user?.role == 'admin') {
          return const AdminShell();
        }
        // Show notification permission screen on first login
        if (!notifShown) {
          return NotificationPermissionScreen(
            onAllow: () {
              ref.read(notifPermissionShownProvider.notifier).state = true;
              // TODO: Request actual notification permission here
            },
            onSkip: () {
              ref.read(notifPermissionShownProvider.notifier).state = true;
            },
          );
        }
        return const UserShell();
      case AuthStatus.unauthenticated:
      case AuthStatus.initial:
        return const LoginScreen();
    }
  }
}
