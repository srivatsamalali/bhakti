import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A high-performance, GPU-rendered Sacred Mandala / Chakra Aura
/// that displays rotating sacred geometry and breathing golden halos
/// behind the deity artwork.
class SacredMandalaAura extends StatelessWidget {
  final bool isPlaying;
  final Animation<double> rotationAnimation;
  final Animation<double> glowAnimation;
  final Color auraColor;
  final double? size;

  const SacredMandalaAura({
    super.key,
    required this.isPlaying,
    required this.rotationAnimation,
    required this.glowAnimation,
    this.auraColor = AppColors.goldPrimary,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final renderSize = size ?? math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: renderSize,
          height: renderSize,
          child: AnimatedBuilder(
            animation: Listenable.merge([rotationAnimation, glowAnimation]),
            builder: (context, child) {
              final glowFactor = isPlaying ? (0.6 + 0.4 * glowAnimation.value) : 0.4;
              final rotationAngle = rotationAnimation.value * 2 * math.pi;

              return CustomPaint(
                painter: _MandalaPainter(
                  color: auraColor,
                  rotation: rotationAngle,
                  glowFactor: glowFactor,
                  isPlaying: isPlaying,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MandalaPainter extends CustomPainter {
  final Color color;
  final double rotation;
  final double glowFactor;
  final bool isPlaying;

  _MandalaPainter({
    required this.color,
    required this.rotation,
    required this.glowFactor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 1. Ambient radial breathing background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.35 * glowFactor),
          color.withOpacity(0.12 * glowFactor),
          Colors.transparent,
        ],
        stops: const [0.2, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, glowPaint);

    // 2. Rotating Sacred Geometric Petals & Rays
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final linePaint = Paint()
      ..color = color.withOpacity((isPlaying ? 0.28 : 0.12) * glowFactor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final dotPaint = Paint()
      ..color = AppColors.goldLight.withOpacity((isPlaying ? 0.6 : 0.25) * glowFactor)
      ..style = PaintingStyle.fill;

    const int petalCount = 12;
    final petalRadius = maxRadius * 0.92;
    final innerRadius = maxRadius * 0.65;

    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi) / petalCount;
      final x1 = innerRadius * math.cos(angle);
      final y1 = innerRadius * math.sin(angle);
      final x2 = petalRadius * math.cos(angle);
      final y2 = petalRadius * math.sin(angle);

      // Sacred ray
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);

      // Outer golden dot
      canvas.drawCircle(Offset(x2, y2), isPlaying ? 2.5 : 1.5, dotPaint);

      // Curved lotus petal arcs
      final nextAngle = ((i + 1) * 2 * math.pi) / petalCount;
      final midAngle = angle + (math.pi / petalCount);
      final midR = petalRadius * 0.96;
      final mx = midR * math.cos(midAngle);
      final my = midR * math.sin(midAngle);

      final path = Path()
        ..moveTo(x1, y1)
        ..quadraticBezierTo(mx, my, innerRadius * math.cos(nextAngle), innerRadius * math.sin(nextAngle));

      canvas.drawPath(path, linePaint);
    }

    // Outer sacred concentric rings
    canvas.drawCircle(Offset.zero, petalRadius, linePaint);
    canvas.drawCircle(Offset.zero, innerRadius, linePaint..strokeWidth = 0.8);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MandalaPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.glowFactor != glowFactor ||
        oldDelegate.color != color ||
        oldDelegate.isPlaying != isPlaying;
  }
}
