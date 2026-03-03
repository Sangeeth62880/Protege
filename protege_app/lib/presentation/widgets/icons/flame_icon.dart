import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Gradient-tinted flame icon for streak indicators.
/// Uses ShaderMask with orange-to-red gradient on Material flame icon.
class FlameIcon extends StatelessWidget {
  final double size;
  const FlameIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.gradientStreakFlame.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Icon(
        Icons.local_fire_department_rounded,
        size: size,
        color: Colors.white, // Will be masked by gradient
      ),
    );
  }
}
