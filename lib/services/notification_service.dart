import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'mongodb_service.dart';

// ─── Model: Admin Notification from DB ───
class AdminNotification {
  final String id;
  final String title;
  final String body;
  final String priority;
  final bool isRead;
  final DateTime createdAt;

  const AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    required this.isRead,
    required this.createdAt,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      priority: json['priority'] ?? 'Normal',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Color get priorityColor {
    switch (priority) {
      case 'Critical': return const Color(0xFFFF006E);
      case 'Important': return const Color(0xFFFF9100);
      default: return const Color(0xFF00E5FF);
    }
  }

  IconData get priorityIcon {
    switch (priority) {
      case 'Critical': return Icons.warning_amber_rounded;
      case 'Important': return Icons.info_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  AdminNotification copyWith({bool? isRead}) => AdminNotification(
    id: id, title: title, body: body, priority: priority,
    isRead: isRead ?? this.isRead, createdAt: createdAt,
  );
}

// ─── In-App Notification (local events like badge, workout) ───
class AppNotification {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final DateTime time;
  final bool isRead;

  const AppNotification({
    required this.title,
    required this.body,
    this.icon = Icons.notifications_rounded,
    this.color = const Color(0xFF00E5FF),
    required this.time,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(title: title, body: body, icon: icon, color: color, time: time, isRead: isRead ?? this.isRead);
  }
}

// ─── Combined Notification State ───
class NotificationState {
  final List<AppNotification> notifications;
  final List<AdminNotification> adminNotifications;
  final int unreadCount;
  final bool isLoadingAdmin;

  const NotificationState({
    this.notifications = const [],
    this.adminNotifications = const [],
    this.unreadCount = 0,
    this.isLoadingAdmin = false,
  });

  int get totalUnread => notifications.where((n) => !n.isRead).length + adminNotifications.where((n) => !n.isRead).length;
}

// ─── Controller ───
class NotificationController extends StateNotifier<NotificationState> {
  NotificationController() : super(const NotificationState()) {
    _initNotifications();
    _startReminders();
  }

  Timer? _reminderTimer;

  void _initNotifications() {
    _addNotification(AppNotification(
      title: 'Welcome to FitTracker! 🎉',
      body: 'Start tracking your workouts and earn points.',
      icon: Icons.celebration_rounded,
      color: const Color(0xFFBB86FC),
      time: DateTime.now(),
    ));
  }

  void _startReminders() {
    _reminderTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      final hour = DateTime.now().hour;
      if (hour >= 6 && hour <= 22) {
        _addNotification(AppNotification(
          title: 'Time to move! 🏃‍♂️',
          body: 'You haven\'t logged a workout recently. Let\'s get active!',
          icon: Icons.fitness_center_rounded,
          color: const Color(0xFF39FF14),
          time: DateTime.now(),
        ));
      }
    });
  }

  void _addNotification(AppNotification notification) {
    final updated = [notification, ...state.notifications];
    state = NotificationState(
      notifications: updated,
      adminNotifications: state.adminNotifications,
      unreadCount: updated.where((n) => !n.isRead).length,
    );
  }

  void workoutCompleted(String type, int points) {
    _addNotification(AppNotification(
      title: 'Workout Complete! 💪',
      body: 'Great $type session! You earned $points points.',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFF9100),
      time: DateTime.now(),
    ));
  }

  void streakMilestone(int streak) {
    _addNotification(AppNotification(
      title: '$streak Day Streak! 🔥',
      body: 'You\'re on fire! Keep up the amazing consistency.',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFFF006E),
      time: DateTime.now(),
    ));
  }

  void levelUp(String levelName) {
    _addNotification(AppNotification(
      title: 'Level Up! ⭐',
      body: 'Congratulations! You reached $levelName tier.',
      icon: Icons.star_rounded,
      color: const Color(0xFFFFEA00),
      time: DateTime.now(),
    ));
  }

  // ─── Admin Notifications (from DB) ───
  Future<void> fetchAdminNotifications() async {
    state = NotificationState(
      notifications: state.notifications,
      adminNotifications: state.adminNotifications,
      unreadCount: state.unreadCount,
      isLoadingAdmin: true,
    );
    try {
      final token = MongoDbService.token;
      if (token == null) return;
      final response = await http.get(
        Uri.parse('${ApiConfig.backendUrl}/broadcast/my-notifications'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['notifications'] as List)
            .map((n) => AdminNotification.fromJson(n))
            .toList();
        state = NotificationState(
          notifications: state.notifications,
          adminNotifications: list,
          isLoadingAdmin: false,
        );
      }
    } catch (e) {
      debugPrint('[Notifications] Failed to fetch admin notifications: $e');
      state = NotificationState(
        notifications: state.notifications,
        adminNotifications: state.adminNotifications,
        isLoadingAdmin: false,
      );
    }
  }

  Future<void> markAdminNotificationRead(String id) async {
    final updated = state.adminNotifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    state = NotificationState(notifications: state.notifications, adminNotifications: updated);
    try {
      final token = MongoDbService.token;
      if (token == null) return;
      await http.patch(
        Uri.parse('${ApiConfig.backendUrl}/broadcast/my-notifications/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {}
  }

  Future<void> markAllAdminRead() async {
    final updated = state.adminNotifications.map((n) => n.copyWith(isRead: true)).toList();
    state = NotificationState(notifications: state.notifications, adminNotifications: updated);
    try {
      final token = MongoDbService.token;
      if (token == null) return;
      await http.patch(
        Uri.parse('${ApiConfig.backendUrl}/broadcast/my-notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {}
  }

  void markAllRead() {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = NotificationState(notifications: updated, adminNotifications: state.adminNotifications, unreadCount: 0);
  }

  void clearAll() {
    state = const NotificationState();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  return NotificationController();
});

final notifPermissionGrantedProvider = StateProvider<bool>((ref) => true);
