import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';

/// A reusable glassmorphism wrapper widget.
/// Applies a background blur, semi-transparent tint, and subtle white border.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double opacity;
  final double blurSigma;
  final double borderOpacity;
  final Color backgroundColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.lg,
    this.opacity = 0.12,
    this.blurSigma = 20.0,
    this.borderOpacity = 0.2,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
