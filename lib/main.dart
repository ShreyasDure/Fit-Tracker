import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/login_screen.dart';
import 'controllers/auth_controller.dart';
import 'user/user_shell.dart';
import 'admin/admin_shell.dart';
import 'user/settings_screen.dart';

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

    return MaterialApp(
      title: 'FitTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.authenticated:
        if (authState.user?.role == 'admin') {
          return const AdminShell();
        }
        return const UserShell();
      case AuthStatus.unauthenticated:
      case AuthStatus.initial:
        return const LoginScreen();
    }
  }
}
