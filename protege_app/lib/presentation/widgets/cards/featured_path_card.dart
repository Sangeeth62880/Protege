import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../common/animated_pressable.dart';
import '../common/category_label.dart';

/// TOP PICK featured path card — purple-bordered with illustration.
class FeaturedPathCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String categoryLabel;
  final Widget illustration;
  final VoidCallback? onTap;

  const FeaturedPathCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.categoryLabel,
    required this.illustration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.purpleLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(color: AppColors.purpleBorder, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP PICK badge
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'TOP PICK',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Illustration
            Center(child: illustration),
            const SizedBox(height: AppSpacing.lg),
            // Category label
            CategoryLabel(text: categoryLabel, color: AppColors.purple),
            const SizedBox(height: AppSpacing.sm),
            // Title
            Text(title, style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            // Subtitle
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
