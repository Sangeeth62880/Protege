import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/theme/app_typography.dart';
import '../common/animated_pressable.dart';
import '../icons/checkmark_badge.dart';

/// Quiz answer option card with selection animation.
/// Shows green border + checkmark for correct, red border + shake for incorrect.
class QuizOptionCard extends StatefulWidget {
  final String text;
  final bool isSelected;
  final bool? isCorrect; // null = not yet answered
  final VoidCallback? onTap;

  const QuizOptionCard({
    super.key,
    required this.text,
    this.isSelected = false,
    this.isCorrect,
    this.onTap,
  });

  @override
  State<QuizOptionCard> createState() => _QuizOptionCardState();
}

class _QuizOptionCardState extends State<QuizOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3, end: -3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3, end: 3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3, end: -3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3, end: 3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void didUpdateWidget(QuizOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shake on incorrect selection
    if (widget.isSelected &&
        widget.isCorrect == false &&
        oldWidget.isCorrect == null) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    double borderWidth = 1.5;

    if (widget.isSelected && widget.isCorrect != null) {
      borderColor = widget.isCorrect! ? AppColors.green : AppColors.red;
      borderWidth = 2;
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: AnimatedPressable(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: AppAnimations.curveDefault,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.text,
                  style: AppTypography.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              // Checkmark badge for correct answer
              if (widget.isSelected && widget.isCorrect == true)
                Positioned(
                  top: -4,
                  right: -4,
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: AppAnimations.curveBounce,
                    child: const CheckmarkBadge(size: 22),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
