import 'package:flutter/material.dart';

/// Protégé Design System — Color Palette
class AppColors {
  AppColors._();

  // ── Surfaces ──
  static const background   = Color(0xFFFAFAFA);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF3F4F6);
  static const darkBg       = Color(0xFF111115);
  static const darkSurface  = Color(0xFF1E1E24);

  // ── Brand ──
  static const brand      = Color(0xFF6C5CE7);
  static const brandLight = Color(0xFFEDE9FE);
  static const brandDark  = Color(0xFF4C3BC2);

  // ── Semantic ──
  static const success      = Color(0xFF22C55E);
  static const successLight = Color(0xFFDCFCE7);
  static const error        = Color(0xFFEF4444);
  static const errorLight   = Color(0xFFFEE2E2);
  static const warning      = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const info         = Color(0xFF3B82F6);
  static const infoLight    = Color(0xFFDBEAFE);

  // ── Accent Palette ──
  static const accentOrange = Color(0xFFF97316);
  static const accentPink   = Color(0xFFEC4899);
  static const accentTeal   = Color(0xFF14B8A6);
  static const accentIndigo = Color(0xFF6366F1);

  // ── Text ──
  static const textPrimary   = Color(0xFF111115);
  static const textSecondary = Color(0xFF4B5563);
  static const textTertiary  = Color(0xFF9CA3AF);
  static const textOnDark    = Color(0xFFF9FAFB);
  static const textOnBrand   = Color(0xFFFFFFFF);

  // ── Borders ──
  static const border      = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF3F4F6);
  static const borderFocus = Color(0xFF6C5CE7);

  // ── Legacy aliases (will be removed after full migration) ──
  static const primary = brand;
  static const primaryLight = brandLight;
  static const primaryDark = brandDark;
  static const onPrimary = textOnBrand;
  static const textOnPrimary = textOnBrand;
  static const teachMode = accentTeal;

  // Legacy surface aliases
  static const surfaceElevated = surface;
  static const surfaceVariant = surfaceMuted;
  static const inputBackground = surfaceMuted;
  static const inputBorder = border;
  static const divider = borderLight;
  static const backgroundDark = darkBg;
  static const darkBackground = darkBg;

  // Legacy shadow aliases
  static const shadow = Color(0x0F000000);
  static const shadowLight = Color(0x0A000000);

  // Legacy accent aliases
  static const accent = warning;
  static const green = success;
  static const greenLight = successLight;
  static const blue = info;
  static const blueLight = infoLight;
  static const orange = accentOrange;
  static const purple = brand;
  static const purpleLight = brandLight;
  static const purpleBorder = brand;
  static const yellowLight = warningLight;
  static const yellow = warning;
  static const red = error;
  static const streak = warning;
  static const xp = success;
  static const secondary = accentTeal;

  // Legacy additional aliases
  static const redLight = errorLight;
  static const amber = warning;
  static const purpleMuted = brandLight;
  static const orangeLight = Color(0xFFFEF3C7);
  static const greenDark = Color(0xFF16A34A);
  static final gradientStreakFlame = LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]);
  static final gradientAmberTrophy = LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]);

  // Legacy gradient
  static final primaryGradient = LinearGradient(colors: [brand, brandDark]);

  // Legacy text aliases
  static const textLight = textTertiary;
}
