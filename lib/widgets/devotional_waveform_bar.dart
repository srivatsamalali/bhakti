import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A sleek glowing Devotional Audio Frequency Waveform Visualizer
/// with lively synchronized bar wave motions.
class DevotionalWaveformBar extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;

  const DevotionalWaveformBar({
    super.key,
    required this.isPlaying,
    this.barCount = 28,
    this.height = 28,
    this.primaryColor = AppColors.goldLight,
    this.secondaryColor = AppColors.goldPrimary,
  });

  @override
  State<DevotionalWaveformBar> createState() => _DevotionalWaveformBarState();
}

class _DevotionalWaveformBarState extends State<DevotionalWaveformBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant DevotionalWaveformBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              // Generate sinusoidal wave motion
              final phase = (index / widget.barCount) * 2 * math.pi;
              final animVal = widget.isPlaying ? _controller.value * 2 * math.pi : 0.0;
              final wave = (math.sin(phase + animVal) * 0.5 + 0.5);
              final wave2 = (math.cos(phase * 1.5 - animVal * 1.2) * 0.5 + 0.5);
              final combined = widget.isPlaying ? (0.2 + 0.8 * ((wave + wave2) / 2)) : 0.15;

              final barHeight = (widget.height * combined).clamp(4.0, widget.height);

              return Container(
                width: 3.0,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [
                      widget.secondaryColor.withOpacity(0.85),
                      widget.primaryColor,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  boxShadow: widget.isPlaying
                      ? [
                          BoxShadow(
                            color: widget.primaryColor.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
