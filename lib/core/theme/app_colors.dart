import 'package:flutter/material.dart';

/// Single source of truth for every color in Zep Pay.
/// Never hardcode hex values in screens — import this file.
abstract final class AppColors {
  static const Color base = Color(0xFF0A0A0F);
  static const Color baseAlt = Color(0xFF0D0D14);
  static const Color hero = Color(0xFF00B4FF);
  static const Color heroDeep = Color(0xFF2D5CFF);
  static const Color surface = Color(0xFF161B26);
  static const Color surfaceHigh = Color(0xFF1C2330);
  static const Color surfaceBorder = Color(0xFF2A3344);
  static const Color stroke = surfaceBorder;
  static const Color textPrimary = Color(0xFFF4F7FF);
  static const Color textMuted = Color(0xFF8B93A7);
  static const Color textDim = Color(0xFF5C6578);
  static const Color danger = Color(0xFFC45C4A);
  static const Color warning = Color(0xFFC4A35A);
  static const Color white = Color(0xFFFFFFFF);

  static const RadialGradient heroGlow = RadialGradient(
    center: Alignment.center,
    radius: 0.95,
    colors: [
      Color(0xFF123A66),
      Color(0xFF0B1A33),
      Color(0xFF0A0A0F),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient scanCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0E2A4A),
      Color(0xFF0A0A0F),
    ],
  );
}
