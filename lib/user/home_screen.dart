
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../controllers/auth_controller.dart';
import '../services/health_service.dart';
import '../services/mongodb_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';
import 'notification_panel.dart';
import 'todays_diet_screen.dart';
import 'points_screen.dart' show levelSettingsProvider;

final latestBmiProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final history = await MongoDbService.getBmiHistory();
  if (history.isEmpty) return null;
  return history.first;
});

final userActivitiesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await MongoDbService.getUserActivities();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _hudController;
  late AnimationController _pulseController;
  late AnimationController _weatherIconController;
  final ScrollController _scrollController = ScrollController();

  WeatherData? _weather;
  String? _weatherError;
  bool _isLoadingWeather = false;

  late final List<Particle> _particles = List.generate(
    15,
    (index) => Particle(
      x: math.Random().nextDouble() * 300,
      y: math.Random().nextDouble() * 150,
      speed: 0.1 + math.Random().nextDouble() * 0.3,
      theta: math.Random().nextDouble() * 2 * math.pi,
      radius: 1.5 + math.Random().nextDouble() * 2.5,
    ),
  );

  bool get _isTesting {
    try {
      return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _hudController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _weatherIconController = AnimationController(vsync: this, duration: const Duration(seconds: 3));

    if (!_isTesting) {
      _hudController.repeat();
      _pulseController.repeat(reverse: true);
      _weatherIconController.repeat();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(healthControllerProvider.notifier).onAppResume();
        ref.read(notificationControllerProvider.notifier).fetchAdminNotifications();
        _loadWeather();
      }
    });
  }

  @override
  void dispose() {
    _hudController.dispose();
    _pulseController.dispose();
    _weatherIconController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final health = ref.watch(healthControllerProvider);
    final latestBmiAsync = ref.watch(latestBmiProvider);
    final notifPermissionGranted = ref.watch(notifPermissionGrantedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050510), // Ultra Dark Navy
      body: Stack(
        children: [
          // 1. Background HUD Layer
          _buildBackgroundHUD(),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(healthControllerProvider.notifier).sync();
                await ref.read(authControllerProvider.notifier).refreshProfile();
                await _loadWeather(force: true);
                ref.invalidate(userActivitiesProvider);
              },
              color: AppColors.neonCyan,
              backgroundColor: const Color(0xFF0A0A25),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 2. Futuristic Header
                  SliverToBoxAdapter(child: _buildFuturisticHeader(user)),
                  
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (health.sensorError != null) ...[
                          _buildSensorErrorBanner(health.sensorError!),
                          const SizedBox(height: 16),
                        ],
                        if (!notifPermissionGranted) ...[
                          _buildNotificationDisabledBanner(),
                          const SizedBox(height: 16),
                        ],
                        // 3. Immersive Activity Hero
                        _buildActivityHero(health),
                        
                        const SizedBox(height: 24),
                        
                        // 3.5. Weather Insight Card
                        _buildWeatherInsightCard(),
                        
                        const SizedBox(height: 24),
                        
                        // 4. Achievement Card (Points + Level)
                        _buildAchievementCard(user),
                        
                        const SizedBox(height: 24),
                        
                        // 5. Today's Health Stats Grid
                        _buildHealthStatsGrid(health, latestBmiAsync),
                        
                        const SizedBox(height: 24),

                        // 6. Quick Action Chips
                        _buildQuickActions(),
                        
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF1744).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF1744)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationDisabledBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9100).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9100).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_off_outlined, color: Color(0xFFFF9100)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications disabled',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundHUD() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.7, -0.6),
                radius: 1.5,
                colors: [Color(0xFF0A0A25), Color(0xFF050510)],
              ),
            ),
          ),
          Opacity(
            opacity: 0.05,
            child: GridPaper(
              color: AppColors.neonCyan,
              divisions: 1,
              subdivisions: 1,
              interval: 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticHeader(user) {
    final notifState = ref.watch(notificationControllerProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 10),
      child: Row(
        children: [
          // Glowing Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.neonCyan.withValues(alpha: 0.3 * _pulseController.value),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.1 * _pulseController.value),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello ${toTitleCase(user?.name.split(' ').first ?? 'User')} 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                Text(
                  'Consistency Is Improving 🚀',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Action Buttons
          _buildHeaderIcon(
            notifState.totalUnread > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
            notifState.totalUnread > 0 ? '${notifState.totalUnread}' : null,
            AppColors.neonCyan,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPanel())),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, String? badge, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          if (badge != null && badge != "0")
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityHero(HealthData health) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 15)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text('DAILY ACTIVITY', style: TextStyle(color: AppColors.neonCyan, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: health.steps),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Text('${_formatNumber(value)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1));
                  },
                ),
                Text('steps today', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                Text(
                  health.steps < health.stepsGoal 
                    ? '${_formatNumber(health.stepsGoal - health.steps)} away from goal 💪'
                    : 'Target cleared! 🔥',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Animated Ring
          Expanded(
            flex: 2,
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 10,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.03)),
                    ),
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonGreen]).createShader(rect),
                      child: CircularProgressIndicator(
                        value: health.stepsProgress.clamp(0.01, 1.0),
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Text('${health.stepsPercent}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(user) {
    final levelSettingsAsync = ref.watch(levelSettingsProvider);

    return levelSettingsAsync.when(
      loading: () => _achievementCardInner(user, 2000, 5000),
      error: (_, __) => _achievementCardInner(user, 2000, 5000),
      data: (settings) {
        final silverMin = (settings['silverMinPoints'] as num? ?? 2000).toInt();
        final goldMin = (settings['goldMinPoints'] as num? ?? 5000).toInt();
        return _achievementCardInner(user, silverMin, goldMin);
      },
    );
  }

  Widget _achievementCardInner(user, int silverMin, int goldMin) {
    final levelName = user?.levelNameWith(silverMin, goldMin) ?? 'Bronze';
    final levelProgress = user?.levelProgressWith(silverMin, goldMin) ?? 0.0;
    final nextLevel = levelName == 'Gold' ? 'Max' : (levelName == 'Silver' ? 'Gold ($goldMin pts)' : 'Silver ($silverMin pts)');
    final levelColor = levelName == 'Gold'
        ? const Color(0xFFFFD700)
        : levelName == 'Silver'
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor.withValues(alpha: 0.08), AppColors.neonPurple.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: levelColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACHIEVEMENTS', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.neonYellow, size: 18),
                      const SizedBox(width: 8),
                      Text('${user?.points ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                      const Text(' PTS', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: levelColor.withValues(alpha: 0.3)),
                ),
                child: Text(levelName, style: TextStyle(color: levelColor, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: levelProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.03),
              valueColor: AlwaysStoppedAnimation<Color>(levelColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(levelName, style: TextStyle(color: levelColor, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('Next: $nextLevel', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatsGrid(HealthData health, AsyncValue latestBmi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TODAY\'S HEALTH STATS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMiniStatCard('Calories', '${health.calories}', 'kcal', Icons.local_fire_department_rounded, AppColors.neonOrange),
            _buildMiniStatCard('Active Min', '${health.activeMinutes}', 'min', Icons.timer_rounded, AppColors.neonGreen),
            _buildMiniStatCard('Heart Rate', '${health.heartRate}', 'bpm', Icons.favorite_rounded, AppColors.neonPink),
            _buildBMICardUpgrade(latestBmi),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Text('$label • $unit', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBMICardUpgrade(AsyncValue latestBmi) {
    return latestBmi.when(
      data: (data) {
        final bmi = (data?['bmi'] as num?)?.toDouble() ?? 0.0;
        final category = _bmiCategory(bmi);
        final color = _bmiColor(category);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.monitor_weight_rounded, color: color, size: 18),
                    const Spacer(),
                    Text(bmi == 0 ? '--' : bmi.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(category.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Body Silhouette Icon/Illustration
              Opacity(
                opacity: 0.2,
                child: Icon(Icons.accessibility_new_rounded, color: color, size: 42),
              ),
            ],
          ),
        );
      },
      loading: () => Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(26))),
      error: (e, s) => Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(26))),
    );
  }


  Widget _buildQuickActions() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TodaysDietScreen()),
      ),
      child: Consumer(
        builder: (context, ref, _) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonGreen.withValues(alpha: 0.06),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.neonGreen.withValues(alpha: 0.2), AppColors.neonCyan.withValues(alpha: 0.1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: AppColors.neonGreen, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today's Nutrition", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                        Text('AI powered diet tracking', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.neonGreen, size: 10),
                          SizedBox(width: 4),
                          Text('AI', style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.2), size: 14),
                  ],
                ),
                const SizedBox(height: 20),
                // Calorie progress bar
                FutureBuilder<Map<String, dynamic>>(
                  future: MongoDbService.getTodayNutritionSummary(),
                  builder: (context, snap) {
                    final summary = snap.data?['summary'] as Map<String, dynamic>? ?? {};
                    final cal = (summary['totalCalories'] as num? ?? 0).toInt();
                    final protein = (summary['totalProtein'] as num? ?? 0).toInt();
                    final carbs = (summary['totalCarbs'] as num? ?? 0).toInt();
                    final fat = (summary['totalFat'] as num? ?? 0).toInt();
                    const targetCal = 2100;
                    final progress = (cal / targetCal).clamp(0.0, 1.0);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Calorie row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$cal kcal',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            Text(
                              '/ $targetCal kcal',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Progress bar
                        Stack(
                          children: [
                            Container(
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 7,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.neonGreen, AppColors.neonCyan],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.neonGreen.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Macros row
                        Row(
                          children: [
                            _buildMacroChip('P', '$protein g', AppColors.neonPink),
                            const SizedBox(width: 8),
                            _buildMacroChip('C', '$carbs g', AppColors.neonOrange),
                            const SizedBox(width: 8),
                            _buildMacroChip('F', '$fat g', AppColors.neonYellow),
                            const Spacer(),
                            Text(
                              cal == 0 ? 'Log your meals →' : '${(progress * 100).toInt()}% of goal',
                              style: TextStyle(
                                color: cal == 0 ? AppColors.neonGreen : Colors.white.withValues(alpha: 0.4),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    final str = value.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (m) => ',');
  }

  String _bmiCategory(double bmi) {
    if (bmi < 1) return 'No Data';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _bmiColor(String category) {
    switch (category) {
      case 'Normal': return AppColors.neonGreen;
      case 'Overweight': return AppColors.neonOrange;
      case 'Obese': return AppColors.error;
      default: return AppColors.neonPurple;
    }
  }

  Future<void> _loadWeather({bool force = false}) async {
    if (mounted) {
      setState(() {
        _isLoadingWeather = true;
        _weatherError = null;
      });
    }
    try {
      if (force) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_weather_data');
      }
      final data = await WeatherService.fetchWeather();
      if (mounted) {
        setState(() {
          _weather = data;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = e.toString().replaceAll('Exception: ', '');
          _isLoadingWeather = false;
        });
      }
    }
  }

  List<Color> _getWeatherGradients(String condition, int isDay) {
    if (isDay == 0) {
      return [
        const Color(0xFF1E0B36).withValues(alpha: 0.6),
        const Color(0xFF0F051D).withValues(alpha: 0.8),
      ];
    }
    switch (condition) {
      case 'Sunny':
        return [
          const Color(0xFFFF8C00).withValues(alpha: 0.25),
          const Color(0xFFFFD700).withValues(alpha: 0.1),
        ];
      case 'Rainy':
        return [
          const Color(0xFF0052D4).withValues(alpha: 0.25),
          const Color(0xFF4364F7).withValues(alpha: 0.1),
        ];
      case 'Cloudy':
      case 'Foggy':
        return [
          const Color(0xFF4A5660).withValues(alpha: 0.25),
          const Color(0xFF2C3E50).withValues(alpha: 0.1),
        ];
      case 'Snowy':
        return [
          const Color(0xFF7F00FF).withValues(alpha: 0.2),
          const Color(0xFFE100FF).withValues(alpha: 0.1),
        ];
      default:
        return [
          const Color(0xFF0A0A25).withValues(alpha: 0.6),
          const Color(0xFF020208).withValues(alpha: 0.8),
        ];
    }
  }

  Color _getWeatherAccentColor(String condition, int isDay) {
    if (isDay == 0) return Colors.purpleAccent;
    switch (condition) {
      case 'Sunny': return Colors.amber;
      case 'Rainy': return AppColors.neonCyan;
      case 'Cloudy': return Colors.blueGrey;
      case 'Foggy': return Colors.grey;
      case 'Snowy': return Colors.lightBlueAccent;
      default: return AppColors.neonCyan;
    }
  }

  Widget _buildAnimatedWeatherIcon(String condition, int isDay) {
    if (isDay == 0) {
      return AnimatedBuilder(
        animation: _weatherIconController,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.95 + 0.05 * math.sin(_weatherIconController.value * 2 * math.pi),
            child: const Icon(Icons.nightlight_round_rounded, color: Colors.purpleAccent, size: 36),
          );
        },
      );
    }
    switch (condition) {
      case 'Sunny':
        return RotationTransition(
          turns: _weatherIconController,
          child: const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 36),
        );
      case 'Cloudy':
        return AnimatedBuilder(
          animation: _weatherIconController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(math.sin(_weatherIconController.value * 2 * math.pi) * 3, 0),
              child: Icon(Icons.cloud_rounded, color: Colors.white60, size: 36),
            );
          },
        );
      case 'Foggy':
        return AnimatedBuilder(
          animation: _weatherIconController,
          builder: (context, child) {
            return Opacity(
              opacity: 0.6 + 0.4 * _weatherIconController.value,
              child: const Icon(Icons.blur_on_rounded, color: Colors.white38, size: 36),
            );
          },
        );
      case 'Snowy':
        return AnimatedBuilder(
          animation: _weatherIconController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _weatherIconController.value * 2 * math.pi,
              child: const Icon(Icons.ac_unit_rounded, color: Colors.lightBlueAccent, size: 36),
            );
          },
        );
      case 'Rainy':
      default:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.cloud_rounded, color: Colors.blueGrey[400], size: 36),
            Positioned(
              bottom: 0,
              child: AnimatedBuilder(
                animation: _weatherIconController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.8,
                    child: Transform.translate(
                      offset: Offset(0, 2 + 6 * _weatherIconController.value),
                      child: const Row(
                        children: [
                          Icon(Icons.water_drop_rounded, color: Colors.blue, size: 8),
                          SizedBox(width: 4),
                          Icon(Icons.water_drop_rounded, color: Colors.blue, size: 8),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
    }
  }

  Widget _buildWeatherInsightCard() {
    if (_isLoadingWeather && _weather == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.neonCyan),
        ),
      );
    }

    if (_weatherError != null && _weather == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weather Sync Suspended',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weatherError!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
              onPressed: () => _loadWeather(force: true),
            ),
          ],
        ),
      );
    }

    final weather = _weather;
    if (weather == null) return const SizedBox.shrink();

    final glowColor = _getWeatherAccentColor(weather.condition, weather.isDay);
    final gradientColors = _getWeatherGradients(weather.condition, weather.isDay);

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: AnimatedBuilder(
        animation: _hudController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + 2.0 * math.sin(_hudController.value * 2 * math.pi), -1.0),
                end: Alignment(1.0 - 2.0 * math.sin(_hudController.value * 2 * math.pi), 1.0),
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: glowColor.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.04),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: WeatherParticlesPainter(
                      _particles,
                      _hudController.value,
                      glowColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildAnimatedWeatherIcon(weather.condition, weather.isDay),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${weather.temp.toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    weather.condition,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _isLoadingWeather ? null : () => _loadWeather(force: true),
                            child: AnimatedBuilder(
                              animation: _weatherIconController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _isLoadingWeather ? _weatherIconController.value * 2 * math.pi : 0.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                      boxShadow: _isLoadingWeather ? [
                                        BoxShadow(
                                          color: glowColor.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ] : null,
                                    ),
                                    child: Icon(
                                      Icons.refresh_rounded,
                                      color: _isLoadingWeather ? glowColor : Colors.white70,
                                      size: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Fitness Recommendation badge placed above recommendation text to avoid overflow
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: glowColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: glowColor.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 10),
                            SizedBox(width: 4),
                            Text(
                              'FITNESS RECOMMENDATION',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        weather.recommendation,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildWeatherChip(Icons.thermostat_rounded, 'Feels Like', '${weather.feelsLike.toStringAsFixed(1)}°C'),
                          _buildWeatherChip(Icons.water_drop_rounded, 'Humidity', '${weather.humidity.toStringAsFixed(0)}%'),
                          _buildWeatherChip(Icons.air_rounded, 'Wind Speed', '${weather.windSpeed.toStringAsFixed(1)} km/h'),
                          _buildWeatherChip(Icons.wb_sunny_outlined, 'UV Index', weather.uvIndex.toStringAsFixed(1)),
                          _buildWeatherChip(Icons.wb_twilight_rounded, 'Sunrise/Sunset', '${weather.sunrise} / ${weather.sunset}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha: 0.3), size: 10),
                          const SizedBox(width: 4),
                          Text(
                            'Synced: ${_formatTime(weather.fetchedAt)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:$minute $ampm';
  }

  Widget _buildWeatherChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 12),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Colors.white30, fontSize: 8)),
              Text(value, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double speed;
  double theta;
  double radius;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.theta,
    required this.radius,
  });
}

class WeatherParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color color;

  WeatherParticlesPainter(this.particles, this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (var p in particles) {
      double currentY = (p.y - animationValue * p.speed * 120) % size.height;
      double currentX = (p.x + math.sin(animationValue * 2 * math.pi + p.theta) * 12) % size.width;

      canvas.drawCircle(Offset(currentX, currentY), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
