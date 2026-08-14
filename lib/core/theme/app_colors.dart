import 'package:flutter/material.dart';

/// Single source of truth for every color in Zep Pay.
/// Never hardcode hex values in screens — import this file.
abstract final class AppColors {
  static const Color base = Color(0xFF0B0B0B);
  static const Color baseAlt = Color(0xFF101012);
  static const Color hero = Color(0xFF1E9BFF);
  static const Color heroDeep = Color(0xFF0B6ED6);
  static const Color heroSoft = Color(0xFF4DB8FF);
  static const Color surface = Color(0xFF161618);
  static const Color surfaceHigh = Color(0xFF1C1C20);
  static const Color surfaceBorder = Color(0xFF2A2A32);
  static const Color stroke = surfaceBorder;
  static const Color homeWash = Color(0xFF12263A);
  static const Color navBar = Color(0xE6101012);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textMuted = Color(0xFF9AA3B5);
  static const Color textDim = Color(0xFF6B7385);
  static const Color danger = Color(0xFFC45C4A);
  static const Color warning = Color(0xFFC4A35A);
  static const Color success = Color(0xFF22C55E);
  static const Color white = Color(0xFFFFFFFF);

  static const RadialGradient heroGlow = RadialGradient(
    center: Alignment.center,
    radius: 0.95,
    colors: [
      Color(0xFF123A66),
      Color(0xFF0B1A33),
      Color(0xFF0B0B0B),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient scanCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0E2440),
      Color(0xFF0B0B0B),
      Color(0xFF071018),
    ],
  );

  static const LinearGradient scanOrb = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6EC8FF),
      Color(0xFF1E9BFF),
      Color(0xFF0B6ED6),
    ],
  );
}
