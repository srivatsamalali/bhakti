import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/temple_theme.dart';
import '../../../repositories/song_repository.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../services/preferences/preferences_service.dart';
import '../../../services/wisdom/special_day_intelligence_service.dart';
import '../../../widgets/sacred_filigree_border.dart';

/// Breathtaking Golden Sanctum Modal for Auspicious Special Days & Festivals.
/// Fully localized across Kannada (kn), Tamil (ta), Telugu (te), Hindi (hi), Malayalam (ml), and English (en).
/// Includes in-modal Language Switcher dropdown and senior-friendly accessible touch targets.
class SpecialDayModalDialog extends StatelessWidget {
  final SpecialDayInfo info;

  const SpecialDayModalDialog({
    super.key,
    required this.info,
  });

  static Future<void> show(BuildContext context, SpecialDayInfo info) {
    HapticFeedback.mediumImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.68),
      builder: (_) => SpecialDayModalDialog(info: info),
    );
  }

  static const Map<String, Map<String, String>> _dialogLabels = {
    'significance': {
      'kn': 'ಪಾವಿತ್ರ್ಯತೆ & ಮಹತ್ವ • Significance',
      'ta': 'புனிதத்துவம் & சிறப்பு • Significance',
      'te': 'పావిత్రత & విశిష్టత • Significance',
      'hi': 'पवित्रता एवं महत्व • Significance',
      'ml': 'വിശുദ്ധിയും പ്രാധാന്യവും • Significance',
      'en': 'Sacred Significance & Blessings',
    },
    'rituals': {
      'kn': 'ಇಂದಿನ ಪವಿತ್ರ ಆಚರಣೆಗಳು • Auspicious Rituals',
      'ta': 'இன்றைய புனித வழிபாடுகள் • Auspicious Rituals',
      'te': 'నేటి పవిత్ర పూజా విధులు • Auspicious Rituals',
      'hi': 'आज के पावन अनुष्ठान • Auspicious Rituals',
      'ml': 'ഇന്നത്തെ വിശുദ്ധ ആചാരങ്ങൾ • Auspicious Rituals',
      'en': 'Today\'s Auspicious Rituals',
    },
    'mantra': {
      'kn': 'ದಿನದ ಪವಿತ್ರ ಜಪ ಮಂತ್ರ',
      'ta': 'இன்றைய புனித ஜெப மந்திரம்',
      'te': 'నేటి పవిత్ర జప మంత్రం',
      'hi': 'आज का पावन जप मंत्र',
      'ml': 'ഇന്നത്തെ പവിത്ര ജപ മന്ത്രം',
      'en': 'Today\'s Sacred Japa Mantra',
    },
    'copySuccess': {
      'kn': 'ಮಂತ್ರ ನಕಲಿಸಲಾಗಿದೆ (Copied to clipboard)',
      'ta': 'மந்திரம் நகலெடுக்கப்பட்டது (Copied to clipboard)',
      'te': 'మంత్రం కాపీ చేయబడింది (Copied to clipboard)',
      'hi': 'मंत्र कॉपी किया गया (Copied to clipboard)',
      'ml': 'മന്ത്രം പകർത്തി (Copied to clipboard)',
      'en': 'Mantra copied to clipboard',
    },
    'listenStotram': {
      'kn': 'ಇಂದಿನ ಪವಿತ್ರ ಸ್ತೋತ್ರ ಆಲಿಸಿ',
      'ta': 'இன்றைய புனித ஸ்தோத்திரத்தைக் கேளுங்கள்',
      'te': 'నేటి పవిత్ర స్తోత్రం వినండి',
      'hi': 'आज का पावन स्तोत्र सुनें',
      'ml': 'ഇന്നത്തെ വിശുദ്ധ സ്തോത്രം ശ്രവിക്കൂ',
      'en': 'Listen to Today\'s Sacred Stotram',
    },
    'darshanBtn': {
      'kn': 'ದರ್ಶನ ಸ್ವೀಕರಿಸಿ',
      'ta': 'தரிசனம் பெறுங்கள்',
      'te': 'దర్శనం స్వీకరించండి',
      'hi': 'दर्शन स्वीकारें',
      'ml': 'ദർശനം സ്വീകരിക്കൂ',
      'en': 'Receive Darshan',
    },
    'shareBtn': {
      'kn': 'ಶುಭ ಹಾರೈಸಿ',
      'ta': 'பகிரவும்',
      'te': 'పంచుకోండి',
      'hi': 'साझा करें',
      'ml': 'പങ്കുവെക്കൂ',
      'en': 'Share',
    },
    'selectLanguage': {
      'kn': 'ಭಾಷೆ ಬದಲಿಸಿ',
      'ta': 'மொழியை மாற்று',
      'te': 'భాషను మార్చు',
      'hi': 'भाषा बदलें',
      'ml': 'ഭാഷ മാറ്റുക',
      'en': 'Change Language',
    },
  };

  static String _tr(String key, String lang) {
    return _dialogLabels[key]?[lang] ?? _dialogLabels[key]?['en'] ?? key;
  }

  void _shareBlessings(BuildContext context, SpecialDayInfo displayInfo, String lang) {
    HapticFeedback.lightImpact();
    final box = context.findRenderObject() as RenderBox?;
    final size = MediaQuery.of(context).size;
    final origin = box != null && box.hasSize
        ? (box.localToGlobal(Offset.zero) & box.size)
        : Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2);

    final shareText = '''🌸 ${displayInfo.title} 🌸
✨ ${displayInfo.subtitle}
🛕 ${displayInfo.deity}

📖 ${displayInfo.significance}

🕉️ ${displayInfo.mantra}

॥ ಶುಭ ದಿನ • Divine Blessings from Bhakti App ॥''';

    Share.share(
      shareText,
      sharePositionOrigin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();
    final templeTheme = TempleTheme.fromId(prefs.getTempleThemeId());
    final songRepo = context.watch<SongRepository>();
    final player = context.watch<AudioPlayerService>();

    // Dynamically re-localize day info whenever language is switched
    final displayInfo = SpecialDayIntelligenceService.getLocalizedInfo(
          info.id,
          currentLang,
          date: info.date,
        ) ??
        info;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFDF9),
              Color(0xFFFAF2E3),
            ],
          ),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB8860B).withOpacity(0.28),
              blurRadius: 26,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SacredCornerFiligree(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFFD4AF37),
          cornerSize: 24,
          strokeWidth: 1.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header Ribbon ---
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFE8D7B8).withOpacity(0.85),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Festive Day Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B1E1E), Color(0xFF5E1010)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B1E1E).withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFDF7A), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            displayInfo.badgeText,
                            style: const TextStyle(
                              color: Color(0xFFFFF9EE),
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // In-Modal Language Switcher Dropdown (44dp touch target)
                    PopupMenuButton<String>(
                      tooltip: _tr('selectLanguage', currentLang),
                      onSelected: (String newLang) async {
                        HapticFeedback.mediumImpact();
                        await prefs.setSelectedLanguage(newLang);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.4),
                      ),
                      color: const Color(0xFFFFFDF8),
                      elevation: 6,
                      itemBuilder: (BuildContext context) => const [
                        PopupMenuItem(
                          value: 'kn',
                          child: Text('🇮🇳  ಕನ್ನಡ (Kannada)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                        PopupMenuItem(
                          value: 'ta',
                          child: Text('🇮🇳  தமிழ் (Tamil)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                        PopupMenuItem(
                          value: 'te',
                          child: Text('🇮🇳  తెలుగు (Telugu)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                        PopupMenuItem(
                          value: 'hi',
                          child: Text('🇮🇳  हिन्दी (Hindi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                        PopupMenuItem(
                          value: 'ml',
                          child: Text('🇮🇳  മലയാളം (Malayalam)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                        PopupMenuItem(
                          value: 'en',
                          child: Text('🇬🇧  English', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                      ],
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1E1E).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.85), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language_rounded, size: 16, color: Color(0xFF8B1E1E)),
                            const SizedBox(width: 4),
                            Text(
                              currentLang.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5A1E14),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Color(0xFF5A1E14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Accessible Close 'X' Button (44dp minimum touch target)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1E1E).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: Color(0xFF5A1E14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Scrollable Sanctum Body ---
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Festival Main Title (High contrast deep walnut)
                      Text(
                        displayInfo.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3B1209),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Festival Subtitle with Color
                      Text(
                        displayInfo.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B3A22),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Presiding Deity Medallion Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2D9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDEB86A), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.temple_hindu_rounded,
                              size: 22,
                              color: Color(0xFF8B1E1E),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                displayInfo.deity,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A140A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Significance Card Header & Content
                      Text(
                        _tr('significance', currentLang),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E150B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayInfo.significance,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.55,
                          color: Color(0xFF2D160C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Auspicious Rituals Header & Items
                      Text(
                        _tr('rituals', currentLang),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E150B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...displayInfo.rituals.map(
                        (ritual) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4, right: 9),
                                child: Icon(
                                  Icons.brightness_7_rounded,
                                  size: 14,
                                  color: Color(0xFFB8860B),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  ritual,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF381C10),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Sacred Daily Mantra Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF0DC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.8),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF8B1E1E)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _tr('mantra', currentLang),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8B1E1E),
                                    ),
                                  ),
                                ),
                                // Accessible 44dp Copy Button
                                Tooltip(
                                  message: _tr('copySuccess', currentLang),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Clipboard.setData(ClipboardData(text: displayInfo.mantra));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(_tr('copySuccess', currentLang)),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.copy_rounded,
                                        size: 18,
                                        color: Color(0xFF6B3A22),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayInfo.mantra,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF220F07),
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Recommended Stotram 1-Tap Play
                      if (displayInfo.recommendedStotram != null && songRepo.allSongs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final songs = songRepo.allSongs;
                            final targetSong = songs.firstWhere(
                              (s) =>
                                  s.title
                                      .toLowerCase()
                                      .contains(displayInfo.recommendedStotram!.toLowerCase()) ||
                                  displayInfo.recommendedStotram!
                                      .toLowerCase()
                                      .contains(s.title.toLowerCase()),
                              orElse: () => songs.first,
                            );

                            return InkWell(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).pop();
                                player.playSong(targetSong);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: templeTheme.heroGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: templeTheme.primaryColor.withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _tr('listenStotram', currentLang),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFFFE8D6),
                                            ),
                                          ),
                                          Text(
                                            targetSong.getLocalizedTitle(currentLang),
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // --- Bottom Actions: Family Share & Darshan Dismiss ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Row(
                  children: [
                    // WhatsApp / Family Blessings Share Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B1D1D),
                        side: const BorderSide(color: Color(0xFF8B1E1E), width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () => _shareBlessings(context, displayInfo, currentLang),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(
                        _tr('shareBtn', currentLang),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Primary Darshan Button (Clean FittedBox with single-line guarantee)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B1D1D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2.5,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _tr('darshanBtn', currentLang),
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
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
