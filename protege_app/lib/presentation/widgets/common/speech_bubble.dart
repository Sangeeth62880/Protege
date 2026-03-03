import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Yellow speech bubble with left-pointing triangular notch.
class SpeechBubble extends StatelessWidget {
  final String text;

  const SpeechBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Triangular notch pointing left
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: CustomPaint(
            size: const Size(10, 14),
            painter: _NotchPainter(),
          ),
        ),
        // Bubble body
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.yellowLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Text(text, style: AppTypography.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _NotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.yellowLight
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
