import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../common/animated_pressable.dart';
import '../icons/checkmark_badge.dart';
import '../icons/status_dot.dart';

/// Lesson tile with status dot, left accent bar, title, duration, and completion badge.
class LessonTile extends StatelessWidget {
  final String title;
  final String? duration;
  final bool isCompleted;
  final bool isInProgress;
  final bool isUpNext;
  final bool isLocked;
  final VoidCallback? onTap;

  const LessonTile({
    super.key,
    required this.title,
    this.duration,
    this.isCompleted = false,
    this.isInProgress = false,
    this.isUpNext = false,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isCompleted
        ? AppColors.green
        : isInProgress
            ? AppColors.purple
            : Colors.transparent;

    final dotState = isCompleted
        ? StatusDotState.completed
        : isInProgress
            ? StatusDotState.inProgress
            : StatusDotState.locked;

    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Status dot
            StatusDot(state: dotState, size: 8),
            const SizedBox(width: AppSpacing.md),
            // Title + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isLocked ? AppColors.textTertiary : AppColors.textPrimary,
                    ),
                  ),
                  if (duration != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(duration!, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Right badge
            if (isCompleted)
              const CheckmarkBadge(size: 22)
            else if (isUpNext)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'UP NEXT',
                  style: AppTypography.labelSmall.copyWith(color: Colors.white, fontSize: 9),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
