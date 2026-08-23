import 'package:flutter/material.dart';

/// Zep Pay — blue / black-grey / white design system.
abstract final class AppColors {
  // Brand blue
  static const Color hero = Color(0xFF3BA3FF);
  static const Color heroDeep = Color(0xFF1B7FE0);
  static const Color heroSoft = Color(0xFF7EC4FF);

  // Primary actions — blue (not orange)
  static const Color accent = hero;
  static const Color accentDeep = heroDeep;

  // Dark surfaces (payment flow, modals)
  static const Color cardDark = Color(0xFF1A1D21);
  static const Color cardDarkAlt = Color(0xFF1C1F24);
  static const Color base = Color(0xFF12151A);
  static const Color baseAlt = Color(0xFF181C22);
  static const Color surface = Color(0xFF1E2329);
  static const Color surfaceHigh = Color(0xFF2A3038);
  static const Color surfaceBorder = Color(0xFF3A424D);
  static const Color stroke = surfaceBorder;

  // Legacy aliases — prefer Theme.of(context).scaffoldBackgroundColor / context.zep
  static const Color cream = Color(0xFF0F1216);
  static const Color creamDeep = Color(0xFF2E3640);
  static const Color rowLight = Color(0xFF1E2329);
  static const Color homeWash = cream;
  static const Color navBar = Color(0xF014181E);

  // Text (dark-theme defaults; light mode uses Theme textTheme)
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textMuted = Color(0xFF9AA3AD);
  static const Color textDim = Color(0xFF6B7280);
  static const Color textOnCream = textPrimary;
  static const Color textOnCreamMuted = textMuted;
  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);

  // Gradients
  static const LinearGradient brandCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1B7FE0), Color(0xFF0F4C8A)],
  );

  /// @deprecated Use [brandCard]
  static const LinearGradient forestCard = brandCard;

  static const LinearGradient scanCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardDarkAlt, cardDark, Color(0xFF252A32)],
  );

  static const LinearGradient scanOrb = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5BB8FF), hero, heroDeep],
  );

  static const RadialGradient heroGlow = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.15,
    colors: [Color(0xFF1E3A5F), Color(0xFF0F1216)],
    stops: [0.0, 1.0],
  );
}
