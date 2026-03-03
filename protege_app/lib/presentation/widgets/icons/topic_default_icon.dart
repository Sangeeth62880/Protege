import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'protege_diamond_icon.dart';

/// Default topic icon — diamond on a light green circle.
class TopicDefaultIcon extends StatelessWidget {
  final double size;
  const TopicDefaultIcon({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.greenLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: ProtegeDiamondIcon(size: size * 0.64),
      ),
    );
  }
}
