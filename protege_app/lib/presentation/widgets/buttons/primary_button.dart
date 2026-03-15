import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';

/// Full-width brand-colored primary button with rich micro-interactions
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

    final scale = _isPressed ? 0.97 : 1.0;
    final duration = _isPressed ? const Duration(milliseconds: 100) : const Duration(milliseconds: 200);
    final curve = _isPressed ? Curves.easeInOutCubic : Curves.easeOutBack;

    // Calculate background color
    Color bgColor = AppColors.brand;
    if (_isPressed) {
      bgColor = Color.lerp(AppColors.brand, Colors.black, 0.1) ?? AppColors.brand;
    } else if (_isHovered && enabled) {
      bgColor = Color.lerp(AppColors.brand, Colors.white, 0.05) ?? AppColors.brand;
    }

    // Calculate shadow
    List<BoxShadow> shadow = AppShadow.sm;
    if (_isPressed || !enabled) {
      shadow = [];
    } else if (_isHovered) {
      shadow = AppShadow.md;
    }

    Widget content = AnimatedScale(
      scale: scale,
      duration: duration,
      curve: curve,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: widget.isDisabled ? AppColors.brand.withOpacity(0.4) : bgColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: shadow,
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.textOnBrand),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: AppColors.textOnBrand, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.label,
                      style: AppTypography.btnLg.copyWith(color: AppColors.textOnBrand),
                    ),
                  ],
                ),
        ),
      ),
    );

    if (kIsWeb || (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux)) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: content,
      );
    }

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
