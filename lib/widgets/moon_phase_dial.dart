import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A dynamic glowing Lunar Phase Dial & Tithi visualizer
/// that illustrates the lunar paksha and illumination.
class MoonPhaseDial extends StatelessWidget {
  final String tithiName;
  final String paksha;
  final double size;

  const MoonPhaseDial({
    super.key,
    required this.tithiName,
    required this.paksha,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    final isShukla = paksha.toLowerCase().contains('shukla') ||
        paksha.toLowerCase().contains('shuklapaksha') ||
        paksha.contains('ಶುಕ್ಲ') ||
        paksha.contains('शुक्ल');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFE082).withOpacity(0.45),
            const Color(0xFFFFB74D).withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.4, 0.75, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.75,
          height: size * 0.75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF523329),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB74D).withOpacity(0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: CustomPaint(
              painter: _MoonPainter(isShukla: isShukla),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  final bool isShukla;

  _MoonPainter({required this.isShukla});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Subtle warm terracotta/amber dark Moon body
    final darkPaint = Paint()..color = const Color(0xFF5C382C);
    canvas.drawCircle(center, radius, darkPaint);

    // Glowing Illuminated Moon Crescent / Disc
    final moonGlowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFDF2), Color(0xFFFFC107)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = Path();
    if (isShukla) {
      // Right side illumination (Waxing)
      path.addArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi);
      path.arcTo(
        Rect.fromCenter(center: center, width: radius * 0.7, height: radius * 2),
        math.pi / 2,
        math.pi,
        false,
      );
    } else {
      // Left side illumination (Waning)
      path.addArc(Rect.fromCircle(center: center, radius: radius), math.pi / 2, math.pi);
      path.arcTo(
        Rect.fromCenter(center: center, width: radius * 0.7, height: radius * 2),
        -math.pi / 2,
        math.pi,
        false,
      );
    }

    canvas.drawPath(path, moonGlowPaint);

    // Golden halo outline
    final rimPaint = Paint()
      ..color = AppColors.goldLight.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 0.5, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) {
    return oldDelegate.isShukla != isShukla;
  }
}
