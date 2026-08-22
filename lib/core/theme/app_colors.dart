import 'package:flutter/material.dart';

/// Zep Pay design tokens — warm cream dashboard, dark feature cards, orange CTAs.
abstract final class AppColors {
  // Brand (logo / splash only)
  static const Color hero = Color(0xFF3BA3FF);
  static const Color heroDeep = Color(0xFF1B7FE0);

  // Surfaces
  static const Color cream = Color(0xFFFDECD9);
  static const Color creamDeep = Color(0xFFF5DFC8);
  static const Color cardDark = Color(0xFF1A1A1A);
  static const Color cardDarkAlt = Color(0xFF1C1C1E);
  static const Color forest = Color(0xFF1B3D2F);
  static const Color forestLight = Color(0xFF2A5C45);
  static const Color rowLight = Color(0xFFFFFBF7);

  // Legacy dark (payment flow overlays, modals)
  static const Color base = cardDarkAlt;
  static const Color baseAlt = Color(0xFF242426);
  static const Color surface = Color(0xFF2C2C2E);
  static const Color surfaceHigh = Color(0xFF3A3A3C);
  static const Color surfaceBorder = Color(0xFF4A4A4E);
  static const Color stroke = surfaceBorder;
  static const Color homeWash = cream;
  static const Color navBar = Color(0xF2FFFBF7);

  // Accent — primary CTA, FAB, pending
  static const Color accent = Color(0xFFE87B3A);
  static const Color accentDeep = Color(0xFFD4622A);

  // Text
  static const Color textPrimary = Color(0xFFF2F2F7);
  static const Color textMuted = Color(0xFFAEAEB2);
  static const Color textDim = Color(0xFF8E8E93);
  static const Color textOnCream = Color(0xFF1A1A1A);
  static const Color textOnCreamMuted = Color(0xFF5C5C5E);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color danger = Color(0xFFC45C4A);
  static const Color warning = Color(0xFFE87B3A);
  static const Color success = Color(0xFF2D8A5E);
  static const Color heroSoft = Color(0xFF7EC4FF);

  static const RadialGradient heroGlow = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.15,
    colors: [Color(0xFFFFF8F0), cream],
    stops: [0.0, 1.0],
  );

  static const LinearGradient forestCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [forestLight, forest],
  );

  static const LinearGradient scanCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardDarkAlt, cardDark, Color(0xFF2C2C2E)],
  );

  static const LinearGradient scanOrb = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5A623), accent, accentDeep],
  );
}
