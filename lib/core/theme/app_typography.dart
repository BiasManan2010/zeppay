import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme() {
    final base = GoogleFonts.manropeTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        fontSize: 42,
        letterSpacing: -1.2,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        fontSize: 32,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: AppColors.textMuted,
      ),
      labelLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 1.4,
        color: AppColors.textMuted,
      ),
      labelSmall: GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 1.6,
        color: AppColors.textDim,
      ),
    );
  }
}
