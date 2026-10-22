import 'dart:convert';
import 'package:http/http.dart' as http;
import '../panchanga/panchanga_service.dart';

/// Comprehensive Model for a Sacred Special Day / Festival
class SpecialDayInfo {
  final String id;
  final String title;
  final String subtitle;
  final String deity;
  final String significance;
  final List<String> rituals;
  final String mantra;
  final String? auspiciousColor;
  final String? recommendedStotram;
  final String badgeText;
  final DateTime? date;

  const SpecialDayInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.deity,
    required this.significance,
    required this.rituals,
    required this.mantra,
    this.auspiciousColor,
    this.recommendedStotram,
    this.badgeText = 'ಪವಿತ್ರ ಪರ್ವದಿನ',
    this.date,
  });
}

/// On-Device Vedic Festival & Special Day Intelligence Service
/// Computes astronomical ephemeris and extracts live time/calendar details on device.
/// Fully localized across Kannada (kn), Tamil (ta), Telugu (te), Hindi (hi), Malayalam (ml), and English (en).
class SpecialDayIntelligenceService {
  /// Returns SpecialDayInfo if today is an auspicious/special day; otherwise returns null.
  static Future<SpecialDayInfo?> getTodaySpecialDay(String lang, {DateTime? testDate}) async {
    final now = testDate ?? DateTime.now();

    // 1. Live online extraction of accurate Indian Standard Time (IST) & calendar day on device
    DateTime evaluatedDate = now;
    try {
      final res = await http
          .get(Uri.parse('https://timeapi.io/api/Time/current/zone?timeZone=Asia/Kolkata'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['dateTime'] != null) {
          evaluatedDate = DateTime.parse(data['dateTime'] as String).toLocal();
        }
      }
    } catch (_) {
      // Robust offline fallback: Device local clock
      evaluatedDate = now;
    }

    final festival = evaluateForDate(evaluatedDate, lang);
    if (festival != null) return festival;
    return _getDailyVedicBlessing(evaluatedDate.weekday, lang, evaluatedDate);
  }

  /// Evaluates special day based on astronomical ephemeris
  static SpecialDayInfo? evaluateForDate(DateTime evaluatedDate, String lang) {
    // 2. High-Precision Astronomical Ephemeris Calculation
    final astro = VedicAstroEngine.calculateEphemeris(evaluatedDate);
    final eveningAstro = VedicAstroEngine.calculateEphemeris(
      DateTime(evaluatedDate.year, evaluatedDate.month, evaluatedDate.day, 20, 0),
    );

    final int tithiNum = astro['tithiNum'] as int;
    final bool isKrishna = astro['isKrishna'] as bool;
    final int weekday = evaluatedDate.weekday;
    final double sunNirayana = (astro['sunNirayana'] as num).toDouble();

    // Solar month (Masa index based on Nirayana Sun longitude: 0 = Mesha, 5 = Kanya, 6 = Thula...)
    final int solarMasaIndex = (sunNirayana / 30.0).floor() % 12;

    // --- CHECK 1: Sharad Navratri / Dasara (10 Days) ---
    // Ashvina / Ashwayuja Shukla Pratipada (1) to Dashami (10)
    final bool isAshwayujaSeason = (solarMasaIndex == 5 || solarMasaIndex == 6) &&
        (evaluatedDate.month == 9 || evaluatedDate.month == 10 || evaluatedDate.month == 11);

    if (isAshwayujaSeason && !isKrishna && tithiNum >= 1 && tithiNum <= 10) {
      return _getDasaraDayInfo(tithiNum, lang, evaluatedDate, weekday);
    }

    // --- CHECK 2: Mahalaya Amavasya (Sarva Pitru Amavasya) ---
    if (isAshwayujaSeason && isKrishna && tithiNum == 15) {
      return _getMahalayaAmavasyaInfo(lang, evaluatedDate);
    }

    // Other Amavasya in year
    if (isKrishna && tithiNum == 15) {
      return _getAmavasyaInfo(weekday, lang, evaluatedDate);
    }

    // --- CHECK 3: Deepavali Festive Days ---
    if ((solarMasaIndex == 6 || solarMasaIndex == 7) &&
        (evaluatedDate.month == 10 || evaluatedDate.month == 11)) {
      if (isKrishna && tithiNum == 13) {
        return _getDhanterasInfo(lang, evaluatedDate);
      } else if (isKrishna && tithiNum == 14) {
        return _getNarakaChaturdashiInfo(lang, evaluatedDate);
      } else if (isKrishna && tithiNum == 15) {
        return _getLakshmiPoojaInfo(lang, evaluatedDate);
      } else if (!isKrishna && tithiNum == 1) {
        return _getBaliPadyamiInfo(lang, evaluatedDate);
      }
    }

    // --- CHECK 4: Maha Shivaratri ---
    if ((evaluatedDate.month == 2 || evaluatedDate.month == 3) && isKrishna && tithiNum == 14) {
      return _getMahaShivaratriInfo(lang, evaluatedDate);
    }

    // --- CHECK 5: Ganesha Chaturthi ---
    if ((evaluatedDate.month == 8 || evaluatedDate.month == 9) && !isKrishna && tithiNum == 4) {
      return _getGaneshChaturthiInfo(lang, evaluatedDate);
    }

    // --- CHECK 6: Sri Krishna Janmashtami ---
    if ((evaluatedDate.month == 8 || evaluatedDate.month == 9) && isKrishna && tithiNum == 8) {
      return _getKrishnaJanmashtamiInfo(lang, evaluatedDate);
    }

    // --- CHECK 7: Sri Rama Navami ---
    if ((evaluatedDate.month == 3 || evaluatedDate.month == 4) && !isKrishna && tithiNum == 9) {
      return _getRamaNavamiInfo(lang, evaluatedDate);
    }

    // --- CHECK 8: Ugadi / Gudi Padwa ---
    if ((evaluatedDate.month == 3 || evaluatedDate.month == 4) && !isKrishna && tithiNum == 1) {
      return _getUgadiInfo(lang, evaluatedDate);
    }

    // --- CHECK 9: Makara Sankranti ---
    if (evaluatedDate.month == 1 && (evaluatedDate.day == 14 || evaluatedDate.day == 15)) {
      return _getMakaraSankrantiInfo(lang, evaluatedDate);
    }

    // --- CHECK 10: Ekadashi Vrata ---
    if (tithiNum == 11) {
      return _getEkadashiInfo(isKrishna, lang, evaluatedDate);
    }

    // --- CHECK 11: Pradosha Vrata ---
    if (tithiNum == 13) {
      return _getPradoshaInfo(weekday, lang, evaluatedDate);
    }

    // --- CHECK 12: Sankashti Chaturthi ---
    final bool isEveningKrishnaChaturthi =
        (eveningAstro['isKrishna'] as bool) && (eveningAstro['tithiNum'] as int == 4);
    if (isEveningKrishnaChaturthi) {
      return _getSankashtiInfo(weekday == DateTime.tuesday, lang, evaluatedDate);
    }

    // --- CHECK 13: Purnima ---
    if (!isKrishna && tithiNum == 15) {
      return _getPurnimaInfo(lang, evaluatedDate);
    }

    return null;
  }

  /// Dynamically re-localizes an existing SpecialDayInfo to another language
  static SpecialDayInfo? getLocalizedInfo(String id, String lang, {DateTime? date}) {
    final evaluatedDate = date ?? DateTime.now();
    final weekday = evaluatedDate.weekday;

    if (id.startsWith('dasara_day_')) {
      final dayNum = int.tryParse(id.replaceFirst('dasara_day_', '')) ?? 1;
      return _getDasaraDayInfo(dayNum, lang, evaluatedDate, weekday);
    } else if (id == 'mahalaya_amavasya') {
      return _getMahalayaAmavasyaInfo(lang, evaluatedDate);
    } else if (id == 'krishna_ekadashi' || id == 'shukla_ekadashi') {
      return _getEkadashiInfo(id == 'krishna_ekadashi', lang, evaluatedDate);
    } else if (id == 'pradosha_vrata') {
      return _getPradoshaInfo(weekday, lang, evaluatedDate);
    } else if (id == 'sankashti_chaturthi') {
      return _getSankashtiInfo(weekday == DateTime.tuesday, lang, evaluatedDate);
    } else if (id == 'purnima_day') {
      return _getPurnimaInfo(lang, evaluatedDate);
    } else if (id == 'amavasya_day') {
      return _getAmavasyaInfo(weekday, lang, evaluatedDate);
    } else if (id == 'dhanteras') {
      return _getDhanterasInfo(lang, evaluatedDate);
    } else if (id == 'naraka_chaturdashi') {
      return _getNarakaChaturdashiInfo(lang, evaluatedDate);
    } else if (id == 'lakshmi_pooja') {
      return _getLakshmiPoojaInfo(lang, evaluatedDate);
    } else if (id == 'bali_padyami') {
      return _getBaliPadyamiInfo(lang, evaluatedDate);
    } else if (id == 'maha_shivaratri') {
      return _getMahaShivaratriInfo(lang, evaluatedDate);
    } else if (id == 'ganesh_chaturthi') {
      return _getGaneshChaturthiInfo(lang, evaluatedDate);
    } else if (id == 'krishna_janmashtami') {
      return _getKrishnaJanmashtamiInfo(lang, evaluatedDate);
    } else if (id == 'rama_navami') {
      return _getRamaNavamiInfo(lang, evaluatedDate);
    } else if (id == 'ugadi') {
      return _getUgadiInfo(lang, evaluatedDate);
    } else if (id == 'makara_sankranti') {
      return _getMakaraSankrantiInfo(lang, evaluatedDate);
    } else if (id.startsWith('daily_vedic_')) {
      return _getDailyVedicBlessing(weekday, lang, evaluatedDate);
    }

    return _getDailyVedicBlessing(weekday, lang, evaluatedDate);
  }

  // ==========================================
  // AUTHENTIC NAVRATRI COLOR CALCULATION
  // ==========================================

  /// In traditional Vedic calendar and temple practice, Navratri 9 colors are governed by
  /// the weekday of that specific day:
  /// Sunday: Orange | Monday: White | Tuesday: Red | Wednesday: Royal Blue
  /// Thursday: Yellow | Friday: Green | Saturday: Grey
  static Map<String, String> getNavratriColorForDay(int dayNum, int weekday) {
    if (dayNum == 10) {
      return {
        'kn': 'ಬಂಗಾರ / ಕೇಸರಿ (Golden / Saffron)',
        'ta': 'தங்கம் / காவி (Golden / Saffron)',
        'te': 'బంగారు / కాషాయం (Golden / Saffron)',
        'hi': 'स्वर्ण / भगवा (Golden / Saffron)',
        'ml': 'സ്വർണ്ണം / കാവി (Golden / Saffron)',
        'en': 'Golden / Saffron',
      };
    }

    switch (weekday) {
      case DateTime.monday:
        return {
          'kn': 'ಬಿಳಿ (White)',
          'ta': 'வெள்ளை (White)',
          'te': 'తెలుపు (White)',
          'hi': 'सफेद (White)',
          'ml': 'വെള്ള (White)',
          'en': 'White',
        };
      case DateTime.tuesday:
        return {
          'kn': 'ಕೆಂಪು (Red)',
          'ta': 'சிவப்பு (Red)',
          'te': 'ఎరుపు (Red)',
          'hi': 'लाल (Red)',
          'ml': 'ചുവപ്പ് (Red)',
          'en': 'Red',
        };
      case DateTime.wednesday:
        return {
          'kn': 'ನೀಲಿ (Royal Blue)',
          'ta': 'நீலம் (Royal Blue)',
          'te': 'రాయల్ బ్లూ (Royal Blue)',
          'hi': 'नीला (Royal Blue)',
          'ml': 'റോയൽ ബ്ലൂ (Royal Blue)',
          'en': 'Royal Blue',
        };
      case DateTime.thursday:
        return {
          'kn': 'ಹಳದಿ (Yellow)',
          'ta': 'மஞ்சள் (Yellow)',
          'te': 'పసుపు (Yellow)',
          'hi': 'पीला (Yellow)',
          'ml': 'മഞ്ഞ (Yellow)',
          'en': 'Yellow',
        };
      case DateTime.friday:
        return {
          'kn': 'ಹಸಿರು (Green)',
          'ta': 'பச்சை (Green)',
          'te': 'ఆకుపచ్చ (Green)',
          'hi': 'हरा (Green)',
          'ml': 'പച്ച (Green)',
          'en': 'Green',
        };
      case DateTime.saturday:
        return {
          'kn': 'ಬೂದು / ಬೆಳ್ಳಿ (Grey/Silver)',
          'ta': 'சாம்பல் (Grey/Silver)',
          'te': 'బూడిద రంగు (Grey/Silver)',
          'hi': 'स्लेटी (Grey/Silver)',
          'ml': 'ഗ്രേ (Grey/Silver)',
          'en': 'Grey/Silver',
        };
      case DateTime.sunday:
      default:
        return {
          'kn': 'ಕಿತ್ತಳೆ (Orange)',
          'ta': 'ஆரஞ்சு (Orange)',
          'te': 'నారింజ (Orange)',
          'hi': 'नारंगी (Orange)',
          'ml': 'ഓറഞ്ച് (Orange)',
          'en': 'Orange',
        };
    }
  }

  // ==========================================
  // DASARA NAVRATRI MULTI-LANGUAGE DEFINITIONS
  // ==========================================

  static SpecialDayInfo _getDasaraDayInfo(int dayNum, String lang, DateTime date, int weekday) {
    final colorMap = getNavratriColorForDay(dayNum, weekday);
    final colorText = colorMap[lang] ?? colorMap['en']!;

    final Map<int, Map<String, dynamic>> dasaraDays = {
      1: {
        'title': {
          'kn': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೧ (ಪಾಡ್ಯ)',
          'ta': 'தசரா நவராத்திரி – நாள் ௧ (பிரதமை)',
          'te': 'దసరా నవరాత్రి – రోజు ౧ (పాడ్యమి)',
          'hi': 'दशहरा नवरात्रि – प्रथम दिवस (प्रतिपदा)',
          'ml': 'ദസറ നവരാത്രി – ഒന്നാം ദിനം (പ്രഥമ)',
          'en': 'Dasara Navratri – Day 1 (Pratipada)',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಶೈಲಪುತ್ರಿ ದೇವಿ (ಘಟಸ್ಥಾಪನ)',
          'ta': 'ஸ்ரீ ஷைலபுத்ரி தேவி (கடஸ்தாபனம்)',
          'te': 'శ్రీ శైలపుత్రి దేవి (ఘటస్థాపన)',
          'hi': 'माता शैलपुत्री (घटस्थापना)',
          'ml': 'ശ്രീ ശൈലപുത്രി ദേവി (ഘടസ്ഥാപനം)',
          'en': 'Goddess Shailaputri (Ghatasthapana)',
        },
        'sig': {
          'kn': 'ನವರಾತ್ರಿಯ ಮೊದಲನೇ ದಿನ. ಪರ್ವತರಾಜ ಹಿಮವಂತನ ಪುತ್ರಿಯಾದ ಶೈಲಪುತ್ರಿ ದೇವಿಯು ಭಕ್ತರಿಗೆ ಧೈರ್ಯ, ಸ್ಥಿರತೆ ಹಾಗೂ ಆಧ್ಯಾತ್ಮಿಕ ಶಕ್ತಿಯನ್ನು ಕರುಣಿಸುತ್ತಾಳೆ.',
          'ta': 'நவராத்திரியின் முதல் நாள். இமயமலையின் மகளான ஷைலபுத்ரி தேவி, பக்தர்களுக்கு மன தைரியம், ஆன்மீக உறுதி மற்றும் அமைதியை அருளுகிறாள்.',
          'te': 'నవరాత్రుల మొదటి రోజు. హిమవంతుని కుమార్తె అయిన శైలపుత్రి దేవి భక్తులకు ధైర్యం, స్థిరత్వం మరియు ఆధ్యాత్మిక శక్తిని ప్రసాదిస్తుంది.',
          'hi': 'नवरात्रि का प्रथम पावन दिन। हिमालय सुपुत्री माता शैलपुत्री की उपासना से जीवन में स्थिरता, तेज और मनोबल की प्राप्ति होती है।',
          'ml': 'നവരാത്രിയുടെ ഒന്നാം ദിനം. ശൈലപുത്രി ദേവി ഭക്തർക്ക് ആത്മവിശ്വാസവും ആത്മീയ ശക്തിയും നൽകുന്നു.',
          'en': 'First day of Navratri dedicated to Maa Shailaputri, embodiment of nature and Himalayas, granting spiritual stability and resolve.',
        },
        'rituals': {
          'kn': ['ಕಳಸ ಸ್ಥಾಪನೆ & ಅಖಂಡ ದೀಪಾರಾಧನೆ', 'ದೇವಿಗೆ ಶುದ್ಧ ಹಸುವಿನ ತುಪ್ಪದ ನೈವೇದ್ಯ', 'ಕುಂಕುಮಾರ್ಚನೆ'],
          'ta': ['கலச ஸ்தாபனம் & அகண்ட தீப வழிபாடு', 'தூய பசும் நெய் நைவேத்தியம்', 'குங்கும அர்ச்சனை'],
          'te': ['కలశ స్థాపన & అఖండ దీపారాధన', 'స్వచ్ఛమైన ఆవు నెయ్యి నైవేద్యం', 'కుంకుమార్చన'],
          'hi': ['घटस्थापना एवं अखंड दीप प्रज्ज्वलन', 'शुद्ध गौघृत का भोग', 'दुर्गा सप्तशती पाठ'],
          'ml': ['കലശ സ്ഥാപനവും ദീപാരാധനയും', 'നെയ്യ് നിവേദ്യം', 'കുങ്കുമാർച്ചന'],
          'en': ['Kalasha Sthapana & Akhanda Deepa', 'Offering pure cow ghee naivedya', 'Kumkumarchana prayers'],
        },
        'mantra': 'ಓಂ ದೇವಿ ಶೈಲಪುತ್ರ್ಯೈ ನಮಃ • Om Devi Shailaputryai Namah',
        'stotram': 'Sri Lalitha Sahasranama Stotram',
      },
      2: {
        'title': {
          'kn': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೨ (ಬಿದಿಗೆ)',
          'ta': 'தசரா நவராத்திரி – நாள் ௨ (துவிதியை)',
          'te': 'దసరా నవరాత్రి – రోజు ౨ (విదియ)',
          'hi': 'दशहरा नवरात्रि – द्वितीय दिवस (द्वितीया)',
          'ml': 'ദസറ നവരാത്രി – രണ്ടാം ദിനം (ദ്വിതീയ)',
          'en': 'Dasara Navratri – Day 2 (Dwitiya)',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಬ್ರಹ್ಮಚಾರಿಣಿ ದೇವಿ',
          'ta': 'ஸ்ரீ பிரம்மச்சாரிணி தேவி',
          'te': 'శ్రీ బ్రహ్మచారిణి దేవి',
          'hi': 'माता ब्रह्मचारिणी',
          'ml': 'ശ്രീ ബ്രഹ്മചാരിണി ദേവി',
          'en': 'Goddess Brahmacharini',
        },
        'sig': {
          'kn': 'ತಪಸ್ಸು ಮತ್ತು ಧ್ಯಾನದ ಅಧಿದೇವತೆ ಬ್ರಹ್ಮಚಾರಿಣಿ. ಭಕ್ತರಲ್ಲಿ ಜ್ಞಾನ, ಸಂಯಮ, ಸತ್ಯಾಗ್ರಹ ಹಾಗೂ ಮನಶ್ಶಾಂತಿಯನ್ನು ಜಾಗೃತಗೊಳಿಸುತ್ತಾಳೆ.',
          'ta': 'தவமும் தியானமும் நிறைந்த அன்னை பிரம்மச்சாரிணி. பக்தர்களுக்கு ஞானம், மன உறுதி, சுயக்கட்டுப்பாடு மற்றும் அமைதியை அருளுகிறாள்.',
          'te': 'తపస్సు మరియు ధ్యానానికి అధిదేవత బ్రహ్మచారిణి. భక్తులలో జ్ఞానం, సంయమనం, సత్యనిష్ఠ మరియు మనశ్శాంతిని జాగృతం చేస్తుంది.',
          'hi': 'तपस्या और वैराग्य की देवी ब्रह्मचारिणी। इनकी आराधना से तप, त्याग, सदाचार और संयम की वृद्धि होती है।',
          'ml': 'തപസ്സിന്റെയും ധ്യാനത്തിന്റെയും അധിദേവതയായ ബ്രഹ്മചാരിണി. ഭക്തർക്ക് ജ്ഞാനവും മനഃശാന്തിയും ഏകാഗ്രതയും നൽകുന്നു.',
          'en': 'Second day celebrating Maa Brahmacharini, embodiment of divine penance and meditation. Bestows wisdom, calm, and inner spiritual strength.',
        },
        'rituals': {
          'kn': ['ಸಕ್ಕರೆ ಹಾಗೂ ಕಲ್ಲುಸಕ್ಕರೆ ನೈವೇದ್ಯ', 'ಜಪಮಾಲೆಯಿಂದ ಗಾಯತ್ರೀ ಜಪ', 'ಶಾಂತಿ ಪೂಜೆ'],
          'ta': ['சர்க்கரை மற்றும் கற்கண்டு நைவேத்தியம்', 'ஜெபமாலையுடன் காயத்ரி ஜெபம்', 'சாந்தி பூஜை மற்றும் தேவி ஆராதனை'],
          'te': ['చక్కెర మరియు కలకండ నైవేద్యం', 'జపమాలతో గాయత్రీ జపం', 'శాంతి పూజ మరియు దేవీ ఆరాధన'],
          'hi': ['शर्करा एवं मिश्री का भोग', 'गायत्री एवं देवी मंत्र जप', 'संध्या आरती एवं शांति पूजा'],
          'ml': ['പഞ്ചസാരയും കൽക്കണ്ടവും നിവേദ്യം', 'ജപമാലയോടെ ഗായത്രീ ജപം', 'ശാന്തി പൂജയും ദേവീ സ്തോത്രവും'],
          'en': ['Sugar and rock sugar sweet offerings', 'Gayatri Mantra chanting with prayer beads', 'Chanting Devi Suktam & evening Aarti'],
        },
        'mantra': 'ಓಂ ದೇವಿ ಬ್ರಹ್ಮಚಾರಿಣ್ಯೈ ನಮಃ • Om Devi Brahmacharinyai Namah',
        'stotram': 'Durga Suktam',
      },
      3: {
        'title': {
          'kn': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೩ (ತದಿಗೆ)',
          'ta': 'தசரா நவராத்திரி – நாள் ௩ (திருதியை)',
          'te': 'దసరా నవరాత్రి – రోజు ౩ (తదియ)',
          'hi': 'दशहरा नवरात्रि – तृतीय दिवस (तृतीया)',
          'ml': 'ദസറ നവരാത്രി – മൂന്നാം ദിനം (തൃതീയ)',
          'en': 'Dasara Navratri – Day 3 (Tritiya)',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಚಂದ್ರಘಂಟಾ ದೇವಿ',
          'ta': 'ஸ்ரீ சந்திரகண்டா தேவி',
          'te': 'శ్రీ చంద్రఘంటా దేవి',
          'hi': 'माता चंद्रघंटा',
          'ml': 'ശ്രീ ചന്ദ്രഘണ്ഡാ ദേവി',
          'en': 'Goddess Chandraghanta',
        },
        'sig': {
          'kn': 'ಹಣೆ ಮೇಲೆ ಗಂಟೆಯಾಕಾರದ ಚಂದ್ರನನ್ನು ಧರಿಸಿದ ಚಂದ್ರಘಂಟಾ ದೇವಿ. ಸಕಲ ಭಯ, ನಕಾರಾತ್ಮಕ ಶಕ್ತಿಗಳನ್ನು ನಾಶಮಾಡಿ ಧೈರ್ಯವನ್ನು ನೀಡುತ್ತಾಳೆ.',
          'ta': 'நெற்றியில் மணி போன்ற பிறைச்சந்திரனை அணிந்த சந்திரகண்டா தேவி. பயங்களை போக்கி தைரியத்தையும் பாதுகாப்பையும் தருகிறாள்.',
          'te': 'నుదుటిపై గంటాకార చంద్రుడిని ధరించిన చంద్రఘంటా దేవి. సమస్త భయాలను పోగొట్టి ధైర్యాన్ని ప్రసాదిస్తుంది.',
          'hi': 'मस्तक पर घंटे के आकार का अर्धचंद्र धारण करने वाली मां चंद्रघंटा। भयमुक्ति, साहस और शांति प्रदान करती हैं।',
          'ml': 'ചന്ദ്രഘണ്ഡാ ദേവി സകല ഭയങ്ങളെയും ഇല്ലാതാക്കി ധൈര്യം പകരുന്നു.',
          'en': 'Maa Chandraghanta carries a half-moon shaped like a bell. Removes fear, anxiety, and all negative vibrations.',
        },
        'rituals': {
          'kn': ['ಹಾಲು ಅಥವಾ ಹಾಲಿನ ಪಾಯಸದ ನೈವೇದ್ಯ', 'ಕಂಚಿನ ಗಂಟೆಯ ನಾದದೊಂದಿಗೆ ಮಂಗಳಾರತಿ'],
          'ta': ['பால் பாயாசம் நைவேத்தியம்', 'மணி ஓசையுடன் தீபாராதனை'],
          'te': ['పాల పాయసం నైవేద్యం', 'గంటానాదంతో మంగళహారతి'],
          'hi': ['दुग्ध निर्मित खीर का भोग', 'घंटा नाद के साथ मंगल आरती'],
          'ml': ['പാൽപ്പായസം നിവേദ്യം', 'മണിനാദത്തോടെ ദീപാരാധന'],
          'en': ['Milk kheer offering', 'Ringing temple bells during Aarti', 'Protection prayers'],
        },
        'mantra': 'ಓಂ ದೇವಿ ಚಂದ್ರಘಂಟಾಯೈ ನಮಃ • Om Devi Chandraghantayai Namah',
        'stotram': 'Mahishasura Mardini Stotram',
      },
      4: {
        'title': {
          'kn': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೪ (ಚೌತಿ)',
          'ta': 'தசரா நவராத்திரி – நாள் ௪ (சதுர்த்தி)',
          'te': 'దసరా నవరాత్రి – రోజు ౪ (చవితి)',
          'hi': 'दशहरा नवरात्रि – चतुर्थ दिवस (चतुर्थी)',
          'ml': 'ദസറ നവരാത്രി – നാലാം ദിനം (ചതുർത്ഥി)',
          'en': 'Dasara Navratri – Day 4 (Chaturthi)',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಕೂಷ್ಮಾಂಡಾ ದೇವಿ',
          'ta': 'ஸ்ரீ கூஷ்மாண்டா தேவி',
          'te': 'శ్రీ కూష్మాండా దేవి',
          'hi': 'माता कूष्माण्डा',
          'ml': 'ശ്രീ കൂഷ്മാണ്ഡാ ദേവി',
          'en': 'Goddess Kushmanda',
        },
        'sig': {
          'kn': 'ತನ್ನ ಮಂದಹಾಸದಿಂದ ಬ್ರಹ್ಮಾಂಡವನ್ನೇ ಸೃಷ್ಟಿಸಿದ ಜಗದಂಬೆ ಕೂಷ್ಮಾಂಡಾ ದೇವಿ. ದಾರಿದ್ರ್ಯ, ರೋಗ-ರುಜಿನಗಳನ್ನು ಪರಿಹರಿಸಿ ಆಯುರಾರೋಗ್ಯ ಕರುಣಿಸುತ್ತಾಳೆ.',
          'ta': 'தன் புன்னகையினால் அண்டத்தை உருவாக்கிய கூஷ்மாண்டா தேவி. நோய்களை தீர்த்து ஆரோக்கியத்தையும் வளத்தையும் அருள்கிறாள்.',
          'te': 'తమ చిరునవ్వుతో సమస్త బ్రహ్మాండాన్ని సృష్టించిన కూష్మాండా దేవి. వ్యాధులను నివారించి ఆయురారోగ్యాలు ప్రసాదిస్తుంది.',
          'hi': 'अपनी मंद मुस्कान से ब्रह्मांड की रचना करने वाली मां कूष्माण्डा। आरोग्य, आयु और यश की प्राप्ति होती है।',
          'ml': 'കൂഷ്മാണ്ഡാ ദേവി സർവ്വ രോഗങ്ങളെയും ദാരിദ്ര്യത്തെയും അകറ്റുന്നു.',
          'en': 'Maa Kushmanda created the universe with her gentle divine smile. Illuminates the soul and removes illness.',
        },
        'rituals': {
          'kn': ['ಮಾಲ್ಪುವಾ ಅಥವಾ ಕುಂಬಳಕಾಯಿ ಸಿಹಿ ನೈವೇದ್ಯ', 'ಸೂರ್ಯ ನಮಸ್ಕಾರ & ದೇವಿಯ ಆರಾಧನೆ'],
          'ta': ['பூசணிக்காய் இனிப்பு நைவேத்தியம்', 'சூரிய நமஸ்காரம் & தேவி வழிபாடு'],
          'te': ['గుమ్మడికాయ ప్రసాదం', 'సూర్య నమస్కారాలు & దేవీ ఆరాధన'],
          'hi': ['मालपुए का भोग', 'सूर्य नमस्कार एवं देवी आराधना'],
          'ml': ['മത്തങ്ങ മധുരം നിവേദ്യം', 'സൂര്യനമസ്കാരവും ദേവീ പൂജയും'],
          'en': ['Sweet pumpkin or Malpua offering', 'Surya and Devi prayers', 'Deeparadhana'],
        },
        'mantra': 'ಓಂ ದೇವಿ ಕೂಷ್ಮಾಂಡಾಯೈ ನಮಃ • Om Devi Kushmandayai Namah',
        'stotram': 'Soundarya Lahari',
      },
      5: {
        'title': {
          'kn': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೫ (ಪಂಚಮಿ)',
          'ta': 'தசரா நவராத்திரி – நாள் ௫ (பஞ்சமி)',
          'te': 'దసరా నవరాత్రి – రోజు ౫ (పంచమి)',
          'hi': 'दशहरा नवरात्रि – पंचम दिवस (पंचमी)',
          'ml': 'ദസറ നവരാത്രി – അഞ്ചാം ദിനം (പഞ്ചമി)',
          'en': 'Dasara Navratri – Day 5 (Panchami)',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಸ್ಕಂದಮಾತಾ (ಉಪಾಂಗ ಲಲಿತಾ ವ್ರತ)',
          'ta': 'ஸ்ரீ ஸ்கந்தமாதா (உபாங்க லலிதா விரதம்)',
          'te': 'శ్రీ స్కందమాత (ఉపాంగ లలితా వ్రతం)',
          'hi': 'माता स्कंदमाता (उपांग ललिता व्रत)',
          'ml': 'ശ്രീ സ്കന്ദമാതാ (ഉപാംഗ ലളിതാ വ്രതം)',
          'en': 'Goddess Skandamata',
        },
        'sig': {
          'kn': 'ಕಾರ್ತಿಕೇಯ (ಸ್ಕಂದ) ದೇವರ ಮಾತೆಯಾದ ಸ್ಕಂದಮಾತೆ. ಭಕ್ತರಿಗೆ ಮಾತೃವಾತ್ಸಲ್ಯ, ಸಂತಾನ ಸೌಭಾಗ್ಯ ಹಾಗೂ ಅಂತಿಮ ಮುಕ್ತಿಯನ್ನು ಕರುಣಿಸುತ್ತಾಳೆ.',
          'ta': 'முருகப்பெருமானின் (ஸ்கந்தன்) தாயான ஸ்கந்தமாதா. பக்தர்களுக்கு தாய்மை அன்பையும் சந்தான பாக்கியத்தையும் அருளுகிறாள்.',
          'te': 'కార్తికేయుని (స్కందుని) తల్లి అయిన స్కందమాత. భక్తులకు సంతాన సౌభాగ్యం మరియు మోక్షాన్ని ప్రసాదిస్తుంది.',
          'hi': 'भगवान कार्तिकेय की माता स्कंदमाता। पारिवारिक सुख, संतान की रक्षा और मोक्ष का वरदान देती हैं।',
          'ml': 'സുബ്രഹ്മണ്യന്റെ മാതാവായ സ്കന്ദമാതാവ് സകല ഐശ്വര്യങ്ങളും പ്രധാനം ചെയ്യുന്നു.',
          'en': 'Mother of Lord Skanda (Kartikeya). Showers maternal compassion, family prosperity, and spiritual liberation.',
        },
        'rituals': {
          'kn': ['ಬಾಳೆಹಣ್ಣು ನೈವೇದ್ಯ', 'ಉಪಾಂಗ ಲಲಿತಾ ವ್ರತ ಪೂಜೆ', 'ಮಕ್ಕಳಿಗೆ ಆಶೀರ್ವಾದ ಕೋರುವುದು'],
          'ta': ['வாழைப்பழ நைவேத்தியம்', 'உபாங்க லலிதா பூஜை', 'குழந்தைகளுக்கான ஆசி'],
          'te': ['అరటిపండు నైవేద్యం', 'ఉపాంగ లలితా వ్రత పూజ', 'సంతాన సౌభాగ్య ప్రార్థన'],
          'hi': ['केले का नैवेद्य', 'उपांग ललिता पूजन', 'संतान कल्याण प्रार्थना'],
          'ml': ['പഴം നിവേദ്യം', 'കുട്ടികൾക്കായുള്ള പ്രാർത്ഥന'],
          'en': ['Banana naivedya', 'Lalitha Vrata worship', 'Prayers for children wellbeing'],
        },
        'mantra': 'ಓಂ ದೇವಿ ಸ್ಕಂದಮಾತ್ರೈ ನಮಃ • Om Devi Skandamatryai Namah',
        'stotram': 'Sri Lalitha Trishati Stotram',
      },
      6: {
        'title': {
          'kn': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೬ (ಷಷ್ಠಿ)',
          'ta': 'தசரா நவராத்திரி – நாள் ௬ (சஷ்டி)',
          'te': 'దసరా నవరాత్రి – రోజు ౬ (షష్ఠి)',
          'hi': 'दशहरा नवरात्रि – षष्ठी दिवस (षष्ठी)',
          'ml': 'ദസറ നവരാത്രി – ആറാം ദിനം (ഷഷ്ഠി)',
          'en': 'Dasara Navratri – Day 6 (Shashthi)',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಕಾತ್ಯಾಯನಿ ದೇವಿ',
          'ta': 'ஸ்ரீ காத்யாயனி தேவி',
          'te': 'శ్రీ కాత్యాయని దేవి',
          'hi': 'माता कात्यायनी',
          'ml': 'ശ്രീ കാത്യായനി ദേവി',
          'en': 'Goddess Katyayani',
        },
        'sig': {
          'kn': 'ಕಾತ್ಯಾಯನ ಮಹರ್ಷಿಗಳ ಪುತ್ರಿಯಾಗಿ ಅವತರಿಸಿ ಮಹಿಷಾಸುರನನ್ನು ಸಂಹರಿಸಿದ ವೀರ ಮಾತೃಕೆ. ವಿವಾಹ ಪ್ರತಿಬಂಧಕ ನಿವಾರಣೆ ಹಾಗೂ ಶತ್ರುಜಯ ನೀಡುತ್ತಾಳೆ.',
          'ta': 'காத்யாயன முனிவரின் மகளாக அவதரித்து மகிஷாசுரனை வதைத்த தேவி. திருமணத் தடைகளை நீக்கி வெற்றியைத் தருகிறாள்.',
          'te': 'కాత్యాయన మహర్షి కుమార్తెగా అవతరించిన కాత్యాయని దేవి. వివాహ దోషాలను తొలగించి విజయాన్ని ప్రసాదిస్తుంది.',
          'hi': 'महर्षि कात्यायन की तपस्या से प्रकट मां कात्यायनी। शीघ्र विवाह योग, सुखी दांपत्य एवं शत्रु बाधा निवारण करती हैं।',
          'ml': 'കാത്യായനി ദേവി വിവാഹ തടസ്സങ്ങൾ നീക്കി ജയം നൽകുന്നു.',
          'en': 'Warrior deity who slayed demons. Removes delays in marriage and grants triumph over obstacles.',
        },
        'rituals': {
          'kn': ['ಜೇನುತುಪ್ಪದ ನೈವೇದ್ಯ', 'ಕೆಂಪು ದಾಸವಾಳ ಹೂವಿನ ಅರ್ಚನೆ', 'ವಿವಾಹ ಯೋಗ ಪ್ರಾರ್ಥನೆ'],
          'ta': ['தேன் நைவேத்தியம்', 'செம்பருத்தி மலர் அர்ச்சனை', 'மாங்கல்ய பிரார்த்தனை'],
          'te': ['తేనె నైవేద్యం', 'మందార పూల పూజ', 'కల్యాణ యోగ ప్రార్థన'],
          'hi': ['शहद का भोग', 'लाल गुड़हल के पुष्पों से अर्चन'],
          'ml': ['തേൻ നിവേദ്യം', 'ചെമ്പരത്തി പൂജ'],
          'en': ['Honey offering', 'Red hibiscus flower worship', 'Sankalpa for righteous goals'],
        },
        'mantra': 'ಓಂ ದೇವಿ ಕಾತ್ಯಾಯನ್ಯೈ ನಮಃ • Om Devi Katyayanyai Namah',
        'stotram': 'Katyayani Mantra & Stotram',
      },
      7: {
        'title': {
          'kn': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೭ (ಸಪ್ತಮಿ)',
          'ta': 'தசரா நவராத்திரி – நாள் ௭ (சப்தமி)',
          'te': 'దసరా నవరాత్రి – రోజు ౭ (సప్తమి)',
          'hi': 'दशहरा नवरात्रि – सप्तम दिवस (सप्तमी)',
          'ml': 'ദസറ നവരാത്രി – ഏഴാം ദിനം (സപ്തമി)',
          'en': 'Dasara Navratri – Day 7 (Saptami)',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಕಾಳರಾತ್ರಿ ದೇವಿ (ಸರಸ್ವತಿ ಆವಾಹನೆ)',
          'ta': 'ஸ்ரீ காளராத்திரி தேவி (சரஸ்வதி ஆவாஹனம்)',
          'te': 'శ్రీ కాళరాత్రి దేవి (సరస్వతీ ఆవాహన)',
          'hi': 'माता कालरात्रि (सरस्वती आवाहन)',
          'ml': 'ശ്രീ കാളരാത്രി ദേവി (സരസ്വതി ആവാഹനം)',
          'en': 'Goddess Kalaratri & Saraswati Avahana',
        },
        'sig': {
          'kn': 'ಕತ್ತಲೆಯನ್ನು ನಾಶಪಡಿಸುವ ಕಾಳರಾತ್ರಿ ದೇವಿ. ಜ್ಞಾನದ ಅಧಿದೇವತೆ ಸರಸ್ವತಿಯ ಆವಾಹನೆಯೊಂದಿಗೆ ಸರ್ವ ಗ್ರಹದೋಷ ನಿವಾರಿಸುತ್ತಾಳೆ.',
          'ta': 'இருளை அகற்றும் காளராத்திரி தேவி. சரஸ்வதி ஆவாஹனத்துடன் சகல நவகிரக தோஷங்களையும் நீக்குகிறாள்.',
          'te': 'అంధకారాన్ని పారద్రోలే కాళరాత్రి దేవి. సరస్వతీ ఆవాహనతో సమస్త గ్రహదోషాలను నివారిస్తుంది.',
          'hi': 'अज्ञान रूपी अंधकार का नाश करने वाली मां कालरात्रि। काल और संकटों का हरण कर अभय प्रदान करती हैं।',
          'ml': 'കാളരാത്രി ദേവി അന്ധകാരത്തെ അകറ്റി ഭയം നീക്കുന്നു.',
          'en': 'Fierce destroyer of dark forces (Shubhankari). Marks Saraswati Avahana for supreme divine wisdom.',
        },
        'rituals': {
          'kn': ['ಬೆಲ್ಲ ಹಾಗೂ ಎಳ್ಳುಂಡೆ ನೈವೇದ್ಯ', 'ಸರಸ್ವತಿ ಆವಾಹನೆ ಪೂಜೆ', 'ಪುಸ್ತಕ-ಲೇಖನಿ ಪೂಜೆ'],
          'ta': ['வெல்லம் மற்றும் எள்ளுருண்டை நைவேத்தியம்', 'சரஸ்வதி ஆவாஹன பூஜை', 'புத்தக பூஜை'],
          'te': ['బెల్లం మరియు నువ్వుల ఉండలు', 'సరస్వతీ ఆవాహన పూజ', 'పుస్తక పూజ'],
          'hi': ['गुड़ का नैवेद्य', 'सरस्वती आवाहन एवं पुस्तक पूजन'],
          'ml': ['ശർക്കര നിവേദ്യം', 'സരസ്വതി പൂജ'],
          'en': ['Jaggery offering', 'Saraswati Avahana worship', 'Prayers for learning and knowledge'],
        },
        'mantra': 'ಓಂ ದೇವಿ ಕಾಳರಾತ್ರ್ಯೈ ನಮಃ • Om Devi Kalaratryai Namah',
        'stotram': 'Saraswati Stotram',
      },
      8: {
        'title': {
          'kn': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೮ (ದುರ್ಗಾಷ್ಟಮಿ)',
          'ta': 'தசரா நவராத்திரி – நாள் ௮ (துர்காஷ்டமி)',
          'te': 'దసరా నవరాత్రి – రోజు ౮ (దుర్గాష్టమి)',
          'hi': 'दशहरा नवरात्रि – अष्टम दिवस (दुर्गाष्टमी)',
          'ml': 'ദസറ നവരാത്രി – എട്ടാം ദിനം (ദുർഗ്ഗാഷ്ടമി)',
          'en': 'Dasara Navratri – Day 8 (Durgashtami)',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಮಹಾಗೌರಿ ದೇವಿ (ಮಹಾಷ್ಟಮಿ)',
          'ta': 'ஸ்ரீ மஹாகௌரி தேவி (மகாஷ்டமி)',
          'te': 'శ్రీ మహాగౌరి దేవి (మహాష్టమి)',
          'hi': 'माता महागौरी (महाअष्टमी)',
          'ml': 'ശ്രീ മഹാഗൗരി ദേവി (മഹാഷ്ടമി)',
          'en': 'Goddess Mahagauri (Maha Ashtami)',
        },
        'sig': {
          'kn': 'ಅತ್ಯಂತ ಮಂಗಳಕರವಾದ ಮಹಾಷ್ಟಮಿ ದಿನ. ಮಹಾಗೌರಿಯು ಭಕ್ತರ ಪಾಪ-ತಾಪಗಳನ್ನು ಕ್ಷಣಾರ್ಧದಲ್ಲಿ ತೊಳೆಯುತ್ತಾಳೆ.',
          'ta': 'மிகவும் மங்களகரமான மகாஷ்டமி நாள். மகாகௌரியின் தரிசனம் பாவங்களை நீக்கி மனத்தூய்மை தருகிறது.',
          'te': 'అత్యంత పవిత్రమైన మహాష్టమి రోజు. మహాగౌరి సమస్త పాపాలను హరించి అఖండ శాంతినిస్తుంది.',
          'hi': 'महाअष्टमी का परम पावन दिन। महागौरी की उपासना से समस्त संचित पाप नष्ट होते हैं और अक्षय सुख की प्राप्ति होती है।',
          'ml': 'മഹാഗൗരി ദേവി ഭക്തർക്ക് ശാന്തിയും ഐശ്വര്യവും നൽകുന്നു.',
          'en': 'The deeply sacred Maha Ashtami day. Maa Mahagauri represents supreme purity and washes away past karmas.',
        },
        'rituals': {
          'kn': ['ತೆಂಗಿನಕಾಯಿ ನೈವೇದ್ಯ', 'ಕನ್ಯಾ ಪೂಜೆ (ಬಾಲೆಯರ ಅರ್ಚನೆ)', 'ಸಂಧಿ ಪೂಜೆ'],
          'ta': ['தேங்காய் நைவேத்தியம்', 'கன்யா பூஜை (பாலியர் வழிபாடு)', 'சந்தி பூஜை'],
          'te': ['కొబ్బరికాయ నైవేద్యం', 'కన్యా పూజ', 'సంధి పూజ'],
          'hi': ['नारियल का भोग', 'कन्या पूजन', 'संधि पूजा दर्शन'],
          'ml': ['തേങ്ങ നിവേദ്യം', 'കന്യാ പൂജ'],
          'en': ['Coconut offering', 'Kanya Puja (honoring young girls)', 'Sandhi Puja in evening'],
        },
        'mantra': 'ಓಂ ದೇವಿ ಮಹಾಗೌರ್ಯೈ ನಮಃ • Om Devi Mahagauryai Namah',
        'stotram': 'Annapurna Stotram',
      },
      9: {
        'title': {
          'kn': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೯ (ಮಹಾನವಮಿ & ಆಯುಧ ಪೂಜೆ)',
          'ta': 'தசரா நவராத்திரி – நாள் ௯ (மகாநவமி & ஆயுத பூஜை)',
          'te': 'దసరా నవరాత్రి – రోజు ౯ (మహానవమి & ఆయుధ పూజ)',
          'hi': 'दशहरा नवरात्रि – नवम दिवस (महानवमी एवं आयुध पूजा)',
          'ml': 'ദസറ നവരാത്രി – ഒമ്പതാം ദിനം (മഹാനവമി & ആയുധ പൂജ)',
          'en': 'Dasara Navratri – Day 9 (Mahanavami & Ayudha Pooja)',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಸಿದ್ಧಿಧಾತ್ರಿ ದೇವಿ (ಆಯುಧ ಪೂಜೆ)',
          'ta': 'ஸ்ரீ சித்திதாத்ரி தேவி (ஆயுத பூஜை)',
          'te': 'శ్రీ సిద్ధిధాత్రి దేవి (ఆయుధ పూజ)',
          'hi': 'माता सिद्धिदात्री (आयुध पूजा)',
          'ml': 'ശ്രീ സിദ്ധിധാത്രി ദേവി (ആയുധ പൂജ)',
          'en': 'Goddess Siddhidatri (Ayudha Pooja)',
        },
        'sig': {
          'kn': 'ಅಷ್ಟಸಿದ್ಧಿಗಳನ್ನು ಕರುಣಿಸುವ ಸಿದ್ಧಿಧಾತ್ರಿ ದೇವಿ. ಜೀವನೋಪಾಯದ ಉಪಕರಣಗಳು, ವಾಹನಗಳು ಹಾಗೂ ಗ್ರಂಥಗಳಿಗೆ ಕೃತಜ್ಞತೆಯಿಂದ ಪೂಜೆ ಸಲ್ಲಿಸುವ ಮಹಾನವಮಿ.',
          'ta': 'அஷ்டசித்திகளை அருளும் சித்திதாத்ரி தேவி. தொழில் கருவிகள், வாகனங்கள் மற்றும் நூல்களுக்கு நன்றி செலுத்தும் ஆயுத பூஜை.',
          'te': 'అష్టసిద్ధులను ప్రసాదించే సిద్ధిధాత్రి దేవి. జీవనోపాధి సాధనాలకు, వాహనాలకు కృతజ్ఞతగా పూజించే ఆయుధ పూజ.',
          'hi': 'अष्ट सिद्धियों की दात्री मां सिद्धिदात्री। समस्त कर्म उपकरणों, वाहनों और विद्या की महापूजा का पावन दिवस।',
          'ml': 'സിദ്ധിധാത്രി ദേവി അഷ്ടസിദ്ധികൾ നൽകുന്നു. ആയുധ പൂജയും വാഹന പൂജയും വിശുദ്ധം.',
          'en': 'Giver of all mystic siddhis. Concurrently celebrated as Ayudha Pooja, honoring instruments of livelihood and learning.',
        },
        'rituals': {
          'kn': ['ಕಡಲೆಕಾಳು ಉಸಲಿ & ಮಂಡಕ್ಕಿ ನೈವೇದ್ಯ', 'ಆಯುಧ ಪೂಜೆ & ವಾಹನ ಪೂಜೆ', 'ಬೂದುಗುಂಬಳಕಾಯಿ ಆರತಿ'],
          'ta': ['சுண்டல் & பொரி நைவேத்தியம்', 'ஆயுத பூஜை & வாகன பூஜை', 'பூசணிக்காய் திருஷ்டி சுற்றல்'],
          'te': ['గుగ్గిళ్ళు & పేలాలు నైవేద్యం', 'ఆయుధ పూజ & వాహన పూజ', 'బూడిద గుమ్మడికాయ హారతి'],
          'hi': ['चना, हलवा एवं खीर का भोग', 'शस्त्र एवं यंत्र पूजन'],
          'ml': ['കടല നിവേദ്യം', 'ആയുധ പൂജയും വാഹന പൂജയും'],
          'en': ['Black gram & puffed rice prasad', 'Sanctification of tools and vehicles', 'Ash-gourd Aarti'],
        },
        'mantra': 'ಓಂ ದೇವಿ ಸಿದ್ಧಿಧಾತ್ರ್ಯೈ ನಮಃ • Om Devi Siddhidatryai Namah',
        'stotram': 'Devi Mahatmyam / Durga Saptashati',
      },
      10: {
        'title': {
          'kn': 'ವಿಜಯದಶಮಿ – ದಸರಾ ಹಬ್ಬದ ಶುಭ ಮಹೋತ್ಸವ',
          'ta': 'விஜயதசமி – தசரா திருவிழா மங்கள நன்னாள்',
          'te': 'విజయదశమి – దసరా పండుగ శుభ మహోత్సవం',
          'hi': 'विजयादशमी – पावन दशहरा महोत्सव',
          'ml': 'വിജയദശമി – ദസറ ഉത്സവ പുണ്യദിനം',
          'en': 'Vijayadashami – Grand Dasara Festival',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ದುರ್ಗಾದೇವಿ & ಶಮೀ ವೃಕ್ಷ (ವಿಜಯೋತ್ಸವ)',
          'ta': 'ஸ்ரீ துர்கா தேவி & வன்னி மரம் (விஜயோற்சவம்)',
          'te': 'శ్రీ దుర్గాదేవి & జమ్మి చెట్టు (విజయోత్సవం)',
          'hi': 'मां दुर्गा एवं मर्यादा पुरुषोत्तम श्रीराम',
          'ml': 'ശ്രീ ദുർഗ്ഗാദേവി & വിദ്യാരംഭം',
          'en': 'Goddess Durga & Lord Rama (Triumph of Dharma)',
        },
        'sig': {
          'kn': 'ಅಧರ್ಮದ ಮೇಲೆ ಧರ್ಮದ ಜಯೋತ್ಸವ. ದುರ್ಗೆಯು ಮಹಿಷಾಸುರನನ್ನು ಸಂಹರಿಸಿದ ಹಾಗೂ ಶ್ರೀರಾಮನು ರಾವಣನ ಮೇಲೆ ವಿಜಯ ಸಾಧಿಸಿದ ಮಹಾ ದಿನ. ಶಮೀ ವೃಕ್ಷ ಪೂಜೆ ವಿಜಯಪ್ರದಾಯಕ.',
          'ta': 'அநீதியை வென்று தர்மம் நிலைநாட்டிய நன்னாள். துர்க்கை மகிஷாசுரனை வென்றதும், ராமர் ராவணனை வென்றதும் இந்நாளில். வன்னி மர வழிபாடு வெற்றி தரும்.',
          'te': 'అధర్మంపై ధర్మం సాధించిన విజయం. దుర్గాదేవి మహిషాసురుడిని సంహరించిన మరియు శ్రీరాముడు రావణుడిని జయించిన పవిత్ర దినం. జమ్మి పూజ శుభకరం.',
          'hi': 'अधर्म पर धर्म और असत्य पर सत्य की शाश्वत विजय का महापर्व। शमी वृक्ष पूजन एवं नए शुभ संकल्पों का शुभारंभ।',
          'ml': 'തിന്മയ്ക്ക് മേൽ നന്മയുടെ വിജയം. വിദ്യാരംഭത്തിനും പുതിയ തുടക്കങ്ങൾക്കും ഉത്തമം.',
          'en': 'Supreme culmination of Navratri symbolizing eternal victory of truth over evil. Rama slayed Ravana and Durga defeated Mahishasura.',
        },
        'rituals': {
          'kn': ['ಬನ್ನಿ ಮರ (ಶಮೀ ವೃಕ್ಷ) ಪೂಜೆ & ಎಲೆ ವಿನಿಮಯ', 'ವಿದ್ಯಾರಂಭ / ಅಕ್ಷರಾಭ್ಯಾಸ', 'ನೂತನ ಕಾರ್ಯಾರಂಭ'],
          'ta': ['வன்னி மர பூஜை & இலை பரிமாற்றம்', 'வித்யாரம்பம் (அட்சராப்பியாசம்)', 'புதிய காரியங்கள் தொடங்குதல்'],
          'te': ['జమ్మి చెట్టు పూజ & జమ్మి ఆకుల మార్పిడి', 'విద్యారంభం / అక్షరాభ్యాసం', 'కొత్త పనులు ప్రారంభం'],
          'hi': ['शमी पूजन एवं अपराजिता स्तोत्र', 'विद्यारंभ संस्कार', 'नूतन कार्य शुभारंभ'],
          'ml': ['വിദ്യാരംഭം', 'പുതിയ കാര്യങ്ങളുടെ തുടക്കം'],
          'en': ['Shami tree worship and gold-leaf exchange', 'Vidyarambha for children', 'Beginning auspicious initiatives'],
        },
        'mantra': 'ಶಮೀ ಶಮಯತೇ ಪಾಪಂ ಶಮೀ ಶತ್ರು ವಿನಾಶಿನೀ • Om Vijaya Durgayai Namah',
        'stotram': 'Shami Shloka & Sri Rama Raksha Stotram',
      },
    };

    final day = dasaraDays[dayNum] ?? dasaraDays[1]!;

    final subMap = {
      'kn': 'ದಸರಾ ನವರಾತ್ರಿ ಮಹೋತ್ಸವ ($colorText)',
      'ta': 'தசரா நவராத்திரி திருவிழா ($colorText)',
      'te': 'దసరా నవరాత్రి మహోత్సవం ($colorText)',
      'hi': 'दशहरा नवरात्रि पावन उत्सव ($colorText)',
      'ml': 'ദസറ നവരാത്രി മഹോത്സവം ($colorText)',
      'en': 'Grand Sharad Navratri Festival ($colorText)',
    };

    final badgeMap = {
      'kn': 'ದಸರಾ ನವರಾತ್ರಿ ದಿನ $dayNum',
      'ta': 'தசரா நவராத்திரி நாள் $dayNum',
      'te': 'దసరా నవరాత్రి రోజు $dayNum',
      'hi': 'दशहरा नवरात्रि दिवस $dayNum',
      'ml': 'ദസറ നവരാത്രി ദിനം $dayNum',
      'en': 'Navratri Day $dayNum',
    };

    final titleMap = day['title'] as Map<String, String>;
    final deityMap = day['deity'] as Map<String, String>;
    final sigMap = day['sig'] as Map<String, String>;
    final ritualsMap = day['rituals'] as Map<String, List<String>>;

    return SpecialDayInfo(
      id: 'dasara_day_$dayNum',
      title: titleMap[lang] ?? titleMap['en']!,
      subtitle: subMap[lang] ?? subMap['en']!,
      deity: deityMap[lang] ?? deityMap['en']!,
      significance: sigMap[lang] ?? sigMap['en']!,
      rituals: ritualsMap[lang] ?? ritualsMap['en']!,
      mantra: day['mantra'] as String,
      auspiciousColor: colorText,
      recommendedStotram: day['stotram'] as String?,
      badgeText: badgeMap[lang] ?? badgeMap['en']!,
      date: date,
    );
  }

  // ==========================================
  // OTHER FESTIVAL DEFINITIONS (FULLY LOCALIZED)
  // ==========================================

  static SpecialDayInfo _getMahalayaAmavasyaInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ಮಹಾಲಯ ಅಮಾವಾಸ್ಯೆ (ಸರ್ವ ಪಿತೃ ಅಮಾವಾಸ್ಯೆ)',
      'ta': 'மஹாளய அமாவாசை (சர்வ பித்ரு அமாவாசை)',
      'te': 'మహాలయ అమావాస్య (సర్వ పితృ అమావాస్య)',
      'hi': 'महालय अमावस्या (सर्वपितृ अमावस्या)',
      'ml': 'മഹാലയ അമാവാസി (സർവ്വ പിതൃ അമാവാസി)',
      'en': 'Mahalaya Amavasya (Sarva Pitru Amavasya)',
    };
    final subtitles = {
      'kn': 'ಪಿತೃಪಕ್ಷದ ಪರಮ ಪವಿತ್ರ ಮಹಾಸಂಗಮ ದಿನ',
      'ta': 'பித்ரு பக்ஷத்தின் புனித மோக்ஷ நன்னாள்',
      'te': 'పితృపక్షం యొక్క పరమ పవిత్ర సంగమ దినం',
      'hi': 'पितृपक्ष की पावन सर्वपितृ मोक्ष तिथि',
      'ml': 'പിതൃപക്ഷത്തിന്റെ പുണ്യസംഗമ ദിനം',
      'en': 'Culmination of Pitru Paksha & Ancestral Blessings',
    };
    final deities = {
      'kn': 'ಪಿತೃ ದೇವತೆಗಳು & ಶ್ರೀ ಮಹಾವಿಷ್ಣು',
      'ta': 'பித்ரு தேவர்கள் & ஸ்ரீ மகாவிஷ்ணு',
      'te': 'పితృ దేవతలు & శ్రీ మహావిష్ణువు',
      'hi': 'पितृ देव एवं श्री लक्ष्मीनारायण',
      'ml': 'പിതൃ ദേവന്മാരും ശ്രീ മഹാവിഷ്ണുവും',
      'en': 'Pitru Devas & Lord Maha Vishnu',
    };
    final sigs = {
      'kn': 'ಪಿತೃಪಕ್ಷದ ಅತ್ಯಂತ ಶ್ರೇಷ್ಠ ದಿನ. ತಿಳಿಯದ ಅಥವಾ ನೆನಪಿರದ ಎಲ್ಲ ಪೂರ್ವಜರಿಗೆ ತರ್ಪಣ ಮತ್ತು ಕೃತಜ್ಞತೆ ಅರ್ಪಿಸುವ ಮಹಾ ಪುಣ್ಯ ಕಾಲ.',
      'ta': 'பித்ரு பக்ஷத்தின் மிக முக்கிய நாள். முன்னோர்களுக்கு தர்ப்பணம் செய்து ஆசி பெறும் புண்ணிய காலம்.',
      'te': 'పితృపక్షంలో అత్యంత శ్రేష్ఠమైన రోజు. పూర్వీకులకు తర్పణం అర్పించి కృతజ్ఞతలు తెలుపుకునే పుణ్య కాలం.',
      'hi': 'पितृपक्ष का सबसे पावन और फलदायी दिन। पूर्वजों के निमित्त तर्पण एवं श्राद्ध से पितृदोष समाप्त होता है।',
      'ml': 'പിതൃക്കൾക്കായി തർപ്പണം ചെയ്ത് അനുഗ്രഹം വാങ്ങുന്ന പുണ്യദിനം.',
      'en': 'The most sacred day of Pitru Paksha. Offering prayers, tarpana, and food ensures ancestral peace.',
    };
    final rituals = {
      'kn': ['ಎಳ್ಳು ಮತ್ತು ಪವಿತ್ರ ಜಲದಿಂದ ಪಿತೃ ತರ್ಪಣ ಸಮರ್ಪಣೆ', 'ಅನ್ನದಾನ ಹಾಗೂ ಗೋಸೇವೆ', 'ಸಂಜೆ ಎಳ್ಳೆಣ್ಣೆ ದೀಪ ಪ್ರಜ್ವಲನ'],
      'ta': ['எள்ளும் நீரும் கொண்டு பித்ரு தர்ப்பணம்', 'அன்னதானம் மற்றும் கோபூஜை', 'மாலையில் நல்லெண்ணெய் தீபம்'],
      'te': ['నువ్వులు మరియు జలంతో పితృ తర్పణం', 'అన్నదానం మరియు గోసేవ', 'సాయంత్రం నువ్వుల నూనె దీపారాధన'],
      'hi': ['तिल और जल से पितरों का तर्पण एवं श्राद्ध', 'गौमाता एवं जरूरतमंदों को अन्नदान', 'सायंकाल दीपदान'],
      'ml': ['എള്ളും ജലവും കൊണ്ട് തർപ്പണം', 'അന്നദാനവും ഗോപൂജയും', 'സന്ധ്യാ ദീപം'],
      'en': ['Offering water & black sesame (Tila Tarpana)', 'Food donation to cows and the needy', 'Evening sesame oil lamps'],
    };
    final badges = {
      'kn': 'ಪಿತೃ ಮೋಕ್ಷ ಪುಣ್ಯಕಾಲ',
      'ta': 'பித்ரு மோக்ஷ புண்ணியகாலம்',
      'te': 'పితృ మోక్ష పుణ్యకాలం',
      'hi': 'सर्वपितृ मोक्ष काल',
      'ml': 'പിതൃ മോക്ഷ പുണ്യകാലം',
      'en': 'Ancestral Blessings',
    };

    return SpecialDayInfo(
      id: 'mahalaya_amavasya',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ಪಿತೃದೇವಾಯ ನಮಃ • ಓಂ ನಮೋ ಭಗವತೇ ವಾಸುದೇವಾಯ',
      recommendedStotram: 'Sri Vishnu Sahasranama Stotram',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getEkadashiInfo(bool isKrishna, String lang, DateTime date) {
    final pakshaKn = isKrishna ? 'ಕೃಷ್ಣ ಪಕ್ಷ' : 'ಶುಕ್ಲ ಪಕ್ಷ';
    final pakshaTa = isKrishna ? 'தேய்பிறை' : 'வளர்பிறை';
    final pakshaTe = isKrishna ? 'కృష్ణ పక్ష' : 'శుక్ల పక్ష';
    final pakshaHi = isKrishna ? 'कृष्ण पक्ष' : 'शुक्ल पक्ष';
    final pakshaMl = isKrishna ? 'കൃഷ്ണ പക്ഷ' : 'ശുക്ല പക്ഷ';

    final titles = {
      'kn': '$pakshaKn ಏಕಾದಶಿ ವ್ರತ',
      'ta': '$pakshaTa ஏகாதசி விரதம்',
      'te': '$pakshaTe ఏకాదశి వ్రతం',
      'hi': '$pakshaHi एकादशी व्रत (हरिवासर)',
      'ml': '$pakshaMl ഏകാദശി വ്രതം',
      'en': 'Sacred Ekadashi Vrata (Harivasara)',
    };
    final subtitles = {
      'kn': 'ಶ್ರೀ ಮಹಾವಿಷ್ಣುವಿನ ಪ್ರೀತ್ಯರ್ಥ ಪರಮ ಪವಿತ್ರ ಉಪವಾಸ ದಿನ',
      'ta': 'ஸ்ரீ மகாவிஷ்ணுவின் அருள்பெறும் புனித விரத நாள்',
      'te': 'శ్రీ మహావిష్ణువు ప్రీత్యర్థం పరమ పవిత్ర ఉపవాస దినం',
      'hi': 'श्री हरि विष्णु की आराधना हेतु पावन उपवास दिवस',
      'ml': 'മഹാവിഷ്ണുവിനായി സമർപ്പിക്കുന്ന വിശുദ്ധ ഉപവാസ ദിനം',
      'en': 'Day of Spiritual Fasting Dedicated to Lord Vishnu',
    };
    final deities = {
      'kn': 'ಶ್ರೀ ಲಕ್ಷ್ಮೀ ನಾರಾಯಣ',
      'ta': 'ஸ்ரீ லக்ஷ்மி நாராயணர்',
      'te': 'శ్రీ లక్ష్మీ నారాయణుడు',
      'hi': 'भगवान श्री लक्ष्मीनारायण',
      'ml': 'ശ്രീ ലക്ഷ്മീ നാരായണൻ',
      'en': 'Lord Maha Vishnu & Goddess Lakshmi',
    };
    final sigs = {
      'kn': 'ಏಕಾದಶಿಯು ಸಕಲ ಪಾಪನಾಶಕ ಮತ್ತು ಮುಕ್ತಿದಾಯಕ ವ್ರತ. ಉಪವಾಸ ಮತ್ತು ವಿಷ್ಣು ನಾಮಸ್ಮರಣೆಯಿಂದ ಆತ್ಮಶುದ್ಧಿ ಪ್ರಾಪ್ತಿಯಾಗುತ್ತದೆ.',
      'ta': 'ஏகாதசி விரதம் பாவங்களை போக்கி முக்தி தரும். விஷ்ணு நாம ஜெபம் மன அமைதியை தரும்.',
      'te': 'ఏకాదశి సమస్త పాపాలను పోగొట్టి మోక్షాన్నిచ్చే వ్రతం. ఉపవాసం మరియు విష్ణు నామస్మరణ విశేష పుణ్యప్రదం.',
      'hi': 'एकादशी सभी व्रतों में शिरोमणि है। श्रीहरि के ध्यान और उपवास से चित्त शुद्धि होती है।',
      'ml': 'ഏകാദശി വ്രതം സകല പാപങ്ങളെയും ശമിപ്പിക്കുന്നു.',
      'en': 'Ekadashi is the mother of all spiritual fasts. Detoxing body and mind while meditating on Vishnu brings grace.',
    };
    final rituals = {
      'kn': ['ಧಾನ್ಯ ತ್ಯಜಿಸಿ ಉಪವಾಸ ಆಚರಣೆ', 'ವಿಷ್ಣು ಸಹಸ್ರನಾಮ ಸ್ತೋತ್ರ ಪಠಣ', 'ತುಳಸಿ ಪೂಜೆ'],
      'ta': ['தானியங்களை தவிர்த்து விரதம்', 'விஷ்ணு சஹஸ்ரநாம பாராயணம்', 'துளசி பூஜை'],
      'te': ['ధాన్యాలు త్యజించి ఉపవాసం', 'విష్ణు సహస్రనామ పారాయణం', 'తులసి పూజ'],
      'hi': ['फलाहार एवं अन्न त्याग उपवास', 'विष्णु सहस्रनाम पाठ', 'तुलसी पूजन'],
      'ml': ['ധാന്യങ്ങൾ ഒഴിവാക്കി ഉപവാസം', 'വിഷ്ണു സഹസ്രനാമ ജപം', 'തുളസി പൂജ'],
      'en': ['Fasting from grains and heavy foods', 'Chanting Vishnu Sahasranama Stotram', 'Tulasi Puja with ghee lamps'],
    };
    final badges = {
      'kn': 'ಹರಿವಾಸರ ಪರ್ವದಿನ',
      'ta': 'ஹரிவாசரம் புண்ணியநாள்',
      'te': 'హరివాసర పర్వదినం',
      'hi': 'पावन हरिवासर',
      'ml': 'ഹരിവാസര പുണ്യദിനം',
      'en': 'Sacred Ekadashi',
    };

    return SpecialDayInfo(
      id: isKrishna ? 'krishna_ekadashi' : 'shukla_ekadashi',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ನಮೋ ನಾರಾಯಣಾಯ • Om Namo Narayanaya',
      recommendedStotram: 'Sri Vishnu Sahasranama Stotram',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getPradoshaInfo(int weekday, String lang, DateTime date) {
    final isShani = weekday == DateTime.saturday;
    final isSoma = weekday == DateTime.monday;

    final titles = {
      'kn': isShani ? 'ಶನಿ ಪ್ರದೋಷ ವ್ರತ' : (isSoma ? 'ಸೋಮ ಪ್ರದೋಷ ವ್ರತ' : 'ಪ್ರದೋಷ ವ್ರತ'),
      'ta': isShani ? 'சனிப் பிரதோஷம்' : (isSoma ? 'சோமப் பிரதோஷம்' : 'பிரதோஷ விரதம்'),
      'te': isShani ? 'శని ప్రదోష వ్రతం' : (isSoma ? 'సోమ ప్రదోష వ్రతం' : 'ప్రదోష వ్రతం'),
      'hi': isShani ? 'शनि प्रदोष व्रत' : (isSoma ? 'सोम प्रदोष व्रत' : 'पावन प्रदोष व्रत'),
      'ml': isShani ? 'ശനി പ്രദോഷം' : (isSoma ? 'സോമ പ്രദോഷം' : 'പ്രദോഷ വ്രതം'),
      'en': isShani ? 'Shani Pradosha Vrata' : (isSoma ? 'Soma Pradosha Vrata' : 'Pradosha Vrata'),
    };
    final subtitles = {
      'kn': 'ಸಂಜೆ ಪ್ರದೋಷ ಕಾಲದಲ್ಲಿ ಶಿವ ಪೂಜೆ & ನಂದೀಶ್ವರ ಆರಾಧನೆ',
      'ta': 'மாலை பிரதோஷ வேளையில் சிவபூஜை மற்றும் நந்தி வழிபாடு',
      'te': 'సాయంకాల ప్రదోష సమయంలో శివ పూజ & నందీశ్వర ఆరాధన',
      'hi': 'सायंकाल प्रदोष बेला में शिव आराधना एवं नंदी दर्शन',
      'ml': 'സന്ധ്യാ പ്രദോഷ സമയത്ത് ശിവപൂജയും നന്ദി ദർശനവും',
      'en': 'Twilight Worship of Lord Shiva & Nandi',
    };
    final deities = {
      'kn': 'ಶ್ರೀ ಮಹಾದೇವ ಪಾರ್ವತಿ ಸಮೇತ',
      'ta': 'ஸ்ரீ பார்வதி சமேத பரமேஸ்வரர்',
      'te': 'పార్వతీ సమేత పరమేశ్వరుడు',
      'hi': 'पार्वती समेत भगवान शिव',
      'ml': 'ശ്രീ പാർവ്വതീ സമേത പരമേശ്വരൻ',
      'en': 'Lord Shiva & Goddess Parvati',
    };
    final sigs = {
      'kn': 'ಮುಸ್ಸಂಜೆ ಸಮಯದಲ್ಲಿ ಕೈಲಾಸದಲ್ಲಿ ಪರಶಿವನು ಆನಂದ ತಾಂಡವವಾಡುವ ಸಮಯ. ನಂದಿ ಮತ್ತು ಶಿವನಿಗೆ ಬಿಲ್ವಪತ್ರೆ ಅರ್ಪಿಸಿದರೆ ಸಕಲ ದೋಷಗಳು ನಿವಾರಣೆಯಾಗುತ್ತವೆ.',
      'ta': 'பிரதோஷ காலத்தில் ஈசனை வழிபடுவது சகல தோஷங்களையும் நீக்கும் என்பது ஐதீகம்.',
      'te': 'సాయం ప్రదోష కాలంలో శివుడికి బిల్వపత్రాలతో పూజ చేస్తే సమస్త కర్మదోషాలు తొలగిపోతాయి.',
      'hi': 'प्रदोष काल में भगवान शिव आनंद तांडव करते हैं। इस समय शिव-नंदी पूजन से सभी संकट दूर होते हैं।',
      'ml': 'പ്രദോഷ വേളയിലെ ശിവപൂജ സകല പാപങ്ങളെയും ശമിപ്പിക്കുന്നു.',
      'en': 'During twilight (Pradosha), Shiva performs divine Ananda Tandava. Bilva offerings remove karmic burdens.',
    };
    final rituals = {
      'kn': ['ಮುಸ್ಸಂಜೆ ಶಿವಲಿಂಗಕ್ಕೆ ಕ್ಷೀರಾಭಿಷೇಕ', 'ಶಿವನಿಗೆ & ನಂದಿಗೆ ಬಿಲ್ವಪತ್ರೆ ಅರ್ಪಣೆ', 'ಓಂ ನಮಃ ಶಿವಾಯ ೧೦೮ ಬಾರಿ ಜಪ'],
      'ta': ['பிரதோஷ வேளையில் பாலாபிஷேகம்', 'நந்தி மற்றும் சிவனுக்கு வில்வ அர்ச்சனை', 'ஓம் நம சிவாய ஜெபம்'],
      'te': ['ప్రదోష సమయంలో క్షీరాభిషేకం', 'నంది మరియు శివునికి బిల్వార్చన', 'ఓం నమః శివాయ జపం'],
      'hi': ['प्रदोष काल में दुग्धाभिषेक', 'शिव एवं नंदी को बिल्वपत्र अर्पण', 'ॐ नमः शिवाय महामंत्र जप'],
      'ml': ['പാലഭിഷേകം', 'കൂവളത്തില അർച്ചന', 'ഓം നമഃ ശിവായ ജപം'],
      'en': ['Milk abhishekam during sunset', 'Offering Bilva leaves to Shiva & Nandi', 'Chanting Om Namah Shivaya 108 times'],
    };
    final badges = {
      'kn': 'ಶಿವ ಪ್ರದೋಷ ಕಾಲ',
      'ta': 'பிரதோஷ காலம்',
      'te': 'శివ ప్రదోష కాలం',
      'hi': 'शिव प्रदोष काल',
      'ml': 'ശിവ പ്രദോഷം',
      'en': 'Pradosham',
    };

    return SpecialDayInfo(
      id: 'pradosha_vrata',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ನಮಃ ಶಿವಾಯ • Om Namah Shivaya',
      recommendedStotram: 'Shiva Tandava Stotram',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getSankashtiInfo(bool isAngarki, String lang, DateTime date) {
    final titles = {
      'kn': isAngarki ? 'ಅಂಗಾರಕಿ ಸಂಕಷ್ಟಹರ ಚತುರ್ಥಿ' : 'ಸಂಕಷ್ಟಹರ ಚತುರ್ಥಿ ವ್ರತ',
      'ta': isAngarki ? 'அங்காரக சங்கடஹர சதுர்த்தி' : 'சங்கடஹர சதுர்த்தி விரதம்',
      'te': isAngarki ? 'అంగారక సంకష్టహర చతుర్థి' : 'సంకష్టహర చతుర్థి వ్రతం',
      'hi': isAngarki ? 'अंगारकी संकष्टी चतुर्थी' : 'संकष्टी चतुर्थी व्रत',
      'ml': isAngarki ? 'അംഗാരക സങ്കഷ്ട ചതുർത്ഥി' : 'സങ്കഷ്ട ചതുർത്ഥി വ്രതം',
      'en': isAngarki ? 'Angarki Sankashti Chaturthi' : 'Sankashti Chaturthi Vrata',
    };
    final subtitles = {
      'kn': 'ವಿಘ್ನನಾಶಕ ಗಣಪತಿ ಪೂಜೆ & ಚಂದ್ರೋದಯ ವ್ರತ',
      'ta': 'விக்ன விநாயகர் பூஜை & சந்திரோதய விரதம்',
      'te': 'విఘ్ననాశక గణపతి పూజ & చంద్రోదయ వ్రతం',
      'hi': 'विघ्नहर्ता गणेश पूजन एवं चंद्रोदय अर्घ्य',
      'ml': 'വിഘ്നവിനാശക ഗണപതി പൂജ',
      'en': 'Obstacle-Removal Ganapati Puja & Moonrise Fast',
    };
    final deities = {
      'kn': 'ಶ್ರೀ ಮಹಾಗಣಪತಿ',
      'ta': 'ஸ்ரீ மகா கணபதி',
      'te': 'శ్రీ మహాగణపతి',
      'hi': 'भगवान श्री गणेश',
      'ml': 'ശ്രീ മഹാഗണപതി',
      'en': 'Lord Ganesha',
    };
    final sigs = {
      'kn': 'ಸಂಕಟಗಳನ್ನು ಕಳೆಯುವ ಮಹಾ ಚತುರ್ಥಿ. ಗಣೇಶನಿಗೆ ಗರಿಕೆ, ಮೋದಕ ಅರ್ಪಿಸಿ ಚಂದ್ರ ದರ್ಶನ ಮಾಡಿದರೆ ಸಂಕಷ್ಟಗಳು ದೂರಾಗುತ್ತವೆ.',
      'ta': 'சங்கடங்களை தீர்க்கும் சதுர்த்தி. விநாயகருக்கு அருகம்புல், கொழுக்கட்டை படைத்து வழிபடுவது நன்மை தரும்.',
      'te': 'కష్టాలను దూరం చేసే చతుర్థి. గణపతికి గరిక, మోదకాలు సమర్పించి చంద్ర దర్శనం చేసుకుంటే సకల విఘ్నాలు తొలగుతాయి.',
      'hi': 'संकटों को हरने वाली चतुर्थी। गणेश जी को दूर्वा और मोदक अर्पण से सभी कष्ट दूर होते हैं।',
      'ml': 'സങ്കടങ്ങളെ അകറ്റുന്ന ഗണപതി പൂജ.',
      'en': 'Sacred fast dedicated to Lord Ganesha. Offering 21 blades of Durva removes hurdles.',
    };
    final rituals = {
      'kn': ['ಗಣಪತಿಗೆ ೨೧ ಗರಿಕೆ (ದೂರ್ವಾ) ಸಮರ್ಪಣೆ', 'ಮೋದಕ ಅಥವಾ ಕಡುಬು ನೈವೇದ್ಯ', 'ರಾತ್ರಿ ಚಂದ್ರೋದಯದ ನಂತರ ಅರ್ಘ್ಯ ಪ್ರದಾನ'],
      'ta': ['விநாயகருக்கு 21 அருகம்புல் சமர்ப்பணம்', 'கொழுக்கட்டை நைவேத்தியம்', 'சந்திரோதயத்திற்கு பின் அர்க்கியம்'],
      'te': ['గణపతికి 21 గరిక సమర్పణ', 'మోదకాలు లేదా కుడుములు నైవేద్యం', 'చంద్రోదయం తర్వాత అర్ఘ్యం'],
      'hi': ['२१ दूर्वा दल अर्पण', 'मोदक एवं लड्डू का भोग', 'चंद्रोदय पश्चात अर्घ्य एवं पारण'],
      'ml': ['കറുക സമർപ്പണം', 'മോദകം നിവേദ്യം', 'ചന്ദ്രോദയ ദർശനം'],
      'en': ['Offering 21 blades of Durva grass', 'Modaka and sweet offering', 'Arghya upon moonrise sighting'],
    };
    final badges = {
      'kn': 'ಸಂಕಷ್ಟಿ ಚತುರ್ಥಿ',
      'ta': 'சங்கடஹர சதுர்த்தி',
      'te': 'సంకష్ట చతుర్థి',
      'hi': 'संकष्टी चतुर्थी',
      'ml': 'സങ്കഷ്ട ചതുർത്ഥി',
      'en': 'Sankashti',
    };

    return SpecialDayInfo(
      id: 'sankashti_chaturthi',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ಗಂ ಗಣಪತಯೇ ನಮಃ • Om Gam Ganapataye Namah',
      recommendedStotram: 'Sankata Nashana Ganesha Stotram',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getPurnimaInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ಹುಣ್ಣಿಮೆ (ಪೌರ್ಣಮಿ) ಮಹಾವ್ರತ',
      'ta': 'பௌர்ணமி மகா விரத நன்னாள்',
      'te': 'పౌర్ణమి మహావ్రత పవిత్ర దినం',
      'hi': 'पूर्णिमा पावन महाव्रत',
      'ml': 'പൗർണ്ണമി പുണ്യദിനം',
      'en': 'Purnima (Full Moon) Sacred Day',
    };
    final subtitles = {
      'kn': 'ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ಪೂಜೆ & ಚಂದ್ರ ದರ್ಶನ',
      'ta': 'ஸ்ரீ சத்யநாராயணர் பூஜை & நிலவு வழிபாடு',
      'te': 'శ్రీ సత్యనారాయణ స్వామి పూజ & చంద్ర దర్శనం',
      'hi': 'सत्यनारायण स्वामी पूजन एवं चंद्र दर्शन',
      'ml': 'ശ്രീ സത്യനാരായണ പൂജ',
      'en': 'Satyanarayana Swamy Puja & Chandra Darshana',
    };
    final deities = {
      'kn': 'ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ಸ್ವಾಮಿ & ಚಂದ್ರ ದೇವ',
      'ta': 'ஸ்ரீ சத்யநாராயணர் & சந்திர பகவான்',
      'te': 'శ్రీ సత్యనారాయణ స్వామి & చంద్ర దేవుడు',
      'hi': 'भगवान सत्यनारायण एवं चंद्र देव',
      'ml': 'ശ്രീ സത്യനാരായണ സ്വാമി',
      'en': 'Lord Satyanarayana Swamy',
    };
    final sigs = {
      'kn': 'ಹುಣ್ಣಿಮೆಯು ಸಕಲ ಸಕಾರಾತ್ಮಕ ಶಕ್ತಿಗಳ ಪ್ರಕಾಶ. ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ವ್ರತ ಆಚರಣೆಯಿಂದ ಕುಟುಂಬದಲ್ಲಿ ನೆಮ್ಮದಿ ನೆಲೆಸುತ್ತದೆ.',
      'ta': 'பௌர்ணமி ஆன்மீக ஒளியின் நன்னாள். சத்யநாராயண விரதம் குடும்பத்தில் அமைதியையும் செல்வத்தையும் தரும்.',
      'te': 'పౌర్ణమి సకల శుభాలకు నిలయం. సత్యనారాయణ వ్రతం ఆచరిస్తే కుటుంబంలో సుఖశాంతులు చేకూరుతాయి.',
      'hi': 'पूर्णिमा पूर्ण आध्यात्मिक ऊर्जा का दिन है। सत्यनारायण कथा से परिवार में सुख-शांति आती है।',
      'ml': 'പൗർണ്ണമി ദിനത്തിലെ പൂജ കുടുംബത്തിൽ സമാധാനം നൽകുന്നു.',
      'en': 'Purnima embodies full spiritual illumination. Satyanarayana puja fills home with prosperity.',
    };
    final rituals = {
      'kn': ['ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ಸ್ವಾಮಿ ಪೂಜೆ', 'ಸಜ್ಜಿಗೆ (ಶಿರಾ) ನೈವೇದ್ಯ', 'ತುಳಸಿ ಕಟ್ಟೆ ಬಳಿ ತುಪ್ಪದ ದೀಪ'],
      'ta': ['சத்யநாராயணர் பூஜை', 'ரவா கேசரி / சிரா நைவேத்தியம்', 'துளசி மாடத்தில் நெய் தீபம்'],
      'te': ['సత్యనారాయణ స్వామి పూజ', 'రవ్వ కేసరి నైవేద్యం', 'తులసి కోట వద్ద నెయ్యి దీపం'],
      'hi': ['सत्यनारायण व्रत एवं कथा श्रवण', 'पंजीरी एवं शीरा भोग', 'तुलसी दीपदान'],
      'ml': ['സത്യനാരായണ പൂജ', 'തുളസിത്തറയിൽ നെയ്വിളക്ക്'],
      'en': ['Sri Satyanarayana Swamy Vrata', 'Offering sweet semolina (Sheera) prasadam', 'Lighting ghee deepa at Tulasi altar'],
    };
    final badges = {
      'kn': 'ಪೌರ್ಣಮಿ ಪುಣ್ಯದಿನ',
      'ta': 'பௌர்ணமி திருநாள்',
      'te': 'పౌర్ణమి పుణ్యదినం',
      'hi': 'पावन पूर्णिमा',
      'ml': 'പൗർണ്ണമി',
      'en': 'Full Moon',
    };

    return SpecialDayInfo(
      id: 'purnima_day',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ಶ್ರೀ ಸತ್ಯನಾರಾಯಣಾಯ ನಮಃ • Om Sri Satyanarayanaya Namah',
      recommendedStotram: 'Sri Satyanarayana Ashtakam',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getAmavasyaInfo(int weekday, String lang, DateTime date) {
    final titles = {
      'kn': 'ಅಮಾವಾಸ್ಯೆ ಪುಣ್ಯದಿನ',
      'ta': 'அமாவாசை புண்ணிய நாள்',
      'te': 'అమావాస్య పుణ్యదినం',
      'hi': 'पावन अमावस्या तिथि',
      'ml': 'അമാവാസി പുണ്യദിനം',
      'en': 'Amavasya (New Moon) Sacred Day',
    };
    final subtitles = {
      'kn': 'ಪಿತೃ ತರ್ಪಣ & ದೀಪಾರಾಧನೆ',
      'ta': 'முன்னோர் வழிபாடு & தீப வழிபாடு',
      'te': 'పితృ తర్పణం & దీపారాధన',
      'hi': 'पितृ स्मरण एवं संध्या दीपदान',
      'ml': 'പിതൃ തർപ്പണവും ദീപവും',
      'en': 'Ancestral Prayers & Spiritual Cleansing',
    };
    final deities = {
      'kn': 'ಪಿತೃ ದೇವತೆಗಳು & ಶ್ರೀ ಪರಮೇಶ್ವರ',
      'ta': 'பித்ரு தேவர்கள் & ஸ்ரீ பரமேஸ்வரர்',
      'te': 'పితృ దేవతలు & పరమేశ్వరుడు',
      'hi': 'पितृ देव एवं भगवान शिव',
      'ml': 'പിതൃക്കളും ഭഗവാൻ ശിവനും',
      'en': 'Pitru Devas & Lord Shiva',
    };
    final sigs = {
      'kn': 'ಅಮಾವಾಸ್ಯೆಯಂದು ನಕಾರಾತ್ಮಕ ಶಕ್ತಿಗಳು ದೂರವಾಗಲು ಮನೆಯಲ್ಲಿ ದೀಪ ಬೆಳಗಿಸಿ, ಪಿತೃಗಳಿಗೆ ತರ್ಪಣ ನೀಡುವುದು ಅತ್ಯಂತ ಶ್ರೇಯಸ್ಕರ.',
      'ta': 'அமாவாசை நன்னாளில் முன்னோர்களை வழிபட்டு தீபமேற்றுவது நன்மை பயக்கும்.',
      'te': 'అమావాస్య రోజున పితృదేవతలను స్మరించి దీపాలు వెలిగిస్తే ఇంట్లో శాంతి నెలకొంటుంది.',
      'hi': 'अमावस्या पर पितृ तर्पण एवं संध्या दीप प्रज्ज्वलन से नकारात्मकता दूर होती है।',
      'ml': 'അമാവാസി ദിനത്തിൽ പിതൃക്കളെ സ്മരിക്കുന്നത് ഉത്തമമാണ്.',
      'en': 'New Moon day sacred for remembering ancestors and removing inner obstacles.',
    };
    final rituals = {
      'kn': ['ಪಿತೃಗಳಿಗೆ ತರ್ಪಣ ಸಮರ್ಪಣೆ', 'ಸಂಜೆ ಹೊಸಿಲಲ್ಲಿ ದೀಪ ಬೆಳಗುವುದು', 'ಅನ್ನದಾನ'],
      'ta': ['முன்னோர்களுக்கு தர்ப்பணம்', 'வாசற்படியில் தீபம் ஏற்றுதல்', 'அன்னதானம்'],
      'te': ['పితృ తర్పణం సమర్పణ', 'గడప వద్ద సాయంత్రం దీపం', 'అన్నదానం'],
      'hi': ['पितृ तर्पण', 'सायंकाल देहरी पर दीपदान', 'अन्नदान'],
      'ml': ['പിതൃ തർപ്പണം', 'സന്ധ്യാ ദീപം തെളിയിക്കൽ', 'അന്നദാനം'],
      'en': ['Tarpana for ancestors', 'Lighting evening lamps at home threshold', 'Food charity'],
    };
    final badges = {
      'kn': 'ಅಮಾವಾಸ್ಯೆ',
      'ta': 'அமாவாசை',
      'te': 'అమావాస్య',
      'hi': 'अमावस्या',
      'ml': 'അമാവാസി',
      'en': 'New Moon',
    };

    return SpecialDayInfo(
      id: 'amavasya_day',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ನಮಃ ಶಿವಾಯ • Om Namah Shivaya',
      recommendedStotram: 'Shiva Panchakshara Stotram',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getDhanterasInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ಧನತೇರಸ್ (ಧನ್ವಂತರಿ ಜಯಂತಿ)',
      'ta': 'தனத்திரயோதசி (தன்வந்தரி ஜெயந்தி)',
      'te': 'ధనత్రయోదశి (ధన్వంతరి జయంతి)',
      'hi': 'धनतेरस (धन्वंतरि जयंती)',
      'ml': 'ധനത്രയോദശി (ധന്വന്തരി ജയന്തി)',
      'en': 'Dhanteras & Dhanvantari Jayanti',
    };
    final subtitles = {
      'kn': 'ದೀಪಾವಳಿಯ ಶುಭಾರಂಭ & ಆರೋಗ್ಯ ಸಮೃದ್ಧಿ',
      'ta': 'தீபாவளியின் மங்கள ஆரம்பம் & ஆரோக்கிய வளம்',
      'te': 'దీపావళి శుభారంభం & ఆరోగ్య సమృద్ధి',
      'hi': 'दीपावली का पावन शुभारंभ एवं आरोग्य समृद्धि',
      'ml': 'ദീപാവലിയുടെ തുടക്കം',
      'en': 'Auspicious Beginning of Deepavali',
    };
    final deities = {
      'kn': 'ಭಗವಾನ್ ಧನ್ವಂತರಿ & ಲಕ್ಷ್ಮೀ ಕುಬೇರ',
      'ta': 'ஸ்ரீ தன்வந்தரி பகவான் & லட்சுமி குபேரர்',
      'te': 'ధన్వంతరి భగవానుడు & లక్ష్మీ కుబేరుడు',
      'hi': 'भगवान धन्वंतरि एवं माता लक्ष्मी-कुबेर',
      'ml': 'ഭഗവാൻ ധന്വന്തരിയും ലക്ഷ്മീദേവിയും',
      'en': 'Lord Dhanvantari & Goddess Lakshmi',
    };
    final sigs = {
      'kn': 'ಆರೋಗ್ಯದ ಅಧಿದೇವತೆ ಧನ್ವಂತರಿ ಹಾಗೂ ಸಮೃದ್ಧಿಯ ಅಧಿದೇವತೆ ಲಕ್ಷ್ಮಿಯ ಆರಾಧನೆಯ ದಿನ.',
      'ta': 'ஆரோக்கியத்தின் அதிபதி தன்வந்தரி மற்றும் செல்வத்தின் அதிபதி லட்சுமியை வழிபடும் நாள்.',
      'te': 'ఆరోగ్య ప్రదాత ధన్వంతరి మరియు ఐశ్వర్య ప్రదాత్రి లక్ష్మీదేవిని పూజించే శుభదినం.',
      'hi': 'आरोग्य के देवता धन्वंतरि एवं ऐश्वर्य की देवी महालक्ष्मी की उपासना का दिन।',
      'ml': 'ആരോഗ്യത്തിന്റെയും ഐശ്വര്യത്തിന്റെയും പൂജ.',
      'en': 'Celebrates Lord Dhanvantari for health and Goddess Lakshmi for abundance.',
    };
    final rituals = {
      'kn': ['ದಕ್ಷಿಣ ದಿಕ್ಕಿಗೆ ಯಮದೀಪ ಬೆಳಗುವುದು', 'ಧನ್ವಂತರಿ ಪೂಜೆ', 'ಹೊಸ ಪಾತ್ರೆ ಅಥವಾ ಲೋಹ ಖರೀದಿ'],
      'ta': ['தெற்கு நோக்கி எமதீபம் ஏற்றுதல்', 'தன்வந்தரி பூஜை', 'புதிய பாத்திரம் வாங்குதல்'],
      'te': ['దక్షిణ దిశగా యమదీపం వెలిగించడం', 'ధన్వంతరి పూజ', 'కొత్త పాత్రలు కొనడం'],
      'hi': ['दक्षिण दिशा में यमदीप प्रज्ज्वलन', 'धन्वंतरि पूजन', 'धातु/बर्तन क्रय'],
      'ml': ['ദീപം തെളിയിക്കൽ', 'ധന്വന്തരി പൂജ'],
      'en': ['Lighting Yama Deepa facing south', 'Prayers for health to Dhanvantari', 'Purchasing new metal utensils'],
    };
    final badges = {
      'kn': 'ದೀಪಾವಳಿ ದಿನ ೧',
      'ta': 'தீபாவளி நாள் ௧',
      'te': 'దీపావళి రోజు ౧',
      'hi': 'दीपावली दिवस १',
      'ml': 'ദീപാവലി ദിനം 1',
      'en': 'Deepavali Day 1',
    };

    return SpecialDayInfo(
      id: 'dhanteras',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ಧನ್ವಂತರಯೇ ನಮಃ • Om Dhanvantaraye Namah',
      recommendedStotram: 'Dhanvantari Mahamantra',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getNarakaChaturdashiInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ನರಕ ಚತುರ್ದಶಿ (ದೀಪಾವಳಿ ಎಣ್ಣೆಶಾಸ್ತ್ರ)',
      'ta': 'நரக சதுர்த்தசி (தீபாவளி கங்கா ஸ்நானம்)',
      'te': 'నరక చతుర్దశి (అభ్యంగన స్నానం)',
      'hi': 'नरक चतुर्दशी (रूप चौदस एवं अभ्यंग स्नान)',
      'ml': 'നരക ചതുർദ്ദശി',
      'en': 'Naraka Chaturdashi (Abhyanga Snana)',
    };
    final subtitles = {
      'kn': 'ದುಷ್ಟ ಶಕ್ತಿಗಳ ನಿವಾರಣೆ & ತೈಲಾಭ್ಯಂಜನ',
      'ta': 'தீய சக்திகள் அழிவு & புனித எண்ணெய்க் குளியல்',
      'te': 'దుష్ట శక్తుల నివారణ & తైలాభ్యంగనం',
      'hi': 'अधर्म पर विजय एवं पावन अभ्यंग स्नान',
      'ml': 'തൈലാഭ്യംഗന സ്നാനം',
      'en': 'Triumph of Light & Sacred Oil Bath',
    };
    final deities = {
      'kn': 'ಶ್ರೀ ಕೃಷ್ಣ & ಸತ್ಯಭಾಮ',
      'ta': 'ஸ்ரீ கிருஷ்ணர் & சத்யபாமா',
      'te': 'శ్రీ కృష్ణుడు & సత్యభామ',
      'hi': 'भगवान श्रीकृष्ण एवं सत्यभामा',
      'ml': 'ശ്രീകൃഷ്ണനും സത്യഭാമയും',
      'en': 'Lord Krishna & Satyabhama',
    };
    final sigs = {
      'kn': 'ಶ್ರೀಕೃಷ್ಣನು ನರಕಾಸುರನನ್ನು ವಧಿಸಿ ಧರ್ಮ ಸ್ಥಾಪಿಸಿದ ಮಹಾದಿನ. ಸೂರ್ಯೋದಯಕ್ಕೂ ಮುನ್ನ ಗಂಗಾಪೂಜೆ ಮಾಡಿ ಅಭ್ಯಂಜನ ಸ್ನಾನ ಮಾಡುವುದು ಶ್ರೇಷ್ಠ.',
      'ta': 'ஸ்ரீகிருஷ்ணர் நரகாசுரனை வதைத்து நலம் காத்த நாள். கங்கா ஸ்நானம் செய்வது விசேஷம்.',
      'te': 'శ్రీకృష్ణుడు నరకాసురుడిని వధించి ధర్మాన్ని నిలిపిన రోజు. సూర్యోదయానికి ముందే అభ్యంగన స్నానం ఆచరిస్తారు.',
      'hi': 'भगवान श्रीकृष्ण द्वारा नरकासुर वध का पावन दिवस। प्रातःकाल अभ्यंग स्नान से पापों का क्षय होता है।',
      'ml': 'നരകാസുര വധത്തിന്റെ സ്മരണയിൽ ദീപം തെളിയിക്കുന്നു.',
      'en': 'Lord Krishna destroyed Narakasura. Taking early morning oil bath washes away past sins.',
    };
    final rituals = {
      'kn': ['ಬ್ರಾಹ್ಮೀ ಮುಹೂರ್ತದಲ್ಲಿ ತೈಲಾಭ್ಯಂಜನ ಸ್ನಾನ', 'ಮನೆಯ ಮುಂದೆ ಸಾಲು ದೀಪಗಳು', 'ಸಿಹಿ ಹಂಚಿಕೆ'],
      'ta': ['அதிகாலையில் கங்கா ஸ்நானம்', 'தீபங்கள் ஏற்றுதல்', 'இனிப்பு பரிமாறுதல்'],
      'te': ['బ్రాహ్మీ ముహూర్తంలో అభ్యంగన స్నానం', 'వరుస దీపాలు వెలిగించడం', 'మిఠాయిలు పంచడం'],
      'hi': ['उषाकाल में अभ्यंग स्नान', 'दीप प्रज्ज्वलन', 'मिष्ठान वितरण'],
      'ml': ['എണ്ണതേച്ചു കുളി', 'ദീപങ്ങൾ തെളിയിക്കൽ'],
      'en': ['Sacred early morning oil bath', 'Lighting series of clay oil lamps', 'Sharing festival sweets'],
    };
    final badges = {
      'kn': 'ದೀಪಾವಳಿ ದಿನ ೨',
      'ta': 'தீபாவளி நாள் ௨',
      'te': 'దీపావళి రోజు ౨',
      'hi': 'दीपावली दिवस २',
      'ml': 'ദീപാവലി ദിനം 2',
      'en': 'Deepavali Day 2',
    };

    return SpecialDayInfo(
      id: 'naraka_chaturdashi',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ನಮೋ ಭಗವತೇ ವಾಸುದೇವಾಯ • Om Namo Bhagavate Vasudevaya',
      recommendedStotram: 'Krishna Ashtakam',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getLakshmiPoojaInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ದೀಪಾವಳಿ ಮಹಾಲಕ್ಷ್ಮೀ ಪೂಜೆ',
      'ta': 'தீபாவளி மகாலட்சுமி பூஜை',
      'te': 'దీపావళి మహాలక్ష్మీ పూజ',
      'hi': 'दीपावली महालक्ष्मी पूजन',
      'ml': 'ദീപാവലി മഹാലക്ഷ്മീ പൂജ',
      'en': 'Deepavali Maha Lakshmi Pooja',
    };
    final subtitles = {
      'kn': 'ಮನೆಯಲ್ಲಿ ದೀಪಗಳ ಹಬ್ಬ & ಸಿರಿ ಸಂಪತ್ತು',
      'ta': 'வீடெங்கும் தீப ஒளி & செல்வ செழிப்பு',
      'te': 'ఇల్లంతా దీపాల కాంతులు & సిరిసంపదలు',
      'hi': 'दीपोत्सव एवं अष्टलक्ष्मी कृपा प्राप्ति',
      'ml': 'ദീപങ്ങളുടെ ഉത്സവം & ഐശ്വര്യം',
      'en': 'Festival of Lights & Divine Abundance',
    };
    final deities = {
      'kn': 'ಶ್ರೀ ಮಹಾಲಕ್ಷ್ಮೀ & ಗಣಪತಿ',
      'ta': 'ஸ்ரீ மகாலட்சுமி & விநாயகர்',
      'te': 'శ్రీ మహాలక్ష్మి & గణపతి',
      'hi': 'माता महालक्ष्मी एवं श्री गणेश',
      'ml': 'ശ്രീ മഹാലക്ഷ്മിയും ഗണപതിയും',
      'en': 'Goddess Maha Lakshmi & Lord Ganesha',
    };
    final sigs = {
      'kn': 'ದೀಪಾವಳಿಯ ಅಮಾವಾಸ್ಯೆಯಂದು ಜಗದಂಬೆ ಲಕ್ಷ್ಮಿದೇವಿಯು ಭಕ್ತರ ಮನೆಗಳಿಗೆ ಆಗಮಿಸಿ ಅಷ್ಟೈಶ್ವರ್ಯವನ್ನು ಕರುಣಿಸುತ್ತಾಳೆ.',
      'ta': 'தீபாவளி அமாவாசையில் அன்னை லட்சுமி இல்லம் தோறும் எழுந்தருளி ஐஸ்வர்யம் அருளுகிறாள்.',
      'te': 'దీపావళి అమావాస్య నాడు లక్ష్మీదేవి భక్తుల గృహాలను దర్శించి అష్టైశ్వర్యాలు ప్రసాదిస్తుంది.',
      'hi': 'दीपावली की पावन रात्रि में माता लक्ष्मी का आगमन होता है, जिससे घर में सुख-समृद्धि वास करती है।',
      'ml': 'മഹാലക്ഷ്മീ പൂജ ഭവനങ്ങളിൽ സർവ്വ ഐശ്വര്യവും നിറയ്ക്കുന്നു.',
      'en': 'Goddess Lakshmi visits pure and illuminated homes to bestow auspicious abundance.',
    };
    final rituals = {
      'kn': ['ಸಂಜೆ ಸಾಲುಸಾಲು ಹಣತೆ ದೀಪಗಳನ್ನು ಬೆಳಗುವುದು', 'ಲಕ್ಷ್ಮೀ-ಕುಬೇರ ಪೂಜೆ', 'ರಂಗೋಲಿ ರಚನೆ'],
      'ta': ['அகல் விளக்குகள் ஏற்றுதல்', 'லட்சுமி-குபேர பூஜை', 'கோலமிடுதல்'],
      'te': ['ప్రమిదలలో దీపాలు వెలిగించడం', 'లక్ష్మీ-కుబేర పూజ', 'ముగ్గులు వేయడం'],
      'hi': ['दीप प्रज्ज्वलन', 'महालक्ष्मी-कुबेर पूजन', 'रंगोली निर्माण'],
      'ml': ['ദീപങ്ങൾ തെളിയിക്കൽ', 'ലക്ഷ്മീ പൂജ', 'കളമെഴുത്ത്'],
      'en': ['Lighting clay deepas around the house', 'Lakshmi-Kubera puja with coins', 'Sacred rangoli offerings'],
    };
    final badges = {
      'kn': 'ದೀಪಾವಳಿ ದಿನ ೩',
      'ta': 'தீபாவளி நாள் ௩',
      'te': 'దీపావళి రోజు ౩',
      'hi': 'दीपावली दिवस ३',
      'ml': 'ദീപാവലി ദിനം 3',
      'en': 'Deepavali Day 3',
    };

    return SpecialDayInfo(
      id: 'lakshmi_pooja',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ಶ್ರೀಂ ಹ್ರೀಂ ಕ್ಲೀಂ ಮಹಾಲಕ್ಷ್ಮ್ಯೈ ನಮಃ • Om Maha Lakshmyai Namah',
      recommendedStotram: 'Sri Mahalakshmi Ashtakam',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getBaliPadyamiInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ಬಲಿಪಾಡ್ಯಮಿ (ಗೋವು ಪೂಜೆ)',
      'ta': 'பலி பாட்யாமி (கோபூஜை)',
      'te': 'బలిపాడ్యమి (గోపూజ)',
      'hi': 'बलि प्रतिपदा (गोवर्धन पूजा / गोपूजा)',
      'ml': 'ബലിപാട്യാമി (ഗോപൂജ)',
      'en': 'Bali Padyami (Go Puja)',
    };
    final subtitles = {
      'kn': 'ಬಲಿ ಚಕ್ರವರ್ತಿ ಆರಾಧನೆ & ಗೋವು ಪೂಜೆ',
      'ta': 'பலி சக்கரவர்த்தி நினைவு & பசு வழிபாடு',
      'te': 'బలి చక్రవర్తి స్మరణ & గోమాత పూజ',
      'hi': 'राजा बलि स्मृति एवं कामधेनु गौमाता पूजन',
      'ml': 'ഗോപൂജയും ബലി സ്മരണയും',
      'en': 'King Bali Remembrance & Cow Worship',
    };
    final deities = {
      'kn': 'ವಾಮನ ಮೂರ್ತಿ & ಕಾಮಧೇನು',
      'ta': 'வாமன மூர்த்தி & காமதேனு',
      'te': 'వామన మూర్తి & కామధేనువు',
      'hi': 'भगवान वामन एवं गौमाता',
      'ml': 'വാമന മൂർത്തിയും കാമധേനുവും',
      'en': 'Lord Vamana & Kamadhenu',
    };
    final sigs = {
      'kn': 'ವಾಮನಾವತಾರದಲ್ಲಿ ಭಗವಂತನು ಬಲಿ ಚಕ್ರವರ್ತಿಗೆ ನೀಡಿದ ವರದಂತೆ ಬಲಿ ರಾಜನು ಭೂಮಿಗೆ ಬರುವ ದಿನ. ಗೋಪೂಜೆ ಪುಣ್ಯಪ್ರದ.',
      'ta': 'பலி மன்னன் பூமிக்கு வருகை தரும் நன்னாள். பசுக்களுக்கு பூஜை செய்வது அளப்பரிய புண்ணியம் தரும்.',
      'te': 'వామనుని అనుగ్రహంతో బలి చక్రవర్తి భూమిని దర్శించే రోజు. గోపూజ అత్యంత ఫలప్రదం.',
      'hi': 'दानवीर राजा बलि का पावन स्मरण दिवस। गौमाता की सेवा एवं पूजन से समृद्धि प्राप्त होती है।',
      'ml': 'ഗോപൂജയും ബലി സ്മരണയും ചെയ്യുന്ന പുണ്യദിനം.',
      'en': 'Day of honoring king Bali for his immense charity. Cows (Gomata) are worshiped.',
    };
    final rituals = {
      'kn': ['ಹಸುವಿಗೆ ಅರಿಶಿನ-ಕುಂಕುಮ ಹಚ್ಚಿ ಗೋಪೂಜೆ', 'ಬಲಿ ಪಾಡ್ಯಮಿ ದೀಪಾರಾಧನೆ', 'ನವೀನ ವಸ್ತ್ರಧಾರಣೆ'],
      'ta': ['பசுவுக்கு மஞ்சள்-குங்குமம் வைத்து கோபூஜை', 'தீப வழிபாடு', 'புத்தாடை அணிதல்'],
      'te': ['ఆవుకు పసుపు-కుంకుమలతో గోపూజ', 'దీపారాధన', 'నూతన వస్త్రధారణ'],
      'hi': ['गौमाता को तिलक कर पूजन', 'गोवर्धन परिक्रमा', 'नवीन वस्त्र धारण'],
      'ml': ['ഗോപൂജ', 'ദീപം തെളിയിക്കൽ'],
      'en': ['Worshiping and feeding cows', 'Bali Padyami deepa lighting', 'Wearing new attire'],
    };
    final badges = {
      'kn': 'ದೀಪಾವಳಿ ದಿನ ೪',
      'ta': 'தீபாவளி நாள் ௪',
      'te': 'దీపావళి రోజు ౪',
      'hi': 'दीपावली दिवस ४',
      'ml': 'ദീപാവലി ദിനം 4',
      'en': 'Deepavali Day 4',
    };

    return SpecialDayInfo(
      id: 'bali_padyami',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ನಮೋ ನಾರಾಯಣಾಯ • Om Namo Narayanaya',
      recommendedStotram: 'Vamana Stotram',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getMahaShivaratriInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ಮಹಾ ಶಿವರಾತ್ರಿ ಮಹಾಪರ್ವ',
      'ta': 'மகா சிவராத்திரி மகா திருவிழா',
      'te': 'మహా శివరాత్రి మహాపర్వం',
      'hi': 'महाशिवरात्रि पावन महापर्व',
      'ml': 'മഹാ ശിവരാത്രി പുണ്യദിനം',
      'en': 'Maha Shivaratri Grand Festival',
    };
    final subtitles = {
      'kn': 'ಜಾಗರಣೆ, ರುದ್ರಾಭಿಷೇಕ & ಲಿಂಗೋದ್ಭವ',
      'ta': 'இரவு விழிப்பு, ருத்ராபிஷேகம் & லிங்கோத்பவம்',
      'te': 'జాగరణ, రుద్రాభిషేకం & లింగోద్భవం',
      'hi': 'अखंड जागरण, रुद्राभिषेक एवं ज्योतिर्लिंग दर्शन',
      'ml': 'ജാഗരണം, രുദ്രാഭിഷേകം',
      'en': 'All-Night Vigil & Divine Rudrabhisheka',
    };
    final deities = {
      'kn': 'ಶ್ರೀ ಪರಮೇಶ್ವರ (ಮಹಾಲಿಂಗ)',
      'ta': 'ஸ்ரீ பரமேஸ்வரர் (மகாலிங்கம்)',
      'te': 'శ్రీ పరమేశ్వరుడు (మహాలింగం)',
      'hi': 'देवाधिदेव महादेव (शिवलिंग)',
      'ml': 'ശ്രീ പരമേശ്വരൻ',
      'en': 'Lord Shiva (Mahalinga)',
    };
    final sigs = {
      'kn': 'ಶಿವ-ಪಾರ್ವತಿಯರ ಕಲ್ಯಾಣ ಮಹೋತ್ಸವ ಮತ್ತು ಲಿಂಗೋದ್ಭವ ಪುಣ್ಯಕಾಲ. ಇಡೀ ರಾತ್ರಿ ಜಾಗರಣೆ ಹಾಗೂ ರುದ್ರಾಭಿಷೇಕದಿಂದ ಮುಕ್ತಿ ಪ್ರಾಪ್ತಿಯಾಗುತ್ತದೆ.',
      'ta': 'சிவ-பார்வதி திருமண நன்னாள் மற்றும் லிங்கோத்பவ காலம். இரவு முழுவதும் கண்விழித்து சிவனை வணங்குவது மோட்சம் தரும்.',
      'te': 'శివపార్వతుల కల్యాణ మహోత్సవం మరియు లింగోద్భవ సమయం. రాత్రంతా జాగరణ, రుద్రాభిషేకాలు విశేష ఫలాన్నిస్తాయి.',
      'hi': 'भगवान शिव और माता पार्वती के मंगल विवाह एवं ज्योतिर्लिंग प्राकट्य का महापर्व। रात्रि जागरण एवं अभिषेक कल्याणकारी है।',
      'ml': 'ശിവരാത്രി വ്രതവും ജാഗരണവും മോക്ഷദായകമാണ്.',
      'en': 'The great night of Lord Shiva. Fasting, night vigil, and chanting bring immense peace and liberation.',
    };
    final rituals = {
      'kn': ['ನಾಲ್ಕು ಜಾವದ ಶಿವಲಿಂಗ ಪೂಜೆ & ಬಿಲ್ವಾರ್ಚನೆ', 'ರಾತ್ರಿ ಜಾಗರಣೆ', 'ಉಪವಾಸ ವ್ರತ'],
      'ta': ['நான்கு கால சிவபூஜை & வில்வார்ச்சனை', 'இரவு விழிப்பு (ஜாகரணை)', 'உபவாச விரதம்'],
      'te': ['నాలుగు జాముల శివలింగ పూజ & బిల్వార్చన', 'రాత్రి జాగరణ', 'ఉపవాస వ్రతం'],
      'hi': ['चार प्रहर रुद्राभिषेक एवं बिल्वपत्र अर्पण', 'रात्रि जागरण', 'निर्जला/फलाहार उपवास'],
      'ml': ['നാല് യാമങ്ങളിലെ പൂജയും കൂവളാർച്ചനയും', 'രാത്രി ജാഗരണം', 'ഉപവാസം'],
      'en': ['Four Prahar Rudrabhishekam with Bilva leaves', 'All-night Jaagarane vigil', 'Strict fasting and meditation'],
    };
    final badges = {
      'kn': 'ಮಹಾ ಶಿವರಾತ್ರಿ',
      'ta': 'மகா சிவராத்திரி',
      'te': 'మహా శివరాత్రి',
      'hi': 'महाशिवरात्रि',
      'ml': 'മഹാ ശിവരാത്രി',
      'en': 'Maha Shivaratri',
    };

    return SpecialDayInfo(
      id: 'maha_shivaratri',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ನಮಃ ಶಿವಾಯ • Om Namah Shivaya',
      recommendedStotram: 'Sri Rudram & Shiva Tandava Stotram',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getGaneshChaturthiInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ಶ್ರೀ ಗಣೇಶ ಚತುರ್ಥಿ (ವಿನಾಯಕ ಹಬ್ಬ)',
      'ta': 'விநாயகர் சதுர்த்தி பெருவிழா',
      'te': 'వినాయక చవితి పండుగ',
      'hi': 'श्री गणेश चतुर्थी (विनायक उत्सव)',
      'ml': 'വിനായക ചതുർത്ഥി',
      'en': 'Sri Vinayaka Chaturthi Festival',
    };
    final subtitles = {
      'kn': 'ಮಹಾಗಣಪತಿಯ ಅವತಾರ ದಿನ',
      'ta': 'விநாயகப் பெருமானின் அவதார திருநாள்',
      'te': 'మహాగణపతి అవతార దినోత్సవం',
      'hi': 'विघ्नहर्ता भगवान गणेश का जन्मोत्सव',
      'ml': 'ഗണപതി ഭഗവാന്റെ ജന്മദിനം',
      'en': 'Birth Day of Lord Ganesha',
    };
    final deities = {
      'kn': 'ಶ್ರೀ ವರಸಿದ್ಧಿ ವಿನಾಯಕ',
      'ta': 'ஸ்ரீ வரசித்தி விநாயகர்',
      'te': 'శ్రీ వరసిద్ధి వినాయకుడు',
      'hi': 'भगवान वरसिद्धि विनायक',
      'ml': 'ശ്രീ സിദ്ധി വിനായകൻ',
      'en': 'Lord Varasiddhi Vinayaka',
    };
    final sigs = {
      'kn': 'ವಿಘ್ನರಾಜನ ಅವತಾರ ದಿನ. ಮಣ್ಣಿನ ಗಣಪತಿಯನ್ನು ಪ್ರತಿಷ್ಠಾಪಿಸಿ ೨೧ ಬಗೆಯ ಪತ್ರೆಗಳಿಂದ ಪೂಜಿಸಿದರೆ ಸಕಲ ಕಾರ್ಯಗಳು ಸಿದ್ಧಿಯಾಗುತ್ತವೆ.',
      'ta': 'விக்னங்களை தீர்க்கும் விநாயகரின் அவதார நாள். களிமண் விநாயகரை 21 வகை இலைகளால் பூஜிப்பது நலம் தரும்.',
      'te': 'విఘ్నాలను తొలగించే వినాయకుని జన్మదినం. మట్టి గణపతిని 21 రకాల పత్రాలతో పూజిస్తే సమస్త కార్యసిద్ధి కలుగుతుంది.',
      'hi': 'सकल विघ्न विनाशक श्रीगणेश का पावन प्राकट्य दिवस। २१ पत्री एवं मोदक अर्पण से सर्वकार्य सिद्ध होते हैं।',
      'ml': 'സകല വിഘ്നങ്ങളും നീക്കുന്ന വിനായക ചതുർത്ഥി.',
      'en': 'Arrival of Lord Ganesha to bestow auspicious beginnings and remove all obstacles.',
    };
    final rituals = {
      'kn': ['ಮಣ್ಣಿನ ಗಣೇಶನ ಪ್ರತಿಷ್ಠಾಪನೆ & ೨೧ ಪತ್ರೆಗಳ ಪೂಜೆ', '೨೧ ಮೋದಕ ನೈವೇದ್ಯ', 'ಅಥರ್ವಶೀರ್ಷ ಪಠಣ'],
      'ta': ['களிமண் விநாயகர் பிரதிஷ்டை & 21 பத்திரி பூஜை', 'கொழுக்கட்டை நைவேத்தியம்', 'கணேச அதர்வசீரிஷம்'],
      'te': ['మట్టి గణపతి ప్రతిష్ఠాపన & 21 పత్రి పూజ', '21 మోదకాలు లేదా కుడుములు', 'అథర్వశీర్ష పారాయణం'],
      'hi': ['पार्थिव गणेश स्थापना एवं २१ पत्री पूजन', '२१ मोदक भोग', 'गणपति अथर्वशीर्ष पाठ'],
      'ml': ['ഗണപതി പ്രതിഷ്ഠയും പൂജയും', 'മോദകം നിവേദ്യം'],
      'en': ['Clay Ganesha installation & 21 Patra Puja', 'Offering 21 modakas', 'Ganesha Atharvashirsha chanting'],
    };
    final badges = {
      'kn': 'ಗಣೇಶ ಹಬ್ಬ',
      'ta': 'விநாயகர் சதுர்த்தி',
      'te': 'వినాయక చవితి',
      'hi': 'गणेश चतुर्थी',
      'ml': 'വിനായക ചതുർത്ഥി',
      'en': 'Ganesh Chaturthi',
    };

    return SpecialDayInfo(
      id: 'ganesh_chaturthi',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ಗಂ ಗಣಪತಯೇ ನಮಃ • Om Gam Ganapataye Namah',
      recommendedStotram: 'Ganesha Atharvashirsha',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getKrishnaJanmashtamiInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ಶ್ರೀ ಕೃಷ್ಣ ಜನ್ಮಾಷ್ಟಮಿ (ಗೋಕುಲಾಷ್ಟಮಿ)',
      'ta': 'ஸ்ரீ கிருஷ்ண ஜெயந்தி (கோகுலாஷ்டமி)',
      'te': 'శ్రీ కృష్ణ జన్మాష్టమి (గోకులాష్టమి)',
      'hi': 'श्रीकृष्ण जन्माष्टमी (गोकुलाष्टमी)',
      'ml': 'ശ്രീകൃഷ്ണ ജന്മാഷ്ടമി',
      'en': 'Sri Krishna Janmashtami',
    };
    final subtitles = {
      'kn': 'ಭಗವಾನ್ ಶ್ರೀಕೃಷ್ಣನ ಅವತಾರ ಮಹೋತ್ಸವ',
      'ta': 'கண்ணன் அவதரித்த மங்கள திருநாள்',
      'te': 'శ్రీకృష్ణ భగవానుని అవతార మహోత్సవం',
      'hi': 'पूर्णब्रह्म भगवान श्रीकृष्ण का पावन अवतरण',
      'ml': 'ശ്രീകൃഷ്ണ ഭഗവാന്റെ അവതാരദിനം',
      'en': 'Divine Advent of Lord Sri Krishna',
    };
    final deities = {
      'kn': 'ಬಾಲಕೃಷ್ಣ & ಶ್ರೀ ವಾಸುದೇವ',
      'ta': 'ஸ்ரீ பாலகிருஷ்ணர் & வாசுதேவர்',
      'te': 'బాలకృష్ణుడు & వాసుదేవుడు',
      'hi': 'बालमुकुंद श्रीकृष्ण',
      'ml': 'ശ്രീകൃഷ്ണൻ',
      'en': 'Lord Sri Krishna',
    };
    final sigs = {
      'kn': 'ಮಧ್ಯರಾತ್ರಿ ರೋಹಿಣಿ ನಕ್ಷತ್ರದಲ್ಲಿ ಕೃಷ್ಣನ ಅವತಾರ. ಮನೆಯಲ್ಲಿ ಪುಟ್ಟ ಪಾದಗಳನ್ನು ಬಿಡಿಸಿ, ಬೆಣ್ಣೆ, ಅವಲಕ್ಕಿ ನೈವೇದ್ಯ ಮಾಡಿ ಸಂಭ್ರಮಿಸುವುದು.',
      'ta': 'நள்ளிரவில் ரோகிணி நட்சத்திரத்தில் அவதரித்த கண்ணன். இல்லத்தில் பாதங்கள் வரைந்து வெண்ணெய் நைவேத்தியம் செய்வது வழக்கம்.',
      'te': 'అర్ధరాత్రి రోహిణీ నక్షత్రంలో శ్రీకృష్ణుని జననం. ఇంట్లో చిన్ని పాదాల ముగ్గులు వేసి, వెన్న, అటుకులు నివేదిస్తారు.',
      'hi': 'मध्यरात्रि रोहिणी नक्षत्र में भगवान श्रीकृष्ण का प्राकट्य। माखन-मिश्री भोग एवं कान्हा के चरणों की सुंदर रंगोली।',
      'ml': 'ഉണ്ണിക്കണ്ണന്റെ ജന്മദിനം ഭക്തിയോടെ ആഘോഷിക്കുന്നു.',
      'en': 'Celebrates the midnight advent of Lord Krishna. Homes are decorated with butter and baby Krishna footsteps.',
    };
    final rituals = {
      'kn': ['ಬಾಲಕೃಷ್ಣನ ಪುಟ್ಟ ಪಾದಗಳ ರಂಗೋಲಿ', 'ಬೆಣ್ಣೆ & ಅವಲಕ್ಕಿ ನೈವೇದ್ಯ', 'ಮಧ್ಯರಾತ್ರಿ ಅರ್ಘ್ಯ ಪ್ರದಾನ'],
      'ta': ['கண்ணன் பாதக் கோலங்கள்', 'வெண்ணெய் & அவல் நைவேத்தியம்', 'நள்ளிரவு அர்க்கியம்'],
      'te': ['బాలకృష్ణుడి చిన్ని పాదాల ముగ్గు', 'వెన్న & అటుకుల నైవేద్యం', 'అర్ధరాత్రి అర్ఘ్యం'],
      'hi': ['कान्हा के पदचिह्न रंगोली', 'माखन-मिश्री एवं पंजीरी भोग', 'मध्यरात्रि आरती एवं अर्घ्य'],
      'ml': ['കണ്ണന്റെ കാൽപ്പാടുകൾ', 'വെണ്ണയും അവലും നിവേദ്യം'],
      'en': ['Drawing baby Krishna footsteps', 'Offering butter, avalakki, and festive treats', 'Midnight arghya'],
    };
    final badges = {
      'kn': 'ಕೃಷ್ಣ ಜನ್ಮಾಷ್ಟಮಿ',
      'ta': 'கிருஷ்ண ஜெயந்தி',
      'te': 'కృష్ణాష్టమి',
      'hi': 'जन्माष्टमी',
      'ml': 'ജന്മാഷ്ടമി',
      'en': 'Janmashtami',
    };

    return SpecialDayInfo(
      id: 'krishna_janmashtami',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಕೃಷ್ಣಾಯ ವಾಸುದೇವಾಯ ಹರಯೇ ಪರಮಾತ್ಮನೇ • Om Namo Bhagavate Vasudevaya',
      recommendedStotram: 'Madhurashtakam & Krishna Ashtakam',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getRamaNavamiInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ಶ್ರೀ ರಾಮನವಮಿ ಮಹೋತ್ಸವ',
      'ta': 'ஸ்ரீ ராம நவமி திருவிழா',
      'te': 'శ్రీ రామ నవమి మహోత్సవం',
      'hi': 'श्री रामनवमी महोत्सव',
      'ml': 'ശ്രീ രാമനവമി ഉത്സവം',
      'en': 'Sri Rama Navami Festival',
    };
    final subtitles = {
      'kn': 'ಮರ್ಯಾದಾ ಪುರುಷೋತ್ತಮ ಶ್ರೀರಾಮನ ಜನ್ಮದಿನ',
      'ta': 'மரியாதா புருஷோத்தமர் ஸ்ரீராமரின் அவதார நாள்',
      'te': 'మర్యాదా పురుషోత్తముడు శ్రీరాముని జన్మదినం',
      'hi': 'मर्यादा पुरुषोत्तम भगवान श्रीराम का जन्मोत्सव',
      'ml': 'ശ്രീരാമ ഭഗവാന്റെ അവതാരദിനം',
      'en': 'Birth Day of Lord Sri Rama',
    };
    final deities = {
      'kn': 'ಸೀತಾ ಲಕ್ಷ್ಮಣ ಸಮೇತ ಶ್ರೀರಾಮಚಂದ್ರ',
      'ta': 'சீதா லட்சுமண சமேத ஸ்ரீராமச்சந்திரர்',
      'te': 'సీతా లక్ష్మణ సమేత శ్రీరామచంద్రుడు',
      'hi': 'सीताराम एवं लक्ष्मण-हनुमान',
      'ml': 'ശ്രീരാമചന്ദ്രൻ',
      'en': 'Lord Sri Ramachandra',
    };
    final sigs = {
      'kn': 'ಧರ್ಮರಕ್ಷಕ ಶ್ರೀರಾಮನ ಆವಿರ್ಭಾವ ದಿನ. ಮಧ್ಯಾಹ್ನ ೧೨ ಗಂಟೆಗೆ ರಾಮ ಜನನೋತ್ಸವ, ಪಾನಕ, ಮಜ್ಜಿಗೆ, ಕೋಸಂಬರಿ ವಿತರಣೆ ಅತ್ಯಂತ ಶ್ರೇಷ್ಠ.',
      'ta': 'தர்மத்தை நிலைநாட்டிய ஸ்ரீராமரின் அவதார நாள். பானகம், நீர்மோர் நைவேத்தியம் விசேஷம்.',
      'te': 'ధర్మ రక్షకుడు శ్రీరాముడు జన్మించిన రోజు. మధ్యాహ్నం 12 గంటలకు రాముని జననం, పానకం, వడపప్పు నివేదన.',
      'hi': 'अभिजीत मुहूर्त में मर्यादा पुरुषोत्तम भगवान श्रीराम का प्राकट्य। पना एवं शीतल पेय वितरण।',
      'ml': 'ശ്രീരാമന്റെ അവതാരദിനം ഭക്തിയോടെ ആഘോഷിക്കുന്നു.',
      'en': 'Appearance day of Lord Rama at noon. Celebrated with cooling Panakam, buttermilk, and Kosambari.',
    };
    final rituals = {
      'kn': ['ಮಧ್ಯಾಹ್ನ ೧೨ ಗಂಟೆಗೆ ರಾಮ ಜನನೋತ್ಸವ', 'ಪಾನಕ, ಮಜ್ಜಿಗೆ, ಕೋಸಂಬರಿ ನೈವೇದ್ಯ', 'ರಾಮ ರಕ್ಷಾ ಸ್ತೋತ್ರ ಪಠಣ'],
      'ta': ['நண்பகலில் ராம ஜென்மோற்சவம்', 'பானகம், நீர்மோர் நைவேத்தியம்', 'ராம ரக்ஷா ஸ்தோத்திரம்'],
      'te': ['మధ్యాహ్నం 12 గంటలకు రాముని జననం', 'పానకం, మజ్జిగ, వడపప్పు సమర్పణ', 'రామ రక్షా స్తోత్ర పారాయణం'],
      'hi': ['मध्याह्न १२ बजे श्रीराम जन्मोत्सव', 'पना, छाछ एवं पंचामृत भोग', 'रामरक्षा स्तोत्र पाठ'],
      'ml': ['നട്ടുച്ചയ്ക്കുള്ള രാമപൂജ', 'പാനകം നിവേദ്യം', 'രാമരക്ഷാ സ്തോത്ര ജപം'],
      'en': ['Noon Rama Janma celebration', 'Panakam and Kosambari distribution', 'Rama Raksha Stotram chanting'],
    };
    final badges = {
      'kn': 'ರಾಮನವಮಿ',
      'ta': 'ராம நவமி',
      'te': 'శ్రీరామ నవమి',
      'hi': 'रामनवमी',
      'ml': 'രാമനവമി',
      'en': 'Rama Navami',
    };

    return SpecialDayInfo(
      id: 'rama_navami',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಶ್ರೀ ರಾಮ ರಾಮ ರಾಮೇತಿ ರಮೇ ರಾಮೇ ಮನೋರಮೇ • Sri Rama Jaya Rama Jaya Jaya Rama',
      recommendedStotram: 'Sri Rama Raksha Stotram',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getUgadiInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ಯುಗಾದಿ ಹಬ್ಬ (ಹೊಸ ಸಂವತ್ಸರದ ಆದಿ)',
      'ta': 'யுகாதி பண்டிகை (புத்தாண்டு)',
      'te': 'ఉగాది పండుగ (నూతన సంవత్సరాది)',
      'hi': 'युगादि / गुड़ी पड़वा (नव संवत्सर)',
      'ml': 'യുഗാദി (പുതുവർഷം)',
      'en': 'Ugadi / Gudi Padwa (New Year)',
    };
    final subtitles = {
      'kn': 'ಸನಾತನ ವೈದಿಕ ಹೊಸ ವರ್ಷದ ಪುಣ್ಯದಿನ',
      'ta': 'வேத முறைப்படியான புத்தாண்டு திருநாள்',
      'te': 'సనాతన వైదిక నూతన సంవత్సర పుణ్యదినం',
      'hi': 'सनातन नव संवत्सर का पावन शुभारंभ',
      'ml': 'വേദകാല പുതുവർഷാരംഭം',
      'en': 'Vedic New Year Day',
    };
    final deities = {
      'kn': 'ಸೃಷ್ಟಿಕರ್ತ ಬ್ರಹ್ಮದೇವ & ಕುಲದೇವತೆ',
      'ta': 'படைப்பின் கடவுள் பிரம்மன் & குலதெய்வம்',
      'te': 'సృష్టికర్త బ్రహ్మదేవుడు & కులదైవం',
      'hi': 'सृष्टिकर्ता ब्रह्मा जी एवं कुलदेवी/देवता',
      'ml': 'ബ്രഹ്മദേവനും കുലദേവതയും',
      'en': 'Lord Brahma & Kuladevata',
    };
    final sigs = {
      'kn': 'ಬ್ರಹ್ಮದೇವನು ಜಗತ್ತನ್ನು ಸೃಷ್ಟಿಸಲು ಪ್ರಾರಂಭಿಸಿದ ದಿನ. ಬೇವು-ಬೆಲ್ಲ ಸೇವನೆಯು ಜೀವನದ ಸುಖ-ದುಃಖಗಳನ್ನು ಸಮಾನವಾಗಿ ಸ್ವೀಕರಿಸುವ ಸಂಕೇತ.',
      'ta': 'பிரம்மன் சிருஷ்டியை தொடங்கிய நாள். வேப்பம்பூ-வெல்லம் சுவைப்பது சுக-துக்கங்களை சமமாக ஏற்கும் குறியீடு.',
      'te': 'బ్రహ్మదేవుడు సృష్టిని ప్రారంభించిన దినం. ఉగాది పచ్చడి జీవితంలోని సుఖదుఃఖాలను సమానంగా స్వీకరించే సంకేతం.',
      'hi': 'ब्रह्मा जी द्वारा सृष्टि रचना का आरंभ दिवस। नीम-गुड़ का सेवन जीवन में सुख-दुःख की समता का प्रतीक है।',
      'ml': 'പുതിയ വർഷത്തെ ഭക്തിയോടെ സ്വാഗതം ചെയ്യുന്നു.',
      'en': 'Dawn of the Vedic era. Tasting neem and jaggery symbolizes accepting life with equanimity.',
    };
    final rituals = {
      'kn': ['ಮಾವು-ಬೇವಿನ ತೋರಣ', 'ಬೇವು-ಬೆಲ್ಲ ಪ್ರಸಾದ ಸ್ವೀಕಾರ', 'ಹೊಸ ಪಂಚಾಂಗ ಶ್ರವಣ'],
      'ta': ['மா இலை தோரணம்', 'வேப்பம்பூ-வெல்லம் உண்ணுதல்', 'பஞ்சாங்க படனம்'],
      'te': ['మామిడాకుల తోరణాలు', 'ఉగాది పచ్చడి సేవనం', 'నూతన పంచాంగ శ్రవణం'],
      'hi': ['तोरण बंधन', 'नीम-गुड़ प्रसादम', 'नव संवत्सर पंचांग श्रवण'],
      'ml': ['തോരണങ്ങൾ ചാർത്തൽ', 'പഞ്ചാംഗ ശ്രവണം'],
      'en': ['Mango leaf torana at entrance', 'Tasting Neem & Jaggery (Bevu-Bella)', 'Panchanga Shravana for the year'],
    };
    final badges = {
      'kn': 'ಯುಗಾದಿ ಹಬ್ಬ',
      'ta': 'யுகாதி',
      'te': 'ఉగాది',
      'hi': 'नव संवत्सर',
      'ml': 'യുഗാദി',
      'en': 'Ugadi New Year',
    };

    return SpecialDayInfo(
      id: 'ugadi',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಶತಾಯುರ್ವಜ್ರದೇಹಾಯ ಸರ್ವಸಂಪತ್ಕರಾಯ ಚ • Om Brahmane Namah',
      recommendedStotram: 'Panchanga Shravana Prayers',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getMakaraSankrantiInfo(String lang, DateTime date) {
    final titles = {
      'kn': 'ಮಕರ ಸಂಕ್ರಾಂತಿ (ಸುಗ್ಗಿ ಹಬ್ಬ)',
      'ta': 'மகர சங்கராந்தி (பொங்கல் நன்னாள்)',
      'te': 'మకర సంక్రాంతి (సంక్రాంతి పండుగ)',
      'hi': 'मकर संक्रांति (उत्तरायण महापर्व)',
      'ml': 'മകര സംക്രാന്തി',
      'en': 'Makara Sankranti (Harvest Festival)',
    };
    final subtitles = {
      'kn': 'ಉತ್ತರಾಯಣ ಪುಣ್ಯಕಾಲದ ಆರಂಭ & ಸೂರ್ಯಾರಾಧನೆ',
      'ta': 'உத்தராயண புண்ணியகால ஆரம்பம் & சூரிய வழிபாடு',
      'te': 'ఉత్తరాయణ పుణ్యకాల ప్రారంభం & సూర్యారాధన',
      'hi': 'सूर्य का मकर राशि में प्रवेश एवं उत्तरायण पुण्यकाल',
      'ml': 'ഉത്തരായന പുണ്യകാലം',
      'en': 'Dawn of Uttarayana & Sun Transiting to Makara',
    };
    final deities = {
      'kn': 'ಭಗವಾನ್ ಸೂರ್ಯನಾರಾಯಣ',
      'ta': 'சூரிய நாராயண பகவான்',
      'te': 'సూర్య భగవానుడు',
      'hi': 'भगवान सूर्यनारायण',
      'ml': 'സൂര്യഭഗവാൻ',
      'en': 'Lord Surya Narayana',
    };
    final sigs = {
      'kn': 'ಸೂರ್ಯನು ದಕ್ಷಿಣಾಯನದಿಂದ ಉತ್ತರಾಯಣಕ್ಕೆ ಪಥ ಬದಲಿಸುವ ಪುಣ್ಯ ಕಾಲ. ಎಳ್ಳು-ಬೆಲ್ಲ ಹಂಚಿ ಒಳ್ಳೆಯ ಮಾತುಗಳನ್ನಾಡುವ ಹಬ್ಬ.',
      'ta': 'சூரிய பகவான் தக்ஷிணாயனத்திலிருந்து உத்தராயணத்திற்கு செல்லும் மங்கள காலம். எள்ளும் வெல்லமும் பரிமாறும் நன்னாள்.',
      'te': 'సూర్యుడు ఉత్తరాయణంలోకి ప్రవేశించే పుణ్యకాలం. నువ్వులు-బెల్లం ఇచ్చిపుచ్చుకుంటూ ఆనందించే పండుగ.',
      'hi': 'भगवान सूर्य का मकर राशि में प्रवेश। तिल-गुड़ दान एवं स्नान से अक्षय पुण्य प्राप्त होता है।',
      'ml': 'സൂര്യദേവനെ പൂജിക്കുന്ന വിളവെടുപ്പ് ഉത്സവം.',
      'en': 'Sun moves into Makara rashi initiating Uttarayana. Exchanging sesame-jaggery signifies sweet speech.',
    };
    final rituals = {
      'kn': ['ಎಳ್ಳು-ಬೆಲ್ಲ, ಕೊಬ್ಬರಿ ವಿನಿಮಯ', 'ಸೂರ್ಯದೇವರಿಗೆ ತರ್ಪಣ & ಗಾಯತ್ರೀ ಜಪ', 'ಗೋವುಗಳ ಪೂಜೆ'],
      'ta': ['பொங்கல் நைவேத்தியம்', 'சூரிய பகவானுக்கு அர்க்கியம்', 'மாட்டுப் பொங்கல்'],
      'te': ['నువ్వులు-బెల్లం పంపిణీ', 'సూర్యునికి అర్ఘ్యం & గాయత్రీ జపం', 'గోపూజ'],
      'hi': ['तिल-गुड़ एवं खिचड़ी दान', 'सूर्य अर्घ्य एवं गायत्री जप', 'गौ सेवा'],
      'ml': ['എള്ളും ശർക്കരയും വിതരണം', 'സൂര്യപൂജ'],
      'en': ['Exchanging Ellu-Bella and sugarcane', 'Surya Arghya and Gayatri japa', 'Honoring cattle and nature'],
    };
    final badges = {
      'kn': 'ಸಂಕ್ರಾಂತಿ ಹಬ್ಬ',
      'ta': 'பொங்கல் / சங்கராந்தி',
      'te': 'సంక్రాంతి',
      'hi': 'मकर संक्रांति',
      'ml': 'സംക്രാന്തി',
      'en': 'Sankranti',
    };

    return SpecialDayInfo(
      id: 'makara_sankranti',
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: 'ಓಂ ಸೂರ್ಯಾಯ ನಮಃ • Om Suryaya Namah',
      recommendedStotram: 'Aditya Hridaya Stotram',
      badgeText: badges[lang] ?? badges['en']!,
      date: date,
    );
  }

  static SpecialDayInfo _getDailyVedicBlessing(int weekday, String lang, DateTime date) {
    final Map<int, Map<String, dynamic>> weekdayData = {
      1: {
        'id': 'daily_vedic_monday',
        'title': {
          'kn': 'ಸೋಮವಾರ ಮಹಾದೇವ ಪೂಜೆ',
          'ta': 'திங்கட்கிழமை சிவபெருமான் வழிபாடு',
          'te': 'సోమవారం పరమశివ పూజ',
          'hi': 'सोमवार भगवान शिव पूजन',
          'ml': 'തിങ്കളാഴ്ച മഹാദേവ പൂജ',
          'en': 'Monday Sacred Shiva Puja',
        },
        'subtitle': {
          'kn': 'ಶ್ರೀ ಮಹಾದೇವ ಸದಾಶಿವನ ದಿವ್ಯ ಆರಾಧನೆ & ಬಿಲ್ವಾರ್ಚನೆ',
          'ta': 'சிவபெருமானின் திவ்ய தரிசனம் மற்றும் வில்வார்ச்சனை',
          'te': 'పరమశివుని దివ్య పూజ మరియు బిల్వార్చన',
          'hi': 'भगवान शिव का पावन अभिषेक एवं बिल्वार्चन',
          'ml': 'ശിവഭഗവാന്റെ ദിവ്യ പൂജയും കൂവളാർച്ചനയും',
          'en': 'Sacred Shiva Worship, Abhisheka & Bilva Offering',
        },
        'deity': {
          'kn': 'ಭಗವಾನ್ ಶ್ರೀ ಪರಮೇಶ್ವರ (ಮಹಾದೇವ)',
          'ta': 'சிவபெருமான்',
          'te': 'పరమశివుడు (మహాదేవుడు)',
          'hi': 'भगवान श्री शिव शंकर',
          'ml': 'മഹാദേവൻ',
          'en': 'Lord Shiva (Mahadeva)',
        },
        'significance': {
          'kn': 'ಸೋಮವಾರವು ಕೈಲಾಸನಾಥ ಶಿವನಿಗೆ ಅತ್ಯಂತ ಪ್ರಿಯವಾದ ದಿನ. ಶಿವನಾಮ ಸ್ಮರಣೆಯಿಂದ ಮನಶ್ಶಾಂತಿ, ಆಯುರಾರೋಗ್ಯ ಹಾಗೂ ಸಕಲ ಪಾಪನಾಶ ಲಭಿಸುತ್ತದೆ.',
          'ta': 'திங்கட்கிழமை சிவபெருமானுக்கு உரிய புனித நாள். சிவநாமத்தை உச்சரிப்பதால் மனஅமைதியும் மங்களமும் கிடைக்கும்.',
          'te': 'సోమవారం పరమశివునికి ఎంతో ప్రీతిపాత్రమైన రోజు. శివనామ స్మరణతో మనశ్శాంతి, ఆరోగ్యం లభిస్తాయి.',
          'hi': 'सोमवार भगवान शिव का अत्यंत प्रिय दिन है। शिव आराधना से मानसिक शांति, उत्तम स्वास्थ्य एवं सर्वमंगल प्राप्त होता है।',
          'ml': 'ശിവഭഗവാനെ ആരാധിക്കാൻ ഏറ്റവും ഉചിതമായ ദിവസമാണ് തിങ്കളാഴ്ച.',
          'en': 'Monday is exceptionally dear to Lord Shiva. Chanting the Panchakshari Mantra bestows serenity, health, and supreme blessings.',
        },
        'rituals': {
          'kn': ['ಶಿವಪಂಚಾಕ್ಷರಿ ಜಪ (ಓಂ ನಮಃ ಶಿವಾಯ)', 'ಬಿಲ್ವಪತ್ರೆ ಹಾಗೂ ಜಲಾಭಿಷೇಕ', 'ದೀಪಾರಾಧನೆ ಮತ್ತು ಭಕ್ತಿ ಸಂಗೀತ'],
          'ta': ['ஓம் நம சிவாய மந்திர ஜபம்', 'வில்வார்ச்சனை மற்றும் தீபாராதனை', 'பக்தி பாடல்கள் கேட்டல்'],
          'te': ['ఓం నమః శివాయ జపం', 'బిల్వపత్ర పూజ మరియు జలాభిషేకం', 'శివ స్తోత్రాలు ఆలకించడం'],
          'hi': ['ॐ नमः शिवाय महामंत्र जप', 'बिल्वपत्र अर्पण एवं जलाभिषेक', 'शिव स्तुति श्रवण'],
          'ml': ['ഓം നമഃ ശിവായ ജപം', 'കൂവളത്തില സമർപ്പണം', 'ശിവ സ്തോത്ര ശ്രവണം'],
          'en': ['Chanting Om Namah Shivaya', 'Water Abhisheka & Bilva leaf offering', 'Listening to sacred Shiva Stotrams'],
        },
        'mantra': 'ಓಂ ನಮಃ ಶಿವಾಯ • Om Namah Shivaya',
        'color': 'ಶ್ವೇತ ವರ್ಣ • White / Pearl',
        'stotram': 'Shiva Tandava Stotram',
      },
      2: {
        'id': 'daily_vedic_tuesday',
        'title': {
          'kn': 'ಮಂಗಳವಾರ ಹನುಮಂತ & ಸುಬ್ರಹ್ಮಣ್ಯ ಪೂಜೆ',
          'ta': 'செவ்வாய்க்கிழமை முருகப்பெருமான் & அனுமன் வழிபாடு',
          'te': 'మంగళవారం ఆంజనేయ & సుబ్రహ్మణ్య స్వామి పూజ',
          'hi': 'मंगलवार श्री हनुमान एवं कार्तिकेय पूजन',
          'ml': 'ചൊവ്വാഴ്ച ഹനുമാൻ & സുബ്രഹ്മണ്യ പൂജ',
          'en': 'Tuesday Sacred Hanuman & Subrahmanya Puja',
        },
        'subtitle': {
          'kn': 'ಸಂಕಟಮೋಚನ ಹನುಮಂತ ಹಾಗೂ ಷಣ್ಮುಖ ಸುಬ್ರಹ್ಮಣ್ಯ ಆರಾಧನೆ',
          'ta': 'சங்கடமோசன அனுமன் மற்றும் முருகனின் திவ்ய அருள்',
          'te': 'భయాందోళనలను తొలగించే హనుమత్ ఆరాధన',
          'hi': 'संकटमोचन हनुमान जी की पावन कृपा',
          'ml': 'വിഘ്നങ്ങളും രോഗങ്ങളും അകറ്റുന്ന ഭക്തി പൂജ',
          'en': 'Removal of Obstacles, Fear & Granting Strength',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಹನುಮಂತ & ಸುಬ್ರಹ್ಮಣ್ಯ ಸ್ವಾಮಿ',
          'ta': 'ஸ்ரீ அனுமன் & முருகப்பெருமான்',
          'te': 'శ్రీ ఆంజనేయ & సుబ్రహ్మణ్య స్వామి',
          'hi': 'श्री हनुमान जी एवं कार्तिकेय स्वामी',
          'ml': 'ശ്രീ ഹനുമാൻ & സുബ്രഹ്മണ്യൻ',
          'en': 'Lord Hanuman & Subrahmanya',
        },
        'significance': {
          'kn': 'ಮಂಗಳವಾರದ ಪೂಜೆಯು ಋಣಭಾರ, ಭಯ, ಶತ್ರುಬಾಧೆ ಹಾಗೂ ಕುಜದೋಷ ನಿವಾರಣೆಗೆ ಅತ್ಯಂತ ಶ್ರೇಷ್ಠ. ಹನುಮಾನ್ ಚಾಲೀಸಾ ಪಠಣವು ಆತ್ಮವಿಶ್ವಾಸವನ್ನು ಹೆಚ್ಚಿಸುತ್ತದೆ.',
          'ta': 'செவ்வாய்க்கிழமை வழிபாடு பயத்தைப் போக்கி தைரியத்தையும் மன உறுதியையும் தரும்.',
          'te': 'మంగళవారం హనుమంతుని ఆరాధించడం వల్ల సకల భయాలు, కష్టాలు తొలగి ఆత్మవిశ్వాసం పెరుగుతుంది.',
          'hi': 'मंगलवार की पूजा से साहस, बल, बुद्धि एवं समस्त बाधाओं से मुक्ति मिलती है।',
          'ml': 'ധൈര്യവും രോഗശാന്തിയും നൽകുന്ന മംഗളകരമായ ദിവസം.',
          'en': 'Tuesday worship burns away debts, fear, and negativity while invoking courage, vitality, and protection.',
        },
        'rituals': {
          'kn': ['ಹನುಮಾನ್ ಚಾಲೀಸಾ ಪಠಣ', 'ಸಿಂಧೂರ ತಿಲಕ ಮತ್ತು ವೀಳ್ಯದೆಲೆ ಹಾರ', 'ಬೆಲ್ಲ ಮತ್ತು ಕಡಲೆ ನೈವೇದ್ಯ'],
          'ta': ['அனுமான் சாலிசா பாராயணம்', 'செந்தூரம் சாற்றுதல்', 'வெல்லம் மற்றும் கொண்டைக்கடலை நைவேத்தியம்'],
          'te': ['హనుమాన్ చాలీసా పారాయణం', 'సింధూర పూజ', 'బెల్లం నైవేద్యం'],
          'hi': ['हनुमान चालीसा पाठ', 'सिंदूर अर्पण', 'गुड़-चने का भोग'],
          'ml': ['ഹനുമാൻ ചാലീസ പാരായണം', 'സിന്ദൂര പൂജ'],
          'en': ['Chanting Hanuman Chalisa', 'Sindoor offering & betel garland', 'Jaggery & roasted gram offering'],
        },
        'mantra': 'ಓಂ ಶ್ರೀ ಹನುಮತೇ ನಮಃ • Om Shri Hanumate Namah',
        'color': 'ಕೆಂಪು & ಕಿತ್ತಳೆ • Red / Orange',
        'stotram': 'Hanuman Chalisa',
      },
      3: {
        'id': 'daily_vedic_wednesday',
        'title': {
          'kn': 'ಬುಧವಾರ ವಿಘ್ನಹರ್ತ ಗಣೇಶ ಪೂಜೆ',
          'ta': 'புதன்கிழமை விநாயகர் வழிபாடு',
          'te': 'బుధవారం విఘ్నేశ్వర పూజ',
          'hi': 'बुधवार श्री गणेश पूजन',
          'ml': 'ബുധനാഴ്ച ഗണപതി പൂജ',
          'en': 'Wednesday Sacred Ganesha Puja',
        },
        'subtitle': {
          'kn': 'ಬುದ್ಧಿ, ವಿದ್ಯೆ ಮತ್ತು ಕಾರ್ಯಸಿದ್ಧಿಯ ಪ್ರದಾತ ಗಣಪತಿ ಆರಾಧನೆ',
          'ta': 'புத்தி மற்றும் காரிய சித்தி தரும் கணபதி வழிபாடு',
          'te': 'బుద్ధి మరియు సర్వకార్య సిద్ధి ప్రసాదించే గణపతి పూజ',
          'hi': 'बुद्धि, विद्या और सफलता प्रदायक श्री गणेश आराधना',
          'ml': 'സർവ്വ വിഘ്നങ്ങളും നീക്കുന്ന ഗണപതി പൂജ',
          'en': 'Wisdom, Intellect & Triumph in Endeavors',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಮಹಾಗಣಪತಿ',
          'ta': 'ஸ்ரீ மகா கணபதி',
          'te': 'శ్రీ మహాగణపతి',
          'hi': 'श्री महागणपति',
          'ml': 'ശ്രീ മഹാഗണപതി',
          'en': 'Lord Ganesha (Vighnaharta)',
        },
        'significance': {
          'kn': 'ಬುಧವಾರ ಗಣೇಶನಿಗೆ ಪ್ರಿಯವಾದ ದಿನ. ಗರಿಕಾರ್ಚನೆ ಮತ್ತು ಮೋದಕ ಸಮರ್ಪಣೆಯಿಂದ ವಿದ್ಯಾರ್ಥಿಗಳಿಗೆ ಉತ್ತಮ ಜ್ಞಾನ, ವ್ಯಾಪಾರದಲ್ಲಿ ಲಾಭ ಲಭಿಸುತ್ತದೆ.',
          'ta': 'புதன்கிழமை விநாயகருக்கு அருகம்புல் சாற்றி வழிபட்டால் நற்கல்வியும் வெற்றியும் கிட்டும்.',
          'te': 'బుధవారం గణపతికి గరిక సమర్పిస్తే విద్యాబుద్ధులు మరియు కార్యసిద్ధి చేకూరుతాయి.',
          'hi': 'बुधवार को श्री गणेश जी को दूर्वा अर्पित करने से बुद्धि, एकाग्रता एवं व्यापार में उन्नति होती है।',
          'ml': 'വിദ്യാവിജയത്തിനും തടസ്സങ്ങൾ നീങ്ങാനും ഗണപതിയെ ഭജിക്കുക.',
          'en': 'Wednesday Ganesha worship grants sharp intellect, success in studies and business, and smooth fulfillment of all endeavors.',
        },
        'rituals': {
          'kn': ['ಗರಿಕೆ ಹುಲ್ಲು ಸಮರ್ಪಣೆ', 'ಗಣೇಶ ಅಷ್ಟೋತ್ತರ ಪಠಣ', 'ಮೋದಕ ಅಥವಾ ಬೆಲ್ಲ ನೈವೇದ್ಯ'],
          'ta': ['அருகம்புல் அர்ச்சனை', 'விநாயகர் அகவல் பாராயணம்', 'மோதகம் நைவேத்தியம்'],
          'te': ['గరిక పూజ', 'గణేశ అష్టోత్తర పారాయణం', 'మోదకం నైవేద్యం'],
          'hi': ['दूर्वा अर्पण', 'संकटनाशन गणेश स्तोत्र पाठ', 'मोदक का भोग'],
          'ml': ['കറുകപ്പുല്ല് അർച്ചന', 'ഗണപതി സ്തോത്ര ജപം'],
          'en': ['Offering sacred Durva grass', 'Reciting Sankatanashana Ganesha Stotram', 'Modak or jaggery offering'],
        },
        'mantra': 'ಓಂ ಗಂ ಗಣಪತಯೇ ನಮಃ • Om Gam Ganapataye Namah',
        'color': 'ಹಸಿರು • Sacred Green',
        'stotram': 'Ganesha Ashtottara',
      },
      4: {
        'id': 'daily_vedic_thursday',
        'title': {
          'kn': 'ಗುರುವಾರ ಶ್ರೀ ಗುರು ರಾಘವೇಂದ್ರ ಪೂಜೆ',
          'ta': 'வியாழக்கிழமை குரு ராகவேந்திரர் & தட்சிணாமூர்த்தி வழிபாடு',
          'te': 'గురువారం శ్రీ గురు రాఘవేంద్ర స్వామి పూజ',
          'hi': 'गुरुवार श्री गुरु राघवेंद्र एवं दत्तात्रेय पूजन',
          'ml': 'വ്യാഴാഴ്ച ഗുരു രാഘവേന്ദ്ര പൂജ',
          'en': 'Thursday Sacred Guru Raghavendra Puja',
        },
        'subtitle': {
          'kn': 'ಗುರು ಕೃಪೆ, ವಿದ್ಯೆ, ಜ್ಞಾನ ಹಾಗೂ ಸಕಲ ಇಷ್ಟಾರ್ಥ ಸಿದ್ಧಿ',
          'ta': 'ஞானம், பக்தி மற்றும் சகல காரிய வெற்றி தரும் குருவின் திருவருள்',
          'te': 'గురు కృప, జ్ఞానము మరియు సకల అభీష్ట సిద్ధి',
          'hi': 'गुरु कृपा, आत्मज्ञान एवं समस्त मनोकामना पूर्ति',
          'ml': 'ഗുരുകൃപയും ആത്മീയ ശാന്തിയും നൽകുന്ന വിശേഷ ദിനം',
          'en': 'Divine Guru Grace, Spiritual Wisdom & Prosperity',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಗುರು ರಾಘವೇಂದ್ರ ಸ್ವಾಮಿ (ರಾಯರು)',
          'ta': 'ஸ்ரீ குரு ராகவேந்திர சுவாமிகள்',
          'te': 'శ్రీ గురు రాఘవేంద్ర స్వామి',
          'hi': 'श्री गुरु राघवेंद्र स्वामी एवं दत्तात्रेय',
          'ml': 'ശ്രീ ഗുരു രാഘവേന്ദ്ര സ്വാമി',
          'en': 'Sri Guru Raghavendra Swami (Rayaru)',
        },
        'significance': {
          'kn': 'ಗುರುವಾರವು ಸದ್ಗುರುಗಳ ಆರಾಧನೆಗೆ ಅತ್ಯಂತ ಪವಿತ್ರ. ಮಂತ್ರಾಲಯ ಪ್ರಭು ಶ್ರೀ ರಾಘವೇಂದ್ರರ ಸ್ಮರಣೆಯಿಂದ ಕಷ್ಟಗಳು ಕರಗಿ ಅಭಯ ಮತ್ತು ಸಮೃದ್ಧಿ ನೆಲೆಸುತ್ತದೆ.',
          'ta': 'வியாழக்கிழமை குருவின் அருளைப் பெற உகந்த நாள். ராகவேந்திரரின் நாம சங்கீர்த்தனம் மன அமைதியை அருளும்.',
          'te': 'గురువారం గురుదేవులను పూజించడం వల్ల జ్ఞానము, శాంతి మరియు సకల శుభాలు కలుగుతాయి.',
          'hi': 'गुरुवार गुरु चरणों में समर्पित होने का पावन दिवस है। गुरु कृपा से असंभव कार्य भी सिद्ध हो जाते हैं।',
          'ml': 'ഗുരു കൃപയാൽ സകല ആഗ്രഹങ്ങളും സഫലമാകുന്ന പുണ്യദിനം.',
          'en': 'Thursday is consecrated to the Supreme Guru. Remembering Sri Raghavendra of Mantralaya dispels sorrow and fulfills every righteous prayer.',
        },
        'rituals': {
          'kn': ['ರಾಘವೇಂದ್ರ ಸ್ತೋತ್ರ ಪಠಣ', 'ಹಳದಿ ಹೂವು ಹಾಗೂ ನೈವೇದ್ಯ ಅರ್ಪಣೆ', 'ತುಪ್ಪದ ದೀಪ ಬೆಳಗುವುದು'],
          'ta': ['ராகவேந்திரர் ஸ்தோத்திர பாராயணம்', 'மஞ்சள் மலர்கள் சமர்ப்பித்தல்', 'நெய் தீபம் ஏற்றுதல்'],
          'te': ['రాఘవేంద్ర స్తోత్ర పారాయణం', 'పసుపు పువ్వుల సమర్పణ', 'నెయ్యి దీపారాధన'],
          'hi': ['गुरु स्तोत्र एवं राघवेंद्र स्तोत्र पाठ', 'पीले पुष्प अर्पण', 'घी का दीपक जलाना'],
          'ml': ['ഗുരു സ്തോത്ര ജപം', 'നെയ്‌വിളക്ക് കൊളുത്തൽ'],
          'en': ['Reciting Raghavendra Stotram', 'Offering yellow flowers & sweets', 'Lighting a pure ghee lamp'],
        },
        'mantra': 'ಪೂಜ್ಯಾಯ ರಾಘವೇಂದ್ರಾಯ ಸತ್ಯಧರ್ಮರತಾಯ ಚ | ಭಜತಾಂ ಕಲ್ಪವೃಕ್ಷಾಯ ನಮತಾಂ ಕಾಮಧೇನವೇ ||',
        'color': 'ಹಳದಿ • Sacred Golden Yellow',
        'stotram': 'Raghavendra Stotram',
      },
      5: {
        'id': 'daily_vedic_friday',
        'title': {
          'kn': 'ಶುಕ್ರವಾರ ಮಹಾಲಕ್ಷ್ಮಿ & ಚಾಮುಂಡೇಶ್ವರಿ ಪೂಜೆ',
          'ta': 'வெள்ளிக்கிழமை மகாலட்சுமி & அம்மன் வழிபாடு',
          'te': 'శుక్రవారం శ్రీ మహాలక్ష్మి & దుర్గా పూజ',
          'hi': 'शुक्रवार माँ महालक्ष्मी एवं जगदम्बा पूजन',
          'ml': 'വെള്ളിയാഴ്ച മഹാലക്ഷ്മി പൂജ',
          'en': 'Friday Sacred Mahalakshmi & Devi Puja',
        },
        'subtitle': {
          'kn': 'ಸಕಲ ಸೌಭಾಗ್ಯ, ಐಶ್ವರ್ಯ ಮತ್ತು ಶಾಂತಿಯ ಪ್ರದಾಯಿನಿ ಜಗದಂಬೆ ಆರಾಧನೆ',
          'ta': 'சகல சௌபாக்கியங்களும் செல்வமும் அருளும் லட்சுமி கடாட்சம்',
          'te': 'సౌభాగ్యము, ఐశ్వర్యము ప్రసాదించే లక్ష్మీదేవి పూజ',
          'hi': 'अष्टलक्ष्मी कृपा, धन-धान्य एवं सौभाग्य प्राप्ति',
          'ml': 'ഐശ്വര്യവും സർവ്വ മംഗളങ്ങളും നൽകുന്ന ലക്ഷ്മീപൂജ',
          'en': 'Auspicious Blessings of Prosperity, Grace & Peace',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ಮಹಾಲಕ್ಷ್ಮಿ & ಚಾಮುಂಡೇಶ್ವರಿ ದೇವಿ',
          'ta': 'ஸ்ரீ மகாலட்சுமி & அம்மன்',
          'te': 'శ్రీ మహాలక్ష్మి & దుర్గాదేవి',
          'hi': 'माँ महालक्ष्मी एवं माता चामुण्डेश्वरी',
          'ml': 'ശ്രീ മഹാലക്ഷ്മി',
          'en': 'Goddess Mahalakshmi & Chamundeshwari',
        },
        'significance': {
          'kn': 'ಶುಕ್ರವಾರವು ಜಗನ್ಮಾತೆಯ ದಿವ್ಯ ದಿನ. ಲಕ್ಷ್ಮೀ ಪೂಜೆಯಿಂದ ಮನೆ-ಮನಗಳಲ್ಲಿ ಸಂತೋಷ, ಸಮೃದ್ಧಿ ಹಾಗೂ ಲಕ್ಷ್ಮೀಕಟಾಕ್ಷ ನೆಲೆಸುತ್ತದೆ.',
          'ta': 'வெள்ளிக்கிழமை அம்பிகைக்கு உரிய மங்களகரமான நாள். மகாலட்சுமியின் அருள் வீட்டில் சுபத்தை உண்டாக்கும்.',
          'te': 'శుక్రవారం లక్ష్మీదేవిని ఆరాధించడం వల్ల అష్టైశ్వర్యాలు మరియు సకల సౌభాగ్యాలు లభిస్తాయి.',
          'hi': 'शुक्रवार माँ लक्ष्मी का पावन दिन है। श्री सूक्त पाठ से घर में सुख, शांति एवं समृद्धि का वास होता है।',
          'ml': 'സമ്പത്തും സമാധാനവും നൽകുന്ന പരിശുദ്ധമായ ദിനം.',
          'en': 'Friday is devoted to the Divine Mother. Chanting Sri Suktam or Lakshmi Ashtakam welcomes joy, prosperity, and divine light.',
        },
        'rituals': {
          'kn': ['ಕನಕಧಾರಾ / ಲಕ್ಷ್ಮೀ ಅಷ್ಟಕಂ ಪಠಣ', 'ಕಮಲ ಅಥವಾ ಗುಲಾಬಿ ಹೂವಿನ ಅರ್ಚನೆ', 'ಹಾಲು-ಪಾಯಸ ನೈವೇದ್ಯ'],
          'ta': ['கனகதாரா ஸ்தோத்திரம் பாராயணம்', 'தாமரை மலர் அர்ச்சனை', 'பாயசம் நைவேத்தியம்'],
          'te': ['కనకధారా స్తోత్ర పారాయణం', 'కమలం లేదా గులాబీ పువ్వులతో అర్చన', 'పాయసం నైవేద్యం'],
          'hi': ['कनकधारा / श्री सूक्त पाठ', 'कमल या गुलाब पुष्प अर्पण', 'खीर का भोग'],
          'ml': ['കനകധാരാ സ്തോത്ര ജപം', 'പായസ നിവേദ്യം'],
          'en': ['Chanting Kanakadhara Stotram', 'Lotus or rose flower offering', 'Sweet Kheer / Payasam offering'],
        },
        'mantra': 'ಓಂ ಶ್ರೀಂ ಹ್ರೀಂ ಶ್ರೀಂ ಕಮಲೇ ಕಮಲಾಲಯೇ ಪ್ರಸೀದ ಪ್ರಸೀದ • Om Shreem Hreem Shreem',
        'color': 'ಗುಲಾಬಿ & ಕೆಂಪು • Rose / Crimson',
        'stotram': 'Kanakadhara Stotram',
      },
      6: {
        'id': 'daily_vedic_saturday',
        'title': {
          'kn': 'ಶನಿವಾರ ಶ್ರೀ ವೆಂಕಟೇಶ್ವರ ಸ್ವಾಮಿ ಪೂಜೆ',
          'ta': 'சனிக்கிழமை திருப்பதி வெங்கடாசலபதி வழிபாடு',
          'te': 'శనివారం తిరుమల వేంకటేశ్వర స్వామి పూజ',
          'hi': 'शनिवार श्री वेंकटेश्वर एवं शनिदेव पूजन',
          'ml': 'ശനിയാഴ്ച വെങ്കടേശ്വര പൂജ',
          'en': 'Saturday Sacred Venkateshwara Puja',
        },
        'subtitle': {
          'kn': 'ಕಲಿಯುಗ ಪ್ರತ್ಯಕ್ಷ ದೈವ ತಿರುಮಲ ಶ್ರೀನಿವಾಸನ ದಿವ್ಯ ಕೃಪೆ',
          'ta': 'கலியுக வரதன் திருப்பதி பாலாஜியின் திவ்ய தரிசனம்',
          'te': 'కలియుగ ప్రత్యక్ష దైవం వేంకటేశ్వరుని ఆరాధన',
          'hi': 'कलियुग प्रत्यक्ष देव श्री तिरुपతి बालाजी कृपा',
          'ml': 'കലിയുഗ വരദനായ ശ്രീനിവാസന്റെ ദിവ്യ കൃപ',
          'en': 'Lord of the Seven Hills, Dispeller of Kali Yuga Sorrows',
        },
        'deity': {
          'kn': 'ಶ್ರೀ ತಿರುಮಲ ವೆಂಕಟೇಶ್ವರ ಸ್ವಾಮಿ (ಬಾಲಾಜಿ)',
          'ta': 'ஸ்ரீ வெங்கடாசலபதி (பாலாஜி)',
          'te': 'శ్రీ వేంకటేశ్వర స్వామి (గోవిందా)',
          'hi': 'भगवान श्री वेंकटेश्वर (तिरुपति बालाजी)',
          'ml': 'ശ്രീ വെങ്കടേശ്വര സ്വാമി',
          'en': 'Lord Venkateshwara (Tirupati Balaji)',
        },
        'significance': {
          'kn': 'ಶನಿವಾರ ಗೋವಿಂದನ ನಾಮಸ್ಮರಣೆಯು ಗ್ರಹಪೀಡೆಗಳನ್ನು ಕಳೆದು ಇಷ್ಟಾರ್ಥಗಳನ್ನು ಪೂರೈಸುತ್ತದೆ. ಸುಪ್ರಭಾತ ಮತ್ತು ಗೋವಿಂದ ನಾಮಾವಳಿ ಅತೀವ ಪುಣ್ಯದಾಯಕ.',
          'ta': 'சனிக்கிழமை கோவிந்த நாமத்தை உச்சரிப்பது நவக்கிரக தோஷங்களை நீக்கி நல்வாழ்வு தரும்.',
          'te': 'శనివారం గోవింద నామస్మరణ సర్వ దోషాలను హరిస్తుంది. వెంకటేశ్వర స్వామి అనుగ్రహం సదా రక్షిస్తుంది.',
          'hi': 'शनिवार श्री वेंकटेश्वर की भक्ति से समस्त कष्टों और ग्रह दोषों का निवारण होता है।',
          'ml': 'സകല ഗ്രഹദോഷങ്ങളും അകറ്റാൻ ശനിയാഴ്ച ഗോവിന്ദനെ ഭജിക്കുക.',
          'en': 'Saturday worship of Lord Venkateshwara removes planetary afflictions and fills life with auspicious energy.',
        },
        'rituals': {
          'kn': ['ವೆಂಕಟೇಶ್ವರ ಸುಪ್ರಭಾತ ಆಲಿಸುವಿಕೆ', 'ತುಳಸೀದಳ ಸಮರ್ಪಣೆ', 'ಗೋವಿಂದ ನಾಮಾವಳಿ ಜಪ'],
          'ta': ['வெங்கடேச சுப்ரபாதம் கேட்டல்', 'துளசி அர்ச்சனை', 'கோவிந்தா நாம ஜபம்'],
          'te': ['వేంకటేశ్వర సుప్రభాతం ఆలకించడం', 'తులసీదళ సమర్పణ', 'గోవింద నామస్మరణ'],
          'hi': ['वेंकटेश्वर सुप्रभातम श्रवण', 'तुलसीदल अर्पण', 'गोविन्द नामावली जप'],
          'ml': ['സുപ്രഭാതം ശ്രവണം', 'തുളസി അർച്ചന'],
          'en': ['Listening to Venkateshwara Suprabhatam', 'Offering sacred Tulasi leaves', 'Chanting Govinda Namavali'],
        },
        'mantra': 'ಓಂ ನಮೋ ವೇಂಕಟೇಶಾಯ • Om Namo Venkateshaya',
        'color': 'ನೀಲಿ & ನೇರಳೆ • Royal Blue / Indigo',
        'stotram': 'Venkateshwara Suprabhatam',
      },
      7: {
        'id': 'daily_vedic_sunday',
        'title': {
          'kn': 'ಭಾನುವಾರ ಸೂರ್ಯನಾರಾಯಣ ಪೂಜೆ',
          'ta': 'ஞாயிற்றுக்கிழமை சூரிய பகவான் வழிபாடு',
          'te': 'ఆదివారం సూర్యనారాయణ పూజ',
          'hi': 'रविवार भगवान सूर्यनारायण पूजन',
          'ml': 'ഞായറാഴ്ച സൂര്യപൂജ',
          'en': 'Sunday Sacred Surya Narayana Puja',
        },
        'subtitle': {
          'kn': 'ಆರೋಗ್ಯ, ತೇಜಸ್ಸು ಹಾಗೂ ಜ್ಞಾನದ ಪ್ರದಾತ ಸೂರ್ಯದೇವರ ಆರಾಧನೆ',
          'ta': 'ஆரோக்கியம், தேஜஸ் மற்றும் நல்வாழ்வு அருளும் சூரிய நமஸ்காரம்',
          'te': 'ఆరోగ్యము, వర్చస్సు ప్రసాదించే సూర్య భగవానుని పూజ',
          'hi': 'आरोग्य, तेज और ऊर्जा प्रदायक सूर्यनारायण आराधना',
          'ml': 'ആരോഗ്യവും ഉന്മേഷവും നൽകുന്ന സൂര്യപൂജ',
          'en': 'Supreme Giver of Health, Vitality & Radiance',
        },
        'deity': {
          'kn': 'ಭಗವಾನ್ ಶ್ರೀ ಸೂರ್ಯನಾರಾಯಣ',
          'ta': 'சூரிய நாராயண பகவான்',
          'te': 'సూర్య భగవానుడు',
          'hi': 'भगवान सूर्यनारायण देव',
          'ml': 'സൂര്യഭഗവാൻ',
          'en': 'Lord Surya Narayana (Sun God)',
        },
        'significance': {
          'kn': 'ಭಾನುವಾರ ಜಗಚ್ಚಕ್ಷು ಸೂರ್ಯನಿಗೆ ಅರ್ಪಿತ. ಸೂರ್ಯ ನಮಸ್ಕಾರ ಹಾಗೂ ಆದಿತ್ಯ ಹೃದಯ ಸ್ತೋತ್ರದಿಂದ ಕಣ್ಣಿನ ದೃಷ್ಟಿ, ಆರೋಗ್ಯ ಹಾಗೂ ತೇಜಸ್ಸು ವೃದ್ಧಿಯಾಗುತ್ತದೆ.',
          'ta': 'ஞாயிற்றுக்கிழமை சூரிய பகவானுக்கு உரிய நாள். ஆதித்ய ஹிருதய ஸ்தோத்திரம் உடலுக்கும் மனதிற்கும் புத்துணர்ச்சி தரும்.',
          'te': 'ఆదివారం సూర్యునికి అర్ఘ్యం సమర్పించడం వల్ల ఆరోగ్యం, యశస్సు మరియు ఆత్మబలం చేకూరుతాయి.',
          'hi': 'रविवार को सूर्य को अर्घ्य देने और आदित्य हृदय स्तोत्र पाठ से ओज, तेज एवं आरोग्य की वृद्धि होती है।',
          'ml': 'ആരോഗ്യ വർദ്ധനവിനായി ആദിത്യ ഹൃദയ സ്തോത്രം ജപിക്കുക.',
          'en': 'Sunday is dedicated to Lord Surya. Offering Arghya and reciting Aditya Hridaya Stotram bestows radiant health, vitality, and victory.',
        },
        'rituals': {
          'kn': ['ತಾಮ್ರದ ಪಾತ್ರೆಯಲ್ಲಿ ಸೂರ್ಯಾರ್ಘ್ಯ', 'ಆದಿತ್ಯ ಹೃದಯ ಸ್ತೋತ್ರ ಪಠಣ', 'ಗಾಯತ್ರೀ ಮಂತ್ರ ಜಪ'],
          'ta': ['சூரிய பகவானுக்கு அர்க்கியம்', 'ஆதித்ய ஹிருதய ஸ்தோத்திரம்', 'காயத்ரி மந்திர ஜபம்'],
          'te': ['సూర్యునికి జలార్ఘ్యం', 'ఆదిత్య హృదయ స్తోత్ర పారాయణం', 'గాయత్రీ జపం'],
          'hi': ['तांबे के पात्र से सूर्य को अर्घ्य', 'आदित्य हृदय स्तोत्र पाठ', 'गायत्री महामंत्र जप'],
          'ml': ['സൂര്യ നമസ്കാരം', 'ആദിത്യ ഹൃദയ സ്തോത്ര ജപം'],
          'en': ['Offering water to Surya in a copper vessel', 'Chanting Aditya Hridaya Stotram', 'Gayatri Mantra meditation'],
        },
        'mantra': 'ಓಂ ಘೃಣಿಃ ಸೂರ್ಯಾಯ ನಮಃ • Om Ghrinih Suryaya Namah',
        'color': 'ಕೇಸರಿ & ಸುವರ್ಣ • Saffron / Gold',
        'stotram': 'Aditya Hridaya Stotram',
      },
    };

    final dayInfo = weekdayData[weekday] ?? weekdayData[4]!;
    final titles = dayInfo['title'] as Map<String, String>;
    final subtitles = dayInfo['subtitle'] as Map<String, String>;
    final deities = dayInfo['deity'] as Map<String, String>;
    final sigs = dayInfo['significance'] as Map<String, String>;
    final rituals = dayInfo['rituals'] as Map<String, List<String>>;

    return SpecialDayInfo(
      id: dayInfo['id'] as String,
      title: titles[lang] ?? titles['en']!,
      subtitle: subtitles[lang] ?? subtitles['en']!,
      deity: deities[lang] ?? deities['en']!,
      significance: sigs[lang] ?? sigs['en']!,
      rituals: rituals[lang] ?? rituals['en']!,
      mantra: dayInfo['mantra'] as String,
      auspiciousColor: dayInfo['color'] as String,
      recommendedStotram: dayInfo['stotram'] as String,
      badgeText: lang == 'kn'
          ? 'ನಿತ್ಯ ಪೂಜಾ ವಿಶೇಷ'
          : (lang == 'te'
              ? 'నిత్య పూజా విశేషం'
              : (lang == 'hi' ? 'दैनिक पूजन विशेष' : 'Daily Sanctum Special')),
      date: date,
    );
  }
}

