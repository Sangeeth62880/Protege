import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/theme/app_typography.dart';
import '../icons/sparkle_star_icon.dart';

/// Animated XP counter that counts from 0 to the target value with a sparkle star.
class XpCounterDisplay extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final bool showSparkle;
  final Color sparkleColor;

  const XpCounterDisplay({
    super.key,
    required this.value,
    this.style,
    this.showSparkle = true,
    this.sparkleColor = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: AppAnimations.durationCount,
      curve: AppAnimations.curveDecelerate,
      builder: (context, currentValue, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currentValue',
              style: style ?? AppTypography.statLarge,
            ),
            if (showSparkle) ...[
              const SizedBox(width: 6),
              AnimatedScale(
                scale: currentValue >= value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: AppAnimations.curveBounce,
                child: SparkleStarIcon(size: 20, color: sparkleColor),
              ),
            ],
          ],
        );
      },
    );
  }
}
