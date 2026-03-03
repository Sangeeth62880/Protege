import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// 4-point sparkle star icon — used as XP/achievement indicator.
class SparkleStarIcon extends StatelessWidget {
  final double size;
  final Color color;
  const SparkleStarIcon({super.key, this.size = 16, this.color = AppColors.green});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _SparklePainter(color: color),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final armLength = size.width * 0.45;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12;

    // 4 arms at 0°, 90°, 180°, 270°
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final end = Offset(
        center.dx + armLength * math.cos(angle),
        center.dy + armLength * math.sin(angle),
      );
      canvas.drawLine(center, end, paint);
    }

    // Center dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.08, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color;
}
