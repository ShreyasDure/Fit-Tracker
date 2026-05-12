import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';

// MongoDB backend service — all HTTP calls to our Express API
class MongoDbService {
  static String? _token;
  static const _timeout = Duration(seconds: 8);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static void setToken(String? token) => _token = token;
  static String? get token => _token;
  static bool get isAuthenticated => _token != null;

  // ─── Helper: HTTP with timeout and standardized error handling ───

  static Future<http.Response> _get(String path) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.backendUrl}$path'), headers: _headers).timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Connection timeout. Please check your internet.');
    } on SocketException {
      throw Exception('Server unreachable. Is the backend running?');
    }
  }

  static Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(Uri.parse('${ApiConfig.backendUrl}$path'), headers: _headers, body: json.encode(body)).timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Connection timeout. Please check your internet.');
    } on SocketException {
      throw Exception('Server unreachable. Is the backend running?');
    }
  }

  static Future<http.Response> _put(String path, [Map<String, dynamic>? body]) async {
    try {
      final response = await http.put(Uri.parse('${ApiConfig.backendUrl}$path'), headers: _headers, body: body != null ? json.encode(body) : null).timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Connection timeout. Please check your internet.');
    } on SocketException {
      throw Exception('Server unreachable. Is the backend running?');
    }
  }

  static http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    final data = json.decode(response.body);
    final error = data['error'] ?? 'Request failed with status: ${response.statusCode}';
    throw Exception(error);
  }

  // ─── Auth ───

  static Future<String> sendSignupOtp(String name, String email, String password, {String role = 'user'}) async {
    final response = await _post('/auth/send-signup-otp', {'name': name, 'email': email, 'password': password, 'role': role});
    return json.decode(response.body)['message'] ?? 'OTP sent';
  }

  static Future<Map<String, dynamic>> register(String email, String otp) async {
    final response = await _post('/auth/register', {'email': email, 'otp': otp});
    final data = json.decode(response.body);
    _token = data['token'];
    return data;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post('/auth/login', {'email': email, 'password': password});
    final data = json.decode(response.body);
    _token = data['token'];
    return data;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _get('/auth/me');
    return json.decode(response.body);
  }

  static void logout() => _token = null;

  // ─── OTP Password Reset ───

  static Future<String> forgotPassword(String email) async {
    final response = await _post('/auth/forgot-password', {'email': email});
    return json.decode(response.body)['message'] ?? 'OTP sent if account exists.';
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final response = await _post('/auth/verify-otp', {'email': email, 'otp': otp});
    final data = json.decode(response.body);
    return data['verified'] == true;
  }

  static Future<String> resetPassword(String email, String otp, String newPassword) async {
    final response = await _post('/auth/reset-password', {'email': email, 'otp': otp, 'newPassword': newPassword});
    return json.decode(response.body)['message'] ?? 'Password updated';
  }

  // ─── Change Password (logged in) ───

  static Future<String> changePassword(String currentPassword, String newPassword) async {
    final response = await _post('/auth/change-password', {'currentPassword': currentPassword, 'newPassword': newPassword});
    return json.decode(response.body)['message'] ?? 'Password changed';
  }

  // ─── Profile Update ───

  static Future<Map<String, dynamic>> updateProfile(String name) async {
    final response = await _put('/auth/profile', {'name': name});
    return json.decode(response.body);
  }

  // ─── Notification Preferences ───

  static Future<Map<String, dynamic>> updateNotificationPrefs({bool? pushNotifications, bool? emailReminders}) async {
    final body = <String, dynamic>{};
    if (pushNotifications != null) body['pushNotifications'] = pushNotifications;
    if (emailReminders != null) body['emailReminders'] = emailReminders;
    final response = await _put('/auth/notifications', body);
    return json.decode(response.body);
  }

  // ─── Support ───

  static Future<String> sendSupportMessage(String message, {String phone = ''}) async {
    final response = await _post('/auth/support', {'message': message, 'phone': phone});
    return json.decode(response.body)['message'] ?? 'Sent';
  }

  static Future<List<Map<String, dynamic>>> getSupportTickets() async {
    final response = await _get('/auth/support-tickets');
    return List<Map<String, dynamic>>.from(json.decode(response.body)['tickets']);
  }

  static Future<void> updateSupportTicketStatus(String ticketId, String status) async {
    await _put('/auth/support-tickets/$ticketId/status', {'status': status});
  }

  // ─── Health & Badges ───

  static Future<Map<String, dynamic>> syncHealthData({
    required int steps, required int calories,
    required int activeMinutes, required int heartRate,
    required String date,
  }) async {
    final response = await _post('/health/sync', {
      'steps': steps, 'calories': calories,
      'activeMinutes': activeMinutes, 'heartRate': heartRate,
      'date': date,
    });
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>?> getTodayHealth() async {
    try {
      final today = DateTime.now();
      final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final response = await _get('/health/today?date=$date');
      return json.decode(response.body)['health'];
    } catch (_) {
      return null;
    }
  }

  // ─── Achievements ───

  static Future<List<Map<String, dynamic>>> getAchievements() async {
    try {
      final response = await _get('/achievements');
      final data = json.decode(response.body);
      final list = data['achievements'];
      if (list is List) return List<Map<String, dynamic>>.from(list);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> syncAchievements() async {
    final response = await _post('/achievements/sync', {});
    return json.decode(response.body);
  }

  // ─── Diet / Nutrition ───
  static Future<Map<String, dynamic>> getAiDietPlan(
    double bmi, double weight, double height, String goal, String activityLevel, {
    bool force = false,
    int steps = 0,
    int calories = 0,
    int activeMinutes = 0,
  }) async {
    final response = await _post('/health/nutrition/ai-diet', {
      'bmi': bmi, 'weight': weight, 'height': height, 'goal': goal, 'activityLevel': activityLevel, 'force': force,
      'steps': steps,
      'calories': calories,
      'activeMinutes': activeMinutes,
    });
    return json.decode(response.body)['dietPlan'];
  }

  // ─── Social ───

  static Future<Map<String, dynamic>> toggleSocialLike(String workoutId) async {
    final response = await _post('/social/like/$workoutId', {});
    return json.decode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getSocialFeed() async {
    try {
      final response = await _get('/social/feed');
      final data = json.decode(response.body);
      final list = data['feed'];
      if (list is List) return List<Map<String, dynamic>>.from(list);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> saveBmi(double weight, double height, double bmi) async {
    final response = await _post('/health/bmi', {
      'weight': weight,
      'height': height,
      'bmi': bmi,
    });
    return json.decode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getBmiHistory() async {
    try {
      final response = await _get('/health/bmi');
      final data = json.decode(response.body);
      final list = data['history'];
      if (list is List) return List<Map<String, dynamic>>.from(list);
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─── Health Data ───

  static Future<List<Map<String, dynamic>>> getHealthHistory() async {
    try {
      final response = await _get('/health/history');
      final data = json.decode(response.body);
      final list = data['history'];
      if (list is List) return List<Map<String, dynamic>>.from(list);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getWeeklyHealthSummary() async {
    try {
      final response = await _get('/health/weekly-summary');
      return json.decode(response.body)['weekly'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> downloadHealthReport() async {
    final response = await http.get(Uri.parse('${ApiConfig.backendUrl}/health/report'), headers: _headers).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception('Report failed with status: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> logNutritionIntake({
    required String food,
    required double quantity,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String? date,
  }) async {
    final response = await _post('/health/nutrition/intake', {
      'food': food,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      if (date != null) 'date': date,
    });
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> getTodayNutritionSummary({String? date}) async {
    final response = await _get('/health/nutrition/today${date != null ? '?date=$date' : ''}');
    return json.decode(response.body);
  }

  // ─── AI Insights ───

  static Future<Map<String, dynamic>> getAiInsight({
    required String name,
    required int steps,
    required int calories,
    required int activeMinutes,
    required int goal,
  }) async {
    final response = await _post('/ai/insight', {
      'name': name,
      'steps': steps,
      'calories': calories,
      'activeMinutes': activeMinutes,
      'goal': goal,
    });
    return json.decode(response.body);
  }

  static Future<String> sendChatMessage({
    required String message,
    required String name,
    required int steps,
    required int calories,
    required int activeMinutes,
    required int goal,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.backendUrl}/ai/chat'),
      headers: _headers,
      body: json.encode({
        'message': message,
        'userData': {
          'name': name,
          'steps': steps,
          'calories': calories,
          'activeMinutes': activeMinutes,
          'goal': goal,
        },
      }),
    ).timeout(const Duration(seconds: 15));
    return json.decode(response.body)['reply'] ?? 'No response';
  }

  static Future<void> generateAiChallenges({required int steps, required int calories, required int activeMinutes, required int streak}) async {
    await _post('/ai/ai-challenges', {
      'steps': steps, 'calories': calories, 'activeMinutes': activeMinutes, 'streak': streak
    });
  }

  // ─── User Personal Challenges ───

  static Future<List<dynamic>> getChallenges({bool activeOnly = false}) async {
    final response = await _get('/challenges${activeOnly ? '?active=true' : ''}');
    return json.decode(response.body)['challenges'];
  }

  static Future<Map<String, dynamic>> joinChallenge(String challengeId, {double currentProgress = 0}) async {
    final response = await _post('/challenges/join/$challengeId', {'currentProgress': currentProgress});
    return json.decode(response.body)['challenge'];
  }

  static Future<Map<String, dynamic>> createAdminChallenge({
    required String title,
    required String description,
    required String difficulty,
    required int reward,
    required double target,
    required String type,
    int durationDays = 7,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _post('/admin/challenges', {
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'reward': reward,
      'target': target,
      'type': type,
      'durationDays': durationDays,
      'startDate': startDate,
      'endDate': endDate,
    });
    return json.decode(response.body)['challenge'];
  }

  // Alias for backward compatibility
  static Future<Map<String, dynamic>> createChallenge({
    required String title,
    required String description,
    required String difficulty,
    required int reward,
    required double target,
    required String type,
    int durationDays = 7,
  }) => createAdminChallenge(
    title: title, description: description, difficulty: difficulty,
    reward: reward, target: target, type: type, durationDays: durationDays
  );

  static Future<void> deleteChallenge(String challengeId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.backendUrl}/challenges/$challengeId'), headers: _headers).timeout(_timeout);
    _handleResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getUserChallenges() async {
    try {
      final response = await _get('/challenges/user');
      final data = json.decode(response.body);
      final list = data['challenges'];
      if (list is List) return List<Map<String, dynamic>>.from(list);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> skipUserChallenge(String challengeId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.backendUrl}/challenges/user/$challengeId'), headers: _headers).timeout(_timeout);
    _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserChallengeProgress(String challengeId, double progress) async {
    final response = await _put('/challenges/user/$challengeId/progress', {'progress': progress});
    return json.decode(response.body)['challenge'];
  }

  static Future<Map<String, dynamic>> generateAiChallenge(String difficulty, {double currentProgress = 0}) async {
    final response = await _post('/challenges/user/ai', {'difficulty': difficulty, 'currentProgress': currentProgress});
    return json.decode(response.body)['challenge'];
  }

  // ─── Users (Admin) ───

  static Future<Map<String, dynamic>> getAdminAnalytics() async {
    final response = await _get('/admin/analytics');
    return json.decode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getAdminActivity() async {
    try {
      final response = await _get('/admin/activity');
      final data = json.decode(response.body);
      final list = data['logs'];
      if (list is List) return List<Map<String, dynamic>>.from(list);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> rewardUsers({
    required List<String> userIds,
    required String achievementName,
    required int points,
    int xpBonus = 0,
    String? badgeRewarded,
  }) async {
    final response = await _post('/admin/rewards', {
      'userIds': userIds,
      'achievementName': achievementName,
      'points': points,
      'xpBonus': xpBonus,
      'badgeRewarded': badgeRewarded,
    });
    return json.decode(response.body);
  }

  static Future<Uint8List> downloadAdminReport() async {
    final response = await http.get(Uri.parse('${ApiConfig.backendUrl}/admin/report'), headers: _headers).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception('Admin report failed');
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _get('/users');
      final data = json.decode(response.body);
      final list = data['users'];
      if (list is List) return List<Map<String, dynamic>>.from(list);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateUserPoints(String userId, int amount) async {
    final response = await _put('/users/$userId/points', {'amount': amount});
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> toggleUserActive(String userId, {String reason = ''}) async {
    final response = await _put('/users/$userId/toggle', {'reason': reason});
    return json.decode(response.body);
  }

  // ─── Workouts ───

  static Future<Map<String, dynamic>> saveWorkout({
    required String type, required int duration,
    double distance = 0, int calories = 0, int heartRateAvg = 0, double pace = 0,
  }) async {
    final response = await _post('/workouts', {
      'type': type, 'duration': duration, 'distance': distance,
      'calories': calories, 'heartRateAvg': heartRateAvg, 'pace': pace,
    });
    return json.decode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getWorkouts() async {
    final response = await _get('/workouts');
    return List<Map<String, dynamic>>.from(json.decode(response.body)['workouts']);
  }

  // ─── Settings (Admin) ───

  static Future<Map<String, dynamic>> getSettings() async {
    final response = await _get('/settings');
    return json.decode(response.body)['settings'];
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final response = await _put('/settings', settings);
    return json.decode(response.body)['settings'];
  }

  // ─── Broadcast (Admin) ───

  static Future<Map<String, dynamic>> generateBroadcastContent({
    required String topic, required String type, required String tone, String priority = 'Normal'
  }) async {
    final response = await _post('/broadcast/generate-content', {
      'topic': topic, 'type': type, 'tone': tone, 'priority': priority
    });
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> sendEmailBroadcast({
    required String subject, required String body, String cta = 'Open FitTracker', required String priority, required String tone
  }) async {
    final response = await _post('/broadcast/send-email', {
      'subject': subject, 'body': body, 'cta': cta, 'priority': priority, 'tone': tone
    });
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> sendNotificationBroadcast({
    required String title, required String body, required String priority, required String tone
  }) async {
    final response = await _post('/broadcast/send-notification', {
      'title': title, 'body': body, 'priority': priority, 'tone': tone
    });
    return json.decode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getBroadcastHistory() async {
    final response = await _get('/broadcast/history');
    return List<Map<String, dynamic>>.from(json.decode(response.body)['history']);
  }
}
