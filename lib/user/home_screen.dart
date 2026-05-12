import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../core/constants.dart';
import '../controllers/auth_controller.dart';
import '../services/health_service.dart';
import '../services/mongodb_service.dart';
import '../services/notification_service.dart';
import 'notification_panel.dart';
import 'todays_diet_screen.dart';

final latestBmiProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final history = await MongoDbService.getBmiHistory();
  if (history.isEmpty) return null;
  return history.first;
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _hudController;
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _hudController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(healthControllerProvider.notifier).onAppResume();
        ref.read(notificationControllerProvider.notifier).fetchAdminNotifications();
      }
    });
  }

  @override
  void dispose() {
    _hudController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final health = ref.watch(healthControllerProvider);
    final latestBmiAsync = ref.watch(latestBmiProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050510), // Ultra Dark Navy
      body: Stack(
        children: [
          // 1. Background HUD Layer
          _buildBackgroundHUD(),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => ref.read(healthControllerProvider.notifier).sync(),
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
                        // 3. Immersive Activity Hero
                        _buildActivityHero(health),
                        
                        const SizedBox(height: 24),
                        
                        // 4. Achievement Card (Points + Level)
                        _buildAchievementCard(user),
                        
                        const SizedBox(height: 24),
                        
                        // 5. Today's Health Stats Grid
                        _buildHealthStatsGrid(health, latestBmiAsync),
                        
                        const SizedBox(height: 24),
                        
                        // 6. AI Health Insights (Swipeable)
                        _buildAIInsights(health, user?.name ?? 'User'),
                        
                        const SizedBox(height: 24),
                        
                        // 7. Weekly Trend Chart
                        _buildWeeklyTrend(health),
                        
                        const SizedBox(height: 24),
                        
                        // 8. Quick Action Chips
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
                  'Hello ${user?.name.split(' ').first ?? 'User'} 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                Text(
                  'Consistency is improving 🚀',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Action Buttons
          _buildHeaderIcon(
            Icons.local_fire_department_rounded,
            '${user?.streak ?? 0}',
            AppColors.neonOrange,
            () {},
          ),
          const SizedBox(width: 10),
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.neonCyan.withValues(alpha: 0.08), AppColors.neonPurple.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                decoration: BoxDecoration(color: AppColors.neonPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3))),
                child: Text('Lv. ${user?.level ?? 1}', style: const TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: user?.levelProgress ?? 0.1,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.03),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(user?.levelName ?? 'Bronze', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              const Text('Next: Silver', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildAIInsights(HealthData health, String name) {
    final insights = [
      {'title': 'Activity', 'text': 'You improved 18% this week. Keep it up!', 'icon': Icons.trending_up_rounded, 'color': AppColors.neonCyan},
      {'title': 'Hydration', 'text': 'Water intake is below target for today.', 'icon': Icons.water_drop_rounded, 'color': Colors.blue},
      {'title': 'Goals', 'text': 'You are close to your calorie burn target.', 'icon': Icons.bolt_rounded, 'color': AppColors.neonOrange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI HEALTH INTELLIGENCE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: insights.length,
            itemBuilder: (context, i) {
              final ins = insights[i];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (ins['color'] as Color).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: (ins['color'] as Color).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(ins['icon'] as IconData, color: ins['color'] as Color, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(ins['title'] as String, style: TextStyle(color: ins['color'] as Color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(ins['text'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrend(HealthData health) {
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
              const Text('WEEKLY STEPS TREND', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Text('+12% vs last week', style: const TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 2.0,
            child: Padding(
              padding: const EdgeInsets.only(right: 18, left: 12, top: 10, bottom: 0),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5), FlSpot(3, 5), FlSpot(4, 4.5), FlSpot(5, 6), FlSpot(6, 7)],
                      isCurved: true,
                      color: AppColors.neonCyan,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true, 
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, 
                          end: Alignment.bottomCenter, 
                          colors: [AppColors.neonCyan.withValues(alpha: 0.15), Colors.transparent]
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionChip('Workouts', Icons.fitness_center_rounded, AppColors.neonCyan, () => Navigator.pushNamed(context, '/workouts')),
        const SizedBox(width: 12),
        _buildActionChip('Diet', Icons.restaurant_rounded, AppColors.neonGreen, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodaysDietScreen()))),
        const SizedBox(width: 12),
        _buildActionChip('Coach', Icons.smart_toy_rounded, AppColors.neonPurple, () => Navigator.pushNamed(context, '/ai')),
      ],
    );
  }

  Widget _buildActionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
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
}
