import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../controllers/auth_controller.dart';

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setDark() => state = ThemeMode.dark;
  void setLight() => state = ThemeMode.light;
}

// Notification toggle provider
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final themeMode = ref.watch(themeProvider);
    final notifsEnabled = ref.watch(notificationsEnabledProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(child: Text(user?.name.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22))),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'User', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.edit_rounded, color: AppColors.neonCyan, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Appearance
            Text('Appearance', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSizes.sm),
            _SettingsTile(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: isDark ? 'On' : 'Off',
              color: AppColors.neonPurple,
              trailing: Switch(
                value: isDark,
                activeThumbColor: AppColors.neonPurple,
                onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
              ),
            ),

            const SizedBox(height: AppSizes.xl),
            // Notifications
            Text('Notifications', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSizes.sm),
            _SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Push Notifications',
              subtitle: notifsEnabled ? 'Enabled' : 'Disabled',
              color: AppColors.neonOrange,
              trailing: Switch(
                value: notifsEnabled,
                activeThumbColor: AppColors.neonOrange,
                onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).state = v,
              ),
            ),
            _SettingsTile(
              icon: Icons.email_rounded,
              title: 'Email Reminders',
              subtitle: 'Workout reminders',
              color: AppColors.neonCyan,
              trailing: Switch(
                value: true,
                activeThumbColor: AppColors.neonCyan,
                onChanged: (_) {},
              ),
            ),

            const SizedBox(height: AppSizes.xl),
            // Privacy
            Text('Privacy', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSizes.sm),
            _SettingsTile(
              icon: Icons.visibility_rounded,
              title: 'Profile Visibility',
              subtitle: 'Everyone can see your profile',
              color: AppColors.neonGreen,
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ),
            _SettingsTile(
              icon: Icons.share_rounded,
              title: 'Activity Sharing',
              subtitle: 'Share workouts to social feed',
              color: AppColors.neonPink,
              trailing: Switch(
                value: true,
                activeThumbColor: AppColors.neonPink,
                onChanged: (_) {},
              ),
            ),

            const SizedBox(height: AppSizes.xl),
            // Account
            Text('Account', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSizes.sm),
            _SettingsTile(icon: Icons.lock_rounded, title: 'Change Password', subtitle: 'Update your password', color: AppColors.neonCyan, trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted)),
            _SettingsTile(icon: Icons.help_rounded, title: 'Help & Support', subtitle: 'FAQ and contact', color: AppColors.neonPurple, trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted)),
            _SettingsTile(icon: Icons.info_rounded, title: 'About', subtitle: 'Version 1.0.0', color: AppColors.textMuted, trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted)),

            const SizedBox(height: AppSizes.xl),
            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final Widget trailing;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
