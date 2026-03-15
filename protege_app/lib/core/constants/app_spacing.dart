// Legacy re-export — old screens import from here.
// The canonical AppSpacing now lives in app_design.dart.
export 'app_design.dart' show AppSpacing, AppRadius, AppMotion, AppShadow;

import 'package:flutter/material.dart';

/// Legacy elevation / shadow presets — kept for un-migrated screens.
class AppElevation {
  AppElevation._();

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
