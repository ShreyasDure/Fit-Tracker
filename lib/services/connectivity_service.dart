import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mongodb_service.dart';

class ConnectivityService extends StateNotifier<bool> {
  final Ref ref;
  static bool? _mockIsOnline;
  static ConnectivityService? _instance;

  ConnectivityService(this.ref) : super(true) {
    _instance = this;
    _init();
  }

  static void setMockIsOnline(bool? value) {
    _mockIsOnline = value;
    if (_instance != null && value != null) {
      final oldState = _instance!.state;
      _instance!.state = value;
      MongoDbService.isOnline = value;
      if (value && !oldState) {
        _instance!.forceSync();
      }
    }
  }

  final _connectivity = Connectivity();
  StreamSubscription? _subscription;

  Future<void> _init() async {
    if (_mockIsOnline != null) {
      state = _mockIsOnline!;
      MongoDbService.isOnline = state;
      return;
    }

    try {
      final result = await _connectivity.checkConnectivity();
      state = _isOnlineResult(result);
      MongoDbService.isOnline = state;
    } catch (_) {
      state = true; // default fallback
      MongoDbService.isOnline = state;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final newOnline = _mockIsOnline ?? _isOnlineResult(results);
      if (newOnline && !state) {
        // Reconnected! Sync offline queue
        MongoDbService.syncOfflineWorkouts(ref);
      }
      state = newOnline;
      MongoDbService.isOnline = state;
    });
  }

  bool _isOnlineResult(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  // Helper method to trigger a manual sync
  Future<void> forceSync() async {
    if (state) {
      await MongoDbService.syncOfflineWorkouts(ref);
    }
  }

  @override
  void dispose() {
    if (_instance == this) {
      _instance = null;
    }
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityService, bool>((ref) {
  return ConnectivityService(ref);
});
