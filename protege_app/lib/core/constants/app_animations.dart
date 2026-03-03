import 'package:flutter/material.dart';

/// Protégé Design System — Animation Constants
class AppAnimations {
  AppAnimations._();

  // ─── Timing ───────────────────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationCelebration = Duration(milliseconds: 800);
  static const Duration durationCount = Duration(milliseconds: 1000);

  // ─── Curves ───────────────────────────────────────────────────────────
  static const Curve curveDefault = Curves.easeInOutCubic;
  static const Curve curveBounce = Curves.elasticOut;
  static const Curve curveSnap = Curves.easeOutBack;
  static const Curve curveSmooth = Curves.easeOutQuart;
  static const Curve curveDecelerate = Curves.decelerate;

  // ─── Stagger ──────────────────────────────────────────────────────────
  static const Duration staggerDelay = Duration(milliseconds: 60);
  static const Duration staggerItemDuration = Duration(milliseconds: 400);
  static const int maxStaggerItems = 10;
}
