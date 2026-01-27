import 'package:flutter/material.dart';

/// App color palette - warm, friendly colors
class AppColors {
  AppColors._();

  // Primary Colors - Soft Orange
  static const Color primary = Color(0xFFFF8C42);
  static const Color primaryLight = Color(0xFFFFAB70);
  static const Color primaryDark = Color(0xFFE07030);

  // Secondary Colors - Warm Coral
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color secondaryLight = Color(0xFFFF9999);
  static const Color secondaryDark = Color(0xFFE04545);

  // Accent Colors
  static const Color accent = Color(0xFF4ECDC4);
  static const Color accentLight = Color(0xFF7EDDD7);
  static const Color accentDark = Color(0xFF36B5AC);

  // Background Colors
  static const Color background = Color(0xFFFFFAF5);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF252540);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFE17055);
  static const Color info = Color(0xFF74B9FF);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF8C42), Color(0xFFFF6B6B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
