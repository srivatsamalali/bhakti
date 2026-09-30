import 'package:flutter/material.dart';

class DivineMusicVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color? barColor;
  final double height;
  final double width;

  const DivineMusicVisualizer({
    super.key,
    required this.isPlaying,
    this.barColor,
    this.height = 18,
    this.width = 22,
  });

  @override
  State<DivineMusicVisualizer> createState() => _DivineMusicVisualizerState();
}

class _DivineMusicVisualizerState extends State<DivineMusicVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  final List<int> _durations = [380, 520, 440, 600];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[index]),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.20, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic),
      );
    }).toList();

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 85), () {
        if (mounted && widget.isPlaying) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
      controller.animateTo(0.20, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void didUpdateWidget(covariant DivineMusicVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.barColor ?? const Color(0xFFFFD700);

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, _) {
              final barVal = _animations[index].value;
              final currentHeight = (widget.height * barVal).clamp(3.5, widget.height);

              return Container(
                width: (widget.width / 4) - 1.8,
                height: currentHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryColor,
                      const Color(0xFFFF9933),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    if (widget.isPlaying)
                      BoxShadow(
                        color: primaryColor.withOpacity(0.65),
                        blurRadius: 6,
                        spreadRadius: 1.0,
                        offset: const Offset(0, -1),
                      ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
