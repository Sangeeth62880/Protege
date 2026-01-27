import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum ButtonType { primary, secondary, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = isDisabled || isLoading || onPressed == null;

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ButtonType.primary ? AppColors.textOnPrimary : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: type == ButtonType.primary 
                ? AppColors.textOnPrimary 
                : (disabled ? AppColors.textLight : AppColors.primary),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(64, 50)),
      fixedSize: width != null ? WidgetStateProperty.all(Size(width!, 50)) : null,
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (type == ButtonType.primary) {
      return ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: style.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textLight.withValues(alpha: 0.3);
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        ),
        child: buttonContent,
      );
    } else if (type == ButtonType.secondary) {
      return OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: style.copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: AppColors.textLight.withValues(alpha: 0.3));
            }
            return const BorderSide(color: AppColors.primary, width: 2);
          }),
        ),
        child: buttonContent,
      );
    } else {
      return TextButton(
        onPressed: disabled ? null : onPressed,
        style: style,
        child: buttonContent,
      );
    }
  }
}
