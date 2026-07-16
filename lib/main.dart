import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'core/login_screen.dart';
import 'controllers/auth_controller.dart';
import 'services/mongodb_service.dart';
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

class FitTrackerApp extends ConsumerStatefulWidget {
  const FitTrackerApp({super.key});

  @override
  ConsumerState<FitTrackerApp> createState() => _FitTrackerAppState();
}

class _FitTrackerAppState extends ConsumerState<FitTrackerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ping to set online status if already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOnlineStatus(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive || 
               state == AppLifecycleState.detached) {
      _syncOnlineStatus(false);
    }
  }

  void _syncOnlineStatus(bool isOnline) {
    final authState = ref.read(authControllerProvider);
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      MongoDbService.updateOnlineStatus(isOnline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeProvider);
    final notifShown = ref.watch(notifPermissionShownProvider);

    return MaterialApp(
      title: 'FitTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Localization delegates — required for en_GB date picker (dd/mm/yyyy)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'GB'), // British English — dd/mm/yyyy
        Locale('en', 'US'),
      ],
      locale: const Locale('en', 'GB'),
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
        '/admin': (context) => Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authControllerProvider);
            if (authState.user?.role == 'admin') {
              return const AdminShell();
            } else {
              return const UserShell();
            }
          },
        ),
      },
      home: _buildHome(authState, notifShown),
    );
  }

  Widget _buildHome(AuthState authState, bool notifShown) {
    switch (authState.status) {
      case AuthStatus.authenticated:
        // Set online status when transitioning to authenticated state
        MongoDbService.updateOnlineStatus(true);
        if (authState.user?.role == 'admin') {
          return const AdminShell();
        }
        // Show notification permission screen on first login
        if (!notifShown) {
          return NotificationPermissionScreen(
            onAllow: () {
              ref.read(notifPermissionShownProvider.notifier).state = true;
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
