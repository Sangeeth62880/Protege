import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Stacked purple blocks illustration for Programming/CS topics.
class TopicProgrammingIcon extends StatelessWidget {
  final double size;
  const TopicProgrammingIcon({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back block
          Transform.rotate(
            angle: -8 * math.pi / 180,
            child: Container(
              width: size * 0.50,
              height: size * 0.36,
              decoration: BoxDecoration(
                color: AppColors.purpleMuted,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          // Middle block
          Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Container(
              width: size * 0.50,
              height: size * 0.36,
              decoration: BoxDecoration(
                color: AppColors.purple.withAlpha(180),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          // Front block
          Transform.rotate(
            angle: 2 * math.pi / 180,
            child: Container(
              width: size * 0.50,
              height: size * 0.36,
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
