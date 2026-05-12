import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../controllers/auth_controller.dart';
import '../services/mongodb_service.dart';
import '../services/biometric_service.dart';

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);
  void toggleTheme() => state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  void setDark() => state = ThemeMode.dark;
  void setLight() => state = ThemeMode.light;
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final themeMode = ref.watch(themeProvider);
    final pushEnabled = user?.pushNotifications ?? true;
    final emailEnabled = user?.emailReminders ?? true;
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Profile Section ───
            Container(
              padding: EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(user?.name.substring(0, 1).toUpperCase() ?? 'U', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22))),
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
                  // ✏️ Edit button — FUNCTIONAL
                  GestureDetector(
                    onTap: () => _showEditProfile(context, ref, user?.name ?? ''),
                    child: Container(
                      padding: EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.edit_rounded, color: AppColors.neonCyan, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.xl),
            // ─── Appearance ───
            Text('Appearance', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).textTheme.bodySmall!.color!)),
            const SizedBox(height: AppSizes.sm),
            _SettingsTile(
              icon: Icons.dark_mode_rounded, title: 'Dark Mode', subtitle: isDark ? 'On' : 'Off', color: AppColors.neonPurple,
              trailing: Switch(value: isDark, activeThumbColor: AppColors.neonPurple, onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme()),
            ),

            const SizedBox(height: AppSizes.xl),
            // ─── Notifications (FUNCTIONAL) ───
            Text('Notifications', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).textTheme.bodySmall!.color!)),
            const SizedBox(height: AppSizes.sm),
            _SettingsTile(
              icon: Icons.notifications_rounded, title: 'Push Notifications',
              subtitle: pushEnabled ? 'Enabled' : 'Disabled', color: AppColors.neonOrange,
              trailing: Switch(
                value: pushEnabled, activeThumbColor: AppColors.neonOrange,
                onChanged: (v) {
                  if (user != null) {
                    ref.read(authControllerProvider.notifier).updateUser(user.copyWith(pushNotifications: v));
                  }
                  MongoDbService.updateNotificationPrefs(pushNotifications: v).catchError((_) => <String, dynamic>{});
                },
              ),
            ),
            _SettingsTile(
              icon: Icons.email_rounded, title: 'Email Reminders',
              subtitle: emailEnabled ? 'Workout reminders' : 'Disabled', color: AppColors.neonCyan,
              trailing: Switch(
                value: emailEnabled, activeThumbColor: AppColors.neonCyan,
                onChanged: (v) {
                  if (user != null) {
                    ref.read(authControllerProvider.notifier).updateUser(user.copyWith(emailReminders: v));
                  }
                  MongoDbService.updateNotificationPrefs(emailReminders: v).catchError((_) => <String, dynamic>{});
                },
              ),
            ),

            const SizedBox(height: AppSizes.xl),
            // ─── Security (BIOMETRIC) ───
            Text('Security', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).textTheme.bodySmall!.color!)),
            const SizedBox(height: AppSizes.sm),
            FutureBuilder<bool>(
              future: BiometricService.isBiometricAvailable(),
              builder: (context, snapshot) {
                final isAvailable = snapshot.data ?? false;
                if (!isAvailable) return const SizedBox.shrink();

                return FutureBuilder<bool>(
                  future: BiometricService.isBiometricEnabled(),
                  builder: (context, statusSnapshot) {
                    final isEnabled = statusSnapshot.data ?? false;
                    return _SettingsTile(
                      icon: Icons.fingerprint_rounded, 
                      title: 'Biometric Login',
                      subtitle: isEnabled ? 'Fingerprint/Face Unlock active' : 'Enable for faster access', 
                      color: AppColors.neonGreen,
                      trailing: Switch(
                        value: isEnabled, 
                        activeThumbColor: AppColors.neonGreen,
                        onChanged: (v) async {
                          if (v) {
                            final authenticated = await BiometricService.authenticate();
                            if (authenticated) {
                              await ref.read(authControllerProvider.notifier).enableBiometrics();
                              // Refresh UI is tricky in ConsumerWidget, but Switch will rebuild
                            }
                          } else {
                            await ref.read(authControllerProvider.notifier).disableBiometrics();
                          }
                        },
                      ),
                    );
                  }
                );
              },
            ),

            const SizedBox(height: AppSizes.xl),
            // ─── Account ───
            Text('Account', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).textTheme.bodySmall!.color!)),
            const SizedBox(height: AppSizes.sm),
            GestureDetector(
              onTap: () => _showChangePassword(context),
              child: _SettingsTile(icon: Icons.lock_rounded, title: 'Change Password', subtitle: 'Update your password', color: AppColors.neonCyan, trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall!.color!)),
            ),
            GestureDetector(
              onTap: () => _showHelpSupport(context, ref),
              child: _SettingsTile(icon: Icons.help_rounded, title: 'Help & Support', subtitle: 'Contact us', color: AppColors.neonPurple, trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall!.color!)),
            ),

            const SizedBox(height: AppSizes.xl),
            // ─── Logout ───
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
                  padding: EdgeInsets.symmetric(vertical: AppSizes.md),
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

  // ─── Edit Profile Dialog ───
  void _showEditProfile(BuildContext context, WidgetRef ref, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(nameCtrl: nameCtrl, ref: ref),
    );
  }

  // ─── Change Password Dialog ───
  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  // ─── Help & Support Dialog ───
  void _showHelpSupport(BuildContext context, WidgetRef ref) {
    final msgCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.neonPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.support_agent_rounded, color: AppColors.neonPurple, size: 20),
                ),
                const SizedBox(width: AppSizes.sm),
                const Text('Support', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need help? Send us a message.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 13)),
                  const SizedBox(height: AppSizes.md),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Your message (Optional)',
                      hintText: 'Describe your issue...',
                      hintStyle: TextStyle(fontSize: 12),
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Phone / WhatsApp *',
                      hintText: '+1 234 567 8900',
                      hintStyle: TextStyle(fontSize: 12),
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.phone_rounded, size: 18, color: Theme.of(context).textTheme.bodySmall!.color!),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!))),
              isSubmitting 
                ? const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.neonCyan, strokeWidth: 2)))
                : ElevatedButton(
                  onPressed: () async {
                    final msg = msgCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number is required'), backgroundColor: AppColors.error));
                      return;
                    }
                    setState(() => isSubmitting = true);
                    try {
                      final responseMsg = await MongoDbService.sendSupportMessage(msg, phone: phoneCtrl.text.trim());
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseMsg), backgroundColor: AppColors.neonGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
                      }
                    } finally {
                      if (context.mounted) setState(() => isSubmitting = false);
                    }
                  },
                  child: const Text('Send'),
                ),
            ],
          );
        }
      ),
    );
  }
}

// ─── Edit Profile Sheet ───
class _EditProfileSheet extends StatefulWidget {
  final TextEditingController nameCtrl;
  final WidgetRef ref;
  const _EditProfileSheet({required this.nameCtrl, required this.ref});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  bool _isLoading = false;
  String? _error;

  Future<void> _save() async {
    final name = widget.nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _error = 'Name cannot be empty'); return; }
    setState(() { _isLoading = true; _error = null; });
    try {
      await MongoDbService.updateProfile(name);
      // Update local state
      final current = widget.ref.read(authControllerProvider).user;
      if (current != null) {
        widget.ref.read(authControllerProvider.notifier).updateUser(current.copyWith(name: name));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSizes.xl, AppSizes.lg, AppSizes.xl, MediaQuery.of(context).viewInsets.bottom + AppSizes.xl),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: AppSizes.lg),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.person_rounded, color: AppColors.neonCyan, size: 28),
          ),
          const SizedBox(height: AppSizes.md),
          Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.xl),
          TextField(
            controller: widget.nameCtrl,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded, color: Theme.of(context).textTheme.bodySmall!.color!)),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSizes.sm),
            Container(
              padding: EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [const Icon(Icons.error_outline, color: AppColors.error, size: 16), const SizedBox(width: AppSizes.sm), Expanded(child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 12)))]),
            ),
          ],
          const SizedBox(height: AppSizes.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!))),
        ],
      ),
    );
  }
}

// ─── Change Password Sheet ───
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() { _currentCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _changePassword() async {
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty) { setState(() => _error = 'Enter current password'); return; }
    if (newPass.length < 6) { setState(() => _error = 'New password must be at least 6 characters'); return; }
    if (newPass != confirm) { setState(() => _error = 'Passwords do not match'); return; }

    setState(() { _isLoading = true; _error = null; });
    try {
      final msg = await MongoDbService.changePassword(current, newPass);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.neonGreen, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSizes.xl, AppSizes.lg, AppSizes.xl, MediaQuery.of(context).viewInsets.bottom + AppSizes.xl),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: AppSizes.lg),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.lock_rounded, color: AppColors.neonCyan, size: 28),
          ),
          const SizedBox(height: AppSizes.md),
          Text('Change Password', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.xl),
          TextField(
            controller: _currentCtrl, obscureText: _obscureCurrent, style: TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline_rounded, color: Theme.of(context).textTheme.bodySmall!.color!),
              suffixIcon: IconButton(icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).textTheme.bodySmall!.color!, size: 20), onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent))),
          ),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _newCtrl, obscureText: _obscureNew, style: TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_rounded, color: Theme.of(context).textTheme.bodySmall!.color!),
              suffixIcon: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).textTheme.bodySmall!.color!, size: 20), onPressed: () => setState(() => _obscureNew = !_obscureNew))),
          ),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _confirmCtrl, obscureText: _obscureConfirm, style: TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock_outline_rounded, color: Theme.of(context).textTheme.bodySmall!.color!),
              suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).textTheme.bodySmall!.color!, size: 20), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSizes.sm),
            Container(
              padding: EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [const Icon(Icons.error_outline, color: AppColors.error, size: 16), const SizedBox(width: AppSizes.sm), Expanded(child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 12)))]),
            ),
          ],
          const SizedBox(height: AppSizes.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Change Password'),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!))),
        ],
      ),
    );
  }
}

// ─── Settings Tile Widget ───
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final Widget trailing;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.sm),
      padding: EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
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
                Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}


