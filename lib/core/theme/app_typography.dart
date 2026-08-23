import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme({required Brightness brightness}) {
    final primary =
        brightness == Brightness.dark ? const Color(0xFFF5F7FA) : const Color(0xFF111827);
    final secondary =
        brightness == Brightness.dark ? const Color(0xFF9AA3AD) : const Color(0xFF4B5563);
    final muted =
        brightness == Brightness.dark ? const Color(0xFF6B7280) : const Color(0xFF6B7280);

    final display = GoogleFonts.syneTextTheme();
    final body = GoogleFonts.dmSansTextTheme();
    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 42,
        letterSpacing: -1.2,
        color: primary,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 32,
        letterSpacing: -0.8,
        color: primary,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        color: primary,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: -0.3,
        color: primary,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: primary,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: primary,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: primary,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: secondary,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 13,
        color: secondary,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.4,
        color: secondary,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 0.2,
        color: muted,
      ),
    );
  }
}
