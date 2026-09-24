import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Accessible and elegant typography for multi-script Indic texts
class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.cinzel(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: AppColors.textDark,
      );

  static TextStyle get titleLarge => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: AppColors.textDark,
      );

  static TextStyle get titleMedium => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textDark,
      );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textMuted,
      );

  static TextStyle get sacredDevotionalText => GoogleFonts.gotu(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.8,
        color: AppColors.textDark,
      );
}
