import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme() {
    final display = GoogleFonts.syneTextTheme();
    final body = GoogleFonts.dmSansTextTheme();
    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 42,
        letterSpacing: -1.2,
        color: AppColors.textOnCream,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 32,
        letterSpacing: -0.8,
        color: AppColors.textOnCream,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        color: AppColors.textOnCream,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: -0.3,
        color: AppColors.textOnCream,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.textOnCream,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: AppColors.textOnCream,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: AppColors.textOnCream,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: AppColors.textOnCreamMuted,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 13,
        color: AppColors.textOnCreamMuted,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.4,
        color: AppColors.textOnCreamMuted,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 0.2,
        color: AppColors.textDim,
      ),
    );
  }
}
