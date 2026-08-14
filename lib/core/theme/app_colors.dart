import 'package:flutter/material.dart';

/// Charcoal grey base, blue only as accent — never a blue wash on screens.
abstract final class AppColors {
  static const Color base = Color(0xFF1C1C1E);
  static const Color baseAlt = Color(0xFF242426);
  static const Color hero = Color(0xFF3BA3FF);
  static const Color heroDeep = Color(0xFF1B7FE0);
  static const Color heroSoft = Color(0xFF7EC4FF);
  static const Color surface = Color(0xFF2C2C2E);
  static const Color surfaceHigh = Color(0xFF3A3A3C);
  static const Color surfaceBorder = Color(0xFF4A4A4E);
  static const Color stroke = surfaceBorder;
  static const Color homeWash = Color(0xFF2A2A2E);
  static const Color navBar = Color(0xE61C1C1E);
  static const Color textPrimary = Color(0xFFF2F2F7);
  static const Color textMuted = Color(0xFFAEAEB2);
  static const Color textDim = Color(0xFF8E8E93);
  static const Color danger = Color(0xFFC45C4A);
  static const Color warning = Color(0xFFC4A35A);
  static const Color success = Color(0xFF34C759);
  static const Color white = Color(0xFFFFFFFF);

  static const RadialGradient heroGlow = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.15,
    colors: [
      Color(0xFF323236),
      Color(0xFF1C1C1E),
    ],
    stops: [0.0, 1.0],
  );

  static const LinearGradient scanCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3A3A3C),
      Color(0xFF1C1C1E),
      Color(0xFF2C2C2E),
    ],
  );

  static const LinearGradient scanOrb = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7EC4FF),
      Color(0xFF3BA3FF),
      Color(0xFF1B7FE0),
    ],
  );
}
