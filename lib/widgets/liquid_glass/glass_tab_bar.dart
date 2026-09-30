import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import 'glass_style.dart';
import 'liquid_glass.dart';

class GlassTabItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? badgeText;
  final bool hasActiveDot;

  const GlassTabItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeText,
    this.hasActiveDot = false,
  });
}

/// A floating Liquid Glass navigation capsule matching Apple's Liquid Glass design.
/// Supports real-time slide scrolling, continuous PageController interpolation, and drag gestures.
class GlassTabBar extends StatefulWidget {
  final List<GlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? tint;
  final Color? activeColor;
  final PageController? pageController;

  const GlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.tint,
    this.activeColor,
    this.pageController,
  });

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar> {
  int _lastHapticIndex = -1;
  double? _dragPosition;

  @override
  void initState() {
    super.initState();
    _lastHapticIndex = widget.currentIndex;
  }

  void _handleDrag(double localX, double maxWidth) {
    final tabWidth = maxWidth / widget.items.length;
    final rawIndex = (localX / tabWidth).clamp(0.0, widget.items.length - 1.0);
    final targetIndex = rawIndex.round();

    setState(() {
      _dragPosition = rawIndex;
    });

    if (targetIndex != _lastHapticIndex) {
      _lastHapticIndex = targetIndex;
      HapticFeedback.selectionClick();
    }

    if (widget.pageController != null && widget.pageController!.hasClients) {
      widget.pageController!.jumpTo(
        rawIndex * widget.pageController!.position.viewportDimension,
      );
    }
  }

  void _finishDrag(double localX, double maxWidth) {
    final tabWidth = maxWidth / widget.items.length;
    final targetIndex = (localX / tabWidth).round().clamp(0, widget.items.length - 1);

    setState(() {
      _dragPosition = null;
    });

    widget.onTap(targetIndex);
    if (widget.pageController != null && widget.pageController!.hasClients) {
      widget.pageController!.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = widget.activeColor ?? Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: LiquidGlass(
        style: GlassStyle.toolbar,
        isStadium: true,
        tint: widget.tint ?? AppColors.goldPrimary,
        enablePrism: true,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / widget.items.length;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                _handleDrag(details.localPosition.dx, constraints.maxWidth);
              },
              onHorizontalDragUpdate: (details) {
                _handleDrag(details.localPosition.dx, constraints.maxWidth);
              },
              onHorizontalDragEnd: (details) {
                if (_dragPosition != null) {
                  _finishDrag(_dragPosition! * tabWidth, constraints.maxWidth);
                }
              },
              onHorizontalDragCancel: () {
                setState(() {
                  _dragPosition = null;
                });
              },
              child: Stack(
                children: [
                  // Smooth Real-Time Sliding Active Tab Indicator
                  AnimatedBuilder(
                    animation: widget.pageController ?? const AlwaysStoppedAnimation(0),
                    builder: (context, child) {
                      double currentOffset;
                      if (_dragPosition != null) {
                        currentOffset = _dragPosition!;
                      } else if (widget.pageController != null &&
                          widget.pageController!.hasClients &&
                          widget.pageController!.page != null) {
                        currentOffset = widget.pageController!.page!;
                      } else {
                        currentOffset = widget.currentIndex.toDouble();
                      }

                      return Positioned(
                        left: currentOffset * tabWidth,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white.withOpacity(0.95),
                            border: Border.all(color: Colors.white, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: (widget.tint ?? AppColors.goldPrimary).withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Interactive Tab Items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(widget.items.length, (index) {
                      final item = widget.items[index];
                      final isSelected = index == widget.currentIndex;

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!isSelected) {
                              HapticFeedback.selectionClick();
                              widget.onTap(index);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                                      color: isSelected
                                          ? effectiveActiveColor
                                          : AppColors.textDark.withOpacity(0.70),
                                      size: isSelected ? 23 : 21,
                                    ),

                                    // Active Dot Indicator
                                    if (item.hasActiveDot && !isSelected)
                                      Positioned(
                                        top: -1,
                                        right: -3,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF25D366),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),

                                    // Number Count Badge
                                    if (item.badgeText != null)
                                      Positioned(
                                        top: -4,
                                        right: -10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF25D366),
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF25D366).withOpacity(0.4),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            item.badgeText!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    color: isSelected
                                        ? effectiveActiveColor
                                        : AppColors.textDark.withOpacity(0.80),
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
