import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants.dart';
import '../controllers/auth_controller.dart';

// Admin registration code — change this to your own secret
const String _adminSecretCode = 'ADMIN2024';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _adminCodeCtrl = TextEditingController();
  bool _isLogin = true;
  bool _wantsAdmin = false;
  bool _obscurePassword = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _adminCodeCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    if (_isLogin) {
      ref.read(authControllerProvider.notifier).login(email, password);
    } else {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) return;

      String role = 'user';
      if (_wantsAdmin) {
        if (_adminCodeCtrl.text.trim() != _adminSecretCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invalid admin code'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          return;
        }
        role = 'admin';
      }
      ref.read(authControllerProvider.notifier).register(name, email, password, role: role);
    }
  }

  void _showForgotPassword() {
    final forgotEmailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: forgotEmailCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_rounded, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password reset link sent to ${forgotEmailCtrl.text}'),
                  backgroundColor: AppColors.neonCyan,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: Colors.black, size: 36),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Text('FitTracker', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: AppSizes.xs),
                  Text(_isLogin ? 'Welcome back!' : 'Create your account', style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: size.height * 0.03),

                  // Login/Register toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                    ),
                    child: Row(
                      children: [
                        _TabButton(label: 'Sign In', isActive: _isLogin, onTap: () => setState(() => _isLogin = true)),
                        _TabButton(label: 'Register', isActive: !_isLogin, onTap: () => setState(() => _isLogin = false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Name field (register only)
                  if (!_isLogin) ...[
                    TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_rounded, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],

                  // Email
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_rounded, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),

                  // Forgot Password (login only)
                  if (_isLogin) ...[
                    const SizedBox(height: AppSizes.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _showForgotPassword,
                        child: const Text('Forgot Password?', style: TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],

                  // Admin toggle + code (register only)
                  if (!_isLogin) ...[
                    const SizedBox(height: AppSizes.md),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.sm),
                        border: Border.all(color: _wantsAdmin ? AppColors.neonPurple.withValues(alpha: 0.3) : AppColors.surfaceLighter),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.admin_panel_settings_rounded, color: AppColors.neonPurple, size: 18),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(child: Text('Register as Admin', style: Theme.of(context).textTheme.bodySmall)),
                              Switch(
                                value: _wantsAdmin,
                                activeThumbColor: AppColors.neonPurple,
                                onChanged: (v) => setState(() => _wantsAdmin = v),
                              ),
                            ],
                          ),
                          if (_wantsAdmin) ...[
                            const SizedBox(height: AppSizes.sm),
                            TextField(
                              controller: _adminCodeCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Admin Code',
                                hintText: 'Enter secret admin code',
                                prefixIcon: Icon(Icons.vpn_key_rounded, color: AppColors.neonPurple),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.xl),

                  // Error message
                  if (authState.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.md),
                      margin: const EdgeInsets.only(bottom: AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.sm),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(child: Text(authState.error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                        ],
                      ),
                    ),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _submit,
                      child: authState.isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(_isLogin ? 'Sign In' : 'Create Account'),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Demo credentials hint
                  if (_isLogin)
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.sm),
                        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Text('Demo Login (no backend needed)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.neonPurple)),
                          const SizedBox(height: 4),
                          Text('User: user@fittracker.com / user123', style: Theme.of(context).textTheme.labelSmall),
                          Text('Admin: admin@fittracker.com / admin123', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.neonCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : AppColors.textMuted,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
