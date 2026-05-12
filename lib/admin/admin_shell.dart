import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'admin_dashboard.dart';
import 'user_management_screen.dart';
import 'points_config_screen.dart';
import 'analytics_screen.dart';
import 'challenges_management_screen.dart';
import 'support_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final _screens = const [
    AdminDashboard(),
    UserManagementScreen(),
    ChallengesManagementScreen(),
    PointsConfigScreen(),
    AnalyticsScreen(),
    SupportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.xs, vertical: AppSizes.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AdminNavItem(icon: Icons.dashboard_rounded, label: 'Home', isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _AdminNavItem(icon: Icons.people_rounded, label: 'Users', isActive: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
                _AdminNavItem(icon: Icons.emoji_events_rounded, label: 'Challenges', isActive: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
                _AdminNavItem(icon: Icons.star_rounded, label: 'Points', isActive: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
                _AdminNavItem(icon: Icons.analytics_rounded, label: 'Stats', isActive: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4)),
                _AdminNavItem(icon: Icons.support_agent_rounded, label: 'Support', isActive: _currentIndex == 5, onTap: () => setState(() => _currentIndex = 5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AdminNavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: AppSizes.xxs, vertical: AppSizes.sm),
          decoration: isActive
              ? BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppSizes.buttonRadius))
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isActive ? AppColors.neonCyan : Theme.of(context).textTheme.bodySmall!.color!),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? AppColors.neonCyan : Theme.of(context).textTheme.bodySmall!.color!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
