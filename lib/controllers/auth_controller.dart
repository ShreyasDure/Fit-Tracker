import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/mongodb_service.dart';
import '../services/biometric_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState(status: AuthStatus.initial)) {
    initialize();
  }

  /// Check for existing biometric session on startup
  Future<void> initialize() async {
    final bool isEnabled = await BiometricService.isBiometricEnabled();
    if (isEnabled) {
      // We don't auto-login here, we wait for user to trigger biometric prompt 
      // OR we could show prompt automatically if we want.
      // For now, we set status to unauthenticated but we know biometrics are ready.
    }
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  /// Login using stored biometric credentials
  Future<void> biometricLogin() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authenticated = await BiometricService.authenticate();
      if (authenticated) {
        final token = await BiometricService.getStoredToken();
        final userDataMap = await BiometricService.getStoredUserData();

        if (token != null && userDataMap != null) {
          // Set token in MongoDbService
          MongoDbService.setToken(token);
          
          final user = UserModel.fromMap(userDataMap);
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
            isLoading: false,
          );
          return;
        }
      }
      state = state.copyWith(isLoading: false, error: 'Biometric authentication failed');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error during biometric login');
    }
  }

  /// Enable biometrics after a successful manual login
  Future<void> enableBiometrics() async {
    if (state.user != null) {
      final token = MongoDbService.token; // Need to ensure token is exposed or saved
      if (token != null) {
        await BiometricService.enableBiometric(token, state.user!.toMap());
      }
    }
  }

  Future<void> disableBiometrics() async {
    await BiometricService.disableBiometric();
  }

  /// Login with MongoDB backend
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await MongoDbService.login(email, password);
      final userData = data['user'] as Map<String, dynamic>;
      // Map MongoDB _id to id
      if (userData['_id'] != null && userData['id'] == null) {
        userData['id'] = userData['_id'].toString();
      }
      final user = UserModel.fromMap(userData);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      // Fallback to dummy login if backend is not running
      final fallbackResult = _tryDummyLogin(email, password);
      if (fallbackResult != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: fallbackResult,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  /// Step 1: Send signup OTP to verify email
  Future<String> sendSignupOtp(String name, String email, String password, {String role = 'user'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final msg = await MongoDbService.sendSignupOtp(name, email, password, role: role);
      state = state.copyWith(isLoading: false);
      return msg;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  /// Step 2: Verify OTP and create account
  Future<void> verifyAndRegister(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await MongoDbService.register(email, otp);
      final userData = data['user'] as Map<String, dynamic>;
      if (userData['_id'] != null && userData['id'] == null) {
        userData['id'] = userData['_id'].toString();
      }
      final user = UserModel.fromMap(userData);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  /// Update user model locally (after profile edit)
  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    MongoDbService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Fallback dummy login when backend is not running
  UserModel? _tryDummyLogin(String email, String password) {
    final dummyUsers = {
      'user@fittracker.com': {'password': 'user123', 'data': const UserModel(id: 'u1', name: 'Alex Johnson', email: 'user@fittracker.com', role: 'user', points: 2750, level: 3, streak: 12, isActive: true)},
      'admin@fittracker.com': {'password': 'admin123', 'data': const UserModel(id: 'a1', name: 'Sarah Admin', email: 'admin@fittracker.com', role: 'admin', points: 0, level: 1, streak: 0, isActive: true)},
    };
    final entry = dummyUsers[email.trim().toLowerCase()];
    if (entry != null && entry['password'] == password) {
      return entry['data'] as UserModel;
    }
    return null;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
