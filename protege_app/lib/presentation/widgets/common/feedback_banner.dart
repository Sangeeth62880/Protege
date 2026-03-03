import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/theme/app_typography.dart';

/// Slide-up feedback banner for quiz correct/incorrect answers.
class FeedbackBanner extends StatefulWidget {
  final bool isCorrect;
  final String message;
  final String? explanation;
  final int xpEarned;
  final VoidCallback? onContinue;
  final VoidCallback? onWhy;

  const FeedbackBanner({
    super.key,
    required this.isCorrect,
    required this.message,
    this.explanation,
    this.xpEarned = 0,
    this.onContinue,
    this.onWhy,
  });

  @override
  State<FeedbackBanner> createState() => _FeedbackBannerState();
}

class _FeedbackBannerState extends State<FeedbackBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveSmooth,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isCorrect ? AppColors.greenLight : AppColors.redLight;
    final accentColor = widget.isCorrect ? AppColors.green : AppColors.red;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  widget.isCorrect
                      ? Icons.celebration_rounded
                      : Icons.close_rounded,
                  color: accentColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.message,
                  style: AppTypography.headlineSmall.copyWith(color: accentColor),
                ),
                const Spacer(),
                if (widget.isCorrect && widget.xpEarned > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: AppColors.green.withAlpha(60)),
                    ),
                    child: Text(
                      '+${widget.xpEarned} XP',
                      style: AppTypography.buttonSmall.copyWith(color: AppColors.green),
                    ),
                  ),
              ],
            ),
            // Explanation
            if (widget.explanation != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.explanation!,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.onWhy != null) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onWhy,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Center(
                          child: Text(
                            'Why?',
                            style: AppTypography.buttonMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onContinue,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Center(
                        child: Text('Continue', style: AppTypography.buttonMedium),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
