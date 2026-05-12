import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../controllers/admin_controller.dart';

class PremiumControlScreen extends ConsumerWidget {
  const PremiumControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Control'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Premium Plans', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.lg),
            ...List.generate(admin.premiumPlans.length, (i) {
              final plan = admin.premiumPlans[i];
              final colors = [AppColors.neonCyan, AppColors.neonPurple, AppColors.neonOrange];
              final color = colors[i % colors.length];
              return Padding(
                padding: EdgeInsets.only(bottom: AppSizes.md),
                child: Container(
                  padding: EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(color: plan.isEnabled ? color.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surfaceContainerHighest),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(AppSizes.sm),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.workspace_premium_rounded, color: color, size: 20),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.name, style: Theme.of(context).textTheme.titleSmall),
                                Text('${plan.days} days · ${plan.pointsRequired} pts', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Switch(value: plan.isEnabled, onChanged: (_) => controller.togglePremiumPlan(i)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

