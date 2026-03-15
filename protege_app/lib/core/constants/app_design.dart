import 'package:flutter/material.dart';

/// Protégé Design System — Shape, Spacing, Motion, Shadow

class AppRadius {
  AppRadius._();
  static const sm   = 8.0;
  static const md   = 12.0;
  static const lg   = 16.0;
  static const xl   = 20.0;
  static const xxl  = 28.0;
  static const full = 999.0;
}

class AppSpacing {
  AppSpacing._();
  static const xs   = 4.0;
  static const sm   = 8.0;
  static const md   = 12.0;
  static const lg   = 16.0;
  static const xl   = 20.0;
  static const xxl  = 24.0;
  static const xxxl = 32.0;
  static const huge = 48.0;

  /// Minimum bottom clearance for scrollable screens so content isn't hidden by the floating navbar
  static const navbarClearance = 80.0;

  /// Standard screen horizontal padding
  static const screenH = EdgeInsets.symmetric(horizontal: 20);

  // ── Legacy radius aliases (use AppRadius instead) ──
  static const double radiusSmall  = AppRadius.sm;
  static const double radiusMedium = AppRadius.md;
  static const double radiusLarge  = AppRadius.lg;
  static const double radiusXLarge = AppRadius.xl;
  static const double radiusFull   = AppRadius.full;

  static BorderRadius get borderRadiusSmall  => BorderRadius.circular(AppRadius.sm);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(AppRadius.md);
  static BorderRadius get borderRadiusLarge  => BorderRadius.circular(AppRadius.lg);
  static BorderRadius get borderRadiusXLarge => BorderRadius.circular(AppRadius.xl);
  static BorderRadius get borderRadiusFull   => BorderRadius.circular(AppRadius.full);
}


class AppMotion {
  AppMotion._();
  static const fast        = Duration(milliseconds: 150);
  static const normal      = Duration(milliseconds: 300);
  static const slow        = Duration(milliseconds: 500);
  static const celebration = Duration(milliseconds: 800);
  static const staggerDelay = Duration(milliseconds: 60);

  static const curveStandard   = Curves.easeInOutCubic;
  static const curveBounce     = Curves.elasticOut;
  static const curveSnap       = Curves.easeOutBack;
  static const curveDecelerate = Curves.easeOutQuart;
}

class AppShadow {
  AppShadow._();
  static final sm = [
    BoxShadow(
      color: Colors.black.withAlpha(10),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  static final md = [
    BoxShadow(
      color: Colors.black.withAlpha(15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  static final lg = [
    BoxShadow(
      color: Colors.black.withAlpha(25),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
