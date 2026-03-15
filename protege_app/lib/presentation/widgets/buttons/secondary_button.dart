import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';

/// Outlined secondary button with rich micro-interactions
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

    final scale = _isPressed ? 0.97 : 1.0;
    final duration = _isPressed ? const Duration(milliseconds: 100) : const Duration(milliseconds: 200);
    final curve = _isPressed ? Curves.easeInOutCubic : Curves.easeOutBack;

    // Calculate border and background color
    Color borderColor = AppColors.border;
    Color bgColor = Colors.transparent;
    
    if (_isPressed && enabled) {
      borderColor = AppColors.brand.withOpacity(0.5);
      bgColor = AppColors.brandLight.withOpacity(0.3);
    } else if (_isHovered && enabled) {
      borderColor = AppColors.brand.withOpacity(0.3);
    }

    Widget content = AnimatedScale(
      scale: scale,
      duration: duration,
      curve: curve,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: widget.isDisabled ? AppColors.border.withOpacity(0.5) : borderColor,
          ),
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.textPrimary),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: AppColors.textPrimary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.label,
                      style: AppTypography.btnMd.copyWith(
                        color: widget.isDisabled ? AppColors.textTertiary : AppColors.textPrimary,
                      ),
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
