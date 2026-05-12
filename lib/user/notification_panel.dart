import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/notification_service.dart';

class NotificationPanel extends ConsumerStatefulWidget {
  const NotificationPanel({super.key});

  @override
  ConsumerState<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<NotificationPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch admin broadcasts from DB on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationControllerProvider.notifier).fetchAdminNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationControllerProvider);
    final controller = ref.read(notificationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            const SizedBox(width: 8),
            if (state.totalUnread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.totalUnread}',
                  style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              controller.markAllRead();
              await controller.markAllAdminRead();
            },
            child: const Text('Mark all read', style: TextStyle(color: AppColors.neonCyan, fontSize: 12)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonCyan,
          labelColor: AppColors.neonCyan,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.campaign_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('Announcements'),
                if (state.adminNotifications.any((n) => !n.isRead)) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.neonCyan, shape: BoxShape.circle),
                  ),
                ]
              ]),
            ),
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.notifications_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('Activity'),
                if (state.notifications.any((n) => !n.isRead)) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.neonOrange, shape: BoxShape.circle),
                  ),
                ]
              ]),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── Admin Announcements Tab ───
          RefreshIndicator(
            color: AppColors.neonCyan,
            onRefresh: () => controller.fetchAdminNotifications(),
            child: state.isLoadingAdmin
                ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
                : state.adminNotifications.isEmpty
                    ? _buildEmpty('No announcements yet', 'Admin messages will appear here', Icons.campaign_rounded)
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        itemCount: state.adminNotifications.length,
                        separatorBuilder: (_, i2) => const SizedBox(height: AppSizes.sm),
                        itemBuilder: (context, i) {
                          final notif = state.adminNotifications[i];
                          return _AdminNotifCard(
                            notif: notif,
                            onTap: () => controller.markAdminNotificationRead(notif.id),
                          );
                        },
                      ),
          ),

          // ─── Activity/Local Notifications Tab ───
          state.notifications.isEmpty
              ? _buildEmpty('No activity yet', 'Your fitness milestones will appear here', Icons.fitness_center_rounded)
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, i2) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, index) {
                    final notif = state.notifications[index];
                    return _ActivityNotifCard(notif: notif);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.neonCyan.withValues(alpha: 0.5), size: 48),
          ),
          const SizedBox(height: AppSizes.md),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _AdminNotifCard extends StatelessWidget {
  final AdminNotification notif;
  final VoidCallback onTap;
  const _AdminNotifCard({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: notif.isRead
              ? Theme.of(context).cardColor
              : notif.priorityColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(
            color: notif.isRead
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : notif.priorityColor.withValues(alpha: 0.25),
            width: notif.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: notif.priorityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notif.priorityIcon, color: notif.priorityColor, size: 20),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: notif.priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notif.priority,
                          style: TextStyle(color: notif.priorityColor, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notif.body, style: Theme.of(context).textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(_formatTime(notif.createdAt), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: notif.priorityColor, shape: BoxShape.circle)),
          ],
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

class _ActivityNotifCard extends StatelessWidget {
  final AppNotification notif;
  const _ActivityNotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: notif.isRead ? Theme.of(context).cardColor : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(
          color: notif.isRead
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : notif.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: notif.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
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
                Text(_formatTime(notif.time), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          if (!notif.isRead)
            Container(width: 8, height: 8, decoration: BoxDecoration(color: notif.color, shape: BoxShape.circle)),
        ],
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
