import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_animations.dart';

/// Smoothly animating progress bar with green fill on light track.
class AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color fillColor;
  final Color trackColor;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.fillColor = AppColors.green,
    this.trackColor = AppColors.borderLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: AppAnimations.curveDefault,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                height: height,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
