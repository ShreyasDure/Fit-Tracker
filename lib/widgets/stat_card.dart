import 'package:flutter/material.dart';
import '../core/constants.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Gradient? gradient; // optional, but we no longer use it as the default fill
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.gradient,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.neonCyan;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          // Premium dark-glass surface
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(
            color: accent.withValues(alpha: 0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: accent,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailing ??
                        Text(
                          subtitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class GlowingStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? trend;

  const GlowingStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor = AppColors.neonCyan,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 14),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 2),
            Text(
              trend!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.neonGreen,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
