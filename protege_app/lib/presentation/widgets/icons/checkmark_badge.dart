import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Green circle with white checkmark badge.
/// Used for completed lessons, correct quiz answers, saved indicators.
class CheckmarkBadge extends StatelessWidget {
  final double size;
  final Color color;
  const CheckmarkBadge({
    super.key,
    this.size = 24,
    this.color = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: size * 0.65,
      ),
    );
  }
}
