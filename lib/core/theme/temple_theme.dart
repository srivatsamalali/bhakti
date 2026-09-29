import 'package:flutter/material.dart';

/// Defines an authentic deity temple theme with curated spiritual color palettes,
/// gradients, and surface styling.
class TempleTheme {
  final String id;
  final String name;
  final String deityName;
  final String subtitle;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentGold;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color textMuted;
  final List<Color> heroGradientColors;
  final List<Color> playerGradientColors;
  final Color auraGlowColor;

  const TempleTheme({
    required this.id,
    required this.name,
    required this.deityName,
    required this.subtitle,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentGold,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.textMuted,
    required this.heroGradientColors,
    required this.playerGradientColors,
    required this.auraGlowColor,
  });

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: heroGradientColors,
      );

  LinearGradient get playerGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: playerGradientColors,
      );

  // 1. Tirumala Balaji (Default) - Royal Sanctum Maroon & Temple Gold
  static const TempleTheme tirumala = TempleTheme(
    id: 'tirumala',
    name: 'Tirumala Balaji',
    deityName: 'Lord Venkateshwara',
    subtitle: 'Royal Sanctum Maroon & 24K Temple Gold',
    emoji: '🪷',
    primaryColor: Color(0xFF7A1426),
    secondaryColor: Color(0xFFD96B06),
    accentGold: Color(0xFFC8932C),
    backgroundColor: Color(0xFFF7F4EE),
    surfaceColor: Color(0xFFEFE9DC),
    cardColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFE5DDD0),
    textColor: Color(0xFF1F1612),
    textMuted: Color(0xFF5E5047),
    heroGradientColors: [Color(0xFF8B182C), Color(0xFF6B0E1E), Color(0xFF3B060F)],
    playerGradientColors: [Color(0xFF380710), Color(0xFF200409), Color(0xFF120205)],
    auraGlowColor: Color(0xFFDFAB48),
  );

  // 2. Kashi Vishwanath - Sacred Bhasma Slate & Bilva Emerald
  static const TempleTheme kashi = TempleTheme(
    id: 'kashi',
    name: 'Kashi Vishwanath',
    deityName: 'Lord Shiva Mahadev',
    subtitle: 'Sacred Bhasma Slate & Nilakantha Azure',
    emoji: '🔱',
    primaryColor: Color(0xFF1E3A5F),
    secondaryColor: Color(0xFF0E6BA8),
    accentGold: Color(0xFFD4AF37),
    backgroundColor: Color(0xFFF3F6F9),
    surfaceColor: Color(0xFFE5ECF2),
    cardColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFD0DCE8),
    textColor: Color(0xFF102030),
    textMuted: Color(0xFF485E74),
    heroGradientColors: [Color(0xFF24476B), Color(0xFF162E47), Color(0xFF0D1B2A)],
    playerGradientColors: [Color(0xFF162436), Color(0xFF0F1A28), Color(0xFF080E17)],
    auraGlowColor: Color(0xFF64B5F6),
  );

  // 3. Ayodhya Ram Mandir - Surya Raghuvanshi Saffron & Solar Amber
  static const TempleTheme ayodhya = TempleTheme(
    id: 'ayodhya',
    name: 'Ayodhya Ram Mandir',
    deityName: 'Bhagwan Shri Ram',
    subtitle: 'Surya Bhagwa Saffron & Radiant Amber',
    emoji: '🏹',
    primaryColor: Color(0xFFC2410C),
    secondaryColor: Color(0xFFEA580C),
    accentGold: Color(0xFFF59E0B),
    backgroundColor: Color(0xFFFFF9F0),
    surfaceColor: Color(0xFFFEF0DB),
    cardColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFFCDCB5),
    textColor: Color(0xFF261102),
    textMuted: Color(0xFF6C4B33),
    heroGradientColors: [Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFF7C2D12)],
    playerGradientColors: [Color(0xFF381404), Color(0xFF230C02), Color(0xFF140701)],
    auraGlowColor: Color(0xFFFBBF24),
  );

  // 4. Lalitha Tripurasundari - Sri Chakra Kumkum Crimson & Lotus Pink
  static const TempleTheme srichakra = TempleTheme(
    id: 'srichakra',
    name: 'Lalitha Sri Chakra',
    deityName: 'Maha Tripurasundari',
    subtitle: 'Kumkum Crimson & Divine Lotus Silk',
    emoji: '🌺',
    primaryColor: Color(0xFF9E1030),
    secondaryColor: Color(0xFFBE185D),
    accentGold: Color(0xFFF6C90E),
    backgroundColor: Color(0xFFFFF4F6),
    surfaceColor: Color(0xFFFCE7EC),
    cardColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFF9CDD7),
    textColor: Color(0xFF26050E),
    textMuted: Color(0xFF6B3645),
    heroGradientColors: [Color(0xFFBE185D), Color(0xFF9E1030), Color(0xFF4C0519)],
    playerGradientColors: [Color(0xFF3A0614), Color(0xFF23030C), Color(0xFF120106)],
    auraGlowColor: Color(0xFFF472B6),
  );

  // 5. Vrindavan Mayura - Peacock Cyan & Pitambara Silk Gold
  static const TempleTheme vrindavan = TempleTheme(
    id: 'vrindavan',
    name: 'Vrindavan Mayura',
    deityName: 'Shri Radha Krishna',
    subtitle: 'Peacock Cyan & Pitambara Silk Gold',
    emoji: '🦚',
    primaryColor: Color(0xFF0F766E),
    secondaryColor: Color(0xFF0D9488),
    accentGold: Color(0xFFEAB308),
    backgroundColor: Color(0xFFF0FDF9),
    surfaceColor: Color(0xFFE0F7F1),
    cardColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFC4EFE3),
    textColor: Color(0xFF042F2E),
    textMuted: Color(0xFF3B6462),
    heroGradientColors: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF042F2E)],
    playerGradientColors: [Color(0xFF072421), Color(0xFF041715), Color(0xFF020E0D)],
    auraGlowColor: Color(0xFF2DD4BF),
  );

  // 6. Shiva Shakti Kailash - Deep Cosmic Amethyst & Chandra White
  static const TempleTheme kailash = TempleTheme(
    id: 'kailash',
    name: 'Kailash Cosmic',
    deityName: 'Shiva Shakti Cosmic',
    subtitle: 'Cosmic Amethyst & Chandra Silver',
    emoji: '🕉️',
    primaryColor: Color(0xFF4338CA),
    secondaryColor: Color(0xFF6366F1),
    accentGold: Color(0xFFF59E0B),
    backgroundColor: Color(0xFFF5F3FF),
    surfaceColor: Color(0xFFEDE9FE),
    cardColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFDDD6FE),
    textColor: Color(0xFF1E1B4B),
    textMuted: Color(0xFF4F46E5),
    heroGradientColors: [Color(0xFF4F46E5), Color(0xFF3730A3), Color(0xFF1E1B4B)],
    playerGradientColors: [Color(0xFF19153B), Color(0xFF0F0C24), Color(0xFF080614)],
    auraGlowColor: Color(0xFFA5B4FC),
  );

  static const List<TempleTheme> allThemes = [
    tirumala,
    kashi,
    ayodhya,
    srichakra,
    vrindavan,
    kailash,
  ];

  static TempleTheme fromId(String? id) {
    if (id == null) return tirumala;
    return allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => tirumala,
    );
  }
}
