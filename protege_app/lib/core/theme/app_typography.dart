import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Protégé Design System — Typography
class AppTypography {
  AppTypography._();

  // ── Display (splash, celebrations, hero headings) ──
  static TextStyle get displayLg => GoogleFonts.plusJakartaSans(
    fontSize: 40, fontWeight: FontWeight.w800,
    letterSpacing: -1.2, color: AppColors.textPrimary, height: 1.1,
  );
  static TextStyle get displayMd => GoogleFonts.plusJakartaSans(
    fontSize: 32, fontWeight: FontWeight.w700,
    letterSpacing: -0.8, color: AppColors.textPrimary, height: 1.15,
  );
  static TextStyle get displaySm => GoogleFonts.plusJakartaSans(
    fontSize: 24, fontWeight: FontWeight.w700,
    letterSpacing: -0.5, color: AppColors.textPrimary, height: 1.2,
  );

  // ── Headings ──
  static TextStyle get headingLg => GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700,
    letterSpacing: -0.3, color: AppColors.textPrimary, height: 1.25,
  );
  static TextStyle get headingMd => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600,
    letterSpacing: -0.2, color: AppColors.textPrimary, height: 1.3,
  );
  static TextStyle get headingSm => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.35,
  );

  // ── Labels ──
  static TextStyle get labelLg => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w700,
    letterSpacing: 0.8, color: AppColors.textSecondary,
  );
  static TextStyle get labelSm => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600,
    letterSpacing: 1.0, color: AppColors.textTertiary,
  );

  // ── Body ──
  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400,
    height: 1.6, color: AppColors.textSecondary,
  );
  static TextStyle get bodyMd => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400,
    height: 1.55, color: AppColors.textSecondary,
  );
  static TextStyle get bodySm => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400,
    height: 1.5, color: AppColors.textTertiary,
  );

  // ── Buttons ──
  static TextStyle get btnLg => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );
  static TextStyle get btnMd => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );

  // ── Stats / Numbers ──
  static TextStyle get statLg => GoogleFonts.plusJakartaSans(
    fontSize: 36, fontWeight: FontWeight.w800,
    letterSpacing: -0.5, color: AppColors.textPrimary,
  );
  static TextStyle get statMd => GoogleFonts.plusJakartaSans(
    fontSize: 24, fontWeight: FontWeight.w700,
    letterSpacing: -0.3, color: AppColors.textPrimary,
  );
  static TextStyle get statSm => GoogleFonts.plusJakartaSans(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── Code ──
  static TextStyle get code => GoogleFonts.jetBrainsMono(
    fontSize: 13, fontWeight: FontWeight.w400,
    height: 1.65, color: AppColors.textOnDark,
  );

  // ── Legacy aliases for ThemeData textTheme ──
  static TextStyle get displayLarge => displayLg;
  static TextStyle get displayMedium => displayMd;
  static TextStyle get displaySmall => displaySm;
  static TextStyle get headlineLarge => headingLg;
  static TextStyle get headlineMedium => headingMd;
  static TextStyle get headlineSmall => headingSm;
  static TextStyle get titleLarge => headingMd;
  static TextStyle get titleMedium => headingSm;
  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle get bodyLarge => bodyLg;
  static TextStyle get bodyMedium => bodyMd;
  static TextStyle get bodySmall => bodySm;
  static TextStyle get labelLarge => labelLg;
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
  );
  static TextStyle get labelSmall => labelSm;

  // More legacy aliases
  static TextStyle get caption => bodySm;
  static TextStyle get buttonSmall => btnMd;
  static TextStyle get statMedium => statMd;
  static TextStyle get statLarge => statLg;
  static TextStyle get buttonMedium => btnMd;
  static TextStyle get labelCategory => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w700,
    letterSpacing: 1.2, color: AppColors.textTertiary,
  );
}
