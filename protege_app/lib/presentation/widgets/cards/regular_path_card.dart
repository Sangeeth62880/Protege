import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../common/animated_pressable.dart';
import '../common/category_label.dart';

/// Standard path card with icon on left, category label + title on right.
class RegularPathCard extends StatelessWidget {
  final String title;
  final String categoryLabel;
  final Color categoryColor;
  final Widget icon;
  final VoidCallback? onTap;

  const RegularPathCard({
    super.key,
    required this.title,
    required this.categoryLabel,
    required this.categoryColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            SizedBox(width: 56, height: 56, child: icon),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryLabel(text: categoryLabel, color: categoryColor),
                  const SizedBox(height: AppSpacing.xs),
                  Text(title, style: AppTypography.headlineSmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
