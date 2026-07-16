import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/constants.dart';
import '../controllers/admin_controller.dart';
import '../models/user_model.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Users', style: Theme.of(context).textTheme.displayMedium),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        helpText: 'Select range',
                        fieldStartHintText: 'dd/mm/yyyy',
                        fieldEndHintText: 'dd/mm/yyyy',
                        fieldStartLabelText: 'Start Date',
                        fieldEndLabelText: 'End Date',
                        builder: (context, child) {
                          // Force en_GB locale so date fields show dd/mm/yyyy
                          return Localizations.override(
                            context: context,
                            locale: const Locale('en', 'GB'),
                            delegates: const [
                              GlobalMaterialLocalizations.delegate,
                              GlobalWidgetsLocalizations.delegate,
                              GlobalCupertinoLocalizations.delegate,
                            ],
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.neonCyan,
                                  surface: Color(0xFF0F0F25),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                        },
                      );
                      if (picked != null) {
                        ref.read(adminControllerProvider.notifier).setDateFilter(picked.start, picked.end);
                      }
                    },
                    icon: const Icon(Icons.date_range_rounded, color: AppColors.neonCyan, size: 16),
                    label: const Text('Filter Date', style: TextStyle(color: AppColors.neonCyan, fontSize: 12)),
                  ),
                  if (ref.watch(adminControllerProvider.notifier).hasDateFilter) ...[
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.error, size: 16),
                      onPressed: () {
                        ref.read(adminControllerProvider.notifier).clearDateFilter();
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text('${admin.totalUsers} total · ${admin.activeUsers} active', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSizes.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: admin.users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, index) {
                    final user = admin.users[index];
                    return GestureDetector(
                      onTap: () => _showUserDetail(context, user, controller),
                      child: Container(
                        padding: EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                          border: Border.all(color: user.isActive ? AppColors.neonCyan.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: user.isActive ? AppColors.neonCyan.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text(user.name.substring(0, 1), style: TextStyle(color: user.isActive ? AppColors.neonCyan : Theme.of(context).textTheme.bodySmall!.color!, fontWeight: FontWeight.w800, fontSize: 16))),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(child: Text(user.name, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
                                      const SizedBox(width: AppSizes.xs),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: user.isActive ? AppColors.neonGreen.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(user.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 9, color: user.isActive ? AppColors.neonGreen : AppColors.error, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('${user.levelName} · ${user.points} pts · Lv.${user.level}', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ActionBtn(icon: Icons.add, color: AppColors.neonGreen, onTap: () => controller.addPoints(user.id, 100)),
                                const SizedBox(width: 4),
                                _ActionBtn(icon: Icons.remove, color: AppColors.neonOrange, onTap: () => controller.removePoints(user.id, 100)),
                                const SizedBox(width: 4),
                                _ActionBtn(
                                  icon: user.isActive ? Icons.block : Icons.check_circle_outline,
                                  color: user.isActive ? AppColors.error : AppColors.neonGreen,
                                  onTap: () {
                                    if (user.isActive) {
                                      _showDeactivateDialog(context, user, controller);
                                    } else {
                                      controller.toggleUserActive(user.id, '');
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetail(BuildContext context, UserModel user, AdminController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSizes.xl),
            // Avatar
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: user.isActive ? AppColors.primaryGradient : null,
                color: user.isActive ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: Text(user.name.substring(0, 1), style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 28))),
            ),
            const SizedBox(height: AppSizes.md),
            Text(user.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(user.email, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSizes.lg),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DetailStat(label: 'Points', value: '${user.points}', color: AppColors.neonCyan),
                _DetailStat(label: 'Level', value: 'Lv.${user.level}', color: AppColors.neonPurple),
                _DetailStat(label: 'Streak', value: '${user.streak}🔥', color: AppColors.neonOrange),
                _DetailStat(label: 'Status', value: user.isActive ? 'Active' : 'Inactive', color: user.isActive ? AppColors.neonGreen : AppColors.error),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            // Level badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm),
              decoration: BoxDecoration(
                color: _levelColor(user.levelName).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.sm),
                border: Border.all(color: _levelColor(user.levelName).withValues(alpha: 0.3)),
              ),
              child: Text('${user.levelName} Tier', style: TextStyle(color: _levelColor(user.levelName), fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: AppSizes.xl),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { controller.addPoints(user.id, 100); Navigator.pop(ctx); },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+100 pts'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGreen),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (user.isActive) {
                        _showDeactivateDialog(context, user, controller);
                      } else {
                        controller.toggleUserActive(user.id, '');
                      }
                    },
                    icon: Icon(user.isActive ? Icons.block : Icons.check_circle, size: 16),
                    label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                    style: ElevatedButton.styleFrom(backgroundColor: user.isActive ? AppColors.error : AppColors.neonGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showDeleteUserDialog(context, user, controller);
                },
                icon: const Icon(Icons.delete_forever, size: 16, color: Colors.white),
                label: const Text('Delete User', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Gold': return const Color(0xFFFFD700);
      case 'Silver': return const Color(0xFFC0C0C0);
      default: return const Color(0xFFCD7F32);
    }
  }

  void _showDeactivateDialog(BuildContext context, UserModel user, AdminController controller) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.block_rounded, color: AppColors.error, size: 20),
          SizedBox(width: 8),
          Text('Deactivate Account', style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deactivating ${user.name}\'s account.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Reason (required)',
                hintText: 'Enter the reason for deactivation...',
                hintStyle: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!))),
          ElevatedButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              controller.toggleUserActive(user.id, reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, UserModel user, AdminController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          SizedBox(width: 8),
          Text('Delete User', style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Text('Are you sure you want to permanently delete user ${user.name}? This action cannot be undone.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DetailStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}


