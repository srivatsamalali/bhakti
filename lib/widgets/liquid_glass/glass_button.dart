import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'glass_style.dart';
import 'liquid_glass.dart';

/// A pressable Button with the Liquid Glass material and spring scale animation.
/// Equivalent to Swift's GlassButton.
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final double? cornerRadius;

  const GlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.tint,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    this.cornerRadius,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _animController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _animController.reverse();
      widget.onPressed?.call();
    }
  }

  void _onTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: LiquidGlass(
              style: GlassStyle.button,
              tint: widget.tint ?? AppColors.saffronPrimary,
              padding: widget.padding,
              cornerRadius: widget.cornerRadius,
              child: child!,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
