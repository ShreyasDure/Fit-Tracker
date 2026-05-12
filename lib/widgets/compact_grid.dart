import 'package:flutter/material.dart';
import '../core/constants.dart';

/// A compact 2-column grid wrapper for cards.
class CompactGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double childAspectRatio;

  const CompactGrid({
    super.key,
    required this.children,
    this.spacing = AppSizes.sm,
    this.childAspectRatio = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: children,
    );
  }
}

/// A section header with optional action button.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.neonCyan),
            const SizedBox(width: AppSizes.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.neonCyan,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gradient progress bar.
class GradientProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Gradient? gradient;
  final Color? backgroundColor;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient ?? AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

