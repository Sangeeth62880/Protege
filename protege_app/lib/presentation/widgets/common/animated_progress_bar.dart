import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';

/// Horizontal animated progress bar
class AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final Color? fillColor;
  final double height;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.fillColor,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: AppMotion.curveStandard,
              width: constraints.maxWidth * progress.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: fillColor ?? AppColors.success,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        );
      },
    );
  }
}
