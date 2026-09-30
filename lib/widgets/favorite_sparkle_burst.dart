import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

/// Celebratory Golden & Crimson Heart Sparkle Burst Button
class FavoriteSparkleBurst extends StatefulWidget {
  final bool isFavorited;
  final VoidCallback onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Widget? child;

  const FavoriteSparkleBurst({
    super.key,
    required this.isFavorited,
    required this.onTap,
    this.size = 22.0,
    this.activeColor,
    this.inactiveColor,
    this.child,
  });

  @override
  State<FavoriteSparkleBurst> createState() => _FavoriteSparkleBurstState();
}

class _FavoriteSparkleBurstState extends State<FavoriteSparkleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late bool _isFav;
  final Random _random = Random();
  late List<_BurstSpark> _sparks;

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorited;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.70), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.70, end: 1.30), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.30, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _generateSparks();
  }

  void _generateSparks() {
    final colors = [
      const Color(0xFFFF3366), // Ruby Rose
      const Color(0xFFFFD700), // Pure Gold
      const Color(0xFFFF9933), // Sacred Saffron
      const Color(0xFFFF5252), // Divine Coral
      const Color(0xFFFFE082), // Soft Gold
      const Color(0xFFE91E63), // Sacred Pink
    ];

    _sparks = List.generate(12, (i) {
      final angle = (i * (2 * pi / 12)) + (_random.nextDouble() * 0.2 - 0.1);
      final dist = _random.nextDouble() * 5 + 13.0; // Stay strictly within 40x40 bounds
      final size = _random.nextDouble() * 1.5 + 1.8;
      return _BurstSpark(
        offset: Offset(cos(angle) * dist, sin(angle) * dist),
        size: size,
        color: colors[i % colors.length],
        isStar: i % 2 == 0,
      );
    });
  }

  @override
  void didUpdateWidget(covariant FavoriteSparkleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorited != widget.isFavorited) {
      final wasFav = _isFav;
      _isFav = widget.isFavorited;
      if (!wasFav && _isFav && !_controller.isAnimating) {
        _generateSparks();
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    final newFav = !_isFav;
    setState(() {
      _isFav = newFav;
    });

    if (_isFav) {
      _generateSparks();
      _controller.forward(from: 0.0);
    } else {
      _controller.forward(from: 0.35);
    }

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeColor ?? AppColors.error;
    final inactive = widget.inactiveColor ?? const Color(0xFF8D7B70);

    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: _handleTap,
        radius: 22,
        splashColor: active.withOpacity(0.15),
        highlightShape: BoxShape.circle,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Particle Burst Canvas
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (!_controller.isAnimating || !_isFav) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    width: 40,
                    height: 40,
                    child: CustomPaint(
                      painter: _SparkleBurstPainter(
                        sparks: _sparks,
                        progress: _controller.value,
                      ),
                    ),
                  );
                },
              ),

              // 2. Animated Heart Icon
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, _) {
                  final scale = _controller.isAnimating ? _scaleAnimation.value : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: widget.child ??
                        Icon(
                          _isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color: _isFav ? active : inactive,
                          size: widget.size,
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BurstSpark {
  final Offset offset;
  final double size;
  final Color color;
  final bool isStar;

  _BurstSpark({
    required this.offset,
    required this.size,
    required this.color,
    required this.isStar,
  });
}

class _SparkleBurstPainter extends CustomPainter {
  final List<_BurstSpark> sparks;
  final double progress;

  _SparkleBurstPainter({
    required this.sparks,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // 1. Expanding Golden/Crimson Shockwave Ring
    if (progress < 0.65) {
      final ringP = progress / 0.65;
      final ringPaint = Paint()
        ..color = const Color(0xFFFF3366).withOpacity((1.0 - ringP) * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.0 * (1.0 - ringP)).clamp(0.5, 2.0);
      canvas.drawCircle(center, 6 + ringP * 12, ringPaint);
    }

    // 2. Flying Radiant Sparks
    for (final spark in sparks) {
      final easeProgress = Curves.easeOutCubic.transform(progress);
      final currentPos = center + (spark.offset * easeProgress);
      final currentSize = (spark.size * (1.0 - progress * 0.65)).clamp(0.5, 3.5);

      final paint = Paint()
        ..color = spark.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      if (spark.isStar) {
        // Draw 4-point Diamond Star
        final starPath = Path();
        starPath.moveTo(currentPos.dx, currentPos.dy - currentSize * 1.3);
        starPath.lineTo(currentPos.dx + currentSize * 0.65, currentPos.dy);
        starPath.lineTo(currentPos.dx, currentPos.dy + currentSize * 1.3);
        starPath.lineTo(currentPos.dx - currentSize * 0.65, currentPos.dy);
        starPath.close();
        canvas.drawPath(starPath, paint);
      } else {
        canvas.drawCircle(currentPos, currentSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleBurstPainter oldDelegate) => true;
}
