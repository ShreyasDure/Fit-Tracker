import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();
  
  static const String _biometricKey = 'biometric_enabled';
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Test mocks
  static bool? mockIsAvailable;
  static bool? mockIsEnabled;
  static bool? mockHasEnrolled;
  static bool? mockAuthenticateResult;
  static String? mockStoredToken;
  static Map<String, dynamic>? mockStoredUserData;

  // Check if device supports any biometrics
  static Future<bool> isBiometricAvailable() async {
    if (mockIsAvailable != null) return mockIsAvailable!;
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  // Check if biometrics are actually enrolled
  static Future<bool> hasEnrolledBiometrics() async {
    if (mockHasEnrolled != null) return mockHasEnrolled!;
    final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
    return availableBiometrics.isNotEmpty;
  }

  // Authenticate user
  static Future<bool> authenticate() async {
    if (mockAuthenticateResult != null) return mockAuthenticateResult!;
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access FitTracker',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/Pattern fallback
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // Save biometric settings and token
  static Future<void> enableBiometric(String token, Map<String, dynamic> userData) async {
    await _storage.write(key: _biometricKey, value: 'true');
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userDataKey, value: json.encode(userData));
  }

  static Future<void> disableBiometric() async {
    await _storage.delete(key: _biometricKey);
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userDataKey);
  }

  static Future<bool> isBiometricEnabled() async {
    if (mockIsEnabled != null) return mockIsEnabled!;
    final value = await _storage.read(key: _biometricKey);
    return value == 'true';
  }

  static Future<String?> getStoredToken() async {
    if (mockStoredToken != null) return mockStoredToken!;
    return await _storage.read(key: _tokenKey);
  }

  static Future<Map<String, dynamic>?> getStoredUserData() async {
    if (mockStoredUserData != null) return mockStoredUserData!;
    final data = await _storage.read(key: _userDataKey);
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }
}
