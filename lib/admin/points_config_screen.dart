import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../controllers/admin_controller.dart';
import '../models/points_config.dart';
import 'levels_management_screen.dart';

class PointsConfigScreen extends ConsumerStatefulWidget {
  const PointsConfigScreen({super.key});

  @override
  ConsumerState<PointsConfigScreen> createState() => _PointsConfigScreenState();
}

class _PointsConfigScreenState extends ConsumerState<PointsConfigScreen> {
  late double _pointsPerMin;
  late double _streakBonus;
  late double _bonusMultiplier;
  late TextEditingController _dailyLimitCtrl;

  @override
  void initState() {
    super.initState();
    final config = ref.read(adminControllerProvider).pointsConfig;
    _pointsPerMin = config.pointsPerMinute;
    _streakBonus = config.streakBonus;
    _bonusMultiplier = config.bonusMultiplier;
    _dailyLimitCtrl = TextEditingController(text: '${config.dailyEarningLimit}');
  }

  @override
  void dispose() {
    _dailyLimitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Points Config', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: AppSizes.xl),
              // Sliders
              _SliderCard(label: 'Points per Minute', value: _pointsPerMin, min: 0.5, max: 10, divisions: 19, displayValue: _pointsPerMin.toStringAsFixed(1),
                onChanged: (v) => setState(() => _pointsPerMin = v)),
              const SizedBox(height: AppSizes.md),
              _SliderCard(label: 'Streak Bonus', value: _streakBonus, min: 10, max: 200, divisions: 19, displayValue: _streakBonus.toStringAsFixed(0),
                onChanged: (v) => setState(() => _streakBonus = v)),
              const SizedBox(height: AppSizes.md),
              _SliderCard(label: 'Bonus Multiplier', value: _bonusMultiplier, min: 1.0, max: 5.0, divisions: 16, displayValue: '${_bonusMultiplier.toStringAsFixed(1)}x',
                onChanged: (v) => setState(() => _bonusMultiplier = v)),
              const SizedBox(height: AppSizes.md),
              // Daily limit input
              Container(
                padding: EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Earning Limit', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSizes.sm),
                    TextField(
                      controller: _dailyLimitCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Enter limit', suffixText: 'pts'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              // Save
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(adminControllerProvider.notifier).updatePointsConfig(
                      PointsConfig(
                        pointsPerMinute: _pointsPerMin,
                        streakBonus: _streakBonus,
                        bonusMultiplier: _bonusMultiplier,
                        dailyEarningLimit: int.tryParse(_dailyLimitCtrl.text) ?? 500,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Points config saved!'), backgroundColor: AppColors.neonCyan, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.sm))),
                    );
                  },
                  child: const Text('Save Points Config'),
                ),
              ),
              const SizedBox(height: AppSizes.xxl),
              // Quick nav to sub-screens
              Align(
                alignment: Alignment.center,
                child: _NavCard(
                  icon: Icons.emoji_events_rounded,
                  title: 'Manage Levels & Benefits',
                  color: AppColors.neonPurple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelsManagementScreen())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderCard({required this.label, required this.value, required this.min, required this.max, required this.divisions, required this.displayValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
                decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(displayValue, style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _NavCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xl),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppSizes.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

