import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'glass_style.dart';

/// A widget that applies the exact Apple iOS 26 Liquid Glass material effect
/// with chromatic prism refraction, specular top rim highlights, and frosted depth.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final GlassStyle style;
  final Color? tint;
  final double? cornerRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? customBorder;
  final bool isStadium;
  final bool enablePrism;
  final VoidCallback? onTap;

  const LiquidGlass({
    super.key,
    required this.child,
    this.style = GlassStyle.card,
    this.tint,
    this.cornerRadius,
    this.padding,
    this.margin,
    this.customBorder,
    this.isStadium = false,
    this.enablePrism = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = isStadium ? 100.0 : (cornerRadius ?? style.defaultCornerRadius);
    final borderRadius = BorderRadius.circular(radius);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // High-vibrancy frosted glass substrate
    final baseFillColor = isDark
        ? const Color(0xFF161210).withOpacity(style.fillOpacity.clamp(0.55, 0.78))
        : Colors.white.withOpacity(style.fillOpacity.clamp(0.60, 0.75));

    Widget glassSurface = RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: style.blurSigma.clamp(8.0, 16.0),
            sigmaY: style.blurSigma.clamp(8.0, 16.0),
          ),
          child: CustomPaint(
            painter: _LiquidGlassPrismPainter(
              borderRadius: radius,
              isDark: isDark,
              tint: tint,
              enablePrism: enablePrism,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: baseFillColor,
                borderRadius: borderRadius,
                border: customBorder,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (tint ?? (isDark ? Colors.white : AppColors.goldLight))
                        .withOpacity(style.tintOpacity + 0.08),
                    (tint ?? (isDark ? Colors.white : AppColors.goldPrimary))
                        .withOpacity(style.tintOpacity * 0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    // Apply soft multi-layer diffuse glass shadow
    glassSurface = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          // Soft ambient dark drop shadow
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF5A4033))
                .withOpacity(style.shadowOpacity.clamp(0.10, 0.22)),
            blurRadius: style.shadowRadius + 6,
            offset: Offset(0, style.shadowOffsetY + 2),
            spreadRadius: -2,
          ),
          // Subtle warm/gold contact rim glow
          if (tint != null || !isDark)
            BoxShadow(
              color: (tint ?? AppColors.goldPrimary).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
        ],
      ),
      child: glassSurface,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: glassSurface,
        ),
      );
    }

    return glassSurface;
  }
}

/// Custom painter that paints the true Apple iOS Liquid Glass optical edges:
/// 1. Top specular bright light reflection (0.8 -> 0.3 white highlight)
/// 2. Chromatic prism rainbow dispersion along the bottom/corners
class _LiquidGlassPrismPainter extends CustomPainter {
  final double borderRadius;
  final bool isDark;
  final Color? tint;
  final bool enablePrism;

  _LiquidGlassPrismPainter({
    required this.borderRadius,
    required this.isDark,
    this.tint,
    required this.enablePrism,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Top Specular High-Refraction Rim Line
    final specularPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (isDark ? Colors.white.withOpacity(0.65) : Colors.white.withOpacity(0.95)),
          (isDark ? Colors.white.withOpacity(0.20) : Colors.white.withOpacity(0.40)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, specularPaint);

    // 2. Chromatic Prism Dispersion along the bottom curve (as seen in iOS 26 / WhatsApp Liquid Glass)
    if (enablePrism) {
      final prismPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = const SweepGradient(
          center: FractionalOffset(0.5, 0.9),
          colors: [
            Color(0x38FF4070), // Rosy pink
            Color(0x40FFB300), // Amber gold
            Color(0x4000E5FF), // Cyan prism
            Color(0x387C4DFF), // Purple prism
            Color(0x38FF4070), // Loop
          ],
          stops: [0.0, 0.25, 0.50, 0.75, 1.0],
        ).createShader(rect);

      canvas.drawRRect(rrect, prismPaint);
    }

    // 3. Subtle Inner Lens Gloss Gradient
    final glossPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(isDark ? 0.08 : 0.22),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.40],
      ).createShader(rect);

    canvas.drawRRect(rrect, glossPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPrismPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.isDark != isDark ||
        oldDelegate.tint != tint;
  }
}
