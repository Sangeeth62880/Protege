import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Ascending orange bar chart illustration for Data Analysis topics.
class TopicDataIcon extends StatelessWidget {
  final double size;
  const TopicDataIcon({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final barWidth = size * 0.20;
    final gap = size * 0.06;
    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Bar(width: barWidth, height: size * 0.32, color: AppColors.orangeLight),
          SizedBox(width: gap),
          _Bar(width: barWidth, height: size * 0.50, color: AppColors.orange.withAlpha(200)),
          SizedBox(width: gap),
          _Bar(width: barWidth, height: size * 0.68, color: AppColors.orange),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  const _Bar({required this.width, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
      ),
    );
  }
}
