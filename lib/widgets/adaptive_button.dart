import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

enum AdaptiveButtonVariant {
  primary,
  secondary,
  glass,
  tinted,
  outline,
}

/// Dynamic Optical Prism Painter for Apple Liquid Glass Controls
class _AppleLiquidGlassPainter extends CustomPainter {
  final double radius;
  final bool isDark;
  final bool isPressed;
  final Color? tint;
  final bool isPrimary;

  _AppleLiquidGlassPainter({
    required this.radius,
    required this.isDark,
    required this.isPressed,
    this.tint,
    this.isPrimary = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 1. Top Specular High-Refraction Rim Highlight
    final topSpecularAlpha = isPressed ? 0.98 : (isDark ? 0.75 : 0.90);
    final specularPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(topSpecularAlpha),
          Colors.white.withOpacity(isDark ? 0.25 : 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, specularPaint);

    // 2. Chromatic Prism Edge along bottom & side curves
    final prismPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = const SweepGradient(
        center: FractionalOffset(0.5, 0.95),
        colors: [
          Color(0x35FF4081), // Prismatic rose
          Color(0x40FFD700), // Prismatic gold
          Color(0x4000E5FF), // Prismatic cyan
          Color(0x357C4DFF), // Prismatic violet
          Color(0x35FF4081),
        ],
        stops: [0.0, 0.25, 0.50, 0.75, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, prismPaint);

    // 3. Top-Half Gloss Sheen / Lens Refraction
    final glossPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(isPressed ? 0.30 : (isDark ? 0.12 : 0.25)),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.48],
      ).createShader(rect);

    canvas.drawRRect(rrect, glossPaint);
  }

  @override
  bool shouldRepaint(covariant _AppleLiquidGlassPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isPressed != isPressed ||
        oldDelegate.tint != tint ||
        oldDelegate.isPrimary != isPrimary;
  }
}

/// Liquid Glass Container implementing Apple's official Liquid Glass specifications
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? glassColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxShape shape;
  final List<BoxShadow>? shadows;
  final bool isStadium;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.blur = 22.0,
    this.opacity = 0.70,
    this.glassColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.shadows,
    this.isStadium = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = shape == BoxShape.circle
        ? BorderRadius.circular(999)
        : (isStadium ? BorderRadius.circular(100) : (borderRadius ?? BorderRadius.circular(20)));
    final numRadius = shape == BoxShape.circle ? 999.0 : (isStadium ? 100.0 : 20.0);

    final defaultShadows = [
      BoxShadow(
        color: (isDark ? Colors.black : const Color(0xFF4A382E)).withOpacity(0.12),
        blurRadius: 16,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: (glassColor ?? AppColors.goldPrimary).withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 1),
      ),
    ];

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? effectiveRadius : null,
        boxShadow: shadows ?? defaultShadows,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            painter: _AppleLiquidGlassPainter(
              radius: numRadius,
              isDark: isDark,
              isPressed: false,
              tint: glassColor,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                shape: shape,
                borderRadius: shape == BoxShape.rectangle ? effectiveRadius : null,
                color: (glassColor ?? (isDark ? const Color(0xFF1E1614) : Colors.white))
                    .withOpacity(opacity),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Platform-Adaptive Button
/// - On iOS/macOS: Authentic Apple Liquid Glass with optical blur, specular highlights, spring physics, and haptics.
/// - On Android: Google Material 3 Elevated/Tonal controls.
class AdaptiveButton extends StatefulWidget {
  final Widget? icon;
  final Widget label;
  final VoidCallback? onPressed;
  final AdaptiveButtonVariant variant;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final bool fullWidth;
  final bool isStadium;

  const AdaptiveButton({
    super.key,
    this.icon,
    required this.label,
    required this.onPressed,
    this.variant = AdaptiveButtonVariant.primary,
    this.color,
    this.textColor,
    this.width,
    this.height = 46,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    this.borderRadius,
    this.isLoading = false,
    this.fullWidth = false,
    this.isStadium = true,
  });

  factory AdaptiveButton.icon({
    Key? key,
    required Widget icon,
    required Widget label,
    required VoidCallback? onPressed,
    AdaptiveButtonVariant variant = AdaptiveButtonVariant.primary,
    Color? color,
    Color? textColor,
    double? width,
    double height = 46,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    BorderRadius? borderRadius,
    bool isLoading = false,
    bool fullWidth = false,
    bool isStadium = true,
  }) {
    return AdaptiveButton(
      key: key,
      icon: icon,
      label: label,
      onPressed: onPressed,
      variant: variant,
      color: color,
      textColor: textColor,
      width: width,
      height: height,
      padding: padding,
      borderRadius: borderRadius,
      isLoading: isLoading,
      fullWidth: fullWidth,
      isStadium: isStadium,
    );
  }

  @override
  State<AdaptiveButton> createState() => _AdaptiveButtonState();
}

class _AdaptiveButtonState extends State<AdaptiveButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.935).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool _isApple(BuildContext context) {
    if (kIsWeb) return false;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    if (_isApple(context)) {
      return _buildAppleLiquidGlassButton(context);
    } else {
      return _buildMaterial3Button(context);
    }
  }

  // ================= APPLE LIQUID GLASS BUTTON =================
  Widget _buildAppleLiquidGlassButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPrimary = widget.variant == AdaptiveButtonVariant.primary;
    final isTinted = widget.variant == AdaptiveButtonVariant.tinted;
    final isOutline = widget.variant == AdaptiveButtonVariant.outline;

    final baseColor = widget.color ?? theme.primaryColor;
    final effectiveRadius = widget.isStadium
        ? BorderRadius.circular(100)
        : (widget.borderRadius ?? BorderRadius.circular(16));
    final numRadius = widget.isStadium ? 100.0 : (widget.borderRadius?.topLeft.x ?? 16.0);

    Color glassFill;
    Color fontColor;

    if (isPrimary) {
      glassFill = baseColor.withOpacity(0.88);
      fontColor = widget.textColor ?? Colors.white;
    } else if (isTinted) {
      glassFill = baseColor.withOpacity(isDark ? 0.25 : 0.15);
      fontColor = widget.textColor ?? baseColor;
    } else if (isOutline) {
      glassFill = (isDark ? Colors.black : Colors.white).withOpacity(0.20);
      fontColor = widget.textColor ?? baseColor;
    } else {
      // Secondary / Clear Liquid Glass
      glassFill = (isDark ? const Color(0xFF2C221F) : Colors.white).withOpacity(isDark ? 0.70 : 0.80);
      fontColor = widget.textColor ?? baseColor;
    }

    Widget content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fontColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          IconTheme(
            data: IconThemeData(color: fontColor, size: 18),
            child: widget.icon!,
          ),
          const SizedBox(width: 6),
        ],
        DefaultTextStyle(
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: fontColor,
            letterSpacing: -0.2,
          ),
          child: widget.label,
        ),
      ],
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: GestureDetector(
          onTapDown: widget.onPressed == null
              ? null
              : (_) {
                  setState(() => _isPressed = true);
                  _animController.forward();
                  HapticFeedback.lightImpact();
                },
          onTapUp: widget.onPressed == null
              ? null
              : (_) {
                  setState(() => _isPressed = false);
                  _animController.reverse();
                },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _animController.reverse();
          },
          onTap: widget.onPressed,
          child: Container(
            width: widget.fullWidth ? double.infinity : widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: effectiveRadius,
              boxShadow: [
                BoxShadow(
                  color: isPrimary
                      ? baseColor.withOpacity(_isPressed ? 0.20 : 0.32)
                      : (isDark ? Colors.black : const Color(0xFF4A382E))
                          .withOpacity(_isPressed ? 0.05 : 0.12),
                  blurRadius: _isPressed ? 6 : 14,
                  offset: Offset(0, _isPressed ? 2 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: effectiveRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: CustomPaint(
                  painter: _AppleLiquidGlassPainter(
                    radius: numRadius,
                    isDark: isDark,
                    isPressed: _isPressed,
                    tint: baseColor,
                    isPrimary: isPrimary,
                  ),
                  child: Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      borderRadius: effectiveRadius,
                      color: glassFill,
                    ),
                    child: Center(child: content),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= ANDROID MATERIAL 3 BUTTON =================
  Widget _buildMaterial3Button(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.color ?? theme.primaryColor;
    final effectiveRadius = widget.isStadium
        ? BorderRadius.circular(100)
        : (widget.borderRadius ?? BorderRadius.circular(16));

    if (widget.variant == AdaptiveButtonVariant.outline) {
      return SizedBox(
        width: widget.fullWidth ? double.infinity : widget.width,
        height: widget.height,
        child: OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.textColor ?? primaryColor,
            side: BorderSide(color: primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
            padding: widget.padding,
          ),
          child: _buildM3Content(widget.textColor ?? primaryColor),
        ),
      );
    }

    if (widget.variant == AdaptiveButtonVariant.tinted || widget.variant == AdaptiveButtonVariant.secondary) {
      return SizedBox(
        width: widget.fullWidth ? double.infinity : widget.width,
        height: widget.height,
        child: FilledButton.tonal(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor.withOpacity(0.12),
            foregroundColor: widget.textColor ?? primaryColor,
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
            padding: widget.padding,
          ),
          child: _buildM3Content(widget.textColor ?? primaryColor),
        ),
      );
    }

    return SizedBox(
      width: widget.fullWidth ? double.infinity : widget.width,
      height: widget.height,
      child: FilledButton(
        onPressed: widget.onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: widget.textColor ?? Colors.white,
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          padding: widget.padding,
        ),
        child: _buildM3Content(widget.textColor ?? Colors.white),
      ),
    );
  }

  Widget _buildM3Content(Color color) {
    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          IconTheme(
            data: IconThemeData(color: color, size: 18),
            child: widget.icon!,
          ),
          const SizedBox(width: 6),
        ],
        DefaultTextStyle(
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          child: widget.label,
        ),
      ],
    );
  }
}

/// Adaptive Circular Liquid Glass Action / Play Button
class AdaptiveIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final String? tooltip;
  final bool isPrimary;

  const AdaptiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.tooltip,
    this.isPrimary = false,
  });

  @override
  State<AdaptiveIconButton> createState() => _AdaptiveIconButtonState();
}

class _AdaptiveIconButtonState extends State<AdaptiveIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isApple(BuildContext context) {
    if (kIsWeb) return false;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final isApple = _isApple(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    if (isApple) {
      final effectiveBg = widget.backgroundColor ??
          (widget.isPrimary
              ? primaryColor.withOpacity(0.90)
              : (isDark ? const Color(0xFF2C221F) : Colors.white).withOpacity(isDark ? 0.70 : 0.80));
      final effectiveIconColor = widget.iconColor ?? (widget.isPrimary ? Colors.white : primaryColor);

      Widget glassDisc = AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTapDown: widget.onPressed == null
                ? null
                : (_) {
                    setState(() => _isPressed = true);
                    _controller.forward();
                    HapticFeedback.lightImpact();
                  },
            onTapUp: widget.onPressed == null
                ? null
                : (_) {
                    setState(() => _isPressed = false);
                    _controller.reverse();
                  },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _controller.reverse();
            },
            onTap: widget.onPressed,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.isPrimary
                        ? primaryColor.withOpacity(_isPressed ? 0.20 : 0.35)
                        : (isDark ? Colors.black : const Color(0xFF4A382E))
                            .withOpacity(_isPressed ? 0.04 : 0.12),
                    blurRadius: _isPressed ? 6 : 12,
                    offset: Offset(0, _isPressed ? 1 : 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: CustomPaint(
                    painter: _AppleLiquidGlassPainter(
                      radius: widget.size / 2,
                      isDark: isDark,
                      isPressed: _isPressed,
                      tint: widget.backgroundColor ?? primaryColor,
                      isPrimary: widget.isPrimary,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: effectiveBg,
                      ),
                      child: Center(
                        child: IconTheme(
                          data: IconThemeData(
                            color: effectiveIconColor,
                            size: widget.size * 0.54,
                          ),
                          child: widget.icon,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (widget.tooltip != null) {
        return Tooltip(message: widget.tooltip!, child: glassDisc);
      }
      return glassDisc;
    }

    // Material 3 Button on Android
    final effectiveBg = widget.backgroundColor ??
        (widget.isPrimary ? primaryColor : primaryColor.withOpacity(0.12));
    final effectiveIconColor = widget.iconColor ?? (widget.isPrimary ? Colors.white : primaryColor);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: effectiveBg,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: widget.icon,
        tooltip: widget.tooltip,
        iconSize: widget.size * 0.54,
        color: effectiveIconColor,
        padding: EdgeInsets.zero,
        onPressed: widget.onPressed,
      ),
    );
  }
}
