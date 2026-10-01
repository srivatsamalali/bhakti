import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Sanctum Architectural Theme & Environment Profile
class GarbhagruhaEnvironment {
  final String deityId;
  final String deityName;
  final String kannadaName;
  final String title;
  final String imagePath;
  final String aerialImagePath;
  final String sanctumName;
  final String locationName;
  final String stateName;
  final String moolaSanskrit;
  final String moolaKannada;
  final String moolaTamil;
  final Color primaryColor;
  final Color accentColor;
  final Color sanctumStoneColor;
  final Color ambientGlowColor;
  final List<Color> gradientColors;
  final String symbol;
  final String archwayStyle; // 'tirumala', 'vinayaka', 'mysuru', 'lakshmi'
  final List<Color> garlandColors;
  final String templeStyleDescription;
  final String aerialEntryNarrative;
  final Offset mapPosition; // Normalized 0..1 on sacred map

  const GarbhagruhaEnvironment({
    required this.deityId,
    required this.deityName,
    required this.kannadaName,
    required this.title,
    required this.imagePath,
    required this.aerialImagePath,
    required this.sanctumName,
    required this.locationName,
    required this.stateName,
    required this.moolaSanskrit,
    required this.moolaKannada,
    required this.moolaTamil,
    required this.primaryColor,
    required this.accentColor,
    required this.sanctumStoneColor,
    required this.ambientGlowColor,
    required this.gradientColors,
    required this.symbol,
    required this.archwayStyle,
    required this.garlandColors,
    required this.templeStyleDescription,
    required this.aerialEntryNarrative,
    required this.mapPosition,
  });
}

/// Floating Golden Light / Sanctum Dust Particle
class SanctumLightParticle {
  double x;
  double y;
  double speedY;
  double speedX;
  double size;
  double opacity;
  double pulseSpeed;
  double phase;

  SanctumLightParticle({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.size,
    required this.opacity,
    required this.pulseSpeed,
    required this.phase,
  });
}

/// Photorealistic Sanctum Architectural Painter
class SanctumArchitecturalPainter extends CustomPainter {
  final Color stoneColor;
  final Color ambientLight;
  final double flameIllumination;
  final String archwayStyle;

  SanctumArchitecturalPainter({
    required this.stoneColor,
    required this.ambientLight,
    required this.flameIllumination,
    required this.archwayStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark Ancient Temple Stone Base Layer
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 0.95 + (flameIllumination * 0.12),
        colors: [
          ambientLight.withOpacity(0.38 + (flameIllumination * 0.15)),
          stoneColor.withOpacity(0.7),
          const Color(0xFF090403),
          const Color(0xFF020101),
        ],
        stops: const [0.0, 0.48, 0.82, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Ornate Garbhagruha Archway (Prabhavali / Sanctum Torana)
    final goldArchPaint = Paint()
      ..color = const Color(0xFFE5A93C).withOpacity(0.25 + (flameIllumination * 0.12))
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final outerArch = Path();
    outerArch.moveTo(size.width * 0.07, size.height);
    outerArch.lineTo(size.width * 0.07, size.height * 0.30);
    outerArch.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.02,
      size.width * 0.93,
      size.height * 0.30,
    );
    outerArch.lineTo(size.width * 0.93, size.height);
    canvas.drawPath(outerArch, goldArchPaint);

    // Inner Filigree Arch
    final innerArchPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.16 + (flameIllumination * 0.08))
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final innerArch = Path();
    innerArch.moveTo(size.width * 0.14, size.height);
    innerArch.lineTo(size.width * 0.14, size.height * 0.33);
    innerArch.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.06,
      size.width * 0.86,
      size.height * 0.33,
    );
    innerArch.lineTo(size.width * 0.86, size.height);
    canvas.drawPath(innerArch, innerArchPaint);

    // 3. Side Sanctum Pillars (Stambha)
    final pillarPaint = Paint()
      ..color = const Color(0xFFC8A050).withOpacity(0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.33),
      Offset(size.width * 0.16, size.height),
      pillarPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.84, size.height * 0.33),
      Offset(size.width * 0.84, size.height),
      pillarPaint,
    );

    // 4. Sanctum Polished Black Stone Pedestal Reflection
    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          ambientLight.withOpacity(0.16 + (flameIllumination * 0.1)),
          const Color(0xFF0F0402).withOpacity(0.92),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28));

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      floorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SanctumArchitecturalPainter oldDelegate) =>
      oldDelegate.flameIllumination != flameIllumination ||
      oldDelegate.stoneColor != stoneColor ||
      oldDelegate.archwayStyle != archwayStyle;
}

/// Floating Golden Prakash Motes Painter
class SanctumLightParticlesPainter extends CustomPainter {
  final List<SanctumLightParticle> particles;

  SanctumLightParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (p.opacity * (0.6 + 0.4 * math.sin(p.phase))).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xFFFFE082).withOpacity(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SanctumLightParticlesPainter oldDelegate) => true;
}

/// Realistic Traditional Brass Pancha-Arathi / Camphor Lamp Painter
class BrassArathiLampPainter extends CustomPainter {
  final double flameFlicker;
  final Color glowColor;

  BrassArathiLampPainter({
    required this.flameFlicker,
    this.glowColor = const Color(0xFFFFB300),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer Aura Glow
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withOpacity(0.6 * (0.85 + flameFlicker * 0.25)),
          const Color(0xFFFF6D00).withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy - 8), radius: 65));
    canvas.drawCircle(Offset(cx, cy - 8), 65, auraPaint);

    // Traditional Brass Handle & Base
    final handlePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFE082),
          Color(0xFFFFA000),
          Color(0xFF8D6E63),
          Color(0xFF5D4037),
        ],
      ).createShader(Rect.fromLTWH(cx - 24, cy + 8, 48, 28));

    // Brass Aarti Plate
    final platePath = Path();
    platePath.moveTo(cx - 28, cy + 10);
    platePath.quadraticBezierTo(cx, cy + 22, cx + 28, cy + 10);
    platePath.lineTo(cx + 20, cy + 16);
    platePath.quadraticBezierTo(cx, cy + 24, cx - 20, cy + 16);
    platePath.close();
    canvas.drawPath(platePath, handlePaint);

    // 5 Traditional Aarti Flame Cups (Pancha Pradeep)
    final cupOffsets = [-20.0, -10.0, 0.0, 10.0, 20.0];
    for (int i = 0; i < cupOffsets.length; i++) {
      final dx = cupOffsets[i];
      final isCenter = i == 2;
      final cupY = cy + 4 - (isCenter ? 4 : 0);

      // Flame Height Modulation
      final flameH = (isCenter ? 24.0 : 18.0) * (0.88 + (math.sin((flameFlicker * math.pi * 2) + i) * 0.14));
      final flameW = isCenter ? 12.0 : 9.0;

      // Flame Base Glow
      final flamePaint = Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.3),
          radius: 0.8,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFFF59D),
            Color(0xFFFF9800),
            Color(0xFFFF3D00),
          ],
          stops: [0.0, 0.25, 0.65, 1.0],
        ).createShader(Rect.fromCenter(center: Offset(cx + dx, cupY - (flameH / 2)), width: flameW, height: flameH));

      final flamePath = Path();
      flamePath.moveTo(cx + dx - (flameW / 2), cupY);
      flamePath.quadraticBezierTo(
        cx + dx - (flameW * 0.6),
        cupY - (flameH * 0.5),
        cx + dx,
        cupY - flameH,
      );
      flamePath.quadraticBezierTo(
        cx + dx + (flameW * 0.6),
        cupY - (flameH * 0.5),
        cx + dx + (flameW / 2),
        cupY,
      );
      flamePath.close();

      canvas.drawPath(flamePath, flamePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BrassArathiLampPainter oldDelegate) =>
      oldDelegate.flameFlicker != flameFlicker;
}
