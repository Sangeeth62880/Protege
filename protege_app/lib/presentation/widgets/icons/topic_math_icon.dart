import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Overlapping Venn diagram circles for Math/Probability topics.
class TopicMathIcon extends StatelessWidget {
  final double size;
  const TopicMathIcon({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _VennPainter(),
      ),
    );
  }
}

class _VennPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final radius = size.width * 0.32;
    final offset = size.width * 0.11;

    // Left circle — blue
    final leftCenter = Offset(size.width / 2 - offset, centerY);
    final leftFill = Paint()..color = AppColors.blue.withAlpha(77);
    final leftStroke = Paint()
      ..color = AppColors.blue.withAlpha(153)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(leftCenter, radius, leftFill);
    canvas.drawCircle(leftCenter, radius, leftStroke);

    // Right circle — amber
    final rightCenter = Offset(size.width / 2 + offset, centerY);
    final rightFill = Paint()..color = AppColors.amber.withAlpha(77);
    final rightStroke = Paint()
      ..color = AppColors.amber.withAlpha(153)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(rightCenter, radius, rightFill);
    canvas.drawCircle(rightCenter, radius, rightStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
