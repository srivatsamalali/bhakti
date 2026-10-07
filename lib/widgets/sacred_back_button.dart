import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';

/// Accessible, prominent single-language back button designed for elders & grandparents
class SacredBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;

  const SacredBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final backText = context.tr('back');
    final textColor = color ?? AppColors.maroonPrimary;
    final bg = backgroundColor ?? const Color(0xFFFFF9EE);
    final border = borderColor ?? const Color(0x60D4AF37);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (onPressed != null) {
                onPressed!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 13,
                      color: textColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      backText,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
