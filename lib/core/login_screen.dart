import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'constants.dart';
import '../controllers/auth_controller.dart';
import '../services/mongodb_service.dart';
import '../services/biometric_service.dart';

// Admin registration code — change this to your own secret
const String _adminSecretCode = 'ADMIN2026';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _adminCodeCtrl = TextEditingController();
  final _signupOtpCtrl = TextEditingController();
  
  bool _isLogin = true;
  bool _wantsAdmin = false;
  bool _obscurePassword = true;
  bool _showSignupOtp = false;
  bool _otpLoading = false;
  String? _otpError;

  late AnimationController _animCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _bgCtrl;
  late Animation<double> _fadeAnim;

  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;


  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutQuart);
    _animCtrl.forward();

    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _adminCodeCtrl.dispose();
    _signupOtpCtrl.dispose();
    _animCtrl.dispose();
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final supported = await BiometricService.isBiometricAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    setState(() {
      _isBiometricSupported = supported;
      _isBiometricEnabled = enabled;
    });

    // Auto-trigger on launch if enabled
    if (enabled && mounted) {
      ref.read(authControllerProvider.notifier).biometricLogin();
    }
  }

  void _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    if (_isLogin) {
      await ref.read(authControllerProvider.notifier).login(email, password);
      // Check if login was successful and prompt for biometrics
      if (ref.read(authControllerProvider).status == AuthStatus.authenticated) {
        _promptBiometrics();
      }
    } else {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) return;
      final registerStrength = _getPasswordStrength(password);
      if (!_isStrongPassword(password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(registerStrength.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

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

      // Send OTP first, then show OTP field
      setState(() { _otpLoading = true; _otpError = null; });
      _sendSignupOtpAsync(name, email, password, role);
    }
  }

  Future<void> _sendSignupOtpAsync(String name, String email, String password, String role) async {
    try {
      await ref.read(authControllerProvider.notifier).sendSignupOtp(name, email, password, role: role);
      setState(() { _otpLoading = false; _showSignupOtp = true; });
    } catch (e) {
      setState(() { _otpLoading = false; _otpError = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  void _promptBiometrics() async {
    if (!_isBiometricSupported || _isBiometricEnabled) return;

    final enrollable = await BiometricService.hasEnrolledBiometrics();
    if (!enrollable) return;

    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.fingerprint_rounded, color: AppColors.neonCyan, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Enable Quick Login?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Use fingerprint or face unlock for faster and secure access next time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).enableBiometrics();
                  if (mounted) Navigator.pop(context);
                  _checkBiometrics();
                },
                child: const Text('ENABLE BIOMETRIC'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('MAYBE LATER', style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }

  void _verifySignupOtp() async {
    final otp = _signupOtpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _otpError = 'Please enter the 6-digit OTP');
      return;
    }
    setState(() { _otpLoading = true; _otpError = null; });
    try {
      await ref.read(authControllerProvider.notifier).verifyAndRegister(_emailCtrl.text.trim(), otp);
      setState(() => _otpLoading = false);
      _promptBiometrics();
    } catch (e) {
      setState(() { _otpLoading = false; _otpError = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ForgotPasswordSheet(),
    );
  }  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Stack(
        children: [
          _buildAnimatedBackground(size),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      _buildHeroSection(),
                      const SizedBox(height: 32),
                      _buildAuthModeSwitcher(),
                      const SizedBox(height: 32),
                      _buildInputSection(authState),
                      const SizedBox(height: 24),
                      _buildPrimaryAction(authState),
                      const SizedBox(height: 24),
                      _buildSecondaryActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (context, child) {
        return Stack(
          children: [
            // Mesh Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.5, -0.2),
                  radius: 1.5,
                  colors: [Color(0xFF0A1A40), Color(0xFF050510)],
                ),
              ),
            ),
            // Floating Orbs
            Positioned(
              top: (size.height * 0.1 + (math.sin(_bgCtrl.value * 2 * math.pi) * 20)).toDouble(),
              left: (-50 + (math.cos(_bgCtrl.value * 2 * math.pi) * 30)).toDouble(),
              child: _buildGlowOrb(150, AppColors.neonCyan.withValues(alpha: 0.15)),
            ),
            Positioned(
              bottom: (size.height * 0.2 + (math.cos(_bgCtrl.value * 2 * math.pi) * 40)).toDouble(),
              right: (-30 + (math.sin(_bgCtrl.value * 2 * math.pi) * 20)).toDouble(),
              child: _buildGlowOrb(180, AppColors.neonPurple.withValues(alpha: 0.15)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 20)],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        // Animated Logo
        ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.05).animate(_pulseCtrl),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              child: const Icon(Icons.bolt_rounded, color: AppColors.neonCyan, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'FitTracker ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.neonGreen, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(
              'Your intelligent fitness ecosystem',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuthModeSwitcher() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _buildModeTab('Sign In', _isLogin, () => setState(() => _isLogin = true)),
          _buildModeTab('Register', !_isLogin, () => setState(() => _isLogin = false)),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: active ? AppColors.neonCyan.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.4),
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(AuthState authState) {
    return Column(
      children: [
        if (!_isLogin) ...[
          _buildGlassField(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
          const SizedBox(height: 16),
        ],
        _buildGlassField(_emailCtrl, 'Email Address', Icons.alternate_email_rounded),
        const SizedBox(height: 16),
        _buildGlassField(
          _passwordCtrl, 
          'Password', 
          Icons.lock_outline_rounded, 
          obscure: _obscurePassword,
          onSuffix: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        if (_isLogin)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPassword,
              child: const Text('Forgot Password?', style: TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        if (!_isLogin) ...[
          const SizedBox(height: 8),
          _PasswordStrengthIndicator(password: _passwordCtrl.text),
          const SizedBox(height: 16),
          _buildAdminToggle(),
        ],
      ],
    );
  }

  Widget _buildGlassField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, VoidCallback? onSuffix}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
          prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 20),
          suffixIcon: onSuffix != null 
            ? IconButton(icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white38, size: 18), onPressed: onSuffix)
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildAdminToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _wantsAdmin ? AppColors.neonPurple.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wantsAdmin ? AppColors.neonPurple.withValues(alpha: 0.2) : Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: AppColors.neonPurple, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('Register as Admin', style: TextStyle(color: Colors.white70, fontSize: 13))),
              Switch(
                value: _wantsAdmin,
                onChanged: (v) => setState(() => _wantsAdmin = v),
                activeColor: AppColors.neonPurple,
              ),
            ],
          ),
          if (_wantsAdmin)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildGlassField(_adminCodeCtrl, 'Secret Admin Code', Icons.vpn_key_outlined),
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(AuthState authState) {
    final bool loading = authState.isLoading || _otpLoading;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.neonCyan, AppColors.neonCyan.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(
                _isLogin ? 'ENTER ECOSYSTEM' : 'INITIALIZE ACCOUNT',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: Colors.white10)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR CONNECT VIA', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold))),
            Expanded(child: Divider(color: Colors.white10)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialBtn(Icons.g_mobiledata_rounded, AppColors.neonCyan),
            const SizedBox(width: 20),
            _buildSocialBtn(Icons.apple_rounded, Colors.white),
            if (_isBiometricSupported && _isBiometricEnabled) ...[
              const SizedBox(width: 20),
              _buildSocialBtn(
                Icons.fingerprint_rounded, 
                AppColors.neonGreen, 
                isBiometric: true,
                onTap: () => ref.read(authControllerProvider.notifier).biometricLogin(),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSocialBtn(IconData icon, Color color, {bool isBiometric = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (isBiometric) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secure Biometric Auth Active')));
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: color, size: 28),
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
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.neonCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Theme.of(context).textTheme.bodySmall!.color!,
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

// ─── OTP-Based Forgot Password Sheet ───

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();
  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  int _step = 0; // 0: email, 1: OTP, 2: new password, 3: success
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await MongoDbService.forgotPassword(email);
      setState(() { _isLoading = false; _step = 1; });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Please enter the 6-digit OTP');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final verified = await MongoDbService.verifyOtp(_emailCtrl.text.trim(), otp);
      if (verified) {
        setState(() { _isLoading = false; _step = 2; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();
    if (!_isStrongPassword(newPass)) { setState(() => _error = _getPasswordStrength(newPass).message); return; }
    if (newPass != confirm) { setState(() => _error = 'Passwords do not match'); return; }

    setState(() { _isLoading = true; _error = null; });
    try {
      await MongoDbService.resetPassword(_emailCtrl.text.trim(), _otpCtrl.text.trim(), newPass);
      setState(() { _isLoading = false; _step = 3; });
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
          if (_step == 0) _buildEmailStep(),
          if (_step == 1) _buildOtpStep(),
          if (_step == 2) _buildNewPasswordStep(),
          if (_step == 3) _buildSuccessStep(),
        ],
      ),
    );
  }

  Widget _errorBox() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: AppSizes.sm),
      child: Container(
        padding: EdgeInsets.all(AppSizes.sm),
        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 12))),
        ]),
      ),
    );
  }

  // Step 0: Enter Email
  Widget _buildEmailStep() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.lock_reset_rounded, color: AppColors.neonCyan, size: 28),
      ),
      const SizedBox(height: AppSizes.md),
      Text('Forgot Password?', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSizes.sm),
      Text('Enter your email and we\'ll send you a 6-digit OTP to reset your password.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 13)),
      const SizedBox(height: AppSizes.xl),
      TextField(controller: _emailCtrl, style: TextStyle(color: Colors.white), keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded, color: Theme.of(context).textTheme.bodySmall!.color!))),
      _errorBox(),
      const SizedBox(height: AppSizes.xl),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _sendOtp, child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Send OTP'))),
      const SizedBox(height: AppSizes.sm),
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Back to Login', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!))),
    ]);
  }

  // Step 1: Enter OTP
  Widget _buildOtpStep() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: AppColors.neonOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.pin_rounded, color: AppColors.neonOrange, size: 28),
      ),
      const SizedBox(height: AppSizes.md),
      Text('Enter OTP', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSizes.sm),
      Text('We sent a 6-digit code to ${_emailCtrl.text.trim()}', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 13)),
      const SizedBox(height: AppSizes.sm),
      const Text('⏰ Code expires in 5 minutes', style: TextStyle(color: AppColors.neonOrange, fontSize: 11)),
      const SizedBox(height: AppSizes.xl),
      TextField(
        controller: _otpCtrl, style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w800),
        textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 6,
        decoration: InputDecoration(counterText: '', hintText: '000000', hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 24, letterSpacing: 8)),
      ),
      _errorBox(),
      const SizedBox(height: AppSizes.xl),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _verifyOtp, child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Verify OTP'))),
      const SizedBox(height: AppSizes.sm),
      TextButton(onPressed: () { _otpCtrl.clear(); _sendOtp(); }, child: const Text('Resend OTP', style: TextStyle(color: AppColors.neonCyan, fontSize: 13))),
      TextButton(onPressed: () => setState(() { _step = 0; _error = null; }), child: Text('Back', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!))),
    ]);
  }

  // Step 2: Set New Password
  Widget _buildNewPasswordStep() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: AppColors.neonGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.lock_rounded, color: AppColors.neonGreen, size: 28),
      ),
      const SizedBox(height: AppSizes.md),
      Text('New Password', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSizes.sm),
      Text('Create a strong new password.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 13)),
      const SizedBox(height: AppSizes.xl),
      TextField(controller: _newPassCtrl, obscureText: _obscureNew, style: TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_rounded, color: Theme.of(context).textTheme.bodySmall!.color!),
          suffixIcon: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).textTheme.bodySmall!.color!, size: 20), onPressed: () => setState(() => _obscureNew = !_obscureNew))),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 6),
      _PasswordStrengthIndicator(password: _newPassCtrl.text.trim()),
      const SizedBox(height: AppSizes.sm),
      TextField(controller: _confirmPassCtrl, obscureText: _obscureConfirm, style: TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline_rounded, color: Theme.of(context).textTheme.bodySmall!.color!),
          suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).textTheme.bodySmall!.color!, size: 20), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)))),
      _errorBox(),
      const SizedBox(height: AppSizes.xl),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _resetPassword, child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Reset Password'))),
      TextButton(onPressed: () => setState(() { _step = 1; _error = null; }), child: Text('Back', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!))),
    ]);
  }

  // Step 3: Success
  Widget _buildSuccessStep() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.neonGreen.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 40),
      ),
      const SizedBox(height: AppSizes.lg),
      Text('Password Reset!', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.neonGreen)),
      const SizedBox(height: AppSizes.sm),
      Text('Your password has been updated. You can now login with your new password.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 13)),
      const SizedBox(height: AppSizes.xl),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Login'))),
      const SizedBox(height: AppSizes.md),
    ]);
  }
}

class _PasswordStrength {
  final String label;
  final Color color;
  final String message;
  const _PasswordStrength(this.label, this.color, this.message);
}

_PasswordStrength _getPasswordStrength(String password) {
  final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
  final hasLower = RegExp(r'[a-z]').hasMatch(password);
  final hasDigit = RegExp(r'\d').hasMatch(password);
  final hasSpecial = RegExp(r'[^A-Za-z\d]').hasMatch(password);
  final meetsLength = password.length >= 8;
  final checks = [hasUpper, hasLower, hasDigit, hasSpecial, meetsLength].where((v) => v).length;

  if (checks <= 2) {
    return const _PasswordStrength(
      'Weak',
      AppColors.error,
      'Password must include uppercase, lowercase, number, and special character.',
    );
  }
  if (checks <= 4) {
    return const _PasswordStrength(
      'Medium',
      AppColors.neonOrange,
      'Add missing rules to make password strong.',
    );
  }
  return const _PasswordStrength('Strong', AppColors.neonGreen, 'Strong password');
}

bool _isStrongPassword(String password) {
  return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$').hasMatch(password);
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = _getPasswordStrength(password);
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 14, color: strength.color),
          const SizedBox(width: 4),
          Text(
            strength.label,
            style: TextStyle(
              color: strength.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}



