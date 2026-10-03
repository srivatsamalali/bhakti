import 'dart:math';
import 'package:flutter/material.dart';

class AmbientDiyaParticles extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color? particleColor;
  final bool enabled;

  const AmbientDiyaParticles({
    super.key,
    required this.child,
    this.particleCount = 6,
    this.particleColor,
    this.enabled = true,
  });

  @override
  State<AmbientDiyaParticles> createState() => _AmbientDiyaParticlesState();
}

class _AmbientDiyaParticlesState extends State<AmbientDiyaParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_DiyaParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, (_) => _DiyaParticle(_random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        // 1. Underlying Main Screen Content
        widget.child,

        // 2. Subtle, Calming Ambient Warm Glow Embers (Non-intrusive)
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DiyaParticlePainter(
                      particles: _particles,
                      progress: _controller.value,
                      baseColor: widget.particleColor ?? const Color(0xFFFFB300),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiyaParticle {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;
  double waveOffset;

  _DiyaParticle(Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        radius = random.nextDouble() * 1.6 + 0.9,
        speed = random.nextDouble() * 0.06 + 0.03,
        opacity = random.nextDouble() * 0.22 + 0.10,
        waveOffset = random.nextDouble() * 2 * pi;

  void advance(double delta) {
    y -= speed * delta;
    if (y < -0.05) {
      y = 1.05;
      x = Random().nextDouble();
    }
  }
}

class _DiyaParticlePainter extends CustomPainter {
  final List<_DiyaParticle> particles;
  final double progress;
  final Color baseColor;

  _DiyaParticlePainter({
    required this.particles,
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      p.advance(0.012);

      final currentX = (p.x * size.width) + sin(progress * 2 * pi + p.waveOffset) * 8;
      final currentY = p.y * size.height;
      final center = Offset(currentX, currentY);

      // Outer Soft Warm Halo (Impeller & Metal safe)
      final outerHalo = Paint()
        ..color = baseColor.withOpacity((p.opacity * 0.18).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, p.radius * 2.5, outerHalo);

      // Inner Warm Glow
      final innerGlow = Paint()
        ..color = baseColor.withOpacity((p.opacity * 0.45).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, p.radius * 1.4, innerGlow);

      // Delicate Luminous Core
      final corePaint = Paint()
        ..color = Colors.white.withOpacity((p.opacity * 0.70).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, p.radius * 0.65, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiyaParticlePainter oldDelegate) => true;
}

