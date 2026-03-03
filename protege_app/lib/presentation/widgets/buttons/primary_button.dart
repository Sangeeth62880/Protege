import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../common/animated_pressable.dart';

/// Dark full-width pill button — the primary CTA.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onPressed != null && !isLoading
              ? AppColors.darkSurface
              : AppColors.textDisabled,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnDark,
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, color: AppColors.textOnDark, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTypography.buttonLarge),
            ],
          ],
        ),
      ),
    );
  }
}
