import 'package:flutter/material.dart';
import 'glass_style.dart';
import 'liquid_glass.dart';

/// A padded container with the Liquid Glass material applied.
/// Equivalent to Swift's GlassCard.
class GlassCard extends StatelessWidget {
  final Widget child;
  final GlassStyle style;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? cornerRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.style = GlassStyle.card,
    this.tint,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.cornerRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      style: style,
      tint: tint,
      padding: padding,
      margin: margin,
      cornerRadius: cornerRadius,
      onTap: onTap,
      child: child,
    );
  }
}
