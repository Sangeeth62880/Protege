import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/theme/app_typography.dart';

/// Colored stat card with icon and animated count-up number.
class AccentStatCard extends StatelessWidget {
  final Color backgroundColor;
  final Widget icon;
  final int value;
  final String label;

  const AccentStatCard({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(height: AppSpacing.md),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: AppAnimations.durationCount,
            curve: AppAnimations.curveDecelerate,
            builder: (context, currentValue, _) {
              return Text(
                '$currentValue',
                style: AppTypography.statMedium,
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
