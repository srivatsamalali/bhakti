import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/localization/app_localizations.dart';
import '../models/language_model.dart';
import '../services/preferences/preferences_service.dart';

class DevotionalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onSettingsTap;
  final bool showLanguageSwitch;

  const DevotionalAppBar({
    super.key,
    this.title,
    this.showLogo = true,
    this.actions,
    this.showBackButton = false,
    this.onSettingsTap,
    this.showLanguageSwitch = true,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final currentCode = prefs.getSelectedLanguage();
    final currentLang = LanguageModel.supported.firstWhere(
      (l) => l.code == currentCode,
      orElse: () => LanguageModel.supported.first,
    );

    return AppBar(
      automaticallyImplyLeading: showBackButton,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      titleSpacing: 16,
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldPrimary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldLight.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'images/logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title ?? context.tr('appName'),
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 22,
                        color: AppColors.maroonPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Text(
              title ?? '',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.maroonPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
      actions: actions ??
          [
            // Quick 1-Tap Language Switcher Menu
            if (showLanguageSwitch)
              PopupMenuButton<String>(
                tooltip: context.tr('selectLanguage'),
                initialValue: currentCode,
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.goldPrimary.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                color: AppColors.creamCard,
                onSelected: (String code) async {
                  await prefs.setSelectedLanguage(code);
                },
                itemBuilder: (context) {
                  return LanguageModel.supported.map((lang) {
                    final isSelected = lang.code == currentCode;
                    return PopupMenuItem<String>(
                      value: lang.code,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.maroonPrimary
                                  : AppColors.creamSurface,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              lang.scriptSymbol,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.goldLight
                                    : AppColors.maroonPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.nativeName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.maroonPrimary
                                        : AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  lang.englishName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: AppColors.maroonPrimary,
                              size: 18,
                            ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldPrimary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentLang.scriptSymbol,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.maroonDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentLang.nativeName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroonDark,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.maroonDark,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

            if (onSettingsTap != null)
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 24),
                color: AppColors.maroonPrimary,
                tooltip: context.tr('navSettings'),
                onPressed: onSettingsTap,
              ),
            const SizedBox(width: 6),
          ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
