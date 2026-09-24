import 'package:flutter/material.dart';

/// Bhakti Devotional Color Palette
/// Designed for spiritual peace, reverence, high contrast, and accessibility.
class AppColors {
  AppColors._();

  // Primary Spiritual Colors
  static const Color maroonPrimary = Color(0xFF7A1426);      // Deep Sacred Maroon
  static const Color maroonDark = Color(0xFF520B17);         // Sanctum Maroon
  static const Color maroonLight = Color(0xFF9E1F35);        // Royal Maroon
  static const Color maroonSurface = Color(0xFF33070E);      // Deep Night Maroon

  // Sacred Saffron & Amber
  static const Color saffronPrimary = Color(0xFFD96B06);     // Bhagwa Saffron
  static const Color saffronLight = Color(0xFFF59E0B);       // Warm Morning Amber
  static const Color saffronDark = Color(0xFFB45309);        // Deep Vermilion

  // Temple Gold & Brass Accents
  static const Color goldPrimary = Color(0xFFC8932C);        // Temple Gold
  static const Color goldLight = Color(0xFFDFAB48);          // Radiant Diya Glow
  static const Color goldDark = Color(0xFF9B6E16);           // Antique Brass
  static const Color goldMuted = Color(0xFFE8CA88);

  // Subtle Serene Parchment & Warm Sandalwood Backgrounds (Easy on elder eyes)
  static const Color subtleBackground = Color(0xFFF7F4EE);   // Calming Warm Ivory
  static const Color subtleSurface = Color(0xFFEFE9DC);      // Soft Temple Sandalwood
  static const Color subtleCard = Color(0xFFFFFFFF);         // Clean Card Surface
  static const Color subtleBorder = Color(0xFFE5DDD0);       // Soft Antique Border
  static const Color subtlePillBg = Color(0xFFEDE5D8);       // Gentle Pill Background
  static const Color subtlePillActive = Color(0xFF7A1426);   // Active Maroon Pill

  // Legacy aliases
  static const Color creamBackground = Color(0xFFF7F4EE);
  static const Color creamSurface = Color(0xFFEFE9DC);
  static const Color creamCard = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF1E1614);
  static const Color darkSurface = Color(0xFF2B211E);
  static const Color darkCard = Color(0xFF352B28);
  static const Color darkBorder = Color(0xFF453834);
  static const Color ytPillBg = Color(0xFFEDE5D8);
  static const Color ytPillActive = Color(0xFF7A1426);

  // High-Contrast Clear Text (Specially tuned for elders)
  static const Color textDark = Color(0xFF1F1612);          // Deep Charcoal Sandalwood
  static const Color textMuted = Color(0xFF5E5047);         // Gentle Subtitle Text
  static const Color textLight = Color(0xFFFFF9F2);         // Light Cream for Maroon banners
  static const Color textLightMuted = Color(0xFFE3D6C8);

  // Status & Feedback
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFEF6C00);

  // Gradients
  static const LinearGradient heroMaroonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B182C), Color(0xFF6B0E1E), Color(0xFF3B060F)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFDF73), Color(0xFFD4AF37), Color(0xFFAA820A)],
  );

  static const LinearGradient saffronSunriseGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF9933), Color(0xFFE65100), Color(0xFF6B0E1E)],
  );

  static const LinearGradient sacredAmberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8F00), Color(0xFFE65100), Color(0xFF8D2400)],
  );

  static const LinearGradient royalTempleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A148C), Color(0xFF311B92), Color(0xFF1A0038)],
  );

  static const LinearGradient vrindavanEmeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF0D3E12), Color(0xFF052008)],
  );

  static const LinearGradient gangaAzureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF012B6B), Color(0xFF00163B)],
  );

  static const LinearGradient lotusPinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFAD1457), Color(0xFF880E4F), Color(0xFF4A0429)],
  );

  static const LinearGradient playerBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF380710),
      Color(0xFF200409),
      Color(0xFF120205),
    ],
  );
}
