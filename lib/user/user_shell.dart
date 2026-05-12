import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/health_service.dart';
import '../services/mongodb_service.dart';
import 'home_screen.dart';
import 'workout_screen.dart';
import 'ai_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';

class UserShell extends ConsumerStatefulWidget {
  const UserShell({super.key});

  @override
  ConsumerState<UserShell> createState() => _UserShellState();
}

class _UserShellState extends ConsumerState<UserShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBmiUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger sync on resume
      ref.read(healthControllerProvider.notifier).onAppResume();
    }
  }

  Future<void> _checkBmiUpdate() async {
    try {
      final history = await MongoDbService.getBmiHistory();
      bool needsUpdate = false;
      if (history.isEmpty) {
        needsUpdate = true;
      } else {
        final lastRecord = history.first;
        final lastDate = DateTime.parse(lastRecord['recordedAt']);
        if (DateTime.now().difference(lastDate).inDays >= 30) {
          needsUpdate = true;
        }
      }
      
      if (needsUpdate && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Update Required'),
            content: const Text('Please update your height and weight in the Profile > Health section to keep your stats accurate!'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 4); // Profile is 4
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Ignore if fails
    }
  }

  final _screens = const [
    HomeScreen(),
    WorkoutScreen(),
    AiScreen(),
    ExploreScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.directions_run_rounded,
                  label: 'Workout',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                  accentColor: AppColors.neonPurple,
                ),
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: 'Explore',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color accentColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.accentColor = AppColors.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.xs,
            vertical: AppSizes.sm,
          ),
          decoration: isActive
              ? BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                )
              : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? accentColor : Theme.of(context).textTheme.bodySmall!.color!,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? accentColor : Theme.of(context).textTheme.bodySmall!.color!,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

