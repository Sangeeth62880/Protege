import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Protégé Design System — Spacing, Radii, and Elevation
class AppSpacing {
  AppSpacing._();

  // ─── Spacing Scale ────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  // ─── Shape System (Border Radius) ─────────────────────────────────────
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusFull = 999;

  static BorderRadius get borderRadiusSmall =>
      BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium =>
      BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge =>
      BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXLarge =>
      BorderRadius.circular(radiusXLarge);
  static BorderRadius get borderRadiusFull =>
      BorderRadius.circular(radiusFull);
}

/// Elevation / Shadow Presets
class AppElevation {
  AppElevation._();

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x0A000000), // 4%
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x0F000000), // 6%
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x1A000000), // 10%
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
