import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InteractiveFlowerOffering extends StatefulWidget {
  final Widget child;
  final VoidCallback? onOffered;

  const InteractiveFlowerOffering({
    super.key,
    required this.child,
    this.onOffered,
  });

  @override
  State<InteractiveFlowerOffering> createState() => _InteractiveFlowerOfferingState();
}

class _InteractiveFlowerOfferingState extends State<InteractiveFlowerOffering>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_FlowerPetal> _petals = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void triggerOffering() {
    HapticFeedback.mediumImpact();
    _petals.clear();
    for (int i = 0; i < 38; i++) {
      _petals.add(_FlowerPetal(_random));
    }
    _animController.forward(from: 0.0);
    widget.onOffered?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_animController.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PetalPainter(
                  petals: _petals,
                  progress: _animController.value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FlowerPetal {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double scale;
  final Color color;
  final double initialRotation;
  final double spinSpeed;
  final double swaySpeed;
  final double swayAmount;
  final double delay;
  final int petalType;

  _FlowerPetal(Random random)
      : startX = 0.5 + (random.nextDouble() - 0.5) * 0.4,
        startY = 0.2 + (random.nextDouble() - 0.5) * 0.2,
        endX = 0.5 + (random.nextDouble() - 0.5) * 1.1,
        endY = 1.05 + random.nextDouble() * 0.25,
        scale = random.nextDouble() * 0.5 + 0.75,
        initialRotation = random.nextDouble() * 2 * pi,
        spinSpeed = (random.nextDouble() - 0.5) * 5.0,
        swaySpeed = 1.5 + random.nextDouble() * 2.0,
        swayAmount = 18.0 + random.nextDouble() * 24.0,
        delay = random.nextDouble() * 0.25,
        petalType = random.nextInt(3),
        color = _getRandomColor(random);

  static Color _getRandomColor(Random r) {
    final colors = [
      const Color(0xFFFF4081), // Sacred Rose Pink
      const Color(0xFFFF80AB), // Soft Lotus Pink
      const Color(0xFFFFB300), // Marigold Golden Yellow
      const Color(0xFFFF6F00), // Deep Saffron Orange
      const Color(0xFFFFF59D), // Champaka Yellow
      const Color(0xFFFFFFFF), // Pure Jasmine White
      const Color(0xFFFF1744), // Hibiscus Red
    ];
    return colors[r.nextInt(colors.length)];
  }
}

class _PetalPainter extends CustomPainter {
  final List<_FlowerPetal> petals;
  final double progress;

  _PetalPainter({required this.petals, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      // Handle staggered petal release delay
      if (progress < p.delay) continue;
      final localProgress = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);

      // Smooth fall curve with gentle gravity
      final curved = Curves.easeInQuad.transform(localProgress);
      final currentBaseX = (p.startX + (p.endX - p.startX) * localProgress) * size.width;
      final currentBaseY = (p.startY + (p.endY - p.startY) * curved) * size.height;

      // Natural gentle breeze horizontal sway
      final swayOffset = sin(localProgress * p.swaySpeed * 2 * pi) * p.swayAmount;
      final currentX = currentBaseX + swayOffset;
      final currentY = currentBaseY;

      // Opacity: stay fully visible for 70% of duration, then softly fade out
      final opacity = localProgress < 0.7
          ? (localProgress / 0.15).clamp(0.0, 1.0)
          : (1.0 - (localProgress - 0.7) / 0.3).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity * 0.92)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.initialRotation + (localProgress * p.spinSpeed * pi));
      canvas.scale(p.scale);

      // Draw graceful petal geometry
      final path = Path();
      if (p.petalType == 0) {
        // Classic Lotus Petal (pointed top, rounded belly)
        path.moveTo(0, -9);
        path.quadraticBezierTo(7, -3, 0, 10);
        path.quadraticBezierTo(-7, -3, 0, -9);
      } else if (p.petalType == 1) {
        // Marigold / Rose Petal (flared heart shape)
        path.moveTo(0, -7);
        path.cubicTo(6, -10, 8, 2, 0, 9);
        path.cubicTo(-8, 2, -6, -10, 0, -7);
      } else {
        // Jasmine Petal (slender drop shape)
        path.moveTo(0, -10);
        path.quadraticBezierTo(4, 0, 0, 8);
        path.quadraticBezierTo(-4, 0, 0, -10);
      }

      // Soft shadow for depth
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(opacity * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) => true;
}
