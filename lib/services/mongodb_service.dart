import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'api_config.dart';

// MongoDB backend service — all HTTP calls to our Express API
// All requests have a 5-second timeout to prevent hanging
class MongoDbService {
  static String? _token;
  static const _timeout = Duration(seconds: 5);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static void setToken(String? token) => _token = token;
  static String? get token => _token;
  static bool get isAuthenticated => _token != null;

  // ─── Helper: HTTP with timeout ───

  static Future<http.Response> _get(String path) =>
      http.get(Uri.parse('${ApiConfig.backendUrl}$path'), headers: _headers).timeout(_timeout);

  static Future<http.Response> _post(String path, Map<String, dynamic> body) =>
      http.post(Uri.parse('${ApiConfig.backendUrl}$path'), headers: _headers, body: json.encode(body)).timeout(_timeout);

  static Future<http.Response> _put(String path, [Map<String, dynamic>? body]) =>
      http.put(Uri.parse('${ApiConfig.backendUrl}$path'), headers: _headers, body: body != null ? json.encode(body) : null).timeout(_timeout);

  // ─── Auth ───

  static Future<Map<String, dynamic>> register(String name, String email, String password, {String role = 'user'}) async {
    try {
      final response = await _post('/auth/register', {'name': name, 'email': email, 'password': password, 'role': role});
      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        _token = data['token'];
        return data;
      }
      throw Exception(data['error'] ?? 'Registration failed');
    } on TimeoutException {
      throw Exception('Server not reachable. Is the backend running?');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _post('/auth/login', {'email': email, 'password': password});
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _token = data['token'];
        return data;
      }
      throw Exception(data['error'] ?? 'Login failed');
    } on TimeoutException {
      throw Exception('Server not reachable. Is the backend running?');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _get('/auth/me');
      final data = json.decode(response.body);
      if (response.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Failed to get profile');
    } on TimeoutException {
      throw Exception('Server timeout');
    }
  }

  static void logout() => _token = null;

  // ─── Users (Admin) ───

  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _get('/users');
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data['users']);
      }
      throw Exception(data['error'] ?? 'Failed to fetch users');
    } on TimeoutException {
      throw Exception('Server timeout');
    }
  }

  static Future<Map<String, dynamic>> updateUserPoints(String userId, int amount) async {
    try {
      final response = await _put('/users/$userId/points', {'amount': amount});
      final data = json.decode(response.body);
      if (response.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Failed to update points');
    } on TimeoutException {
      throw Exception('Server timeout');
    }
  }

  static Future<Map<String, dynamic>> toggleUserActive(String userId) async {
    try {
      final response = await _put('/users/$userId/toggle');
      final data = json.decode(response.body);
      if (response.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Failed to toggle user');
    } on TimeoutException {
      throw Exception('Server timeout');
    }
  }

  // ─── Workouts ───

  static Future<Map<String, dynamic>> saveWorkout({
    required String type,
    required int duration,
    double distance = 0,
    int calories = 0,
    int heartRateAvg = 0,
    double pace = 0,
  }) async {
    try {
      final response = await _post('/workouts', {
        'type': type,
        'duration': duration,
        'distance': distance,
        'calories': calories,
        'heartRateAvg': heartRateAvg,
        'pace': pace,
      });
      final data = json.decode(response.body);
      if (response.statusCode == 201) return data;
      throw Exception(data['error'] ?? 'Failed to save workout');
    } on TimeoutException {
      throw Exception('Server timeout');
    }
  }

  static Future<List<Map<String, dynamic>>> getWorkouts() async {
    try {
      final response = await _get('/workouts');
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(data['workouts']);
      }
      throw Exception(data['error'] ?? 'Failed to fetch workouts');
    } on TimeoutException {
      throw Exception('Server timeout');
    }
  }

  // ─── Settings (Admin) ───

  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _get('/settings');
      final data = json.decode(response.body);
      if (response.statusCode == 200) return data['settings'];
      throw Exception(data['error'] ?? 'Failed to fetch settings');
    } on TimeoutException {
      throw Exception('Server timeout');
    }
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _put('/settings', settings);
      final data = json.decode(response.body);
      if (response.statusCode == 200) return data['settings'];
      throw Exception(data['error'] ?? 'Failed to update settings');
    } on TimeoutException {
      throw Exception('Server timeout');
    }
  }
}
