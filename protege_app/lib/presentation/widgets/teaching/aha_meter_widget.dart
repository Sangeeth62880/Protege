import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/teaching_session_model.dart';

/// Animated Aha! Meter widget showing teaching progress
class AhaMeterWidget extends StatefulWidget {
  final double score;
  final AhaBreakdown? breakdown;
  final bool showBreakdown;
  final double size;

  const AhaMeterWidget({
    super.key,
    required this.score,
    this.breakdown,
    this.showBreakdown = true,
    this.size = 120,
  });

  @override
  State<AhaMeterWidget> createState() => _AhaMeterWidgetState();
}

class _AhaMeterWidgetState extends State<AhaMeterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AhaMeterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _previousScore = oldWidget.score / 100;
      _animation = Tween<double>(
        begin: _previousScore,
        end: widget.score / 100,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    if (widget.score >= 85) return AppColors.success;
    if (widget.score >= 60) return Colors.orange;
    if (widget.score >= 40) return Colors.amber;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main circular progress
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                // Progress arc
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _ArcPainter(
                      progress: _animation.value,
                      color: _scoreColor,
                      strokeWidth: 12,
                    ),
                  ),
                ),
                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(widget.score).toInt()}%',
                      style: TextStyle(
                        fontSize: widget.size * 0.25,
                        fontWeight: FontWeight.bold,
                        color: _scoreColor,
                      ),
                    ),
                    Text(
                      'Aha!',
                      style: TextStyle(
                        fontSize: widget.size * 0.12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                // Celebration icon for mastery
                if (widget.score >= 85)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        // Breakdown indicators
        if (widget.showBreakdown && widget.breakdown != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BreakdownIndicator(
                label: 'Clarity',
                score: widget.breakdown!.clarity,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _BreakdownIndicator(
                label: 'Accuracy',
                score: widget.breakdown!.accuracy,
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _BreakdownIndicator(
                label: 'Complete',
                score: widget.breakdown!.completeness,
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Custom painter for progress arc
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw arc from top (-90 degrees)
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );

    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Mini breakdown indicator
class _BreakdownIndicator extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _BreakdownIndicator({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 4,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: color,
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

/// Compact Aha! meter for app bar
class CompactAhaMeter extends StatelessWidget {
  final double score;

  const CompactAhaMeter({super.key, required this.score});

  Color get _color {
    if (score >= 85) return AppColors.success;
    if (score >= 60) return Colors.orange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.psychology, color: _color, size: 20),
        const SizedBox(width: 4),
        Text(
          '${score.toInt()}%',
          style: TextStyle(
            color: _color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
