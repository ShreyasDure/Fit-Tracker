import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../models/user_model.dart';
import '../services/mongodb_service.dart';
import '../services/weather_service.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late AnimationController _weatherIconController;
  final ScrollController _mainScrollCtrl = ScrollController();

  WeatherData? _weather;
  bool _isLoadingWeather = false;
  String? _weatherError;

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
    _headerController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _weatherIconController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    if (!_isTesting) {
      _headerController.repeat();
      _pulseController.repeat(reverse: true);
      _weatherIconController.repeat();
    }
    _loadWeather();
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

  @override
  void dispose() {
    _headerController.dispose();
    _pulseController.dispose();
    _weatherIconController.dispose();
    _mainScrollCtrl.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminControllerProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFF020208), // Ultra Deep Navy
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackgroundHUD(),
          SafeArea(
            child: Column(
              children: [
                _buildProductionHeader(user),
                Expanded(
                  child: ListView(
                    controller: _mainScrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      _buildOverviewSection(admin),
                      const SizedBox(height: 24),
                      _buildQuickActions(admin),
                      const SizedBox(height: 24),
                      _buildBroadcastCenter(),
                      const SizedBox(height: 24),
                      _buildGrowthAndActivity(admin),
                      const SizedBox(height: 24),
                      _buildInsightsAndStatus(),
                      const SizedBox(height: 40),
                      _buildFooter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<UserModel> _getActiveUsers(List<UserModel> allUsers) {
    final now = DateTime.now();
    return allUsers.where((u) {
      if (u.role == 'admin') return false;
      if (u.isOnline) return true;
      if (u.lastActive != null) {
        return now.difference(u.lastActive!).inMinutes < 5;
      }
      return false;
    }).toList();
  }

  String _formatLastActive(DateTime? lastActive, bool isOnline) {
    if (isOnline) return 'Active now';
    if (lastActive == null) return 'Last active: Unknown';
    final diff = DateTime.now().difference(lastActive);
    if (diff.inSeconds < 60) {
      return 'Active just now';
    } else if (diff.inMinutes < 60) {
      return 'Active ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return 'Active ${diff.inHours}h ago';
    } else {
      return 'Active ${diff.inDays}d ago';
    }
  }

  Widget _buildBackgroundHUD() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.5, -0.2),
            radius: 1.2,
            colors: [Color(0xFF0A0A25), Color(0xFF020208)],
          ),
        ),
      ),
    );
  }

  Widget _buildProductionHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Panel',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    Text(
                      'Welcome back, ${user?.name ?? 'Admin'} 👋',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
              _buildHeaderButton(Icons.refresh_rounded, 'Refresh', AppColors.neonCyan, () {
                ref.read(adminControllerProvider.notifier).refreshAll();
                _loadWeather(force: true);
              }),
              const SizedBox(width: 8),
              _buildHeaderButton(Icons.logout_rounded, 'Sign Out', AppColors.error, () {
                ref.read(authControllerProvider.notifier).logout();
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.neonGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('System Operational', style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w700)),
                ],
              ),
              Text(
                '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} PM | May 18, 2025',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(AdminDashboardState admin) {
    final activeUsersList = _getActiveUsers(admin.users);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OVERVIEW', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Total Users", 
                  "${admin.totalUsers}", 
                  "+5.2%", 
                  AppColors.neonCyan, 
                  Icons.people_alt_rounded, 
                  () => _showUserList(context, 'Total Users', admin.users)
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  "Active Users", 
                  "${activeUsersList.length}", 
                  "+12.4%", 
                  AppColors.neonGreen, 
                  Icons.person_rounded, 
                  () => _showUserList(context, 'Active Users', activeUsersList)
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Total Points", 
                  _formatNumber(admin.totalPoints), 
                  "+8.7%", 
                  AppColors.neonYellow, 
                  Icons.star_rounded, 
                  () => _showLeaderboard(context)
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAdminWeatherCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminWeatherCard() {
    final glowColor = _weather != null 
        ? _getWeatherAccentColor(_weather!.condition, _weather!.isDay)
        : AppColors.neonCyan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glowColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: _isLoadingWeather 
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan, strokeWidth: 2))
          : _weatherError != null 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wb_cloudy_rounded, color: Colors.white24, size: 24),
                    const SizedBox(height: 4),
                    const Text('Weather Unavailable', style: TextStyle(color: Colors.white30, fontSize: 10), textAlign: TextAlign.center),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.neonCyan, size: 16),
                      onPressed: () => _loadWeather(force: true),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                )
              : _weather == null 
                  ? Center(
                      child: TextButton(
                        onPressed: () => _loadWeather(),
                        child: const Text('Load Weather', style: TextStyle(color: AppColors.neonCyan, fontSize: 11)),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _buildAdminWeatherIcon(_weather!.condition, _weather!.isDay),
                                const SizedBox(width: 6),
                                Text(
                                  '${_weather!.temp.toStringAsFixed(0)}°C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            // Mini refresh button with rotation & pulse glow when loading
                            GestureDetector(
                              onTap: _isLoadingWeather ? null : () => _loadWeather(force: true),
                              child: AnimatedBuilder(
                                animation: _weatherIconController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _isLoadingWeather ? _weatherIconController.value * 2 * math.pi : 0.0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _weather!.condition,
                              style: TextStyle(
                                color: glowColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getAdminWeatherRecommendation(_weather!.condition, _weather!.temp),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 9,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha: 0.3), size: 8),
                            const SizedBox(width: 4),
                            Text(
                              'Synced: ${_formatTime(_weather!.fetchedAt)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
    );
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

  Widget _buildAdminWeatherIcon(String condition, int isDay) {
    if (isDay == 0) return const Icon(Icons.nightlight_round_rounded, color: Colors.purpleAccent, size: 20);
    switch (condition) {
      case 'Sunny': return const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 20);
      case 'Cloudy': return const Icon(Icons.cloud_rounded, color: Colors.white60, size: 20);
      case 'Foggy': return const Icon(Icons.blur_on_rounded, color: Colors.white38, size: 20);
      case 'Snowy': return const Icon(Icons.ac_unit_rounded, color: Colors.lightBlueAccent, size: 20);
      case 'Rainy':
      default: return const Icon(Icons.beach_access_rounded, color: AppColors.neonCyan, size: 20);
    }
  }

  String _getAdminWeatherRecommendation(String condition, double temp) {
    if (condition == 'Rainy') {
      return 'Rain – lower outdoor workout traffic expected.';
    }
    if (condition == 'Sunny') {
      return 'Sunny – high outdoor activity expected.';
    }
    if (condition == 'Snowy') {
      return 'Snow – gyms expected to be busy.';
    }
    if (temp > 30) {
      return 'Extreme Heat – caution for runners.';
    }
    return 'Moderate – ideal outdoor exercise conditions.';
  }

  Widget _buildMetricCardFullWidth(String label, String value, String trend, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trend,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  'View all',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: color.withValues(alpha: 0.7),
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String trend, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Text(trend, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            Row(
              children: [
                Text('View all', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: color.withValues(alpha: 0.7), size: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(AdminDashboardState admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUICK ADMIN ACTIONS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildActionBox("Add Challenge", "Create new challenge", Icons.add_circle_outline_rounded, AppColors.neonCyan, () => _showAddChallengeModal(context)),
              _buildActionBox("Reward Users", "Give points/rewards", Icons.card_giftcard_rounded, AppColors.neonYellow, () => _showRewardUsersModal(context, admin.users)),
              _buildActionBox("Broadcast", "Send announcements", Icons.campaign_rounded, AppColors.neonPurple, () => _showBroadcastModal(context, 'notification')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBox(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BROADCAST CENTER', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _buildBroadcastPanel("Send Email", "Send professional email updates", Icons.email_rounded, AppColors.neonCyan, 18, "92%", 230, () => _showBroadcastModal(context, 'email')),
        const SizedBox(height: 12),
        _buildBroadcastPanel("Send Notify", "Push notifications to all users", Icons.notifications_active_rounded, AppColors.neonPurple, 45, "98%", 1200, () => _showBroadcastModal(context, 'notification')),
      ],
    );
  }

  Widget _buildBroadcastPanel(String title, String sub, IconData icon, Color color, int sent, String rate, int reached, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(onPressed: onTap, icon: Icon(Icons.arrow_forward_rounded, color: color, size: 20)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat("Emails Sent", "$sent", color),
              _buildMiniStat("Open Rate", rate, color),
              _buildMiniStat("Recipients", "$reached", color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthAndActivity(AdminDashboardState admin) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildGrowthCard(admin)),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _buildActivityCard(admin)),
      ],
    );
  }

  Widget _buildGrowthCard(AdminDashboardState admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('USER GROWTH', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('+14%', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('Growth this week', style: TextStyle(color: Colors.white30, fontSize: 9)),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 2.2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 18, left: 12, top: 10, bottom: 0),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [FlSpot(0, 1), FlSpot(1, 3), FlSpot(2, 2), FlSpot(3, 5), FlSpot(4, 4), FlSpot(5, 7), FlSpot(6, 6)],
                          isCurved: true,
                          color: AppColors.neonCyan,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.neonCyan.withValues(alpha: 0.2), Colors.transparent])),
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(AdminDashboardState admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECENT ACTIVITY', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: admin.activityLogs.isEmpty
            ? const Center(child: Text("No live events", style: TextStyle(color: Colors.white12, fontSize: 10)))
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: admin.activityLogs.length,
                itemBuilder: (context, i) {
                  final log = admin.activityLogs[i];
                  final cat = log['category'] ?? 'system';
                  final color = _getCategoryColor(cat);
                  return _buildActivityItem(_getCategoryIcon(cat), log['title'] ?? 'Activity', log['userName'] ?? 'System', color);
                },
              ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'user': return AppColors.neonGreen;
      case 'challenge': return AppColors.neonCyan;
      case 'reward': return AppColors.neonYellow;
      case 'broadcast': return AppColors.neonPurple;
      default: return Colors.white38;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'user': return Icons.person_add_rounded;
      case 'challenge': return Icons.flag_rounded;
      case 'reward': return Icons.card_giftcard_rounded;
      case 'broadcast': return Icons.campaign_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  Widget _buildActivityItem(IconData icon, String t, String s, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: c, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)), Text(s, style: const TextStyle(color: Colors.white24, fontSize: 8))])),
        ],
      ),
    );
  }

  Widget _buildInsightsAndStatus() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildAIInsightsSection()),
        const SizedBox(width: 16),
        Expanded(child: _buildSystemStatusSection()),
      ],
    );
  }

  Widget _buildAIInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI INSIGHTS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _buildInsightItem(Icons.trending_up_rounded, "User activity increased 22% this week.", AppColors.neonGreen),
        _buildInsightItem(Icons.access_time_rounded, "Most active time is 7 PM - 9 PM.", AppColors.neonPurple),
      ],
    );
  }

  Widget _buildInsightItem(IconData icon, String text, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: c, size: 14),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildSystemStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SYSTEM STATUS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _buildStatusRow("Server", "Online", AppColors.neonGreen),
        _buildStatusRow("Database", "Online", AppColors.neonGreen),
        _buildStatusRow("API", "Online", AppColors.neonCyan),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: c, size: 14),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))),
          Text(status, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text('FitTracker Admin Dashboard', style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 10)),
          Text('© 2025 All Rights Reserved', style: TextStyle(color: Colors.white.withValues(alpha: 0.05), fontSize: 8)),
        ],
      ),
    );
  }

  // --- Reused Modals ---
  void _showUserList(BuildContext context, String title, List<UserModel> users) {
    final admin = ref.read(adminControllerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    title == 'Active Users' ? Icons.online_prediction_rounded : Icons.people_rounded,
                    color: title == 'Active Users' ? AppColors.neonGreen : AppColors.neonCyan,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (title == 'Active Users' ? AppColors.neonGreen : AppColors.neonCyan).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      admin.isLoading ? '...' : '${users.length}',
                      style: TextStyle(
                        color: title == 'Active Users' ? AppColors.neonGreen : AppColors.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: admin.isLoading
                    ? _buildShimmerLoader()
                    : users.isEmpty
                        ? _buildEmptyState(title)
                        : ListView.builder(
                            controller: scrollCtrl,
                            physics: const BouncingScrollPhysics(),
                            itemCount: users.length,
                            itemBuilder: (context, i) {
                              final u = users[i];
                              final isOnline = u.isOnline || (u.lastActive != null && DateTime.now().difference(u.lastActive!).inMinutes < 5);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (isOnline ? AppColors.neonGreen : Colors.white).withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: (isOnline ? AppColors.neonGreen : AppColors.neonCyan).withValues(alpha: 0.1),
                                          child: Text(
                                            u.name.isNotEmpty ? u.name.substring(0, 1).toUpperCase() : 'U',
                                            style: TextStyle(
                                              color: isOnline ? AppColors.neonGreen : AppColors.neonCyan,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (isOnline)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF0F0F1A),
                                                shape: BoxShape.circle,
                                              ),
                                              child: AnimatedBuilder(
                                                animation: _pulseController,
                                                builder: (context, child) {
                                                  return Opacity(
                                                    opacity: 0.4 + 0.6 * _pulseController.value,
                                                    child: Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.neonGreen,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  );
                                                },
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
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  u.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            u.email,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.3),
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatLastActive(u.lastActive, u.isOnline),
                                            style: TextStyle(
                                              color: isOnline ? AppColors.neonGreen.withValues(alpha: 0.7) : Colors.white24,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${u.points} pts',
                                          style: const TextStyle(
                                            color: AppColors.neonCyan,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Lv.${u.level}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, i) => AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) => Opacity(
          opacity: 0.3 + 0.4 * _pulseController.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 22, backgroundColor: Colors.white10),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 100, height: 12, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(width: 150, height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
                Container(width: 40, height: 12, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            title == 'Active Users' ? Icons.offline_bolt_rounded : Icons.people_outline_rounded,
            color: Colors.white24,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            title == 'Active Users'
                ? 'No users currently active 🟢'
                : 'No users found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddChallengeModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '10000');
    final rewardCtrl = TextEditingController(text: '500');
    String type = 'steps';
    String difficulty = 'moderate';
    int duration = 7;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: Color(0xFF101020), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('CREATE CHALLENGE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _modalInputDecoration('CHALLENGE TITLE', Icons.title_rounded),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _modalInputDecoration('DESCRIPTION', Icons.description_rounded),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: targetCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _modalInputDecoration('TARGET', Icons.track_changes_rounded))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: rewardCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _modalInputDecoration('REWARD PTS', Icons.star_rounded))),
                ],
              ),
              const SizedBox(height: 20),
              const Text('CHALLENGE TYPE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Row(
                children: ['steps', 'calories', 'workouts'].map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t.toUpperCase()),
                    selected: type == t,
                    onSelected: (val) => setModalState(() => type = t),
                    selectedColor: AppColors.neonCyan,
                    labelStyle: TextStyle(color: type == t ? Colors.black : Colors.white54, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 30),
              if (isSaving)
                const LinearProgressIndicator(color: AppColors.neonCyan)
              else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.isEmpty) return;
                      setModalState(() => isSaving = true);
                      try {
                        await ref.read(adminControllerProvider.notifier).createChallenge(
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          difficulty: difficulty,
                          reward: int.parse(rewardCtrl.text),
                          target: double.parse(targetCtrl.text),
                          type: type,
                          durationDays: duration,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModalState(() => isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text('LAUNCH CHALLENGE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRewardUsersModal(BuildContext context, List<UserModel> users) {
    final achievementCtrl = TextEditingController(text: 'Special Performance');
    final pointsCtrl = TextEditingController(text: '100');
    final List<String> selectedUserIds = [];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: Color(0xFF101020), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('DISTRIBUTE REWARDS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              TextField(
                controller: achievementCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _modalInputDecoration('ACHIEVEMENT NAME', Icons.emoji_events_rounded),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _modalInputDecoration('POINTS TO AWARD', Icons.star_rounded),
              ),
              const SizedBox(height: 20),
              const Text('SELECT RECIPIENTS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final isSelected = selectedUserIds.contains(u.id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: Colors.white12, child: Text(u.name.substring(0, 1), style: const TextStyle(color: Colors.white))),
                      title: Text(u.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) selectedUserIds.add(u.id);
                            else selectedUserIds.remove(u.id);
                          });
                        },
                        checkColor: Colors.black,
                        activeColor: AppColors.neonYellow,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              if (isSaving)
                const LinearProgressIndicator(color: AppColors.neonYellow)
              else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: selectedUserIds.isEmpty ? null : () async {
                      setModalState(() => isSaving = true);
                      try {
                        await ref.read(adminControllerProvider.notifier).massRewardUsers(
                          userIds: selectedUserIds,
                          achievement: achievementCtrl.text,
                          points: int.parse(pointsCtrl.text),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModalState(() => isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonYellow, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: Text('REWARD ${selectedUserIds.length} USERS', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _modalInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900),
      prefixIcon: Icon(icon, color: Colors.white38, size: 18),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white12)),
    );
  }

  void _showLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: MongoDbService.getLeaderboard(),
        builder: (ctx, snap) {
          final entries = snap.data ?? [];
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.leaderboard_rounded, color: AppColors.neonYellow, size: 20),
                      SizedBox(width: 10),
                      Text("Leaderboard", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.neonYellow)))
                  else if (entries.isEmpty)
                    const Expanded(child: Center(child: Text('No data yet', style: TextStyle(color: Colors.white38))))
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        itemCount: entries.length,
                        itemBuilder: (context, i) {
                          final u = entries[i];
                          final name = u['name'] ?? 'User';
                          final pts = (u['points'] as num? ?? 0).toInt();
                          final streak = (u['streak'] as num? ?? 0).toInt();
                          final isTop3 = i < 3;
                          final rankColor = i == 0
                              ? const Color(0xFFFFD700)
                              : i == 1
                                  ? const Color(0xFFC0C0C0)
                                  : i == 2
                                      ? const Color(0xFFCD7F32)
                                      : Colors.white38;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isTop3
                                  ? rankColor.withValues(alpha: 0.06)
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isTop3 ? rankColor.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Rank badge
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: rankColor.withValues(alpha: isTop3 ? 0.15 : 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isTop3
                                        ? Text(['🥇', '🥈', '🥉'][i], style: const TextStyle(fontSize: 14))
                                        : Text('${i + 1}', style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 11)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                      if (streak > 0)
                                        Text('🔥 $streak day streak', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${_formatNumber(pts)} pts',
                                  style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBroadcastModal(BuildContext context, String type) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String tone = 'Professional';
    String priority = 'Normal';
    bool isGenerating = false;
    bool isSending = false;
    String ctaText = 'Open FitTracker';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF101020),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('Broadcast ${type.toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'TOPIC',
                  labelStyle: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w900),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              if (isGenerating)
                const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (titleController.text.isEmpty) return;
                      setModalState(() => isGenerating = true);
                      try {
                        final res = await MongoDbService.generateBroadcastContent(
                          topic: titleController.text,
                          type: type,
                          tone: tone,
                          priority: priority,
                        );
                        setModalState(() {
                          titleController.text = type == 'email' ? (res['subject'] ?? titleController.text) : (res['title'] ?? titleController.text);
                          bodyController.text = res['body'] ?? bodyController.text;
                          ctaText = res['cta'] ?? 'Open FitTracker';
                          isGenerating = false;
                        });
                      } catch (e) {
                        setModalState(() => isGenerating = false);
                      }
                    },
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('AI GENERATE CONTENT'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1), foregroundColor: AppColors.neonCyan),
                  ),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: bodyController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white70),
                decoration: InputDecoration(
                  labelText: 'MESSAGE',
                  labelStyle: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 30),
              if (isSending)
                const LinearProgressIndicator(color: AppColors.neonGreen)
              else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (bodyController.text.isEmpty) return;
                      setModalState(() => isSending = true);
                      try {
                        Map<String, dynamic> res;
                        if (type == 'email') {
                          res = await MongoDbService.sendEmailBroadcast(
                            subject: titleController.text,
                            body: bodyController.text,
                            cta: ctaText,
                            priority: priority,
                            tone: tone,
                          );
                        } else {
                          res = await MongoDbService.sendNotificationBroadcast(
                            title: titleController.text,
                            body: bodyController.text,
                            priority: priority,
                            tone: tone,
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModalState(() => isSending = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: type == 'email' ? AppColors.neonCyan : AppColors.neonPurple,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('EXECUTE BROADCAST', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
