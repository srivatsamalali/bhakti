import 'package:flutter/material.dart';
export 'favorite_sparkle_burst.dart';

/// Delicate Sacred Temple Corner Filigree / Kolam Motifs
class SacredCornerFiligreePainter extends CustomPainter {
  final Color filigreeColor;
  final double cornerSize;
  final double strokeWidth;

  SacredCornerFiligreePainter({
    this.filigreeColor = const Color(0xFFD4AF37),
    this.cornerSize = 22.0,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = filigreeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = filigreeColor
      ..style = PaintingStyle.fill;

    // Top-Left Corner
    _drawCornerMotif(canvas, 0, 0, 1, 1, paint, dotPaint);
    // Top-Right Corner
    _drawCornerMotif(canvas, size.width, 0, -1, 1, paint, dotPaint);
    // Bottom-Left Corner
    _drawCornerMotif(canvas, 0, size.height, 1, -1, paint, dotPaint);
    // Bottom-Right Corner
    _drawCornerMotif(canvas, size.width, size.height, -1, -1, paint, dotPaint);
  }

  void _drawCornerMotif(
    Canvas canvas,
    double ox,
    double oy,
    double dx,
    double dy,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    final path = Path();

    // 1. Geometric Corner L-bracket
    path.moveTo(ox + dx * 6, oy + dy * (cornerSize + 6));
    path.lineTo(ox + dx * 6, oy + dy * 6);
    path.lineTo(ox + dx * (cornerSize + 6), oy + dy * 6);

    // 2. Sacred Temple Lotus Arch
    path.moveTo(ox + dx * 3, oy + dy * (cornerSize - 2));
    path.cubicTo(
      ox + dx * (cornerSize - 2),
      oy + dy * (cornerSize - 2),
      ox + dx * (cornerSize - 2),
      oy + dy * 3,
      ox + dx * (cornerSize - 2),
      oy + dy * 3,
    );

    // 3. Inner Decorative S-Curve flourish
    path.moveTo(ox + dx * 10, oy + dy * 10);
    path.quadraticBezierTo(
      ox + dx * (cornerSize * 0.7),
      oy + dy * (cornerSize * 0.7),
      ox + dx * (cornerSize * 0.9),
      oy + dy * 10,
    );

    canvas.drawPath(path, strokePaint);

    // 4. Sacred Bindu (Golden Center Dot)
    canvas.drawCircle(
      Offset(ox + dx * 10, oy + dy * 10),
      1.8,
      fillPaint,
    );

    // 5. Outer Corner Star Dot
    canvas.drawCircle(
      Offset(ox + dx * 4, oy + dy * 4),
      1.2,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SacredCornerFiligreePainter oldDelegate) =>
      oldDelegate.filigreeColor != filigreeColor ||
      oldDelegate.cornerSize != cornerSize ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Helper wrapper that places the Sacred Filigree on top of the card
class SacredCornerFiligree extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double cornerSize;
  final double strokeWidth;
  final BorderRadius? borderRadius;

  const SacredCornerFiligree({
    super.key,
    required this.child,
    this.color,
    this.cornerSize = 20.0,
    this.strokeWidth = 1.4,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: radius,
              child: CustomPaint(
                foregroundPainter: SacredCornerFiligreePainter(
                  filigreeColor: color ?? const Color(0xFFD4AF37).withOpacity(0.75),
                  cornerSize: cornerSize,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
