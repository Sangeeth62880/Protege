import 'package:flutter/material.dart';
import '../../../core/constants/app_design.dart';

/// Pressable wrapper — scale 0.97 on press, 1.0 on release
class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Determine the shadow and brightness based on press state
    final scale = _isPressed ? 0.975 : 1.0;
    final duration = _isPressed ? const Duration(milliseconds: 100) : const Duration(milliseconds: 200);
    final curve = _isPressed ? Curves.easeInOutCubic : Curves.easeOutBack;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: scale,
        duration: duration,
        curve: curve,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(_isPressed ? 0.03 : 0.0),
            BlendMode.darken,
          ),
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            decoration: BoxDecoration(
              // Assuming child manages its own padding/borderRadius, we just affect the overall shadow 
              // The slight dimming from ColorFiltered + Scale provides the primary tactile feel
              // Alternatively, if cards have standard shadows, we could override them here,
              // but cards define their own shape. Scale + Darken works globally.
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
