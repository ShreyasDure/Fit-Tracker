import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/mongodb_service.dart';

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
  AuthController() : super(const AuthState(status: AuthStatus.unauthenticated));

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

  /// Register a new account with MongoDB backend
  Future<void> register(String name, String email, String password, {String role = 'user'}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await MongoDbService.register(name, email, password, role: role);
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
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
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
