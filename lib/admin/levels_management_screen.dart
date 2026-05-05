import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../controllers/admin_controller.dart';


class LevelsManagementScreen extends ConsumerStatefulWidget {
  const LevelsManagementScreen({super.key});

  @override
  ConsumerState<LevelsManagementScreen> createState() => _LevelsManagementScreenState();
}

class _LevelsManagementScreenState extends ConsumerState<LevelsManagementScreen> {
  late TextEditingController _silverCtrl;
  late TextEditingController _goldCtrl;

  @override
  void initState() {
    super.initState();
    final config = ref.read(adminControllerProvider).levelsConfig;
    _silverCtrl = TextEditingController(text: '${config.silverMinPoints}');
    _goldCtrl = TextEditingController(text: '${config.goldMinPoints}');
  }

  @override
  void dispose() {
    _silverCtrl.dispose();
    _goldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(adminControllerProvider).levelsConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Levels Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Min points inputs
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.cardRadius), border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level Thresholds', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSizes.md),
                  TextField(controller: _silverCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Silver Min Points', labelStyle: TextStyle(color: AppColors.textMuted))),
                  const SizedBox(height: AppSizes.md),
                  TextField(controller: _goldCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Gold Min Points', labelStyle: TextStyle(color: AppColors.textMuted))),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            // Benefits display
            _BenefitTier(tier: 'Bronze', icon: Icons.circle, color: const Color(0xFFCD7F32), benefits: config.bronzeBenefits),
            const SizedBox(height: AppSizes.sm),
            _BenefitTier(tier: 'Silver', icon: Icons.circle, color: const Color(0xFFC0C0C0), benefits: config.silverBenefits),
            const SizedBox(height: AppSizes.sm),
            _BenefitTier(tier: 'Gold', icon: Icons.circle, color: const Color(0xFFFFD700), benefits: config.goldBenefits),
            const SizedBox(height: AppSizes.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(adminControllerProvider.notifier).updateLevelsConfig(
                    config.copyWith(
                      silverMinPoints: int.tryParse(_silverCtrl.text) ?? 2000,
                      goldMinPoints: int.tryParse(_goldCtrl.text) ?? 5000,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Levels saved!'), backgroundColor: AppColors.neonCyan, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.sm))),
                  );
                },
                child: const Text('Save Levels'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitTier extends StatelessWidget {
  final String tier;
  final IconData icon;
  final Color color;
  final String benefits;
  const _BenefitTier({required this.tier, required this.icon, required this.color, required this.benefits});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(benefits, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
