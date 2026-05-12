import 'package:flutter/material.dart';
import '../core/constants.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;
    
    // childAspectRatio adjusted to ensure 8 cards fit perfectly on one screen
    final double gridAspectRatio = isSmallScreen ? 1.32 : 1.2;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF020208), // Ultra Deep Navy
      body: Stack(
        children: [
          // Background Mesh & Subtle Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0A0A25), Color(0xFF020208)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Production Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explore Hub',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'Cyber Fitness Control Center',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 8-Card Grid (No Scroll)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: gridAspectRatio,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(), // Force fit, no scroll
                      children: _dashboardItems.map((item) => _CompactCard(item: item)).toList(),
                    ),
                  ),
                ),
                
                // Footer Branding
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Center(
                    child: Text(
                      'v2.4.1 PRODUCTION STABLE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.05),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final String route;

  const _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    required this.route,
  });
}

const List<_DashboardItem> _dashboardItems = [
  _DashboardItem(
    title: 'Workouts',
    subtitle: 'Elite sessions',
    icon: Icons.fitness_center_rounded,
    color: AppColors.neonCyan,
    badge: 'LIVE',
    route: '/workouts',
  ),
  _DashboardItem(
    title: 'Nutrition',
    subtitle: 'Daily fuel',
    icon: Icons.restaurant_rounded,
    color: AppColors.neonGreen,
    badge: 'HOT',
    route: '/nutrition',
  ),
  _DashboardItem(
    title: 'Challenges',
    subtitle: 'AI events',
    icon: Icons.bolt_rounded,
    color: AppColors.neonOrange,
    badge: 'NEW',
    route: '/challenges',
  ),
  _DashboardItem(
    title: 'Social',
    subtitle: 'Community',
    icon: Icons.people_rounded,
    color: AppColors.neonPurple,
    route: '/social',
  ),
  _DashboardItem(
    title: 'Points',
    subtitle: 'Rewards',
    icon: Icons.star_rounded,
    color: AppColors.neonYellow,
    badge: 'API',
    route: '/points',
  ),
  _DashboardItem(
    title: 'Stats',
    subtitle: 'Deep data',
    icon: Icons.bar_chart_rounded,
    color: AppColors.neonPink,
    route: '/stats',
  ),
  _DashboardItem(
    title: 'BMI',
    subtitle: 'Health index',
    icon: Icons.monitor_weight_rounded,
    color: Colors.blue,
    route: '/bmi',
  ),
  _DashboardItem(
    title: 'Settings',
    subtitle: 'Preferences',
    icon: Icons.settings_rounded,
    color: Colors.grey,
    route: '/settings',
  ),
];

class _CompactCard extends StatefulWidget {
  final _DashboardItem item;
  const _CompactCard({required this.item});

  @override
  State<_CompactCard> createState() => _CompactCardState();
}

class _CompactCardState extends State<_CompactCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: () => Navigator.pushNamed(context, item.route),
      child: AnimatedScale(
        scale: _isTapped ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: item.color.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP: Icon & Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: item.color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  if (item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.badge!,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              // CENTER: Typography
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // BOTTOM RIGHT: Action Arrow
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: item.color,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
