import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class DivineMusicVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color? barColor;
  final double height;
  final double width;

  const DivineMusicVisualizer({
    super.key,
    required this.isPlaying,
    this.barColor,
    this.height = 16,
    this.width = 18,
  });

  @override
  State<DivineMusicVisualizer> createState() => _DivineMusicVisualizerState();
}

class _DivineMusicVisualizerState extends State<DivineMusicVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  final List<int> _durations = [480, 620, 540, 700];

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
      return Tween<double>(begin: 0.25, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 110), () {
        if (mounted && widget.isPlaying) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
      controller.animateTo(0.25, duration: const Duration(milliseconds: 200));
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
    final color = widget.barColor ?? AppColors.goldPrimary;

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
              return Container(
                width: (widget.width / 4) - 1.5,
                height: widget.height * _animations[index].value,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    if (widget.isPlaying)
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 4,
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
