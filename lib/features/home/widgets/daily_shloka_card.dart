import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/temple_theme.dart';
import '../../../services/preferences/preferences_service.dart';
import '../../../services/wisdom/daily_wisdom_service.dart';

import '../../../widgets/interactive_flower_offering.dart';
import '../../../widgets/sacred_filigree_border.dart';
import '../../wallpaper/sacred_wallpaper_generator_dialog.dart';

class DailyShlokaCard extends StatefulWidget {
  const DailyShlokaCard({super.key});

  @override
  State<DailyShlokaCard> createState() => _DailyShlokaCardState();
}

class _DailyShlokaCardState extends State<DailyShlokaCard> {
  final GlobalKey<State<InteractiveFlowerOffering>> _offeringKey = GlobalKey();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _togglePlayShloka(String text, String lang) async {
    if (_isPlayingAudio) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isPlayingAudio = false);
      return;
    }

    try {
      setState(() => _isPlayingAudio = true);
      String ttsLang = 'sa-IN';
      if (lang == 'kn') {
        ttsLang = 'kn-IN';
      } else if (lang == 'hi') {
        ttsLang = 'hi-IN';
      } else if (lang == 'ta') {
        ttsLang = 'ta-IN';
      } else if (lang == 'ml') {
        ttsLang = 'ml-IN';
      } else if (lang == 'en') {
        ttsLang = 'en-IN';
      }

      await _flutterTts.setLanguage(ttsLang);
      await _flutterTts.setSpeechRate(0.38); // Gentle sacred chanting pace
      await _flutterTts.setPitch(0.95);
      await _flutterTts.speak(text);
    } catch (_) {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();
    final templeTheme = TempleTheme.fromId(prefs.getTempleThemeId());
    final todayWisdom = DailyWisdomService.getTodayWisdom();

    final cardTitle = currentLang == 'kn'
        ? (todayWisdom.category == 'Vachana'
            ? 'ದಿನದ ಪವಿತ್ರ ವಚನ'
            : todayWisdom.category == 'Dasa Sahitya'
                ? 'ದಾಸ ಸಾಹಿತ್ಯಾಮೃತ'
                : 'ದಿನದ ಪವಿತ್ರ ಶ್ಲೋಕ')
        : 'Sacred Daily Wisdom';

    final authorDisplay = todayWisdom.getAuthor(currentLang);
    final verseText = todayWisdom.getVerse(currentLang);
    final meaningText = todayWisdom.getMeaning(currentLang);
    final deityDisplay = '$authorDisplay • ${todayWisdom.deity}';

    return InteractiveFlowerOffering(
      key: _offeringKey,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFDF9),
              Color(0xFFFAF4E8),
            ],
          ),
          border: Border.all(
            color: templeTheme.borderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: templeTheme.accentGold.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: templeTheme.primaryColor.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SacredCornerFiligree(
          borderRadius: BorderRadius.circular(24),
          color: templeTheme.accentGold,
          cornerSize: 22,
          strokeWidth: 1.5,
          child: Stack(
              children: [
                // Subtle Decorative Corner Diya Accent
                Positioned(
                  top: -10,
                  right: -10,
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    size: 70,
                    color: templeTheme.accentGold.withOpacity(0.10),
                  ),
                ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Clean Unclipped Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: templeTheme.heroGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: templeTheme.primaryColor.withOpacity(0.22),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 13, color: AppColors.goldLight),
                            const SizedBox(width: 6),
                            Text(
                              cardTitle.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick Listen / Pause Pill
                      InkWell(
                        onTap: () => _togglePlayShloka(verseText, currentLang),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isPlayingAudio ? templeTheme.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isPlayingAudio ? templeTheme.primaryColor : templeTheme.borderColor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                                size: 15,
                                color: _isPlayingAudio ? Colors.white : templeTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isPlayingAudio ? 'Playing' : 'Listen',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isPlayingAudio ? Colors.white : templeTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Mantra / Deity / Author Title
                  Text(
                    deityDisplay,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: templeTheme.primaryColor,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sacred Shloka / Vachana Verse with gold accent
                  Text(
                    verseText,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C1E18),
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Meaning Box with spiritual saffron accent
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.90),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFECD7B8)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.spa_rounded,
                            color: AppColors.goldDark,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            meaningText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5E4E42),
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- Dedicated Premium Action Toolbar ---
                  Row(
                    children: [
                      // 1. Offer Pushpam
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            final state = _offeringKey.currentState;
                            if (state != null) {
                              (state as dynamic).triggerOffering();
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8EE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.goldPrimary.withOpacity(0.5)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.spa_rounded, size: 16, color: AppColors.goldDark),
                                SizedBox(width: 5),
                                Text(
                                  'Pushpam',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.maroonPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 2. Wallpaper & Story Generator
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            SacredWallpaperGeneratorDialog.show(
                              context,
                              shlokaTitle: todayWisdom.title,
                              shlokaText: verseText,
                              shlokaMeaning: meaningText,
                              deity: deityDisplay,
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8EE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.goldPrimary.withOpacity(0.5)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wallpaper_rounded, size: 16, color: AppColors.saffronPrimary),
                                SizedBox(width: 5),
                                Text(
                                  'Wallpaper',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.maroonPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 3. Copy Shloka
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '$verseText\n\n$meaningText\n— $deityDisplay'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Wisdom verse copied to clipboard! 🙏'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: templeTheme.primaryColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: templeTheme.borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 15, color: templeTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: templeTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  ),
);
}
}

