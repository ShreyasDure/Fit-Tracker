import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:math' as math;

import '../core/constants.dart';
import '../controllers/auth_controller.dart';
import '../services/health_service.dart';
import 'settings_screen.dart';

import 'health_report_screen.dart';
import '../services/mongodb_service.dart';

final achievementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await MongoDbService.getAchievements();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _auraController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _auraController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final health = ref.watch(healthControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Stack(
        children: [
          // 1. Background Visuals
          _buildBackgroundHUD(),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  // 2. Profile Header (Settings Icon)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.settings_rounded, color: Colors.white24),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                  ),
                  
                  // 3. Immersive Hero Section
                  _buildProfileHero(user),
                  
                  const SizedBox(height: 30),
                  
                  // 4. Achievement Stats Grid
                  _buildStatsGrid(user),
                  
                  const SizedBox(height: 30),
                  
                  // 5. XP Progression Module
                  _buildXPProgression(user),
                  
                  const SizedBox(height: 30),
                  
                  // 6. Badges & Achievements
                  _buildBadgesSection(health),
                  
                  const SizedBox(height: 30),
                  
                  // 7. Today's Activity Summary
                  _buildActivitySummary(health),
                  
                  const SizedBox(height: 40),
                  
                  // 8. Quick Action Hub
                  _buildQuickActionHub(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncAchievements() async {
    try {
      await MongoDbService.syncAchievements();
      ref.invalidate(achievementsProvider);
    } catch (e) {
      // Silent fail
    }
  }

  Widget _buildBackgroundHUD() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, -0.6),
            radius: 1.5,
            colors: [Color(0xFF0A0A25), Color(0xFF050510)],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Holographic Aura
            AnimatedBuilder(
              animation: _auraController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _auraController.value * 2 * math.pi,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2), width: 1.5),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: CustomPaint(
                      painter: _AuraPainter(AppColors.neonCyan),
                    ),
                  ),
                );
              },
            ),
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 2),
                ],
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 42),
                ),
              ),
            ),
            // Online Indicator
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.neonGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF050510), width: 3),
                  boxShadow: [BoxShadow(color: AppColors.neonGreen.withValues(alpha: 0.5), blurRadius: 10)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          user?.name ?? 'User',
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.neonCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${user?.levelName ?? 'Bronze'} Athlete'.toUpperCase(),
            style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(user) {
    final stats = [
      {'label': 'TOTAL POINTS', 'value': '${user?.points ?? 0}', 'icon': Icons.stars_rounded, 'color': AppColors.neonCyan},
      {'label': 'DAILY STREAK', 'value': '${user?.streak ?? 0}d', 'icon': Icons.local_fire_department_rounded, 'color': AppColors.neonOrange},
      {'label': 'CURRENT LVL', 'value': 'Lv.${user?.level ?? 1}', 'icon': Icons.emoji_events_rounded, 'color': AppColors.neonPurple},
      {'label': 'WEEKLY GROWTH', 'value': '+14%', 'icon': Icons.trending_up_rounded, 'color': AppColors.neonGreen},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        final color = s['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(s['icon'] as IconData, color: color, size: 16),
              const Spacer(),
              Text(s['value'] as String, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              Text(s['label'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildXPProgression(user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LEVEL PROGRESSION', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text('XP: 1,450 / 2,000', style: TextStyle(color: AppColors.neonCyan.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: user?.levelProgress ?? 0.72,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.03),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('600 XP TO', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('SILVER RANK'.toUpperCase(), style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(health) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ACHIEVEMENTS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            GestureDetector(
              onTap: _syncAchievements,
              child: const Icon(Icons.refresh_rounded, color: Colors.white24, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        achievementsAsync.when(
          data: (achievements) {
            if (achievements.isEmpty) {
              return const Text('No achievements unlocked yet.', style: TextStyle(color: Colors.white24, fontSize: 12));
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final a = achievements[index];
                final isUnlocked = a['isUnlocked'] == true;
                final rarity = a['rarity'] ?? 'Common';
                final color = _getRarityColor(rarity);
                final progress = (a['progress'] as num?)?.toDouble() ?? 0.0;
                final target = (a['target'] as num?)?.toDouble() ?? 1.0;

                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress Ring
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            value: progress / target,
                            strokeWidth: 2,
                            color: color.withValues(alpha: isUnlocked ? 1.0 : 0.2),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isUnlocked ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withValues(alpha: isUnlocked ? 0.3 : 0.1)),
                          ),
                          child: Center(
                            child: Opacity(
                              opacity: isUnlocked ? 1.0 : 0.3,
                              child: Text(
                                a['icon'] ?? '🏆',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                        if (isUnlocked)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: AppColors.neonGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.check, color: Colors.black, size: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (a['title'] ?? '').toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white24,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: LinearProgressIndicator()),
          error: (e, s) => const Text('Failed to load achievements', style: TextStyle(color: AppColors.error, fontSize: 10)),
        ),
      ],
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Legendary': return AppColors.neonYellow;
      case 'Epic': return AppColors.neonPurple;
      case 'Rare': return AppColors.neonCyan;
      default: return Colors.white38;
    }
  }

  Widget _buildActivitySummary(HealthData health) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActivityRing('Steps', health.steps.toString(), AppColors.neonCyan, 0.7),
          _buildActivityRing('Cals', health.calories.toString(), AppColors.neonOrange, 0.5),
          _buildActivityRing('Mins', health.activeMinutes.toString(), AppColors.neonGreen, 0.8),
        ],
      ),
    );
  }

  Widget _buildActivityRing(String label, String value, Color color, double progress) {
    return Column(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: Colors.white.withValues(alpha: 0.03),
          ),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildQuickActionHub() {
    return Row(
      children: [
        _buildActionChip('Download Report', Icons.picture_as_pdf_rounded, AppColors.neonCyan, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthReportScreen()));
        }),
        const SizedBox(width: 12),
        _buildActionChip('Log Out', Icons.logout_rounded, AppColors.error, () => ref.read(authControllerProvider.notifier).logout()),
      ],
    );
  }

  Widget _buildActionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  final Color color;
  _AuraPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), angle, math.pi / 4, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
