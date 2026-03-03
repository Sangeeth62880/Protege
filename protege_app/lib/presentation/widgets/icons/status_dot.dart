import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Colored status dot for list items.
enum StatusDotState { completed, inProgress, locked, failed }

class StatusDot extends StatelessWidget {
  final StatusDotState state;
  final double size;
  const StatusDot({super.key, required this.state, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _fillColor,
        border: state == StatusDotState.locked
            ? Border.all(color: AppColors.border, width: 1.5)
            : null,
      ),
    );
  }

  Color get _fillColor {
    switch (state) {
      case StatusDotState.completed:
        return AppColors.green;
      case StatusDotState.inProgress:
        return AppColors.purple;
      case StatusDotState.locked:
        return AppColors.borderLight;
      case StatusDotState.failed:
        return AppColors.red;
    }
  }
}
