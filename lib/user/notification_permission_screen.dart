import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants.dart';

class NotificationPermissionScreen extends StatefulWidget {
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const NotificationPermissionScreen({super.key, required this.onAllow, required this.onSkip});

  @override
  State<NotificationPermissionScreen> createState() => _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState extends State<NotificationPermissionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _bellAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _slideAnim = CurvedAnimation(parent: _animCtrl, curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic));
    _bellAnim = CurvedAnimation(parent: _animCtrl, curve: const Interval(0.5, 1.0, curve: Curves.elasticOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A1A), Color(0xFF0D1B2A), Color(0xFF050510)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.xl),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // App icon
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.35), blurRadius: 30, spreadRadius: 2),
                        BoxShadow(color: AppColors.neonGreen.withValues(alpha: 0.15), blurRadius: 50, spreadRadius: 5),
                      ],
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: Colors.black, size: 36),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Text('FitTracker', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                const SizedBox(height: 4),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Text('Stay consistent with your fitness journey', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 13)),
                ),
                const Spacer(),
                // Glassmorphism card
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_slideAnim),
                  child: FadeTransition(
                    opacity: _slideAnim,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppSizes.xl),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            boxShadow: [
                              BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.05), blurRadius: 40),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Bell icon with glow
                              ScaleTransition(
                                scale: _bellAnim,
                                child: Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [AppColors.neonCyan.withValues(alpha: 0.2), AppColors.neonGreen.withValues(alpha: 0.1)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.2), blurRadius: 20),
                                    ],
                                  ),
                                  child: const Icon(Icons.notifications_active_rounded, color: AppColors.neonCyan, size: 30),
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),
                              Text('Enable Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSizes.md),
                              Text(
                                'Get workout reminders, daily streak updates, and personalized fitness tips to keep you motivated 💪',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 14, height: 1.5),
                              ),
                              const SizedBox(height: AppSizes.xxl),
                              // Allow button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [AppColors.neonCyan, Color(0xFF00897B)]),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: widget.onAllow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.notifications_rounded, color: Colors.black, size: 20),
                                        SizedBox(width: 8),
                                        Text('Allow Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.md),
                              // Not Now button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: widget.onSkip,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(context).textTheme.bodyMedium!.color!,
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text('Not Now', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Subtle privacy text
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    'You can change this later in Settings',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color!, fontSize: 11),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


