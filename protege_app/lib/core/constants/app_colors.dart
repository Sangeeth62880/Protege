import 'package:flutter/material.dart';

/// Protégé Design System — Color Palette
/// Brilliant.org-inspired flat, premium aesthetic
class AppColors {
  AppColors._();

  // ─── Core Surfaces ────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F7F7);
  static const Color surfaceVariant = Color(0xFFF7F7F7); // alias
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF1B1B1B);
  static const Color darkSurface = Color(0xFF2D2D2D);
  static const Color darkSurfaceLight = Color(0xFF3D3D3D);
  static const Color backgroundDark = darkBackground; // legacy alias
  static const Color inputBackground = Color(0xFFF5F5F5);

  // ─── Brand / Primary ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF2D2D2D);
  static const Color primaryLight = Color(0xFF4A4A4A);
  static const Color primaryDark = Color(0xFF1B1B1B);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ─── Green ────────────────────────────────────────────────────────────
  static const Color green = Color(0xFF43B929);
  static const Color greenLight = Color(0xFFE8F7E4);
  static const Color greenDark = Color(0xFF2E8B1E);
  static const Color greenMuted = Color(0xFFA8E6A1);
  static const Color success = green;
  static const Color successLight = greenLight;

  // ─── Purple ───────────────────────────────────────────────────────────
  static const Color purple = Color(0xFF7C5CFC);
  static const Color purpleLight = Color(0xFFF0ECFF);
  static const Color purpleMuted = Color(0xFFC4B5FD);
  static const Color purpleBorder = Color(0xFFB8A9FF);

  // ─── Yellow ───────────────────────────────────────────────────────────
  static const Color yellow = Color(0xFFFFD84D);
  static const Color yellowLight = Color(0xFFFFF9E0);
  static const Color yellowMuted = Color(0xFFFFE8A3);

  // ─── Orange ───────────────────────────────────────────────────────────
  static const Color orange = Color(0xFFFF8C42);
  static const Color orangeLight = Color(0xFFFFF0E5);
  static const Color peach = Color(0xFFFFD4B8);

  // ─── Blue ─────────────────────────────────────────────────────────────
  static const Color blue = Color(0xFF4C8BF5);
  static const Color blueLight = Color(0xFFE3F0FF);
  static const Color blueMuted = Color(0xFFA3C9FF);

  // ─── Red ──────────────────────────────────────────────────────────────
  static const Color red = Color(0xFFFF4444);
  static const Color redLight = Color(0xFFFFE8E8);
  static const Color redMuted = Color(0xFFFFA3A3);
  static const Color error = red;
  static const Color errorLight = redLight;

  // ─── Amber ────────────────────────────────────────────────────────────
  static const Color amber = Color(0xFFFFAB00);
  static const Color amberLight = Color(0xFFFFF3D6);

  // ─── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9B9B9B);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFFC8C8C8);
  static const Color textLight = textTertiary; // legacy alias
  static const Color textLink = blue;

  // ─── Borders & Dividers ───────────────────────────────────────────────
  static const Color border = Color(0xFFE8E8E8);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderSelected = green;
  static const Color borderFeatured = purpleBorder;
  static const Color borderError = red;
  static const Color divider = border;
  static const Color inputBorder = border;
  static const Color inputBorderFocused = green;

  // ─── Shadows ──────────────────────────────────────────────────────────
  static const Color shadow = Color(0x0A000000); // 4%
  static const Color shadowLight = Color(0x06000000);
  static const Color overlay = Color(0x80000000);

  // ─── Legacy Aliases (backward compatibility) ──────────────────────────
  static const Color secondary = purple;
  static const Color secondaryLight = purpleLight;
  static const Color secondaryDark = Color(0xFF5A3FD4);
  static const Color accent = yellow;
  static const Color accentLight = yellowLight;
  static const Color accentDark = Color(0xFFE6A800);
  static const Color warning = orange;
  static const Color warningLight = orangeLight;
  static const Color info = blue;
  static const Color infoLight = blueLight;
  static const Color teachMode = purple;
  static const Color teachModeLight = purpleLight;
  static const Color quizMode = green;
  static const Color quizModeLight = greenLight;
  static const Color streak = orange;
  static const Color xp = green;
  static const Color level = purple;

  // ─── Gradients ────────────────────────────────────────────────────────
  static const LinearGradient gradientStreakFlame = LinearGradient(
    colors: [Color(0xFFFF8C42), Color(0xFFFF4444)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const RadialGradient gradientGreenGlow = RadialGradient(
    colors: [Color(0x6643B929), Colors.transparent],
    stops: [0.4, 1.0],
    center: Alignment.center,
  );

  static const LinearGradient gradientPurpleCard = LinearGradient(
    colors: [Color(0xFFF0ECFF), Color(0xFFE0D6FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientXpSparkle = LinearGradient(
    colors: [Color(0xFF43B929), Color(0xFFA8E6A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientAmberTrophy = LinearGradient(
    colors: [Color(0xFFFFAB00), Color(0xFFFF8C42)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Legacy gradient aliases
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = gradientStreakFlame;

  static const LinearGradient coolGradient = LinearGradient(
    colors: [blue, blueMuted],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F7F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
