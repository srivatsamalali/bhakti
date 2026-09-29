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

/// A floating Liquid Glass navigation capsule matching Apple's iOS 26 Liquid Glass design.
/// Seamlessly animates a single active pill bubble with zero lag and zero residual traces.
class GlassTabBar extends StatelessWidget {
  final List<GlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? tint;

  const GlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: LiquidGlass(
        style: GlassStyle.toolbar,
        isStadium: true,
        tint: tint ?? AppColors.goldPrimary,
        enablePrism: true,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / items.length;

            return Stack(
              children: [
                // Single Smooth Sliding Active Tab Indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  left: currentIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white.withOpacity(0.94),
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: (tint ?? AppColors.goldPrimary).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Interactive Tab Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!isSelected) {
                            HapticFeedback.selectionClick();
                            onTap(index);
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
                                        ? AppColors.maroonPrimary
                                        : AppColors.textDark.withOpacity(0.70),
                                    size: isSelected ? 23 : 21,
                                  ),

                                  // Active Green/Gold Dot
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
                                      ? AppColors.maroonPrimary
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
            );
          },
        ),
      ),
    );
  }
}
