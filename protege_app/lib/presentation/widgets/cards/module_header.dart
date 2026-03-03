import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Module section header with numbered circle, title, and circular progress.
class ModuleHeader extends StatelessWidget {
  final int moduleNumber;
  final String title;
  final int completedLessons;
  final int totalLessons;
  final bool isCompleted;
  final bool isInProgress;

  const ModuleHeader({
    super.key,
    required this.moduleNumber,
    required this.title,
    required this.completedLessons,
    required this.totalLessons,
    this.isCompleted = false,
    this.isInProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final circleColor = isCompleted
        ? AppColors.green
        : isInProgress
            ? AppColors.purple
            : AppColors.borderLight;
    final numberColor = (isCompleted || isInProgress) ? Colors.white : AppColors.textTertiary;
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Numbered circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$moduleNumber',
                style: AppTypography.titleSmall.copyWith(color: numberColor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Title + lesson count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  '$completedLessons of $totalLessons lessons',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          // Circular progress
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.green : AppColors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
