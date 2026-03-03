import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Green diamond brand icon — Protégé's logo mark.
/// A rotated square with rounded corners and gradient green fill.
class ProtegeDiamondIcon extends StatelessWidget {
  final double size;
  const ProtegeDiamondIcon({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _DiamondPainter(),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final diamondSize = size.width * 0.65;

    // Outer glow
    final glowPaint = Paint()
      ..color = AppColors.green.withAlpha(30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, size.width * 0.42, glowPaint);

    // Rotated rounded rectangle (diamond)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: diamondSize, height: diamondSize),
      Radius.circular(diamondSize * 0.18),
    );

    final gradient = const LinearGradient(
      colors: [Color(0xFF5CD65C), Color(0xFF43B929)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCenter(center: Offset.zero, width: diamondSize, height: diamondSize),
      );

    canvas.drawRRect(rect, fillPaint);

    // Inner facet detail
    final facetSize = diamondSize * 0.18;
    final facetPaint = Paint()..color = AppColors.greenDark.withAlpha(60);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: facetSize, height: facetSize),
        Radius.circular(facetSize * 0.2),
      ),
      facetPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
