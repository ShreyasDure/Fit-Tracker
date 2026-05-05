import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Users', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 4),
              Text('${admin.totalUsers} total · ${admin.activeUsers} active', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSizes.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: admin.users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, index) {
                    final user = admin.users[index];
                    return GestureDetector(
                      onTap: () => _showUserDetail(context, user, controller),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                          border: Border.all(color: user.isActive ? AppColors.neonCyan.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: user.isActive ? AppColors.neonCyan.withValues(alpha: 0.15) : AppColors.surfaceLighter,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text(user.name.substring(0, 1), style: TextStyle(color: user.isActive ? AppColors.neonCyan : AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 16))),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                                  onTap: () => controller.toggleUserActive(user.id),
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceLighter, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSizes.xl),
            // Avatar
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: user.isActive ? AppColors.primaryGradient : null,
                color: user.isActive ? null : AppColors.surfaceLighter,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: Text(user.name.substring(0, 1), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 28))),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm),
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
                    onPressed: () { controller.toggleUserActive(user.id); Navigator.pop(ctx); },
                    icon: Icon(user.isActive ? Icons.block : Icons.check_circle, size: 16),
                    label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                    style: ElevatedButton.styleFrom(backgroundColor: user.isActive ? AppColors.error : AppColors.neonGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
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
