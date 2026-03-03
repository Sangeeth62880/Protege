import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Warm gradient brain/psychology icon for Science/Thinking topics.
class TopicScienceIcon extends StatelessWidget {
  final double size;
  const TopicScienceIcon({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.64;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.86,
            height: size * 0.86,
            decoration: const BoxDecoration(
              color: AppColors.yellowLight,
              shape: BoxShape.circle,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.gradientAmberTrophy.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Icon(
              Icons.psychology_rounded,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
