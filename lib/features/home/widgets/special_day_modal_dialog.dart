import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/temple_theme.dart';
import '../../../repositories/song_repository.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../services/preferences/preferences_service.dart';
import '../../../services/wisdom/special_day_intelligence_service.dart';
import '../../../services/wisdom/daily_gita_service.dart';
import '../../../services/notifications/devotional_reminder_service.dart';
import '../../../widgets/sacred_filigree_border.dart';

/// 2-Page Sanctum Opening Modal featuring:
/// Page 1: Day's Special (festivals, tithi, auspicious rituals, deity, mantra)
/// Page 2: Daily Bhagavad Gita Shloka (701 shlokas, device-specific progressive day count, online fetching)
class SpecialDayModalDialog extends StatefulWidget {
  final SpecialDayInfo? info;

  const SpecialDayModalDialog({
    super.key,
    this.info,
  });

  static Future<void> show(BuildContext context, [SpecialDayInfo? info]) {
    HapticFeedback.mediumImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.68),
      builder: (_) => SpecialDayModalDialog(info: info),
    );
  }

  @override
  State<SpecialDayModalDialog> createState() => _SpecialDayModalDialogState();
}

class _SpecialDayModalDialogState extends State<SpecialDayModalDialog> {
  late final PageController _pageController;
  int _currentPage = 0;

  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlayingGitaAudio = false;

  int _shlokaNumber = 1;
  BhagavadGitaVerse? _gitaVerse;
  bool _isLoadingGita = false;

  static const Map<String, Map<String, String>> _dialogLabels = {
    'tabSpecial': {
      'kn': 'ದಿನದ ವಿಶೇಷ',
      'ta': 'சிறப்பு நாள்',
      'te': 'దిన విశేషం',
      'hi': 'आज का विशेष',
      'ml': 'വിശേഷ ദിവസം',
      'en': "Day's Special",
    },
    'tabGita': {
      'kn': 'ಭಗವದ್ಗೀತೆ',
      'ta': 'பகவத் கீதை',
      'te': 'భగవద్గీత',
      'hi': 'भगवद्गीता',
      'ml': 'ഭഗവദ്ഗീത',
      'en': 'Bhagavad Gita',
    },
    'gitaPagePromptTitle': {
      'kn': 'ಇಂದಿನ ಭಗವದ್ಗೀತಾ ಶ್ಲೋಕ (ದಿನ {day})',
      'ta': 'இன்றைய பகவத் கீதை சுலோகம் (நாள் {day})',
      'te': 'నేటి భగవద్గీత శ్లోకం (రోజు {day})',
      'hi': 'आज का भगवद्गीता श्लोक (दिन {day})',
      'ml': 'ഇന്നത്തെ ഭഗവദ്ഗീത ശ്ലോകം (ദിവസം {day})',
      'en': "Today's Bhagavad Gita Shloka (Day {day})",
    },
    'gitaPagePromptSubtitle': {
      'kn': 'ಮುಂದಿನ ಪುಟಕ್ಕೆ ಹೋಗಲು ಇಲ್ಲಿ ಸ್ಪರ್ಶಿಸಿ →',
      'ta': 'அடுத்த பக்கத்திற்கு செல்ல தொடவும் →',
      'te': 'తదుపరి పేజీకి వెళ్ళడానికి నొక్కండి →',
      'hi': 'अगले पृष्ठ पर जाने के लिए यहाँ टैप करें →',
      'ml': 'അടുത്ത പേജിലേക്ക് പോകാൻ സ്പർശിക്കുക →',
      'en': 'Tap or swipe to read today\'s sacred verse →',
    },
    'backToSpecial': {
      'kn': '← ದಿನದ ವಿಶೇಷಕ್ಕೆ ಹಿಂತಿರುಗಿ',
      'ta': '← சிறப்பு நாளுக்கு திரும்பவும்',
      'te': '← విశేష దినమునకు తిరిగి వెళ్లండి',
      'hi': '← विशेष दिवस पर वापस जाएं',
      'ml': '← വിശേഷ ദിവസത്തിലേക്ക് മടങ്ങുക',
      'en': '← Back to Day\'s Special',
    },
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
      'en': "Today's Auspicious Rituals",
    },
    'mantra': {
      'kn': 'ದಿನದ ಪವಿತ್ರ ಜಪ ಮಂತ್ರ',
      'ta': 'இன்றைய புனித ஜெப மந்திரம்',
      'te': 'నేటి పవిత్ర జప మంత్రం',
      'hi': 'आज का पावन जप मंत्र',
      'ml': 'ഇന്നത്തെ പവിത്ര ജപ മന്ത്രം',
      'en': "Today's Sacred Japa Mantra",
    },
    'gitaTitle': {
      'kn': 'ನಿತ್ಯ ಭಗವದ್ಗೀತಾ ಸಂದೇಶ',
      'ta': 'தினசரி பகவத் கீதை உபதேசம்',
      'te': 'నిత్య భగవద్గీత సందేశం',
      'hi': 'दैनिक श्रीमद्भगवद्गीता ज्ञान',
      'ml': 'നിത്യ ഭഗവദ്ഗീത സന്ദേശം',
      'en': 'Daily Bhagavad Gita Wisdom',
    },
    'gitaMeaning': {
      'kn': 'ಶ್ಲೋಕದ ದೈವಿಕ ಭಾವಾರ್ಥ',
      'ta': 'சுலோகத்தின் புனிதப் பொருள்',
      'te': 'శ్లోక భావార్ధము',
      'hi': 'श्लोक का पावन भावार्थ',
      'ml': 'ശ്ലോകത്തിന്റെ ദിവ്യ അർത്ഥം',
      'en': 'Sacred Meaning & Wisdom',
    },
    'listenAudio': {
      'kn': 'ಶ್ಲೋಕ ಪಠಣ ಆಲಿಸಿ',
      'ta': 'சுலோகப் பாராயணம் கேளுங்கள்',
      'te': 'శ్లోక పఠనం వినండి',
      'hi': 'श्लोक पाठ सुनें',
      'ml': 'ശ്ലോകാലാപനം ശ്രവിക്കൂ',
      'en': 'Chant Sacred Verse',
    },
    'stopAudio': {
      'kn': 'ಪಠಣ ನಿಲ್ಲಿಸಿ',
      'ta': 'நிறுத்து',
      'te': 'ఆపండి',
      'hi': 'रोकें',
      'ml': 'നിർത്തൂ',
      'en': 'Stop Chanting',
    },
    'copySuccess': {
      'kn': 'ಮಂತ್ರ ನಕಲಿಸಲಾಗಿದೆ (Copied)',
      'ta': 'மந்திரம் நகலெடுக்கப்பட்டது (Copied)',
      'te': 'మంత్రం కాపీ చేయబడింది (Copied)',
      'hi': 'मंत्र कॉपी किया गया (Copied)',
      'ml': 'മന്ത്രം പകർത്തി (Copied)',
      'en': 'Mantra copied to clipboard',
    },
    'shlokaCopied': {
      'kn': 'ಗೀತಾ ಶ್ಲೋಕ ನಕಲಿಸಲಾಗಿದೆ',
      'ta': 'கீதை சுலோகம் நகலெடுக்கப்பட்டது',
      'te': 'గీతా శ్లోకం కాపీ చేయబడింది',
      'hi': 'गीता श्लोक कॉपी किया गया',
      'ml': 'ഗീതാ ശ്ലോകം പകർത്തി',
      'en': 'Gita Shloka copied to clipboard',
    },
    'listenStotram': {
      'kn': 'ಇಂದಿನ ಪವಿತ್ರ ಸ್ತೋತ್ರ ಆಲಿಸಿ',
      'ta': 'இன்றைய புனித ஸ்தோத்திரத்தைக் கேளுங்கள்',
      'te': 'నేటి పవిత్ర స్తోత్రం వినండి',
      'hi': 'आज का पावन स्तोत्र सुनें',
      'ml': 'ഇന്നത്തെ വിശുദ്ധ സ്തോത്രം ശ്രവിക്കൂ',
      'en': "Listen to Today's Sacred Stotram",
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
    'remindRitualTitle': {
      'kn': 'ಪೂಜೆ ಮತ್ತು ಆಚರಣೆಗಳ ಜ್ಞಾಪನೆ',
      'ta': 'வழிபாடு மற்றும் சடங்கு நினைவூட்டல்',
      'te': 'పూజా విధులను గుర్తుచేయి',
      'hi': 'दैनिक पूजन एवं अनुष्ठान स्मरण',
      'ml': 'പൂജയും ആചാരങ്ങളും ഓർമ്മിപ്പിക്കുക',
      'en': "Remind Today's Rituals & Chanting",
    },
    'remindRitualSubtitle': {
      'kn': 'ದೇವತಾ ಪೂಜೆ, ಬಣ್ಣ ಮತ್ತು ಜಪದ ಅಧಿಸೂಚನೆ ಪಡೆಯಿರಿ',
      'ta': 'தெய்வ வழிபாடு, நிறம் மற்றும் ஜெப அறிவிப்பைப் பெறுங்கள்',
      'te': 'దేవత పూజ, శుభ వర్ణం మరియు జప నోటిఫికేషన్ పొందండి',
      'hi': 'देवी पूजन, पावन रंग और जप की सूचना प्राप्त करें',
      'ml': 'ദേവ പൂജ, ശുഭ നിറം, ജപ അറിയിപ്പ് നേടുക',
      'en': 'Instant notification for deity worship, sacred color & mantra',
    },
    'ritualReminderSent': {
      'kn': '🔔 ಇಂದಿನ ಪೂಜೆ ಮತ್ತು ಆಚರಣೆಗಳ ಅಧಿಸೂಚನೆ ಕಳುಹಿಸಲಾಗಿದೆ!',
      'ta': '🔔 இன்றைய பூஜை மற்றும் சடங்குகளின் அறிவிப்பு அனுப்பப்பட்டது!',
      'te': '🔔 నేటి పూజ & విశేషాల నోటిఫికేషన్ పంపబడింది!',
      'hi': '🔔 आज के विशेष पूजन एवं अनुष्ठान की सूचना भेज दी गई है!',
      'ml': '🔔 ഇന്നത്തെ പൂജയുടെയും ചടങ്ങുകളുടെയും അറിയിപ്പ് അയച്ചു!',
      'en': '🔔 Special occasion & ritual notification sent!',
    },
  };

  static String _tr(String key, String lang) {
    return _dialogLabels[key]?[lang] ?? _dialogLabels[key]?['en'] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initTts();
    _loadDeviceShloka();
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlayingGitaAudio = false);
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isPlayingGitaAudio = false);
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() => _isPlayingGitaAudio = false);
    });
  }

  Future<void> _loadDeviceShloka([String? lang]) async {
    final num = await DailyBhagavadGitaService.getDeviceDayShlokaNumber();
    if (!mounted) return;
    setState(() {
      _shlokaNumber = num;
      _gitaVerse = DailyBhagavadGitaService.getInitialVerseForNumber(num);
    });
    _fetchShloka(num, lang);
  }

  Future<void> _fetchShloka(int num, [String? lang]) async {
    setState(() => _isLoadingGita = true);
    try {
      final verse = await DailyBhagavadGitaService.fetchShlokaForNumber(
        num,
        targetLang: lang,
      );
      if (mounted) {
        setState(() {
          _gitaVerse = verse;
          _isLoadingGita = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGita = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _togglePlayGitaShloka(String text, String lang) async {
    if (_isPlayingGitaAudio) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isPlayingGitaAudio = false);
      return;
    }

    try {
      setState(() => _isPlayingGitaAudio = true);
      String ttsLang = 'sa-IN';
      if (lang == 'kn') {
        ttsLang = 'kn-IN';
      } else if (lang == 'te') {
        ttsLang = 'te-IN';
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
      await _flutterTts.setSpeechRate(0.38); // Sacred, gentle Vedic pace
      await _flutterTts.setPitch(0.96);
      await _flutterTts.speak(text);
    } catch (_) {
      if (mounted) setState(() => _isPlayingGitaAudio = false);
    }
  }

  void _shareContent(
    BuildContext context,
    SpecialDayInfo displayInfo,
    BhagavadGitaVerse? gita,
    String lang,
  ) {
    HapticFeedback.lightImpact();
    final box = context.findRenderObject() as RenderBox?;
    final size = MediaQuery.of(context).size;
    final origin = box != null && box.hasSize
        ? (box.localToGlobal(Offset.zero) & box.size)
        : Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2);

    String shareText;
    if (_currentPage == 1 && gita != null) {
      shareText = '''🕉️ ಶ್ರೀಮದ್ಭಗವದ್ಗೀತಾ • ದಿನ $_shlokaNumber 🕉️
📖 ${gita.getReference(lang)}
✨ ${gita.getChapterName(lang)} • ${gita.getTheme(lang)}

${gita.sanskrit}

📜 ಭಾವಾರ್ಥ:
${gita.getMeaning(lang)}

॥ ದೈವಿಕ ಸಂದೇಶ • ಭಕ್ತಿ ಅಪ್ಲಿಕೇಶನ್ ॥''';
    } else {
      shareText = '''🌸 ${displayInfo.title} 🌸
✨ ${displayInfo.subtitle}
🛕 ${displayInfo.deity}

📖 ${displayInfo.significance}

🕉️ ${displayInfo.mantra}

॥ ಶುಭ ದಿನ • Divine Blessings from Bhakti App ॥''';
    }

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

    // Dynamically resolve Day's Special: always guarantee authentic daily celebration
    final SpecialDayInfo displayInfo = widget.info != null
        ? (SpecialDayIntelligenceService.getLocalizedInfo(
              widget.info!.id,
              currentLang,
              date: widget.info!.date,
            ) ??
            widget.info!)
        : (SpecialDayIntelligenceService.evaluateForDate(
              DateTime.now(),
              currentLang,
            ) ??
            SpecialDayIntelligenceService.getLocalizedInfo(
              'daily_vedic_${DateTime.now().weekday}',
              currentLang,
              date: DateTime.now(),
            )!);

    final gita = _gitaVerse ?? DailyBhagavadGitaService.getInitialVerseForNumber(_shlokaNumber);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
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
              // --- Header Bar with 2 Page Tabs & Language Switcher ---
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
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
                    // Page Navigation Tabs (Day's Special vs Bhagavad Gita)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E7D3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            // Tab 1: Day's Special
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _pageController.animateToPage(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                borderRadius: BorderRadius.circular(13),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: _currentPage == 0
                                        ? const LinearGradient(
                                            colors: [Color(0xFF8B1E1E), Color(0xFF5E1010)],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '🌸',
                                        style: TextStyle(
                                          fontSize: _currentPage == 0 ? 13 : 11,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _tr('tabSpecial', currentLang),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _currentPage == 0 ? Colors.white : const Color(0xFF7C2D12),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Tab 2: Bhagavad Gita
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _pageController.animateToPage(
                                    1,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                borderRadius: BorderRadius.circular(13),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: _currentPage == 1
                                        ? const LinearGradient(
                                            colors: [Color(0xFF8B1E1E), Color(0xFF5E1010)],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '🕉️',
                                        style: TextStyle(
                                          fontSize: _currentPage == 1 ? 13 : 11,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${_tr('tabGita', currentLang)} ($_shlokaNumber)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _currentPage == 1 ? Colors.white : const Color(0xFF7C2D12),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // In-Modal Language Switcher Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9EE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.7)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentLang,
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8B1E1E), size: 18),
                          items: const [
                            DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'te', child: Text('తెలుగు', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'ta', child: Text('தமிழ்', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'hi', child: Text('हिन्दी', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'ml', child: Text('മലയാളം', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (newLang) {
                            if (newLang != null && newLang != currentLang) {
                              HapticFeedback.selectionClick();
                              prefs.setSelectedLanguage(newLang);
                              _fetchShloka(_shlokaNumber, newLang);
                            }
                          },
                        ),
                      ),
                    ),

                    // Close Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF8B1E1E)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              // --- 2-Page Scrollable Content ---
              Flexible(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() => _currentPage = idx);
                  },
                  children: [
                    // PAGE 1: Day's Special (Original sanctum experience)
                    _buildDaysSpecialPage(
                      context,
                      displayInfo,
                      currentLang,
                      templeTheme,
                      songRepo,
                      player,
                    ),

                    // PAGE 2: Daily Bhagavad Gita Shloka (Device-specific progressive shlokas 1-701)
                    _buildBhagavadGitaPage(
                      context,
                      gita,
                      currentLang,
                      templeTheme,
                    ),
                  ],
                ),
              ),

              // --- Footer Action Bar with Page Dots & Actions ---
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F0),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFE8D7B8).withOpacity(0.85),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicator dots & label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: _currentPage == 0 ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _currentPage == 0 ? const Color(0xFF8B1E1E) : const Color(0xFFD4AF37).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: _currentPage == 1 ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _currentPage == 1 ? const Color(0xFF8B1E1E) : const Color(0xFFD4AF37).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _currentPage == 0
                              ? '1/2 • ${_tr('tabSpecial', currentLang)}'
                              : '2/2 • ${_tr('tabGita', currentLang)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C2D12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        // Secondary Share Button
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF8B1E1E), width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                foregroundColor: const Color(0xFF8B1E1E),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () => _shareContent(context, displayInfo, gita, currentLang),
                              icon: const Icon(Icons.share_rounded, size: 16),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _tr('shareBtn', currentLang),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Primary Darshan / Blessing Button
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1E1E),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(0xFF8B1E1E).withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.temple_hindu_rounded, size: 17, color: Color(0xFFFFD700)),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _tr('darshanBtn', currentLang),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                                ),
                              ),
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

  // ==========================================
  // PAGE 1: DAY'S SPECIAL
  // ==========================================
  Widget _buildDaysSpecialPage(
    BuildContext context,
    SpecialDayInfo displayInfo,
    String currentLang,
    TempleTheme templeTheme,
    SongRepository songRepo,
    AudioPlayerService player,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Festival Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 13),
                    const SizedBox(width: 5),
                    Text(
                      displayInfo.badgeText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title & Subtitle
          Text(
            displayInfo.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E0A0A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayInfo.subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A4A1E),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 12),

          // Presiding Deity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0C080), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.temple_hindu_rounded, size: 18, color: Color(0xFF8B1E1E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayInfo.deity,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5E1010),
                    ),
                  ),
                ),
                if (displayInfo.auspiciousColor != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8C898)),
                    ),
                    child: Text(
                      displayInfo.auspiciousColor!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1E1E),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // PROMINENT INVITATION TO VIEW BHAGAVAD GITA (PAGE 2)
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B1E1E), Color(0xFFB8860B)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B1E1E).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Color(0xFFFFD700), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('gitaPagePromptTitle', currentLang).replaceAll('{day}', '$_shlokaNumber'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tr('gitaPagePromptSubtitle', currentLang),
                          style: const TextStyle(
                            color: Color(0xFFFFE8D6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Sacred Significance Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2C99A), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFFB8860B)),
                    const SizedBox(width: 6),
                    Text(
                      _tr('significance', currentLang),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A4A1E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  displayInfo.significance,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2C1810),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Auspicious Rituals Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2C99A), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.spa_rounded, size: 16, color: Color(0xFF8B1E1E)),
                    const SizedBox(width: 6),
                    Text(
                      _tr('rituals', currentLang),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1E1E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...displayInfo.rituals.map(
                  (ritual) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🪔 ',
                          style: TextStyle(fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            ritual,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF3A2015),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Sacred Japa Mantra Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF5E6), Color(0xFFFFECC8)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Color(0xFF8B1E1E)),
                        const SizedBox(width: 6),
                        Text(
                          _tr('mantra', currentLang),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B1E1E),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF8B1E1E)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Copy Mantra',
                      onPressed: () {
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
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  displayInfo.mantra,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A1010),
                    fontFamily: 'serif',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Recommended Stotram Listening Card
          if (displayInfo.recommendedStotram != null) ...[
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final songs = songRepo.allSongs;
                if (songs.isEmpty) return const SizedBox.shrink();
                final targetSong = songs.firstWhere(
                  (s) => s.title.toLowerCase().contains(displayInfo.recommendedStotram!.toLowerCase()),
                  orElse: () => songs.first,
                );

                return InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    player.playSong(targetSong);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B1E1E), Color(0xFF5E1010)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B1E1E).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFE8D6),
                                ),
                              ),
                              Text(
                                targetSong.getLocalizedTitle(currentLang),
                                style: const TextStyle(
                                  fontSize: 13,
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

          // Sacred Ritual & Deity Notification Card
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final reminders = context.read<DevotionalReminderService>();
              await reminders.sendCurrentDaySpecialityNotification(currentLang);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _tr('ritualReminderSent', currentLang),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF4A1010),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA580C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('remindRitualTitle', currentLang),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C2D12),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tr('remindRitualSubtitle', currentLang),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFFEA580C)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 2: BHAGAVAD GITA (SHLOKAS 1 - 701)
  // ==========================================
  Widget _buildBhagavadGitaPage(
    BuildContext context,
    BhagavadGitaVerse gita,
    String currentLang,
    TempleTheme templeTheme,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shloka Header Badge & Day Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const Text('🕉️ ', style: TextStyle(fontSize: 11)),
                    Text(
                      'ದಿನ $_shlokaNumber • ಶ್ಲೋಕ $_shlokaNumber (೭೦೧ ರಲ್ಲಿ)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoadingGita)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B1E1E)),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Chapter & Theme
          Text(
            gita.getChapterName(currentLang),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E0A0A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF0C080), width: 1),
                ),
                child: Text(
                  gita.getReference(currentLang),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B1E1E),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  gita.getTheme(currentLang),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A4A1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Original Sanskrit Shloka Card in Devanagari
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF9ED), Color(0xFFFFECC8)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB8860B).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                SelectableText(
                  gita.sanskrit,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A1010),
                    fontFamily: 'serif',
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                ),
                if (currentLang != 'sa' &&
                    gita.verseByLang.containsKey(currentLang) &&
                    gita.verseByLang[currentLang] != gita.sanskrit) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFFD4AF37), thickness: 0.7),
                  ),
                  SelectableText(
                    gita.verseByLang[currentLang]!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C2D12),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // TTS Audio Chanting & Copy Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlayingGitaAudio
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF8B1E1E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () => _togglePlayGitaShloka(gita.sanskrit, currentLang),
                    icon: Icon(
                      _isPlayingGitaAudio ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _isPlayingGitaAudio
                          ? _tr('stopAudio', currentLang)
                          : _tr('listenAudio', currentLang),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B1E1E), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: const Color(0xFF8B1E1E),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(
                      text: '${gita.sanskrit}\n\n${gita.getMeaning(currentLang)}',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_tr('shlokaCopied', currentLang)),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    'Copy',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Sacred Meaning Card in User's Selected Language
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2C99A), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF8B1E1E)),
                    const SizedBox(width: 6),
                    Text(
                      _tr('gitaMeaning', currentLang),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1E1E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  gita.getMeaning(currentLang).isNotEmpty
                      ? gita.getMeaning(currentLang)
                      : gita.getMeaning('en'),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF2C1810),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Previous / Next Shloka Navigation Bar (Allows reading all 701 Gita verses)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_shlokaNumber > 1)
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _shlokaNumber -= 1);
                    _fetchShloka(_shlokaNumber, currentLang);
                  },
                  icon: const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF8B1E1E)),
                  label: Text(
                    'ಶ್ಲೋಕ ${_shlokaNumber - 1}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1E1E)),
                  ),
                )
              else
                const SizedBox.shrink(),

              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _shlokaNumber = (_shlokaNumber % 701) + 1);
                  _fetchShloka(_shlokaNumber, currentLang);
                },
                icon: Text(
                  'ಶ್ಲೋಕ ${(_shlokaNumber % 701) + 1}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1E1E)),
                ),
                label: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF8B1E1E)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Return to Page 1 (Day's Special) CTA Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFB8860B), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF8B1E1E)),
            label: Text(
              _tr('backToSpecial', currentLang),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1E1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
