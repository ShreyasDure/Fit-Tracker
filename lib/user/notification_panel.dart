import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/notification_service.dart';

class NotificationPanel extends ConsumerWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationControllerProvider);
    final controller = ref.read(notificationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          if (notifState.notifications.isNotEmpty)
            TextButton(
              onPressed: () => controller.markAllRead(),
              child: const Text('Mark all read', style: TextStyle(color: AppColors.neonCyan, fontSize: 12)),
            ),
        ],
      ),
      body: SafeArea(
        child: notifState.notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off_rounded, color: AppColors.textMuted.withValues(alpha: 0.3), size: 56),
                    const SizedBox(height: AppSizes.md),
                    Text('No notifications', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSizes.lg),
                itemCount: notifState.notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                itemBuilder: (context, index) {
                  final notif = notifState.notifications[index];
                  return Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: notif.isRead ? AppColors.surface : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                      border: Border.all(color: notif.isRead ? AppColors.surfaceLighter : notif.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: notif.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(notif.icon, color: notif.color, size: 18),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notif.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(notif.body, style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(_formatTime(notif.time), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted, fontSize: 10)),
                            ],
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: notif.color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
