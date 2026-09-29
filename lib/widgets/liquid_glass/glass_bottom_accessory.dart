import 'package:flutter/material.dart';
import 'glass_style.dart';
import 'liquid_glass.dart';

/// A persistent glass control docked above a tab bar (e.g., Now Playing mini player pill).
/// Faithfully reproduces GlassBottomAccessory from the LiquidGlass architecture.
class GlassBottomAccessory extends StatelessWidget {
  final Widget child;
  final Color? tint;
  final double cornerRadius;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const GlassBottomAccessory({
    super.key,
    required this.child,
    this.tint,
    this.cornerRadius = 20.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      style: GlassStyle.sheet,
      tint: tint,
      cornerRadius: cornerRadius,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}
