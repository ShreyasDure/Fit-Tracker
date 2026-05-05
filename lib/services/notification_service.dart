import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// In-app notification service (no external dependencies needed)
// In production, replace with firebase_messaging for push notifications

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

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
  });
}

class NotificationController extends StateNotifier<NotificationState> {
  NotificationController() : super(const NotificationState()) {
    _initNotifications();
    _startReminders();
  }

  Timer? _reminderTimer;

  void _initNotifications() {
    // Welcome notification
    _addNotification(AppNotification(
      title: 'Welcome to FitTracker! 🎉',
      body: 'Start tracking your workouts and earn points.',
      icon: Icons.celebration_rounded,
      color: const Color(0xFFBB86FC),
      time: DateTime.now(),
    ));
  }

  void _startReminders() {
    // Send workout reminder every 2 minutes (in production, use daily)
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
      unreadCount: updated.where((n) => !n.isRead).length,
    );
  }

  /// Call this when user completes a workout
  void workoutCompleted(String type, int points) {
    _addNotification(AppNotification(
      title: 'Workout Complete! 💪',
      body: 'Great $type session! You earned $points points.',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFF9100),
      time: DateTime.now(),
    ));
  }

  /// Call this when user reaches a streak milestone
  void streakMilestone(int streak) {
    _addNotification(AppNotification(
      title: '$streak Day Streak! 🔥',
      body: 'You\'re on fire! Keep up the amazing consistency.',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFFF006E),
      time: DateTime.now(),
    ));
  }

  /// Call this when user levels up
  void levelUp(String levelName) {
    _addNotification(AppNotification(
      title: 'Level Up! ⭐',
      body: 'Congratulations! You reached $levelName tier.',
      icon: Icons.star_rounded,
      color: const Color(0xFFFFEA00),
      time: DateTime.now(),
    ));
  }

  void markAllRead() {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = NotificationState(notifications: updated, unreadCount: 0);
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
