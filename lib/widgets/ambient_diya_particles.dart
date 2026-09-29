import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AmbientDiyaParticles extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color? particleColor;
  final bool enabled;

  const AmbientDiyaParticles({
    super.key,
    required this.child,
    this.particleCount = 18,
    this.particleColor,
    this.enabled = true,
  });

  @override
  State<AmbientDiyaParticles> createState() => _AmbientDiyaParticlesState();
}

class _AmbientDiyaParticlesState extends State<AmbientDiyaParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, (_) => _Particle(_random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _controller.value,
                      baseColor: widget.particleColor ?? AppColors.goldLight,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;
  double waveOffset;

  _Particle(Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        radius = random.nextDouble() * 2.2 + 1.0,
        speed = random.nextDouble() * 0.15 + 0.08,
        opacity = random.nextDouble() * 0.45 + 0.15,
        waveOffset = random.nextDouble() * 2 * pi;

  void advance(double delta) {
    y -= speed * delta;
    if (y < -0.05) {
      y = 1.05;
      x = Random().nextDouble();
    }
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color baseColor;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.advance(0.016);
      final currentX = (p.x * size.width) + sin(progress * 2 * pi + p.waveOffset) * 8;
      final currentY = p.y * size.height;

      final paint = Paint()
        ..color = baseColor.withOpacity(p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(Offset(currentX, currentY), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
