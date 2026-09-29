import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DeityTheme {
  final List<Color> gradientColors;
  final Color primaryGlow;
  final Color accentColor;
  final Color tagBackground;

  const DeityTheme({
    required this.gradientColors,
    required this.primaryGlow,
    required this.accentColor,
    required this.tagBackground,
  });
}

class DeityThemeHelper {
  static DeityTheme getThemeForDeity(String? deity) {
    if (deity == null || deity.trim().isEmpty) {
      return const DeityTheme(
        gradientColors: [Color(0xFF420812), Color(0xFF24040A), Color(0xFF140205)],
        primaryGlow: AppColors.goldPrimary,
        accentColor: AppColors.goldLight,
        tagBackground: Color(0xFF5A101C),
      );
    }

    final lower = deity.toLowerCase();

    // Hanuman / Ganesha / Surya -> Saffron & Radiant Gold
    if (lower.contains('hanuman') ||
        lower.contains('ganesha') ||
        lower.contains('ganapathi') ||
        lower.contains('surya') ||
        lower.contains('maruti') ||
        lower.contains('bajrang')) {
      return const DeityTheme(
        gradientColors: [Color(0xFF4A1806), Color(0xFF2E0D03), Color(0xFF170601)],
        primaryGlow: Color(0xFFFF9933),
        accentColor: Color(0xFFFFD59E),
        tagBackground: Color(0xFF6B240B),
      );
    }

    // Shiva / Rudra -> Mystic Smoky Ash & Copper Gold
    if (lower.contains('shiva') ||
        lower.contains('shivaa') ||
        lower.contains('rudra') ||
        lower.contains('mahadev') ||
        lower.contains('nataraja') ||
        lower.contains('linga')) {
      return const DeityTheme(
        gradientColors: [Color(0xFF231A29), Color(0xFF160F1C), Color(0xFF0C0710)],
        primaryGlow: Color(0xFFB8A9D9),
        accentColor: Color(0xFFE5DEFF),
        tagBackground: Color(0xFF382942),
      );
    }

    // Krishna / Vishnu / Rama / Venkateshwara / Narayana -> Celestial Azure Peacock & Gold
    if (lower.contains('krishna') ||
        lower.contains('vishnu') ||
        lower.contains('rama') ||
        lower.contains('venkateshwara') ||
        lower.contains('narayana') ||
        lower.contains('govinda') ||
        lower.contains('balaji')) {
      return const DeityTheme(
        gradientColors: [Color(0xFF0B2136), Color(0xFF051424), Color(0xFF020B14)],
        primaryGlow: Color(0xFF4DA8DA),
        accentColor: Color(0xFFFFE082),
        tagBackground: Color(0xFF123456),
      );
    }

    // Durga / Lalitha / Lakshmi / Saraswati / Devi / Gayathri -> Deep Royal Maroon & Rose Gold
    if (lower.contains('lalitha') ||
        lower.contains('durga') ||
        lower.contains('lakshmi') ||
        lower.contains('saraswati') ||
        lower.contains('gayathri') ||
        lower.contains('devi') ||
        lower.contains('amman') ||
        lower.contains('shakti')) {
      return const DeityTheme(
        gradientColors: [Color(0xFF48091B), Color(0xFF28030D), Color(0xFF140106)],
        primaryGlow: Color(0xFFE57373),
        accentColor: Color(0xFFFFC1C7),
        tagBackground: Color(0xFF641028),
      );
    }

    // Default Sacred Gold Maroon
    return const DeityTheme(
      gradientColors: [Color(0xFF420812), Color(0xFF24040A), Color(0xFF140205)],
      primaryGlow: AppColors.goldPrimary,
      accentColor: AppColors.goldLight,
      tagBackground: Color(0xFF5A101C),
    );
  }
}
