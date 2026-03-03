import 'package:flutter/material.dart';

/// Protégé App Color System
/// Designed for high contrast and accessibility (WCAG AA compliant)
class AppColors {
  // ═══════════════════════════════════════════════════════════════════════
  // PRIMARY BRAND COLORS
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Main brand color - Warm Orange
  static const Color primary = Color(0xFFE86A33);
  static const Color primaryLight = Color(0xFFFF8F5C);
  static const Color primaryDark = Color(0xFFC94D1A);
  
  /// Secondary brand color - Deep Teal
  static const Color secondary = Color(0xFF1A5F7A);
  static const Color secondaryLight = Color(0xFF2E8BA8);
  static const Color secondaryDark = Color(0xFF0D3D4D);
  
  /// Accent color - Golden Yellow (for highlights, achievements)
  static const Color accent = Color(0xFFFFC93C);
  static const Color accentLight = Color(0xFFFFD966);
  static const Color accentDark = Color(0xFFE6A800);
  
  // ═══════════════════════════════════════════════════════════════════════
  // BACKGROUND COLORS
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Main background - Warm off-white
  static const Color background = Color(0xFFFAF7F5);
  
  /// Surface color for cards and containers
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Slightly tinted surface for layered cards
  static const Color surfaceVariant = Color(0xFFF5F0EC);
  
  /// Dark background for contrast sections
  static const Color backgroundDark = Color(0xFF1A1A2E);
  
  // ═══════════════════════════════════════════════════════════════════════
  // TEXT COLORS - HIGH CONTRAST
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Primary text - Almost black for maximum readability
  static const Color textPrimary = Color(0xFF1A1A1A);
  
  /// Secondary text - Dark gray for supporting text
  static const Color textSecondary = Color(0xFF5A5A5A);
  
  /// Tertiary text - Medium gray for hints, captions
  static const Color textTertiary = Color(0xFF8A8A8A);
  
  /// Disabled text
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  /// Text on primary color backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  /// Text on dark backgrounds
  static const Color textOnDark = Color(0xFFF5F5F5);
  
  /// Light text color (alias for backward compatibility)
  static const Color textLight = textTertiary;
  
  /// Link color
  static const Color textLink = Color(0xFF1A5F7A);
  
  // ═══════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Success - Green
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  
  /// Error - Red
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  
  /// Warning - Amber
  static const Color warning = Color(0xFFFF8F00);
  static const Color warningLight = Color(0xFFFFF3E0);
  
  /// Info - Blue
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);
  
  // ═══════════════════════════════════════════════════════════════════════
  // UI ELEMENT COLORS
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Dividers and borders
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFD0D0D0);
  static const Color borderLight = Color(0xFFE8E8E8);
  
  /// Input field backgrounds
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputBorderFocused = Color(0xFFE86A33);
  
  /// Shadows
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  
  /// Overlay
  static const Color overlay = Color(0x80000000);
  
  // ═══════════════════════════════════════════════════════════════════════
  // GRADIENT DEFINITIONS
  // ═══════════════════════════════════════════════════════════════════════
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFE86A33), Color(0xFFFFC93C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient coolGradient = LinearGradient(
    colors: [Color(0xFF1A5F7A), Color(0xFF2E8BA8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF7F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // ═══════════════════════════════════════════════════════════════════════
  // FEATURE-SPECIFIC COLORS
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Reverse Tutoring / Teach Mode
  static const Color teachMode = Color(0xFF7B2CBF);
  static const Color teachModeLight = Color(0xFFF3E5F5);
  
  /// Quiz Mode
  static const Color quizMode = Color(0xFF00796B);
  static const Color quizModeLight = Color(0xFFE0F2F1);
  
  /// Progress / Achievements
  static const Color streak = Color(0xFFFF6B35);
  static const Color xp = Color(0xFFFFD700);
  static const Color level = Color(0xFF9C27B0);

  // ═══════════════════════════════════════════════════════════════════════
  // SPACING SCALE
  // ═══════════════════════════════════════════════════════════════════════

  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;

  // ═══════════════════════════════════════════════════════════════════════
  // BORDER RADII
  // ═══════════════════════════════════════════════════════════════════════

  static const double radiusCard = 12;
  static const double radiusHero = 28;
  static const double radiusFAB = 24;
}
