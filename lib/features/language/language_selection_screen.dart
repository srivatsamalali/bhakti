import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/language_model.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../main_navigation_shell.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isInitialLaunch;

  const LanguageSelectionScreen({super.key, this.isInitialLaunch = false});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<PreferencesService>();
    _selectedCode = prefs.getSelectedLanguage();
  }

  Future<void> _saveAndProceed(String code) async {
    final prefs = context.read<PreferencesService>();
    await prefs.setSelectedLanguage(code);
    await prefs.setFirstLaunchComplete();
    AnalyticsService.instance.logLanguageSelected(code);

    if (!mounted) return;

    if (widget.isInitialLaunch) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: widget.isInitialLaunch
          ? null
          : AppBar(
              title: Text(context.tr('selectLanguage')),
              centerTitle: true,
              elevation: 0,
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isInitialLaunch) ...[
                const SizedBox(height: 24),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('selectLanguage'),
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 26,
                    color: AppColors.maroonPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('selectLanguageSubtitle'),
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
              ],

              // 5 Large Language Cards
              Expanded(
                child: ListView.builder(
                  itemCount: LanguageModel.supported.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final lang = LanguageModel.supported[index];
                    final isSelected = lang.code == _selectedCode;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCode = lang.code;
                          });
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.maroonPrimary
                                : AppColors.creamCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.goldLight
                                  : AppColors.goldPrimary.withOpacity(0.3),
                              width: isSelected ? 2 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.maroonPrimary.withOpacity(0.25)
                                    : Colors.black.withOpacity(0.04),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Script Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.goldPrimary
                                      : AppColors.creamSurface,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  lang.scriptSymbol,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.maroonPrimary
                                        : AppColors.maroonPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),

                              // Native & English Names
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.nativeName,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      lang.englishName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected
                                            ? AppColors.goldLight
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection Indicator
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? AppColors.goldLight
                                    : AppColors.goldPrimary.withOpacity(0.5),
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Confirm / Continue Button
              ElevatedButton(
                onPressed: () => _saveAndProceed(_selectedCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.maroonPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.tr('continueButton'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
