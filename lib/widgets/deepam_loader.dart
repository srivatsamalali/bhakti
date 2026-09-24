import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';

/// A spiritually inspired loader widget featuring a glowing sacred Deepam (Diya)
/// in the center surrounded by a smooth celestial golden orbital ring and pulsating aura.
class DeepamLoader extends StatefulWidget {
  final double size;
  final String? message;
  final String? subtitle;
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool showAura;
  final bool showRays;
  final TextStyle? messageStyle;

  const DeepamLoader({
    super.key,
    this.size = 80.0,
    this.message,
    this.subtitle,
    this.primaryColor,
    this.secondaryColor,
    this.showAura = true,
    this.showRays = true,
    this.messageStyle,
  });

  /// Compact preset for buttons, mini player bars, and inline chips
  const DeepamLoader.compact({
    super.key,
    this.size = 28.0,
    this.message,
    this.subtitle,
    this.primaryColor,
    this.secondaryColor,
    this.showAura = false,
    this.showRays = false,
    this.messageStyle,
  });

  /// Large preset for full screen loading and splash views
  const DeepamLoader.large({
    super.key,
    this.size = 140.0,
    this.message = 'Loading Divine Melodies...',
    this.subtitle = 'ॐ ಶಾಂತಿಃ ಶಾಂತಿಃ ಶಾಂತಿಃ',
    this.primaryColor,
    this.secondaryColor,
    this.showAura = true,
    this.showRays = true,
    this.messageStyle,
  });

  @override
  State<DeepamLoader> createState() => _DeepamLoaderState();
}

class _DeepamLoaderState extends State<DeepamLoader> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _flameController;
  late AnimationController _pulseController;

  late Animation<double> _flameFlicker;
  late Animation<double> _pulseScale;
  late Animation<double> _auraOpacity;

  @override
  void initState() {
    super.initState();

    // 1. Orbital Ring Rotation (Smooth 2.4s continuous loop)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 2. Organic Flame Flicker & Sway (850ms cycle)
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _flameFlicker = Tween<double>(begin: 0.92, end: 1.12).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOutSine),
    );

    // 3. Divine Aura Pulse (1800ms heartbeat)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _auraOpacity = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _flameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold1 = widget.primaryColor ?? AppColors.goldLight;
    final gold2 = widget.secondaryColor ?? AppColors.goldPrimary;
    final saffron = AppColors.saffronPrimary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The Glowing Deepam + Orbital Loader Ring
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Pulsing Golden Background Aura
                if (widget.showAura)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: _pulseScale.value,
                        child: Container(
                          width: widget.size * 0.92,
                          height: widget.size * 0.92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: gold1.withOpacity(0.28 * _auraOpacity.value),
                                blurRadius: widget.size * 0.45,
                                spreadRadius: widget.size * 0.12,
                              ),
                              BoxShadow(
                                color: saffron.withOpacity(0.18 * _auraOpacity.value),
                                blurRadius: widget.size * 0.25,
                                spreadRadius: widget.size * 0.05,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // 2. Surrounding Orbital Rotating Divine Loader Ring
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, _) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _OrbitalRingPainter(
                          primaryColor: gold1,
                          secondaryColor: gold2,
                          accentColor: saffron,
                          showRays: widget.showRays,
                        ),
                      ),
                    );
                  },
                ),

                // 3. Central Sacred Deepam (Diya) with Living Flame
                AnimatedBuilder(
                  animation: _flameController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(widget.size * 0.58, widget.size * 0.58),
                      painter: _SacredDeepamPainter(
                        flickerScale: _flameFlicker.value,
                        flameSway: math.sin(_flameController.value * math.pi * 2) * 0.08,
                        goldColor: gold1,
                        deepGold: gold2,
                        saffronColor: saffron,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Optional Sacred Message
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            SizedBox(height: widget.size > 50 ? 16 : 6),
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: widget.messageStyle ??
                  AppTypography.titleMedium.copyWith(
                    fontSize: 15,
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    shadows: [
                      Shadow(
                        color: AppColors.maroonDark.withOpacity(0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
            ),
          ],

          // Optional Subtitle / Mantra
          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.goldPrimary.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                fontSize: 12,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for the rotating celestial orbital ring and radiant pearls
class _OrbitalRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final bool showRays;

  _OrbitalRingPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.showRays,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;
    final strokeW = math.max(2.0, size.width * 0.045);

    // Sweeping gradient arc
    final sweepGradient = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: [
        primaryColor.withOpacity(0.0),
        secondaryColor.withOpacity(0.3),
        accentColor.withOpacity(0.8),
        primaryColor,
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    );

    final arcPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    // Draw main leading arc (300 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.65,
      false,
      arcPaint,
    );

    // Orbiting luminous golden pearl at the leading tip
    final headAngle = math.pi * 1.65;
    final headPoint = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );

    final pearlGlowPaint = Paint()
      ..color = primaryColor.withOpacity(0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeW * 2);
    canvas.drawCircle(headPoint, strokeW * 1.6, pearlGlowPaint);

    final pearlPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headPoint, strokeW * 0.9, pearlPaint);

    // Decorative orbiting pearls
    final minorPoint1 = Offset(
      center.dx + radius * math.cos(headAngle - 0.7),
      center.dy + radius * math.sin(headAngle - 0.7),
    );
    canvas.drawCircle(minorPoint1, strokeW * 0.6, Paint()..color = primaryColor);

    final minorPoint2 = Offset(
      center.dx + radius * math.cos(headAngle - 1.4),
      center.dy + radius * math.sin(headAngle - 1.4),
    );
    canvas.drawCircle(minorPoint2, strokeW * 0.45, Paint()..color = secondaryColor);

    // Optional sacred rays
    if (showRays && size.width >= 60) {
      final rayPaint = Paint()
        ..color = primaryColor.withOpacity(0.25)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4);
        final r1 = radius + 2;
        final r2 = radius + strokeW * 1.5;
        canvas.drawLine(
          Offset(center.dx + r1 * math.cos(angle), center.dy + r1 * math.sin(angle)),
          Offset(center.dx + r2 * math.cos(angle), center.dy + r2 * math.sin(angle)),
          rayPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalRingPainter oldDelegate) => true;
}

/// Custom painter for the sacred Diya (lamp body, wick, and living flame)
class _SacredDeepamPainter extends CustomPainter {
  final double flickerScale;
  final double flameSway;
  final Color goldColor;
  final Color deepGold;
  final Color saffronColor;

  _SacredDeepamPainter({
    required this.flickerScale,
    required this.flameSway,
    required this.goldColor,
    required this.deepGold,
    required this.saffronColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ==========================================
    // 1. DIYA BASE & BOWL (Brass Lamp)
    // ==========================================
    final bowlTopY = h * 0.58;
    final bowlBottomY = h * 0.88;
    final standBottomY = h * 0.98;

    // Diya Stand (Base foot)
    final standPath = Path()
      ..moveTo(cx - w * 0.22, standBottomY)
      ..quadraticBezierTo(cx, standBottomY - h * 0.04, cx + w * 0.22, standBottomY)
      ..lineTo(cx + w * 0.14, bowlBottomY)
      ..lineTo(cx - w * 0.14, bowlBottomY)
      ..close();

    final standPaint = Paint()
      ..shader = LinearGradient(
        colors: [deepGold, goldColor, AppColors.saffronLight, deepGold],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, bowlBottomY, w, h * 0.2));
    canvas.drawPath(standPath, standPaint);

    // Diya Main Curving Bowl (Clay / Brass Diya)
    final bowlPath = Path()
      ..moveTo(cx - w * 0.44, bowlTopY)
      ..cubicTo(
        cx - w * 0.42, bowlBottomY,
        cx + w * 0.42, bowlBottomY,
        cx + w * 0.44, bowlTopY,
      )
      ..quadraticBezierTo(cx, bowlTopY + h * 0.06, cx - w * 0.44, bowlTopY)
      ..close();

    final bowlGradient = LinearGradient(
      colors: [
        AppColors.saffronLight,
        goldColor,
        Colors.white.withOpacity(0.8),
        goldColor,
        deepGold,
      ],
      stops: const [0.0, 0.35, 0.5, 0.75, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    canvas.drawPath(
      bowlPath,
      Paint()..shader = bowlGradient.createShader(Rect.fromLTWH(0, bowlTopY, w, bowlBottomY - bowlTopY)),
    );

    // Decorative Diya Lip Rim (Shimmer highlight)
    final rimPath = Path()
      ..moveTo(cx - w * 0.44, bowlTopY)
      ..quadraticBezierTo(cx, bowlTopY + h * 0.05, cx + w * 0.44, bowlTopY)
      ..quadraticBezierTo(cx, bowlTopY - h * 0.03, cx - w * 0.44, bowlTopY);

    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.035);
    canvas.drawPath(rimPath, rimPaint);

    // ==========================================
    // 2. SACRED LIVING FLAME (Jyoti)
    // ==========================================
    final flameBaseX = cx + (flameSway * w * 0.4);
    final flameBaseY = bowlTopY + h * 0.02;
    final flameHeight = (h * 0.54) * flickerScale;
    final flameTopY = flameBaseY - flameHeight;
    final flameWidth = (w * 0.34) * (2.0 - flickerScale);

    // A. Outer Radiant Fire Glow
    final glowPaint = Paint()
      ..color = saffronColor.withOpacity(0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.18);
    canvas.drawCircle(Offset(flameBaseX, flameBaseY - flameHeight * 0.45), flameWidth * 1.2, glowPaint);

    // B. Outer Saffron Flame Petal
    final outerFlamePath = Path()
      ..moveTo(flameBaseX, flameBaseY)
      ..cubicTo(
        flameBaseX - flameWidth * 1.2, flameBaseY - flameHeight * 0.35,
        flameBaseX - flameWidth * 0.6, flameBaseY - flameHeight * 0.75,
        flameBaseX, flameTopY,
      )
      ..cubicTo(
        flameBaseX + flameWidth * 0.6, flameBaseY - flameHeight * 0.75,
        flameBaseX + flameWidth * 1.2, flameBaseY - flameHeight * 0.35,
        flameBaseX, flameBaseY,
      )
      ..close();

    final outerFlameGradient = LinearGradient(
      colors: [
        AppColors.maroonPrimary,
        saffronColor,
        goldColor,
      ],
      stops: const [0.0, 0.4, 1.0],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );

    canvas.drawPath(
      outerFlamePath,
      Paint()..shader = outerFlameGradient.createShader(Rect.fromLTWH(0, flameTopY, w, flameHeight)),
    );

    // C. Inner Core Golden Flame
    final innerWidth = flameWidth * 0.58;
    final innerHeight = flameHeight * 0.72;
    final innerTopY = flameBaseY - innerHeight;

    final innerFlamePath = Path()
      ..moveTo(flameBaseX, flameBaseY)
      ..cubicTo(
        flameBaseX - innerWidth, flameBaseY - innerHeight * 0.4,
        flameBaseX - innerWidth * 0.5, flameBaseY - innerHeight * 0.8,
        flameBaseX, innerTopY,
      )
      ..cubicTo(
        flameBaseX + innerWidth * 0.5, flameBaseY - innerHeight * 0.8,
        flameBaseX + innerWidth, flameBaseY - innerHeight * 0.4,
        flameBaseX, flameBaseY,
      )
      ..close();

    final innerFlameGradient = LinearGradient(
      colors: [
        saffronColor,
        goldColor,
        Colors.white,
      ],
      stops: const [0.0, 0.6, 1.0],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );

    canvas.drawPath(
      innerFlamePath,
      Paint()..shader = innerFlameGradient.createShader(Rect.fromLTWH(0, innerTopY, w, innerHeight)),
    );

    // D. White-hot Diya Core Spark
    canvas.drawCircle(
      Offset(flameBaseX, flameBaseY - innerHeight * 0.35),
      innerWidth * 0.35,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _SacredDeepamPainter oldDelegate) => true;
}

/// Glassmorphic full-screen or container loading overlay with DeepamLoader
class DeepamLoadingOverlay extends StatelessWidget {
  final String? message;
  final String? subtitle;

  const DeepamLoadingOverlay({
    super.key,
    this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.maroonDark.withOpacity(0.72),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.maroonPrimary.withOpacity(0.92),
                AppColors.maroonDark.withOpacity(0.96),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.goldLight.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.goldPrimary.withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: DeepamLoader(
            size: 100,
            message: message ?? 'Loading Divine Content...',
            subtitle: subtitle ?? 'ॐ ಶಾಂತಿಃ',
          ),
        ),
      ),
    );
  }
}
