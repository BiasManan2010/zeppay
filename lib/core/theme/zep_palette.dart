import 'package:flutter/material.dart';

/// Semantic colors for light / dark — use via `context.zep`.
@immutable
class ZepPalette extends ThemeExtension<ZepPalette> {
  const ZepPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.card,
    required this.border,
    required this.navBar,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.promoText,
    required this.promoSubtext,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color card;
  final Color border;
  final Color navBar;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color promoText;
  final Color promoSubtext;

  static const dark = ZepPalette(
    background: Color(0xFF0F1216),
    surface: Color(0xFF181C22),
    surfaceElevated: Color(0xFF222831),
    card: Color(0xFF1E2329),
    border: Color(0xFF2E3640),
    navBar: Color(0xF014181E),
    textPrimary: Color(0xFFF5F7FA),
    textSecondary: Color(0xFFB8C0CC),
    textMuted: Color(0xFF8B95A5),
    promoText: Color(0xFFFFFFFF),
    promoSubtext: Color(0xB3FFFFFF),
  );

  static const light = ZepPalette(
    background: Color(0xFFE8EAED),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF4F6F8),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFD8DEE4),
    navBar: Color(0xF2FFFFFF),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF6B7280),
    promoText: Color(0xFF111827),
    promoSubtext: Color(0xFF4B5563),
  );

  /// Higher contrast variant — stronger text/border separation.
  static const darkHighContrast = ZepPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceElevated: Color(0xFF141414),
    card: Color(0xFF101010),
    border: Color(0xFFE5E7EB),
    navBar: Color(0xF0000000),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFF3F4F6),
    textMuted: Color(0xFFD1D5DB),
    promoText: Color(0xFFFFFFFF),
    promoSubtext: Color(0xFFE5E7EB),
  );

  static const lightHighContrast = ZepPalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF9FAFB),
    card: Color(0xFFFFFFFF),
    border: Color(0xFF111827),
    navBar: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF1F2937),
    textMuted: Color(0xFF374151),
    promoText: Color(0xFF000000),
    promoSubtext: Color(0xFF1F2937),
  );

  @override
  ZepPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? card,
    Color? border,
    Color? navBar,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? promoText,
    Color? promoSubtext,
  }) {
    return ZepPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      card: card ?? this.card,
      border: border ?? this.border,
      navBar: navBar ?? this.navBar,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      promoText: promoText ?? this.promoText,
      promoSubtext: promoSubtext ?? this.promoSubtext,
    );
  }

  @override
  ZepPalette lerp(ThemeExtension<ZepPalette>? other, double t) {
    if (other is! ZepPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ZepPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      card: l(card, other.card),
      border: l(border, other.border),
      navBar: l(navBar, other.navBar),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      promoText: l(promoText, other.promoText),
      promoSubtext: l(promoSubtext, other.promoSubtext),
    );
  }
}

extension ZepThemeContext on BuildContext {
  ZepPalette get zep =>
      Theme.of(this).extension<ZepPalette>() ?? ZepPalette.dark;
}
