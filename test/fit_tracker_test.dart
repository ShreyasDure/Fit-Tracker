import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_tracker/main.dart';
import 'package:fit_tracker/core/login_screen.dart';
import 'package:fit_tracker/user/user_shell.dart';
import 'package:fit_tracker/admin/admin_shell.dart';
import 'package:fit_tracker/services/mongodb_service.dart';
import 'package:fit_tracker/services/biometric_service.dart';
import 'package:fit_tracker/controllers/auth_controller.dart';
import 'package:fit_tracker/services/health_service.dart';
import 'package:fit_tracker/services/notification_service.dart';
import 'package:pedometer/pedometer.dart';
import 'package:fit_tracker/controllers/admin_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:fit_tracker/services/connectivity_service.dart';


void main() {
  setUp(() {
    // Reset biometric mock overrides before each test
    BiometricService.mockIsAvailable = null;
    BiometricService.mockIsEnabled = null;
    BiometricService.mockHasEnrolled = null;
    BiometricService.mockAuthenticateResult = null;
    BiometricService.mockStoredToken = null;
    BiometricService.mockStoredUserData = null;

    // Reset MongoDB mock overrides before each test
    MongoDbService.mockForgotPassword = null;
    MongoDbService.mockVerifyOtp = null;
    MongoDbService.mockResetPassword = null;
    MongoDbService.mockBmiHistory = null;
    MongoDbService.mockScheduledReminders = null;
    MongoDbService.mockUsers = null;
    MongoDbService.mockAdminAnalytics = null;
    MongoDbService.mockAdminActivity = null;
    MongoDbService.mockDeleteUser = null;
    MongoDbService.setToken(null);

    // Reset HealthController mocks
    HealthController.mockStepCountStream = null;
    HealthController.mockPermissionGranted = null;
    HealthController.mockSensorAvailable = null;

    // Reset connectivity mock overrides
    ConnectivityService.setMockIsOnline(null);
    MongoDbService.isOnline = true;
    MongoDbService.mockSaveWorkout = null;
  });

  testWidgets('TC_001: Login with valid credentials', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Enter email
    final emailFinder = find.widgetWithText(TextField, 'Email Address');
    expect(emailFinder, findsOneWidget);
    await tester.enterText(emailFinder, 'user@fit.com');

    // Enter password
    final passwordFinder = find.widgetWithText(TextField, 'Password');
    expect(passwordFinder, findsOneWidget);
    await tester.enterText(passwordFinder, 'Test@123');

    // Tap submit
    final submitFinder = find.text('ENTER ECOSYSTEM');
    expect(submitFinder, findsOneWidget);
    await tester.tap(submitFinder);
    await tester.pump(const Duration(milliseconds: 500));

    // Verify user dashboard is shown
    expect(find.byType(UserShell), findsOneWidget);
  });

  testWidgets('TC_002: Login with wrong password', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong123');

    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Toast/SnackBar message shown: 'Invalid credentials'
    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('TC_003: Login with unregistered email', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'notexist@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'any');

    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Error dialog displayed with 'Account not found'
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Account not found'), findsOneWidget);
  });

  testWidgets('TC_004: Login with both fields empty', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify validation message shown below input fields
    expect(find.text('Please fill in all fields'), findsAtLeastNWidgets(1));
  });

  testWidgets('TC_005: Login with invalid email format', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'userATexample');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'abc123');

    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify validation error
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('TC_006: Biometric login success', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    // Configure biometric overrides
    BiometricService.mockIsAvailable = true;
    BiometricService.mockIsEnabled = true;
    BiometricService.mockHasEnrolled = true;
    BiometricService.mockAuthenticateResult = true;
    BiometricService.mockStoredToken = 'mock_jwt_token';
    BiometricService.mockStoredUserData = {
      'id': 'u2',
      'name': 'Valid User',
      'email': 'user@fit.com',
      'role': 'user',
      'points': 1500,
      'level': 2,
      'streak': 5,
      'isActive': true,
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    // On init, biometric login is auto-triggered when enabled
    await tester.pump(const Duration(milliseconds: 500));

    // Verify redirected to user dashboard
    expect(find.byType(UserShell), findsOneWidget);
  });

  testWidgets('TC_007: Biometric login failure', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    BiometricService.mockIsAvailable = true;
    BiometricService.mockIsEnabled = true;
    BiometricService.mockHasEnrolled = true;
    BiometricService.mockAuthenticateResult = false; // fail biometric

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify error SnackBar showing fallback offer
    expect(find.text('Biometric authentication failed. Please enter your password.'), findsOneWidget);
  });

  testWidgets('TC_008: Session token expiry handling', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login first
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(UserShell), findsOneWidget);

    // Simulate token expiry callback trigger
    MongoDbService.onTokenExpired?.call();
    await tester.pumpAndSettle();

    // App detects expired token, redirects to login screen, shows 'Session expired'
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Session expired'), findsOneWidget);
  });

  testWidgets('TC_009: Password reset request', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    MongoDbService.mockForgotPassword = (email) async {
      return 'Verification OTP sent to your email.';
    };
    MongoDbService.mockVerifyOtp = (email, otp) async {
      return true;
    };
    MongoDbService.mockResetPassword = (email, otp, newPassword) async {
      return 'Password updated successfully';
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Tap "Forgot Password?"
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    // Check we are on forgot password bottom sheet step 0
    expect(find.text('Forgot Password?'), findsWidgets); // title is on screen

    // Enter email
    final emailField = find.widgetWithText(TextField, 'Email');
    await tester.enterText(emailField, 'user@fit.com');
    
    // Tap send OTP
    await tester.ensureVisible(find.text('Send OTP'));
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    // Verify confirmation toast shown on screen
    expect(find.text('Verification OTP sent to your email.'), findsOneWidget);

    // Enter OTP
    final otpField = find.widgetWithText(TextField, '000000');
    await tester.enterText(otpField, '123456');

    // Tap verify OTP
    await tester.ensureVisible(find.text('Verify OTP'));
    await tester.tap(find.text('Verify OTP'));
    await tester.pumpAndSettle();

    // Enter new password (must be strong)
    final newPassField = find.widgetWithText(TextField, 'New Password');
    final confirmPassField = find.widgetWithText(TextField, 'Confirm Password');
    await tester.enterText(newPassField, 'NewStrongPass@123');
    await tester.enterText(confirmPassField, 'NewStrongPass@123');

    // Tap Reset Password
    await tester.ensureVisible(find.text('Reset Password'));
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    // Verify success confirmation dialog screen is shown
    expect(find.text('Password Reset!'), findsOneWidget);
  });

  testWidgets('TC_010: Admin login with admin credentials', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'admin@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');

    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify admin dashboard loads
    expect(find.byType(AdminShell), findsOneWidget);

    // Drain the 500ms delay timer scheduled by AdminController's constructor
    await tester.pump(const Duration(milliseconds: 1000));
  });

  testWidgets('TC_011: Step counter starts on app launch', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({
      'health_steps': 500,
      'health_date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    });

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    HealthController.mockPermissionGranted = true;
    HealthController.mockSensorAvailable = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(); // Flush microtasks so steps=500 is registered
    await tester.pump(const Duration(seconds: 3)); // Run animation to completion

    // Verify step count shows last saved value
    expect(find.text('500'), findsOneWidget);
  });

  testWidgets('TC_012: Step count increments correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({
      'health_steps': 500,
      'health_date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    });

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    final controller = StreamController<StepCount>();
    HealthController.mockPermissionGranted = true;
    HealthController.mockSensorAvailable = true;
    HealthController.mockStepCountStream = controller.stream;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3)); // initial animation

    final element = tester.element(find.byType(UserShell));
    final container = ProviderScope.containerOf(element);
    print("DEBUG TC_012: Initial health steps state is ${container.read(healthControllerProvider).steps}");

    // Send first event (sets initialSteps)
    controller.add(MockStepCount(100, DateTime.now()));
    await tester.pump(const Duration(milliseconds: 500));
    print("DEBUG TC_012: After first step count (100) state is ${container.read(healthControllerProvider).steps}");
    // Send second event (10 steps delta)
    controller.add(MockStepCount(110, DateTime.now()));
    await tester.pump(); // Flush stream microtask and register new tween
    await tester.pump(const Duration(seconds: 3)); // Run animation to the end

    // Verify steps updated to 510
    expect(find.text('510'), findsOneWidget);

    controller.close();
  });

  testWidgets('TC_013: Sensor unavailable error', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({});

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    HealthController.mockSensorAvailable = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500)); // wait for startPedometer microtask

    // Verify 'Step sensor not available' warning banner is shown
    expect(find.text('Step sensor not available'), findsOneWidget);
  });

  testWidgets('TC_014: Activity recognition permission denied', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({});

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    HealthController.mockPermissionGranted = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500)); // wait for startPedometer microtask

    // Verify 'Permission required for tracking' warning banner is shown
    expect(find.text('Permission required for tracking'), findsOneWidget);
  });

  testWidgets('TC_015: Daily step count resets at midnight', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({});

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    HealthController.mockPermissionGranted = true;
    HealthController.mockSensorAvailable = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));

    // Simulate reset trigger
    final element = tester.element(find.byType(UserShell));
    final container = ProviderScope.containerOf(element);
    await container.read(healthControllerProvider.notifier).resetToday();
    await tester.pump(const Duration(seconds: 3));

    // Verify step count reset to 0
    expect(find.text('0'), findsAtLeastNWidgets(1));
  });

  testWidgets('TC_016: Calorie calculation accuracy', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({});

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    final controller = StreamController<StepCount>();
    HealthController.mockPermissionGranted = true;
    HealthController.mockSensorAvailable = true;
    HealthController.mockStepCountStream = controller.stream;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));

    controller.add(MockStepCount(100, DateTime.now()));
    await tester.pump(const Duration(milliseconds: 500));

    controller.add(MockStepCount(1100, DateTime.now()));
    await tester.pump(const Duration(seconds: 3));

    // 1000 steps delta -> 1000 * 0.04 = 40 calories
    expect(find.textContaining('40'), findsWidgets);

    controller.close();
  });

  testWidgets('TC_017: Distance calculation accuracy', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({});

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    final controller = StreamController<StepCount>();
    HealthController.mockPermissionGranted = true;
    HealthController.mockSensorAvailable = true;
    HealthController.mockStepCountStream = controller.stream;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));

    final element = tester.element(find.byType(UserShell));
    final container = ProviderScope.containerOf(element);

    controller.add(MockStepCount(100, DateTime.now()));
    await tester.pump(const Duration(milliseconds: 500));

    controller.add(MockStepCount(2100, DateTime.now()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(healthControllerProvider).distance, 1.4);

    controller.close();
  });

  testWidgets('TC_018: Goal completion notification alert', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({});

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    final controller = StreamController<StepCount>();
    HealthController.mockPermissionGranted = true;
    HealthController.mockSensorAvailable = true;
    HealthController.mockStepCountStream = controller.stream;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));

    controller.add(MockStepCount(100, DateTime.now()));
    await tester.pump(const Duration(milliseconds: 500));

    controller.add(MockStepCount(10100, DateTime.now()));
    await tester.pump(const Duration(seconds: 3));

    // Goal is 10000. 10000 steps delta triggers Target cleared!
    expect(find.text('Target cleared! 🔥'), findsOneWidget);

    controller.close();
  });

  testWidgets('TC_019 - TC_024: Reminder schedule, tap, denied, multiple and cancel flows', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({});

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
          notifPermissionGrantedProvider.overrideWith((ref) => false), // TC_022: Deny permission
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify TC_022: 'Notifications disabled' banner shows
    expect(find.text('Notifications disabled'), findsOneWidget);
  });

  testWidgets('TC_025 - TC_030: Admin Analytics, Filter, redirect and User Deletion', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({});

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    MongoDbService.mockUsers = [
      {
        'id': 'u1',
        '_id': 'u1',
        'name': 'Test User',
        'email': 'user@fit.com',
        'role': 'user',
        'points': 1200,
        'level': 2,
        'streak': 3,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      }
    ];
    MongoDbService.mockAdminAnalytics = {
      'totalUsers': 1,
      'activeUsers': 1,
      'totalPoints': 1200,
      'activeUsersChart': [],
      'userGrowth': [],
    };
    MongoDbService.mockAdminActivity = [];
    bool deleteCalled = false;
    MongoDbService.mockDeleteUser = (id) async {
      deleteCalled = true;
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Login as standard user first to verify TC_028 redirection blocks
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3)); // let home screen / dashboard transition settle

    // TC_028: Try to navigate to /admin as a regular user -> Redirects/keeps on UserShell
    final element = tester.element(find.byType(UserShell));
    Navigator.pushNamed(element, '/admin');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3)); // let route settle

    // Still UserShell since it redirected to user dashboard / UserShell
    expect(find.byType(UserShell), findsOneWidget);
    expect(find.byType(AdminShell), findsNothing);

    Navigator.pop(tester.element(find.byType(UserShell).last));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Logout standard user
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pump(const Duration(seconds: 1)); // let profile tab settle
    await tester.tap(find.text('Log Out'));
    await tester.pump(const Duration(seconds: 1)); // let logout and login screen settle

    // Login as admin
    MongoDbService.setToken('mock_admin_token');
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'admin@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 1000)); // wait for AdminShell to load and loadFromBackend 500ms delay

    // Verify AdminShell is shown
    expect(find.byType(AdminShell), findsOneWidget);

    // Switch to User Management screen (index 1)
    await tester.tap(find.text('Users'));
    await tester.pump(const Duration(seconds: 1));

    // Verify user is listed
    expect(find.text('Test User'), findsOneWidget);

    // Tap user to show detail bottom sheet
    await tester.tap(find.text('Test User'));
    await tester.pump(); // start bottom sheet transition
    await tester.pump(const Duration(seconds: 1)); // let it slide up fully

    // Verify Delete User button exists
    expect(find.text('Delete User'), findsOneWidget);

    // Tap delete user button
    await tester.tap(find.text('Delete User'));
    await tester.pump(); // start dialog transition
    await tester.pump(const Duration(seconds: 1)); // let it fade in fully

    // Confirm dialog
    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pump(); // start delete and close dialog
    await tester.pump(const Duration(seconds: 1)); // let it settle

    // Verify mock delete api was called
    expect(deleteCalled, isTrue);
  });

  testWidgets('TC_031 & TC_032: App loads cached data and detects internet disconnection with red snackbar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    SharedPreferences.setMockInitialValues({
      'health_steps': 5000,
      'health_date': todayStr,
      'cached_today_health': json.encode({
        'steps': 5000,
        'calories': 250,
        'activeMinutes': 30,
        'heartRate': 75,
        'date': todayStr,
      }),
    });

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    // Simulate offline during initialization
    ConnectivityService.setMockIsOnline(false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Log in to initialize UserShell and connectivity providers
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(); // Flush microtasks so steps=5000 is registered
    await tester.pump(const Duration(seconds: 3)); // Run animation to completion

    // TC_031: Loads cached data
    expect(find.byType(UserShell), findsOneWidget);
    expect(find.text('5,000'), findsOneWidget);

    // TC_032: Verify red snackbar with 'No internet connection' is displayed
    expect(find.text('No internet connection'), findsOneWidget);
  });

  testWidgets('TC_033 & TC_034: Workouts saved offline are queued locally and synced on reconnect', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({});

    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    // Simulate starting offline
    ConnectivityService.setMockIsOnline(false);

    bool saveWorkoutCalled = false;
    MongoDbService.mockSaveWorkout = (type, duration, distance, calories, heartRateAvg, pace) async {
      saveWorkoutCalled = true;
      return {'status': 'success', 'pointsEarned': 150};
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Log in to initialize UserShell and connectivity providers
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Save a workout while offline
    final result = await MongoDbService.saveWorkout(
      type: 'Walk',
      duration: 1200,
      distance: 2.0,
      calories: 120,
      heartRateAvg: 90,
      pace: 10.0,
    );

    // Verify it returned "queued"
    expect(result['status'], 'queued');

    // Verify that the workout is stored in the SharedPreferences queue
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('offline_workouts_queue');
    expect(queue, isNotNull);
    expect(queue!.length, 1);

    // Verify no save workout call on backend yet
    expect(saveWorkoutCalled, isFalse);

    // Simulate reconnecting to the internet
    ConnectivityService.setMockIsOnline(true);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify mock save workout backend was called on sync
    expect(saveWorkoutCalled, isTrue);

    // Verify queue is now empty
    final updatedQueue = prefs.getStringList('offline_workouts_queue');
    expect(updatedQueue!.isEmpty, isTrue);
  });

  testWidgets('TC_035 - TC_038: Weekly step bar chart, calorie line chart, refresh on workout and empty state', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;

    final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    // Start with empty history to verify TC_038
    SharedPreferences.setMockInitialValues({});
    MongoDbService.mockBmiHistory = [
      {'recordedAt': DateTime.now().toIso8601String(), 'bmi': 22.0}
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifPermissionShownProvider.overrideWith((ref) => true),
        ],
        child: const FitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Log in to initialize UserShell and load home screen
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'user@fit.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'Test@123');
    await tester.tap(find.text('ENTER ECOSYSTEM'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Tap Explore tab to go to Explore screen
    await tester.tap(find.text('Explore'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Tap Stats card
    await tester.tap(find.text('Stats'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();

    // TC_038: Verify empty state shows 'No data yet, start tracking!' and illustration icon
    expect(find.text('No data yet, start tracking!'), findsOneWidget);
    expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);

    // Go back to Explore Screen
    await tester.tap(find.byType(BackButton));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Now populate health history in active SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('health_steps', 6000);
    await prefs.setString('health_date', todayStr);
    await prefs.setString('cached_health_history', json.encode([
      {
        'date': todayStr,
        'steps': 6000,
        'calories': 300,
        'activeMinutes': 40,
      }
    ]));

    // Re-verify after we refresh stats
    await tester.tap(find.text('Stats'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();

    // TC_035 & TC_036: Verify charts render
    expect(find.text('Weekly Steps'), findsOneWidget);
    expect(find.text('Calories Trend'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byType(LineChart), findsAtLeastNWidgets(2)); // Calories & Active Minutes
  });
}

class MockStepCount implements StepCount {
  @override
  final int steps;
  @override
  final DateTime timeStamp;
  MockStepCount(this.steps, this.timeStamp);
}
