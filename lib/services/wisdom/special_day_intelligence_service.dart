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
  });
}

/// On-Device Vedic Festival & Special Day Intelligence Service
/// Computes astronomical festivals and checks online sources for day's significance.
class SpecialDayIntelligenceService {
  /// Returns SpecialDayInfo if today is an auspicious/special day; otherwise returns null.
  static Future<SpecialDayInfo?> getTodaySpecialDay(String lang, {DateTime? testDate}) async {
    final now = testDate ?? DateTime.now();

    // 1. First attempt to check live online ephemeris / calendar status if connected
    DateTime evaluatedDate = now;
    try {
      final res = await http
          .get(Uri.parse('https://worldtimeapi.org/api/timezone/Asia/Kolkata'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['datetime'] != null) {
          evaluatedDate = DateTime.parse(data['datetime'] as String).toLocal();
        }
      }
    } catch (_) {
      // Offline fallback: Use on-device clock
      evaluatedDate = now;
    }

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
    // In Nirayana Sun, Kanya Masa ends and Thula begins around September/October.
    final bool isAshwayujaSeason = (solarMasaIndex == 5 || solarMasaIndex == 6) &&
        (evaluatedDate.month == 9 || evaluatedDate.month == 10 || evaluatedDate.month == 11);

    if (isAshwayujaSeason && !isKrishna && tithiNum >= 1 && tithiNum <= 10) {
      return _getDasaraDayInfo(tithiNum, lang);
    }

    // --- CHECK 2: Mahalaya Amavasya (Sarva Pitru Amavasya) ---
    // Krishna Paksha 15 (Amavasya) preceding Sharad Navratri (Bhadrapada / Kanya Amavasya)
    if (isAshwayujaSeason && isKrishna && tithiNum == 15) {
      return _getMahalayaAmavasyaInfo(lang);
    }

    // Other Amavasya in year
    if (isKrishna && tithiNum == 15) {
      return _getAmavasyaInfo(weekday, lang);
    }

    // --- CHECK 3: Deepavali Festive Days ---
    // Ashvina Krishna Trayodashi (13) to Kartika Shukla Pratipada (1) / Dvitiya (Bhai Dooj)
    if ((solarMasaIndex == 6 || solarMasaIndex == 7) &&
        (evaluatedDate.month == 10 || evaluatedDate.month == 11)) {
      if (isKrishna && tithiNum == 13) {
        return _getDhanterasInfo(lang);
      } else if (isKrishna && tithiNum == 14) {
        return _getNarakaChaturdashiInfo(lang);
      } else if (isKrishna && tithiNum == 15) {
        return _getLakshmiPoojaInfo(lang);
      } else if (!isKrishna && tithiNum == 1) {
        return _getBaliPadyamiInfo(lang);
      }
    }

    // --- CHECK 4: Maha Shivaratri ---
    // Magha Krishna Chaturdashi (Feb / March)
    if ((evaluatedDate.month == 2 || evaluatedDate.month == 3) && isKrishna && tithiNum == 14) {
      return _getMahaShivaratriInfo(lang);
    }

    // --- CHECK 5: Ganesha Chaturthi ---
    // Bhadrapada Shukla Chaturthi (Aug / Sept)
    if ((evaluatedDate.month == 8 || evaluatedDate.month == 9) && !isKrishna && tithiNum == 4) {
      return _getGaneshChaturthiInfo(lang);
    }

    // --- CHECK 6: Sri Krishna Janmashtami ---
    // Shravana / Bhadrapada Krishna Ashtami (Aug / Sept)
    if ((evaluatedDate.month == 8 || evaluatedDate.month == 9) && isKrishna && tithiNum == 8) {
      return _getKrishnaJanmashtamiInfo(lang);
    }

    // --- CHECK 7: Sri Rama Navami ---
    // Chaitra Shukla Navami (April)
    if ((evaluatedDate.month == 3 || evaluatedDate.month == 4) && !isKrishna && tithiNum == 9) {
      return _getRamaNavamiInfo(lang);
    }

    // --- CHECK 8: Ugadi / Gudi Padwa ---
    // Chaitra Shukla Pratipada (March / April)
    if ((evaluatedDate.month == 3 || evaluatedDate.month == 4) && !isKrishna && tithiNum == 1) {
      return _getUgadiInfo(lang);
    }

    // --- CHECK 9: Makara Sankranti ---
    if (evaluatedDate.month == 1 && (evaluatedDate.day == 14 || evaluatedDate.day == 15)) {
      return _getMakaraSankrantiInfo(lang);
    }

    // --- CHECK 10: Ekadashi Vrata (Harivasara) ---
    if (tithiNum == 11) {
      return _getEkadashiInfo(isKrishna, lang);
    }

    // --- CHECK 11: Pradosha Vrata ---
    if (tithiNum == 13) {
      return _getPradoshaInfo(weekday, lang);
    }

    // --- CHECK 12: Sankashti Chaturthi / Angarki ---
    final bool isEveningKrishnaChaturthi =
        (eveningAstro['isKrishna'] as bool) && (eveningAstro['tithiNum'] as int == 4);
    if (isEveningKrishnaChaturthi) {
      return _getSankashtiInfo(weekday == DateTime.tuesday, lang);
    }

    // --- CHECK 13: Purnima / Pournami (Satyanarayana Vrata) ---
    if (!isKrishna && tithiNum == 15) {
      return _getPurnimaInfo(lang);
    }

    // If today is a normal everyday without any festival / major vrata, return null!
    return null;
  }

  // ==========================================
  // FESTIVAL DETAILS DEFINITIONS
  // ==========================================

  static SpecialDayInfo _getDasaraDayInfo(int dayNum, String lang) {
    final Map<int, Map<String, dynamic>> dasaraDays = {
      1: {
        'knTitle': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೧ (ಪಾಡ್ಯ)',
        'enTitle': 'Dasara Navratri – Day 1 (Pratipada)',
        'hiTitle': 'दशहरा नवरात्रि – प्रथम दिवस (प्रतिपदा)',
        'knDeity': 'ಶ್ರೀ ಶೈಲಪುತ್ರಿ ದೇವಿ (ಘಟಸ್ಥಾಪನ)',
        'enDeity': 'Goddess Shailaputri (Ghatasthapana)',
        'hiDeity': 'माता शैलपुत्री (घटस्थापना)',
        'knColor': 'ಹಳದಿ (Yellow)',
        'knSig':
            'ನವರಾತ್ರಿಯ ಮೊದಲನೇ ದಿನ. ಪರ್ವತರಾಜ ಹಿಮವಂತನ ಪುತ್ರಿಯಾದ ಶೈಲಪುತ್ರಿ ದೇವಿಯು ಭಕ್ತರಿಗೆ ಧೈರ್ಯ, ಸ್ಥಿರತೆ ಹಾಗೂ ಆಧ್ಯಾತ್ಮಿಕ ಶಕ್ತಿಯನ್ನು ಕರುಣಿಸುತ್ತಾಳೆ.',
        'enSig':
            'First day of Navratri dedicated to Maa Shailaputri, embodiment of the Earth and daughter of the Himalayas, granting spiritual stability and resolve.',
        'hiSig':
            'नवरात्रि का प्रथम पावन दिन। हिमालय सुपुत्री माता शैलपुत्री की उपासना से जीवन में स्थिरता, तेज और मनोबल की प्राप्ति होती है।',
        'knRituals': ['ಕಳಸ ಸ್ಥಾಪನೆ & ಅಖಂಡ ದೀಪಾರಾಧನೆ', 'ದೇವಿಗೆ ಶುದ್ಧ ಹಸುವಿನ ತುಪ್ಪದ ನೈವೇದ್ಯ', 'ಕುಂಕುಮಾರ್ಚನೆ'],
        'enRituals': ['Kalasha Sthapana & Akhanda Deepa', 'Offering pure cow ghee naivedya', 'Kumkumarchana'],
        'hiRituals': ['घटस्थापना एवं अखंड दीप प्रज्ज्वलन', 'शुद्ध गौघृत का भोग', 'दुर्गा सप्तशती पाठ'],
        'mantra': 'ಓಂ ದೇವಿ ಶೈಲಪುತ್ರ್ಯೈ ನಮಃ • Om Devi Shailaputryai Namah',
        'stotram': 'Sri Lalitha Sahasranama Stotram',
      },
      2: {
        'knTitle': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೨ (ಬಿದಿಗೆ)',
        'enTitle': 'Dasara Navratri – Day 2 (Dwitiya)',
        'hiTitle': 'दशहरा नवरात्रि – द्वितीय दिवस (द्वितीया)',
        'knDeity': 'ಶ್ರೀ ಬ್ರಹ್ಮಚಾರಿಣಿ ದೇವಿ',
        'enDeity': 'Goddess Brahmacharini',
        'hiDeity': 'माता ब्रह्मचारिणी',
        'knColor': 'ಹಸಿರು (Green)',
        'knSig':
            'ತಪಸ್ಸು ಮತ್ತು ಧ್ಯಾನದ ಅಧಿದೇವತೆ ಬ್ರಹ್ಮಚಾರಿಣಿ. ಭಕ್ತರಲ್ಲಿ ಜ್ಞಾನ, ಸಂಯಮ, ಸತ್ಯಾಗ್ರಹ ಹಾಗೂ ಮನಶ್ಶಾಂತಿಯನ್ನು ಜಾಗೃತಗೊಳಿಸುತ್ತಾಳೆ.',
        'enSig':
            'Second day celebrating Maa Brahmacharini, who performed severe penance. Bestows emotional calm, wisdom, and penance power.',
        'hiSig':
            'तपस्या और वैराग्य की देवी ब्रह्मचारिणी। इनकी आराधना से तप, त्याग, सदाचार और संयम की वृद्धि होती है।',
        'knRituals': ['ಸಕ್ಕರೆ ಹಾಗೂ ಕಲ್ಲುಸಕ್ಕರೆ ನೈವೇದ್ಯ', 'ಜಪಮಾಲೆಯಿಂದ ಗಾಯತ್ರೀ ಜಪ', 'ಶಾಂತಿ ಪೂಜೆ'],
        'enRituals': ['Sugar and sweet offerings', 'Japa meditation', 'Chanting Devi Suktam'],
        'hiRituals': ['शर्करा एवं मिश्री का भोग', 'गायत्री एवं देवी मंत्र जप', 'संध्या आरती'],
        'mantra': 'ಓಂ ದೇವಿ ಬ್ರಹ್ಮಚಾರಿಣ್ಯೈ ನಮಃ • Om Devi Brahmacharinyai Namah',
        'stotram': 'Durga Suktam',
      },
      3: {
        'knTitle': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೩ (ತದಿಗೆ)',
        'enTitle': 'Dasara Navratri – Day 3 (Tritiya)',
        'hiTitle': 'दशहरा नवरात्रि – तृतीय दिवस (तृतीया)',
        'knDeity': 'ಶ್ರೀ ಚಂದ್ರಘಂಟಾ ದೇವಿ',
        'enDeity': 'Goddess Chandraghanta',
        'hiDeity': 'माता चंद्रघंटा',
        'knColor': 'ಬೂದು / ಬೆಳ್ಳಿ (Grey/Silver)',
        'knSig':
            'ಹಣೆ ಮೇಲೆ ಗಂಟೆಯಾಕಾರದ ಚಂದ್ರನನ್ನು ಧರಿಸಿದ ಚಂದ್ರಘಂಟಾ ದೇವಿ. ಸಕಲ ಭಯ, ನಕಾರಾತ್ಮಕ ಶಕ್ತಿಗಳನ್ನು ನಾಶಮಾಡಿ ಧೈರ್ಯವನ್ನು ನೀಡುತ್ತಾಳೆ.',
        'enSig':
            'Maa Chandraghanta carries a half-moon shaped like a temple bell. Removes fear, anxiety, and all negative energies.',
        'hiSig':
            'मस्तक पर घंटे के आकार का अर्धचंद्र धारण करने वाली मां चंद्रघंटा। भयमुक्ति, साहस और शांति प्रदान करती हैं।',
        'knRituals': ['ಹಾಲು ಅಥವಾ ಹಾಲಿನ ಪಾಯಸದ ನೈವೇದ್ಯ', 'ಕಂಚಿನ ಗಂಟೆಯ ನಾದದೊಂದಿಗೆ ಮಂಗಳಾರತಿ'],
        'enRituals': ['Milk kheer offering', 'Ringing temple bells during Aarti', 'Protection prayers'],
        'hiRituals': ['दुग्ध निर्मित खीर का भोग', 'घंटा नाद के साथ मंगल आरती'],
        'mantra': 'ಓಂ ದೇವಿ ಚಂದ್ರಘಂಟಾಯೈ ನಮಃ • Om Devi Chandraghantayai Namah',
        'stotram': 'Mahishasura Mardini Stotram',
      },
      4: {
        'knTitle': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೪ (ಚೌತಿ)',
        'enTitle': 'Dasara Navratri – Day 4 (Chaturthi)',
        'hiTitle': 'दशहरा नवरात्रि – चतुर्थ दिवस (चतुर्थी)',
        'knDeity': 'ಶ್ರೀ ಕೂಷ್ಮಾಂಡಾ ದೇವಿ',
        'enDeity': 'Goddess Kushmanda',
        'hiDeity': 'माता कूष्माण्डा',
        'knColor': 'ಕಿತ್ತಳೆ (Orange)',
        'knSig':
            'ತನ್ನ ಮಂದಹಾಸದಿಂದ ಬ್ರಹ್ಮಾಂಡವನ್ನೇ ಸೃಷ್ಟಿಸಿದ ಜಗದಂಬೆ ಕೂಷ್ಮಾಂಡಾ ದೇವಿ. ದಾರಿದ್ರ್ಯ, ರೋಗ-ರುಜಿನಗಳನ್ನು ಪರಿಹರಿಸಿ ಆಯುರಾರೋಗ್ಯ ಕರುಣಿಸುತ್ತಾಳೆ.',
        'enSig':
            'Maa Kushmanda created the universe with her gentle divine smile. Illuminates the soul and removes chronic illness and poverty.',
        'hiSig':
            'अपनी मंद मुस्कान से ब्रह्मांड की रचना करने वाली मां कूष्माण्डा। आरोग्य, आयु और यश की प्राप्ति होती है।',
        'knRituals': ['ಮಾಲ್ಪುವಾ ಅಥವಾ ಕುಂಬಳಕಾಯಿ ಸಿಹಿ ನೈವೇದ್ಯ', 'ಸೂರ್ಯ ನಮಸ್ಕಾರ & ದೇವಿಯ ಆರಾಧನೆ'],
        'enRituals': ['Sweet pumpkin or Malpua offering', 'Surya and Devi prayers', 'Deeparadhana'],
        'hiRituals': ['मालपुए का भोग', 'सूर्य नमस्कार एवं देवी आराधना'],
        'mantra': 'ಓಂ ದೇವಿ ಕೂಷ್ಮಾಂಡಾಯೈ ನಮಃ • Om Devi Kushmandayai Namah',
        'stotram': 'Soundarya Lahari',
      },
      5: {
        'knTitle': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೫ (ಪಂಚಮಿ)',
        'enTitle': 'Dasara Navratri – Day 5 (Panchami)',
        'hiTitle': 'दशहरा नवरात्रि – पंचम दिवस (पंचमी)',
        'knDeity': 'ಶ್ರೀ ಸ್ಕಂದಮಾತಾ (ಉಪಾಂಗ ಲಲಿತಾ ವ್ರತ)',
        'enDeity': 'Goddess Skandamata',
        'hiDeity': 'माता स्कंदमाता',
        'knColor': 'ಬಿಳಿ (White)',
        'knSig':
            'ಕಾರ್ತಿಕೇಯ (ಸ್ಕಂದ) ದೇವರ ಮಾತೆಯಾದ ಸ್ಕಂದಮಾತೆ. ಭಕ್ತರಿಗೆ ಮಾತೃವಾತ್ಸಲ್ಯ, ಸಂತಾನ ಸೌಭಾಗ್ಯ ಹಾಗೂ ಅಂತಿಮ ಮುಕ್ತಿಯನ್ನು ಕರುಣಿಸುತ್ತಾಳೆ.',
        'enSig':
            'Mother of Lord Skanda (Kartikeya). Showers pure motherly compassion, family prosperity, and spiritual liberation.',
        'hiSig':
            'भगवान कार्तिकेय की माता स्कंदमाता। पारिवारिक सुख, संतान की रक्षा और मोक्ष का वरदान देती हैं।',
        'knRituals': ['ಬಾಳೆಹಣ್ಣು ನೈವೇದ್ಯ', 'ಉಪಾಂಗ ಲಲಿತಾ ವ್ರತ ಪೂಜೆ', 'ಮಕ್ಕಳಿಗೆ ಆಶೀರ್ವಾದ ಕೋರುವುದು'],
        'enRituals': ['Banana naivedya', 'Lalitha Vrata worship', 'Prayers for children wellbeing'],
        'hiRituals': ['केले का नैवेद्य', 'उपांग ललिता पूजन', 'संतान कल्याण प्रार्थना'],
        'mantra': 'ಓಂ ದೇವಿ ಸ್ಕಂದಮಾತ್ರೈ ನಮಃ • Om Devi Skandamatryai Namah',
        'stotram': 'Sri Lalitha Trishati Stotram',
      },
      6: {
        'knTitle': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೬ (ಷಷ್ಠಿ)',
        'enTitle': 'Dasara Navratri – Day 6 (Shashthi)',
        'hiTitle': 'दशहरा नवरात्रि – षष्ठी दिवस (षष्ठी)',
        'knDeity': 'ಶ್ರೀ ಕಾತ್ಯಾಯನಿ ದೇವಿ',
        'enDeity': 'Goddess Katyayani',
        'hiDeity': 'माता कात्यायनी',
        'knColor': 'ಕೆಂಪು (Red)',
        'knSig':
            'ಕಾತ್ಯಾಯನ ಮಹರ್ಷಿಗಳ ಪುತ್ರಿಯಾಗಿ ಅವತರಿಸಿ ಮಹಿಷಾಸುರನನ್ನು ಸಂಹರಿಸಿದ ವೀರ ಮಾತೃಕೆ. ವಿವಾಹ ಪ್ರತಿಬಂಧಕ ನಿವಾರಣೆ ಹಾಗೂ ಶತ್ರುಜಯ ನೀಡುತ್ತಾಳೆ.',
        'enSig':
            'Warrior deity who slayed demons. Removes delays in marriage, cleanses past sins, and grants triumph over obstacles.',
        'hiSig':
            'महर्षि कात्यायन की तपस्या से प्रकट मां कात्यायनी। शीघ्र विवाह योग, सुखी दांपत्य एवं शत्रु बाधा निवारण करती हैं।',
        'knRituals': ['ಜೇನುತುಪ್ಪದ ನೈವೇದ್ಯ', 'ಕೆಂಪು ದಾಸವಾಳ ಹೂವಿನ ಅರ್ಚನೆ', 'ವಿವಾಹ ಯೋಗ ಪ್ರಾರ್ಥನೆ'],
        'enRituals': ['Honey offering', 'Red hibiscus flower worship', 'Sankalpa for righteous goals'],
        'hiRituals': ['शहद का भोग', 'लाल गुड़हल के पुष्पों से अर्चन'],
        'mantra': 'ಓಂ ದೇವಿ ಕಾತ್ಯಾಯನ್ಯೈ ನಮಃ • Om Devi Katyayanyai Namah',
        'stotram': 'Katyayani Mantra & Stotram',
      },
      7: {
        'knTitle': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೭ (ಸಪ್ತಮಿ)',
        'enTitle': 'Dasara Navratri – Day 7 (Saptami)',
        'hiTitle': 'दशहरा नवरात्रि – सप्तम दिवस (सप्तमी)',
        'knDeity': 'ಶ್ರೀ ಕಾಳರಾತ್ರಿ ದೇವಿ (ಸರಸ್ವತಿ ಆವಾಹನೆ)',
        'enDeity': 'Goddess Kalaratri & Saraswati Avahana',
        'hiDeity': 'माता कालरात्रि (सरस्वती आवाहन)',
        'knColor': 'ನೀಲಿ (Royal Blue)',
        'knSig':
            'ಕತ್ತಲೆಯನ್ನು ನಾಶಪಡಿಸುವ ಕಾಳರಾತ್ರಿ ದೇವಿ. ಶುಭಂಕರಿ ಎಂದೂ ಕರೆಯಲ್ಪಡುವ ಈ ತಾಯಿ ಜ್ಞಾನದ ಅಧಿದೇವತೆ ಸರಸ್ವತಿಯ ಆವಾಹನೆಯೊಂದಿಗೆ ಸರ್ವ ಗ್ರಹದೋಷ ನಿವಾರಿಸುತ್ತಾಳೆ.',
        'enSig':
            'Fierce destroyer of dark forces while bestowing auspicious boons (Shubhankari). Also marks Saraswati Avahana for supreme wisdom.',
        'hiSig':
            'अज्ञान रूपी अंधकार का नाश करने वाली मां कालरात्रि। काल और संकटों का हरण कर अभय प्रदान करती हैं।',
        'knRituals': ['ಬೆಲ್ಲ ಹಾಗೂ ಎಳ್ಳುಂಡೆ ನೈವೇದ್ಯ', 'ಸರಸ್ವತಿ ಆವಾಹನೆ ಪೂಜೆ', 'ಪುಸ್ತಕ-ಲೇಖನಿ ಪೂಜೆ'],
        'enRituals': ['Jaggery offering', 'Saraswati Avahana worship', 'Prayers for learning and knowledge'],
        'hiRituals': ['गुड़ का नैवेद्य', 'सरस्वती आवाहन एवं पुस्तक पूजन'],
        'mantra': 'ಓಂ ದೇವಿ ಕಾಳರಾತ್ರ್ಯೈ ನಮಃ • Om Devi Kalaratryai Namah',
        'stotram': 'Saraswati Stotram',
      },
      8: {
        'knTitle': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೮ (ದುರ್ಗಾಷ್ಟಮಿ)',
        'enTitle': 'Dasara Navratri – Day 8 (Durgashtami)',
        'hiTitle': 'दशहरा नवरात्रि – अष्टम दिवस (दुर्गाष्टमी)',
        'knDeity': 'ಶ್ರೀ ಮಹಾಗೌರಿ ದೇವಿ (ಮಹಾಷ್ಟಮಿ)',
        'enDeity': 'Goddess Mahagauri (Maha Ashtami)',
        'hiDeity': 'माता महागौरी (महाअष्टमी)',
        'knColor': 'ಗುಲಾಬಿ (Pink)',
        'knSig':
            'ಅತ್ಯಂತ ಮಂಗಳಕರವಾದ ಮಹಾಷ್ಟಮಿ ದಿನ. ಶಂಖ, ಚಂದ್ರರಂತೆ ಶುಭ್ರವಾಗಿರುವ ಮಹಾಗೌರಿಯು ಭಕ್ತರ ಪಾಪ-ತಾಪಗಳನ್ನು ಕ್ಷಣಾರ್ಧದಲ್ಲಿ ತೊಳೆಯುತ್ತಾಳೆ.',
        'enSig':
            'The deeply sacred Maha Ashtami day. Maa Mahagauri represents supreme purity and washes away past karmas instantly.',
        'hiSig':
            'महाअष्टमी का परम पावन दिन। महागौरी की उपासना से समस्त संचित पाप नष्ट होते हैं और अक्षय सुख की प्राप्ति होती है।',
        'knRituals': ['ತೆಂಗಿನಕಾಯಿ ನೈವೇದ್ಯ', 'ಕನ್ಯಾ ಪೂಜೆ (ಬಾಲೆಯರ ಅರ್ಚನೆ)', 'ಸಂಧಿ ಪೂಜೆ'],
        'enRituals': ['Coconut offering', 'Kanya Puja (honoring young girls)', 'Sandhi Puja in evening'],
        'hiRituals': ['नारियल का भोग', 'कन्या पूजन', 'संधि पूजा दर्शन'],
        'mantra': 'ಓಂ ದೇವಿ ಮಹಾಗೌರ್ಯೈ ನಮಃ • Om Devi Mahagauryai Namah',
        'stotram': 'Annapurna Stotram',
      },
      9: {
        'knTitle': 'ದಸರಾ ನವರಾತ್ರಿ – ದಿನ ೯ (ಮಹಾನವಮಿ & ಆಯುಧ ಪೂಜೆ)',
        'enTitle': 'Dasara Navratri – Day 9 (Mahanavami & Ayudha Pooja)',
        'hiTitle': 'दशहरा नवरात्रि – नवम दिवस (महानवमी एवं आयुध पूजा)',
        'knDeity': 'ಶ್ರೀ ಸಿದ್ಧಿಧಾತ್ರಿ ದೇವಿ',
        'enDeity': 'Goddess Siddhidatri (Ayudha Pooja)',
        'hiDeity': 'माता सिद्धिदात्री (आयुध पूजा)',
        'knColor': 'ನೇರಳೆ (Purple)',
        'knSig':
            'ಅಷ್ಟಸಿದ್ಧಿಗಳನ್ನು ಕರುಣಿಸುವ ಸಿದ್ಧಿಧಾತ್ರಿ ದೇವಿ. ಜೀವನೋಪಾಯದ ಉಪಕರಣಗಳು, ವಾಹನಗಳು ಹಾಗೂ ಗ್ರಂಥಗಳಿಗೆ ಕೃತಜ್ಞತೆಯಿಂದ ಪೂಜೆ ಸಲ್ಲಿಸುವ ಮಹಾನವಮಿ.',
        'enSig':
            'Giver of all mystic siddhis and accomplishments. Concurrently celebrated as Ayudha Pooja, honoring instruments of livelihood.',
        'hiSig':
            'अष्ट सिद्धियों की दात्री मां सिद्धिदात्री। समस्त कर्म उपकरणों, वाहनों और विद्या की महापूजा का पावन दिवस।',
        'knRituals': ['ಕಡಲೆಕಾಳು ಉಸಲಿ & ಮಂಡಕ್ಕಿ ನೈವೇದ್ಯ', 'ಆಯುಧ ಪೂಜೆ & ವಾಹನ ಪೂಜೆ', 'ಬೂದುಗುಂಬಳಕಾಯಿ ಆರತಿ'],
        'enRituals': ['Black gram & puffed rice prasad', 'Sanctification of tools and vehicles', 'Kumbalakai Aarti'],
        'hiRituals': ['चना, हलवा एवं खीर का भोग', 'शस्त्र एवं यंत्र पूजन'],
        'mantra': 'ಓಂ ದೇವಿ ಸಿದ್ಧಿಧಾತ್ರ್ಯೈ ನಮಃ • Om Devi Siddhidatryai Namah',
        'stotram': 'Devi Mahatmyam / Durga Saptashati',
      },
      10: {
        'knTitle': 'ವಿಜಯದಶಮಿ – ದಸರಾ ಹಬ್ಬದ ಶುಭ ಮಹೋತ್ಸವ',
        'enTitle': 'Vijayadashami – Grand Dasara Festival',
        'hiTitle': 'विजयादशमी – पावन दशहरा महोत्सव',
        'knDeity': 'ಶ್ರೀ ದುರ್ಗಾದೇವಿ & ಶಮೀ ವೃಕ್ಷ (ವಿಜಯೋತ್ಸವ)',
        'enDeity': 'Goddess Durga & Lord Rama (Triumph of Dharma)',
        'hiDeity': 'मां दुर्गा एवं मर्यादा पुरुषोत्तम श्रीराम',
        'knColor': 'ಬಂಗಾರ (Golden / Saffron)',
        'knSig':
            'ಅಧರ್ಮದ ಮೇಲೆ ಧರ್ಮದ ಜಯೋತ್ಸವ. ದುರ್ಗೆಯು ಮಹಿಷಾಸುರನನ್ನು ಸಂಹರಿಸಿದ ಹಾಗೂ ಶ್ರೀರಾಮನು ರಾವಣನ ಮೇಲೆ ವಿಜಯ ಸಾಧಿಸಿದ ಮಹಾ ದಿನ. ಶಮೀ ವೃಕ್ಷ ಪೂಜೆ ವಿಜಯಪ್ರದಾಯಕ.',
        'enSig':
            'Supreme culmination of Navratri symbolizing the eternal victory of truth over evil. Rama slayed Ravana and Durga defeated Mahishasura.',
        'hiSig':
            'अधर्म पर धर्म और असत्य पर सत्य की शाश्वत विजय का महापर्व। शमी वृक्ष पूजन एवं नए शुभ संकल्पों का शुभारंभ।',
        'knRituals': ['ಬನ್ನಿ ಮರ (ಶಮೀ ವೃಕ್ಷ) ಪೂಜೆ & ಎಲೆ ವಿನಿಮಯ', 'ವಿದ್ಯಾರಂಭ / ಅಕ್ಷರಾಭ್ಯಾಸ', 'ನೂತನ ಕಾರ್ಯಾರಂಭ'],
        'enRituals': ['Shami tree worship and gold-leaf exchange', 'Vidyarambha for children', 'Beginning new initiatives'],
        'hiRituals': ['शमी पूजन एवं अपराजिता स्तोत्र', 'विद्यारंभ संस्कार', 'नूतन कार्य शुभारंभ'],
        'mantra': 'ಶಮೀ ಶಮಯತೇ ಪಾಪಂ ಶಮೀ ಶತ್ರು ವಿನಾಶಿನೀ • Om Vijaya Durgayai Namah',
        'stotram': 'Shami Shloka & Sri Rama Raksha Stotram',
      },
    };

    final day = dasaraDays[dayNum] ?? dasaraDays[1]!;
    final isKn = lang == 'kn';
    final isHi = lang == 'hi';

    return SpecialDayInfo(
      id: 'dasara_day_$dayNum',
      title: isKn ? day['knTitle']! : (isHi ? day['hiTitle']! : day['enTitle']!),
      subtitle: isKn
          ? 'ದಸರಾ ನವರಾತ್ರಿ ಮಹೋತ್ಸವ (${day['knColor']})'
          : (isHi ? 'दशहरा नवरात्रि पावन उत्सव' : 'Grand Sharad Navratri Festival'),
      deity: isKn ? day['knDeity']! : (isHi ? day['hiDeity']! : day['enDeity']!),
      significance: isKn ? day['knSig']! : (isHi ? day['hiSig']! : day['enSig']!),
      rituals: isKn
          ? List<String>.from(day['knRituals']!)
          : (isHi ? List<String>.from(day['hiRituals']!) : List<String>.from(day['enRituals']!)),
      mantra: day['mantra'] as String,
      auspiciousColor: day['knColor'] as String?,
      recommendedStotram: day['stotram'] as String?,
      badgeText: isKn ? 'ದಸರಾ ನವರಾತ್ರಿ ದಿನ $dayNum' : 'Navratri Day $dayNum',
    );
  }

  static SpecialDayInfo _getMahalayaAmavasyaInfo(String lang) {
    final isKn = lang == 'kn';
    final isHi = lang == 'hi';

    return SpecialDayInfo(
      id: 'mahalaya_amavasya',
      title: isKn
          ? 'ಮಹಾಲಯ ಅಮಾವಾಸ್ಯೆ (ಸರ್ವ ಪಿತೃ ಅಮಾವಾಸ್ಯೆ)'
          : (isHi ? 'महालय अमावस्या (सर्वपितृ अमावस्या)' : 'Mahalaya Amavasya (Sarva Pitru Amavasya)'),
      subtitle: isKn
          ? 'ಪಿತೃಪಕ್ಷದ ಪರಮ ಪವಿತ್ರ ಮಹಾಸಂಗಮ ದಿನ'
          : (isHi ? 'पितृपक्ष की पावन सर्वपितृ मोक्ष तिथि' : 'Culmination of Pitru Paksha & Ancestral Blessings'),
      deity: isKn
          ? 'ಪಿತೃ ದೇವತೆಗಳು & ಶ್ರೀ ಮಹಾವಿಷ್ಣು'
          : (isHi ? 'पितृ देव एवं श्री लक्ष्मीनारायण' : 'Pitru Devas & Lord Maha Vishnu'),
      significance: isKn
          ? 'ಪಿತೃಪಕ್ಷದ ಅತ್ಯಂತ ಶ್ರೇಷ್ಠ ದಿನ. ತಿಳಿಯದ ಅಥವಾ ನೆನಪಿರದ ಎಲ್ಲ ಪೂರ್ವಜರಿಗೆ ತರ್ಪಣ ಮತ್ತು ಕೃತಜ್ಞತೆ ಅರ್ಪಿಸುವ ಮಹಾ ಪುಣ್ಯ ಕಾಲ. ಪಿತೃಗಳ ಸಂತೃಪ್ತಿಯಿಂದ ಕುಟುಂಬದಲ್ಲಿ ಸುಖ, ಶಾಂತಿ, ಆರೋಗ್ಯ ಹಾಗೂ ವಂಶಾಭಿವೃದ್ಧಿ ಸಿದ್ಧಿಸುತ್ತದೆ.'
          : (isHi
              ? 'पितृपक्ष का सबसे पावन और फलदायी दिन। अज्ञात एवं ज्ञात सभी पूर्वजों के निमित्त तर्पण, श्राद्ध और अन्नदान से पितृदोष समाप्त होता है और परिवार में सुख-समृद्धि आती है।'
              : 'The most sacred day of Pitru Paksha. Offering prayers, tarpana, and food donations for all departed souls ensures ancestral liberation, peace, and family harmony.'),
      rituals: isKn
          ? [
              'ಎಳ್ಳು ಮತ್ತು ಪವಿತ್ರ ಜಲದಿಂದ ಪಿತೃ ತರ್ಪಣ ಸಮರ್ಪಣೆ',
              'ಅನ್ನದಾನ, ಗೋಸೇವೆ (ಹಸುವಿಗೆ ಅಗ್ರಾಸನ) ಹಾಗೂ ಕಾಗೆಗಳಿಗೆ ಅನ್ನ ನೀಡಿಕೆ',
              'ತುಳಸಿ ಕಟ್ಟೆಯ ಬಳಿ ಸಂಜೆ ಎಳ್ಳೆಣ್ಣೆ ದೀಪ ಪ್ರಜ್ವಲನ',
              'ಪೂರ್ವಜರ ಆತ್ಮಶಾಂತಿಗಾಗಿ ಭಗವದ್ಗೀತಾ ೭ನೇ ಅಧ್ಯಾಯ ಪಠಣ',
            ]
          : (isHi
              ? [
                  'तिल और जल से पितरों का तर्पण एवं श्राद्ध',
                  'गौमाता, ब्राह्मण एवं जरूरतमंदों को अन्नदान',
                  'सायंकाल तुलसी जी के समीप दीपदान',
                  'भगवद्गीता के सातवें अध्याय का पाठ',
                ]
              : [
                  'Offering water & black sesame (Tila Tarpana)',
                  'Food donation to the needy, cows, and birds',
                  'Lighting sesame oil lamps in the evening',
                  'Recitation of Bhagavad Gita Chapter 7',
                ]),
      mantra: 'ಓಂ ಪಿತೃದೇವಾಯ ನಮಃ • ಓಂ ನಮೋ ಭಗವತೇ ವಾಸುದೇವಾಯ',
      recommendedStotram: 'Sri Vishnu Sahasranama Stotram',
      badgeText: isKn ? 'ಪಿತೃ ಮೋಕ್ಷ ಪುಣ್ಯಕಾಲ' : 'Ancestral Blessings',
    );
  }

  static SpecialDayInfo _getEkadashiInfo(bool isKrishna, String lang) {
    final isKn = lang == 'kn';
    final isHi = lang == 'hi';

    return SpecialDayInfo(
      id: isKrishna ? 'krishna_ekadashi' : 'shukla_ekadashi',
      title: isKn
          ? (isKrishna ? 'ಕೃಷ್ಣ ಪಕ್ಷ ಏಕಾದಶಿ ವ್ರತ' : 'ಶುಕ್ಲ ಪಕ್ಷ ಏಕಾದಶಿ ವ್ರತ')
          : (isHi ? 'पावन एकादशी व्रत (हरिवासर)' : 'Sacred Ekadashi Vrata (Harivasara)'),
      subtitle: isKn
          ? 'ಶ್ರೀ ಮಹಾವಿಷ್ಣುವಿನ ಪ್ರೀತ್ಯರ್ಥ ಪರಮ ಪವಿತ್ರ ಉಪವಾಸ ದಿನ'
          : 'Day of Spiritual Fasting Dedicated to Lord Vishnu',
      deity: isKn ? 'ಶ್ರೀ ಲಕ್ಷ್ಮೀ ನಾರಾಯಣ' : 'Lord Maha Vishnu',
      significance: isKn
          ? 'ಏಕಾದಶಿಯು ಸಕಲ ಪಾಪನಾಶಕ ಮತ್ತು ಮುಕ್ತಿದಾಯಕ ವ್ರತ. ಉಪವಾಸ ಮತ್ತು ವಿಷ್ಣು ನಾಮಸ್ಮರಣೆಯಿಂದ ಆತ್ಮಶುದ್ಧಿ ಹಾಗೂ ಮನಸ್ಸಿನ ಶಾಂತಿ ಪ್ರಾಪ್ತಿಯಾಗುತ್ತದೆ.'
          : 'Ekadashi is the mother of all spiritual fasts. Detoxing body and mind while meditating on Lord Vishnu brings mental peace and boundless grace.',
      rituals: isKn
          ? [
              'ಧಾನ್ಯ ತ್ಯಜಿಸಿ ಲಘು ಆಹಾರ ಅಥವಾ ಉಪವಾಸ ಆಚರಣೆ',
              'ವಿಷ್ಣು ಸಹಸ್ರನಾಮ ಸ್ತೋತ್ರ ಪಠಣ ಹಾಗೂ ಹರೇ ಕೃಷ್ಣ ಮಹಾಮಂತ್ರ ಜಪ',
              'ತುಳಸಿ ಪೂಜೆ (ಇಂದು ತುಳಸಿ ಎಲೆ ಕೀಳಬಾರದು, ಕೇವಲ ನಮಸ್ಕಾರ)',
            ]
          : [
              'Fasting from grains and heavy foods',
              'Chanting Vishnu Sahasranama & Hare Krishna Maha Mantra',
              'Tulasi Puja with ghee lamps',
            ],
      mantra: 'ಓಂ ನಮೋ ನಾರಾಯಣಾಯ • Om Namo Narayanaya',
      recommendedStotram: 'Sri Vishnu Sahasranama Stotram',
      badgeText: isKn ? 'ಹರಿವಾಸರ ಪರ್ವದಿನ' : 'Sacred Ekadashi',
    );
  }

  static SpecialDayInfo _getPradoshaInfo(int weekday, String lang) {
    final isKn = lang == 'kn';
    final isShani = weekday == DateTime.saturday;
    final isSoma = weekday == DateTime.monday;

    final name = isShani
        ? (isKn ? 'ಶನಿ ಪ್ರದೋಷ ವ್ರತ' : 'Shani Pradosha Vrata')
        : (isSoma ? (isKn ? 'ಸೋಮ ಪ್ರದೋಷ ವ್ರತ' : 'Soma Pradosha Vrata') : (isKn ? 'ಪ್ರದೋಷ ವ್ರತ' : 'Pradosha Vrata'));

    return SpecialDayInfo(
      id: 'pradosha_vrata',
      title: name,
      subtitle: isKn ? 'ಸಂಜೆ ಪ್ರದೋಷ ಕಾಲದಲ್ಲಿ ಶಿವ ಪೂಜೆ' : 'Twilight Worship of Lord Shiva',
      deity: isKn ? 'ಶ್ರೀ ಮಹಾದೇವ ಪಾರ್ವತಿ ಸಮೇತ' : 'Lord Shiva & Goddess Parvati',
      significance: isKn
          ? 'ಸೂರ್ಯಾಸ್ತದ ಮುನ್ನ ಮುಸ್ಸಂಜೆ ಸಮಯದಲ್ಲಿ ಕೈಲಾಸದಲ್ಲಿ ಪರಶಿವನು ಆನಂದ ತಾಂಡವವಾಡುವ ಸಮಯ. ಈ ವೇಳೆಯಲ್ಲಿ ನಂದಿ ಮತ್ತು ಶಿವನಿಗೆ ಬಿಲ್ವಪತ್ರೆ ಅರ್ಪಿಸಿದರೆ ಸಕಲ ದೋಷಗಳು ನಿವಾರಣೆಯಾಗುತ್ತವೆ.'
          : 'During twilight (Pradosha kalam), Lord Shiva performs his divine Ananda Tandava. Offering prayers and bilva leaves removes karmic burdens.',
      rituals: isKn
          ? [
              'ಮುಸ್ಸಂಜೆ ಪ್ರದೋಷ ಕಾಲದಲ್ಲಿ ಶಿವಲಿಂಗಕ್ಕೆ ಜಲಾಭಿಷೇಕ / ಕ್ಷೀರಾಭಿಷೇಕ',
              'ಶಿವನಿಗೆ ಮತ್ತು ನಂದೀಶ್ವರನಿಗೆ ಬಿಲ್ವಪತ್ರೆ ಅರ್ಪಣೆ',
              'ಓಂ ನಮಃ ಶಿವಾಯ ಪಂಚಾಕ್ಷರೀ ಮಂತ್ರ ೧೦೮ ಬಾರಿ ಜಪ',
            ]
          : [
              'Abhishekam with milk/water during sunset hours',
              'Offering Bilva leaves to Shiva and Nandi',
              'Chanting Om Namah Shivaya 108 times',
            ],
      mantra: 'ಓಂ ನಮಃ ಶಿವಾಯ • Om Namah Shivaya',
      recommendedStotram: 'Shiva Tandava Stotram',
      badgeText: isKn ? 'ಶಿವ ಪ್ರದೋಷ ಕಾಲ' : 'Pradosham',
    );
  }

  static SpecialDayInfo _getSankashtiInfo(bool isAngarki, String lang) {
    final isKn = lang == 'kn';
    final title = isAngarki
        ? (isKn ? 'ಅಂಗಾರಕಿ ಸಂಕಷ್ಟಹರ ಚತುರ್ಥಿ' : 'Angarki Sankashti Chaturthi')
        : (isKn ? 'ಸಂಕಷ್ಟಹರ ಚತುರ್ಥಿ ವ್ರತ' : 'Sankashti Chaturthi Vrata');

    return SpecialDayInfo(
      id: 'sankashti_chaturthi',
      title: title,
      subtitle: isKn ? 'ವಿಘ್ನನಾಶಕ ಗಣಪತಿ ಪೂಜೆ & ಚಂದ್ರೋದಯ ವ್ರತ' : 'Obstacle-Removal Ganapati Puja & Moonrise Fast',
      deity: isKn ? 'ಶ್ರೀ ಮಹಾಗಣಪತಿ' : 'Lord Ganesha',
      significance: isKn
          ? 'ಸಂಕಟಗಳನ್ನು ಕಳೆಯುವ ಮಹಾ ಚತುರ್ಥಿ. ದಿನವಿಡೀ ಉಪವಾಸವಿದ್ದು ರಾತ್ರಿ ಚಂದ್ರೋದಯದ ನಂತರ ಗಣೇಶನಿಗೆ ಗರಿಕೆ, ಮೋದಕ ಅರ್ಪಿಸಿ ಚಂದ್ರ ದರ್ಶನ ಮಾಡಿದರೆ ಸಂಕಷ್ಟಗಳು ದೂರಾಗುತ್ತವೆ.'
          : 'Sacred fast dedicated to Lord Ganesha. Observing fast until moonrise and offering 21 Durva blades removes insurmountable hurdles.',
      rituals: isKn
          ? [
              'ಗಣಪತಿಗೆ ೨೧ ಗರಿಕೆ (ದೂರ್ವಾ) ಸಮರ್ಪಣೆ',
              'ಮೋದಕ ಅಥವಾ ಬೆಲ್ಲದ ಕಡುಬು ನೈವೇದ್ಯ',
              'ರಾತ್ರಿ ಚಂದ್ರೋದಯದ ನಂತರ ಅರ್ಘ್ಯ ಪ್ರದಾನ ಮತ್ತು ಪ್ರಸಾದ ಸ್ವೀಕಾರ',
            ]
          : [
              'Offering 21 blades of sacred Durva grass',
              'Modaka and jaggery prasad offering',
              'Arghya offering upon moonrise sighting',
            ],
      mantra: 'ಓಂ ಗಂ ಗಣಪತಯೇ ನಮಃ • Om Gam Ganapataye Namah',
      recommendedStotram: 'Sankata Nashana Ganesha Stotram',
      badgeText: isKn ? 'ಸಂಕಷ್ಟಿ ಚತುರ್ಥಿ' : 'Sankashti',
    );
  }

  static SpecialDayInfo _getPurnimaInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'purnima_day',
      title: isKn ? 'ಹುಣ್ಣಿಮೆ (ಪೌರ್ಣಮಿ) ಮಹಾವ್ರತ' : 'Purnima (Full Moon) Sacred Day',
      subtitle: isKn ? 'ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ಪೂಜೆ & ಚಂದ್ರ ದರ್ಶನ' : 'Satyanarayana Swamy Puja & Chandra Darshana',
      deity: isKn ? 'ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ಸ್ವಾಮಿ & ಚಂದ್ರ ದೇವ' : 'Lord Satyanarayana Swamy',
      significance: isKn
          ? 'ಹುಣ್ಣಿಮೆಯು ಸಕಲ ಸಕಾರಾತ್ಮಕ ಶಕ್ತಿಗಳ ಪ್ರಕಾಶ. ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ವ್ರತ ಆಚರಣೆಯಿಂದ ಕುಟುಂಬದಲ್ಲಿ ನೆಮ್ಮದಿ, ಐಶ್ವರ್ಯ ಹಾಗೂ ಶಾಂತಿ ನೆಲೆಸುತ್ತದೆ.'
          : 'Purnima embodies full spiritual illumination. Performing Satyanarayana puja and lighting ghee lamps fills the home with prosperity.',
      rituals: isKn
          ? [
              'ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ಸ್ವಾಮಿ ಕಥಾ ಶ್ರವಣ ಹಾಗೂ ಪೂಜೆ',
              'ಸಪ್ಪೆ ಸಜ್ಜಿಗೆ (ಶಿರಾ) ನೈವೇದ್ಯ ಅರ್ಪಣೆ',
              'ಸಂಜೆ ತುಳಸಿ ಕಟ್ಟೆ ಬಳಿ ತುಪ್ಪದ ದೀಪಾರಾಧನೆ',
            ]
          : [
              'Sri Satyanarayana Swamy Vrata & Katha',
              'Offering sweet semolina (Sheera) prasadam',
              'Lighting ghee deepa at Tulasi altar',
            ],
      mantra: 'ಓಂ ಶ್ರೀ ಸತ್ಯನಾರಾಯಣಾಯ ನಮಃ • Om Sri Satyanarayanaya Namah',
      recommendedStotram: 'Sri Satyanarayana Ashtakam',
      badgeText: isKn ? 'ಪೌರ್ಣಮಿ ಪುಣ್ಯದಿನ' : 'Full Moon',
    );
  }

  static SpecialDayInfo _getAmavasyaInfo(int weekday, String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'amavasya_day',
      title: isKn ? 'ಅಮಾವಾಸ್ಯೆ ಪುಣ್ಯದಿನ' : 'Amavasya (New Moon) Sacred Day',
      subtitle: isKn ? 'ಪಿತೃ ತರ್ಪಣ & ದೀಪಾರಾಧನೆ' : 'Ancestral Prayers & Spiritual Cleansing',
      deity: isKn ? 'ಪಿತೃ ದೇವತೆಗಳು & ಶ್ರೀ ಪರಮೇಶ್ವರ' : 'Pitru Devas & Lord Shiva',
      significance: isKn
          ? 'ಅಮಾವಾಸ್ಯೆಯಂದು ನಕಾರಾತ್ಮಕ ಶಕ್ತಿಗಳು ದೂರವಾಗಲು ಮನೆಯಲ್ಲಿ ದೀಪ ಬೆಳಗಿಸಿ, ಪಿತೃಗಳಿಗೆ ತರ್ಪಣ ನೀಡುವುದು ಅತ್ಯಂತ ಶ್ರೇಯಸ್ಕರ.'
          : 'New Moon day sacred for remembering ancestors and removing inner obstacles through evening lamps and prayers.',
      rituals: isKn
          ? ['ಪಿತೃಗಳಿಗೆ ತರ್ಪಣ ಸಮರ್ಪಣೆ', 'ದರಿದ್ರ ನಿವಾರಣೆಗೆ ಸಂಜೆ ಹೊಸಿಲಲ್ಲಿ ದೀಪ ಬೆಳಗುವುದು', 'ಅನ್ನದಾನ']
          : ['Tarpana for ancestors', 'Lighting evening lamps at home threshold', 'Food charity'],
      mantra: 'ಓಂ ನಮಃ ಶಿವಾಯ • Om Namah Shivaya',
      recommendedStotram: 'Shiva Panchakshara Stotram',
      badgeText: isKn ? 'ಅಮಾವಾಸ್ಯೆ' : 'New Moon',
    );
  }

  static SpecialDayInfo _getDhanterasInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'dhanteras',
      title: isKn ? 'ಧನತೇರಸ್ (ಧನ್ವಂತರಿ ಜಯಂತಿ)' : 'Dhanteras & Dhanvantari Jayanti',
      subtitle: isKn ? 'ದೀಪಾವಳಿಯ ಶುಭಾರಂಭ' : 'Auspicious Beginning of Deepavali',
      deity: isKn ? 'ಭಗವಾನ್ ಧನ್ವಂತರಿ & ಲಕ್ಷ್ಮೀ ಕುಬೇರ' : 'Lord Dhanvantari & Goddess Lakshmi',
      significance: isKn
          ? 'ಆರೋಗ್ಯದ ಅಧಿದೇವತೆ ಧನ್ವಂತರಿ ಹಾಗೂ ಸಮೃದ್ಧಿಯ ಅಧಿದೇವತೆ ಲಕ್ಷ್ಮಿಯ ಆರಾಧನೆಯ ದಿನ. ಸಂಜೆ ಯಮದೀಪ ದಾನದಿಂದ ಅಪಮೃತ್ಯು ಭಯ ನಿವಾರಣೆಯಾಗುತ್ತದೆ.'
          : 'Celebrates Lord Dhanvantari, god of health, and Goddess Lakshmi for abundance and freedom from ailments.',
      rituals: isKn
          ? ['ದಕ್ಷಿಣ ದಿಕ್ಕಿಗೆ ಮುಖಮಾಡಿ ಯಮದೀಪ ಬೆಳಗುವುದು', 'ಧನ್ವಂತರಿ ಪೂಜೆ & ಆಯುರ್ವೇದ ನಮಸ್ಕಾರ', 'ಚಿನ್ನ, ಬೆಳ್ಳಿ ಅಥವಾ ಹೊಸ ಪಾತ್ರೆ ಖರೀದಿ']
          : ['Lighting Yama Deepa facing south', 'Prayers for robust health to Dhanvantari', 'Purchasing new metal utensils'],
      mantra: 'ಓಂ ಧನ್ವಂತರಯೇ ನಮಃ • Om Dhanvantaraye Namah',
      recommendedStotram: 'Dhanvantari Mahamantra',
      badgeText: isKn ? 'ದೀಪಾವಳಿ ದಿನ ೧' : 'Deepavali Day 1',
    );
  }

  static SpecialDayInfo _getNarakaChaturdashiInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'naraka_chaturdashi',
      title: isKn ? 'ನರಕ ಚತುರ್ದಶಿ (ದೀಪಾವಳಿ ಎಣ್ಣೆಶಾಸ್ತ್ರ)' : 'Naraka Chaturdashi (Abhyanga Snana)',
      subtitle: isKn ? 'ದುಷ್ಟ ಶಕ್ತಿಗಳ ನಿವಾರಣೆ & ತೈಲಾಭ್ಯಂಜನ' : 'Triumph of Light & Sacred Oil Bath',
      deity: isKn ? 'ಶ್ರೀ ಕೃಷ್ಣ & ಸತ್ಯಭಾಮ' : 'Lord Krishna & Satyabhama',
      significance: isKn
          ? 'ಶ್ರೀಕೃಷ್ಣನು ನರಕಾಸುರನನ್ನು ವಧಿಸಿ ಧರ್ಮವನ್ನು ಸ್ಥಾಪಿಸಿದ ಮಹಾದಿನ. ಸೂರ್ಯೋದಯಕ್ಕೂ ಮುನ್ನ ಗಂಗಾಪೂಜೆ ಮಾಡಿ ಅಭ್ಯಂಜನ ಸ್ನಾನ ಮಾಡುವುದು ಶ್ರೇಷ್ಠ.'
          : 'Lord Krishna destroyed demon Narakasura. Taking early morning oil bath with Ganga invocation washes away past sins.',
      rituals: isKn
          ? ['ಬ್ರಾಹ್ಮೀ ಮುಹೂರ್ತದಲ್ಲಿ ತೈಲಾಭ್ಯಂಜನ ಸ್ನಾನ', 'ಮನೆಯ ಮುಂದೆ ಸಾಲು ದೀಪಗಳ ಬೆಳಗುವಿಕೆ', 'ಸಿಹಿ ಹಂಚಿಕೆ']
          : ['Sacred early morning oil bath', 'Lighting series of clay oil lamps', 'Sharing festival sweets'],
      mantra: 'ಓಂ ನಮೋ ಭಗವತೇ ವಾಸುದೇವಾಯ • Om Namo Bhagavate Vasudevaya',
      recommendedStotram: 'Krishna Ashtakam',
      badgeText: isKn ? 'ದೀಪಾವಳಿ ದಿನ ೨' : 'Deepavali Day 2',
    );
  }

  static SpecialDayInfo _getLakshmiPoojaInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'lakshmi_pooja',
      title: isKn ? 'ದೀಪಾವಳಿ ಮಹಾಲಕ್ಷ್ಮೀ ಪೂಜೆ' : 'Deepavali Maha Lakshmi Pooja',
      subtitle: isKn ? 'ಮನೆಯಲ್ಲಿ ದೀಪಗಳ ಹಬ್ಬ & ಸಿರಿ ಸಂಪತ್ತು' : 'Festival of Lights & Divine Abundance',
      deity: isKn ? 'ಶ್ರೀ ಮಹಾಲಕ್ಷ್ಮೀ & ಗಣಪತಿ' : 'Goddess Maha Lakshmi & Lord Ganesha',
      significance: isKn
          ? 'ದೀಪಾವಳಿಯ ಅಮಾವಾಸ್ಯೆಯಂದು ಜಗದಂಬೆ ಲಕ್ಷ್ಮಿದೇವಿಯು ಭಕ್ತರ ಮನೆಗಳಿಗೆ ಆಗಮಿಸಿ ಸುಖ-ಶಾಂತಿ, ಅಷ್ಟೈಶ್ವರ್ಯವನ್ನು ಕರುಣಿಸುತ್ತಾಳೆ.'
          : 'Auspicious Deepavali Amavasya when Goddess Lakshmi visits pure and illuminated homes to bestow auspicious wealth.',
      rituals: isKn
          ? ['ಸಂಜೆ ಸಾಲುಸಾಲು ಹಣತೆ ದೀಪಗಳನ್ನು ಬೆಳಗುವುದು', 'ಲಕ್ಷ್ಮೀ-ಕುಬೇರ ಪೂಜೆ & ಕಾಸಿನ ಪೂಜೆ', 'ಮನೆಯ ಬಾಗಿಲಲ್ಲಿ ರಂಗೋಲಿ ರಚನೆ']
          : ['Lighting clay deepas around the house', 'Lakshmi-Kubera puja with gold/coins', 'Sacred rangoli offerings'],
      mantra: 'ಓಂ ಶ್ರೀಂ ಹ್ರೀಂ ಕ್ಲೀಂ ಮಹಾಲಕ್ಷ್ಮ್ಯೈ ನಮಃ • Om Maha Lakshmyai Namah',
      recommendedStotram: 'Sri Mahalakshmi Ashtakam',
      badgeText: isKn ? 'ದೀಪಾವಳಿ ದಿನ ೩' : 'Deepavali Day 3',
    );
  }

  static SpecialDayInfo _getBaliPadyamiInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'bali_padyami',
      title: isKn ? 'ಬಲಿಪಾಡ್ಯಮಿ (ಗೋವು ಪೂಜೆ)' : 'Bali Padyami (Go Puja)',
      subtitle: isKn ? 'ಬಲಿ ಚಕ್ರವರ್ತಿ ಆರಾಧನೆ & ಗೋವು ಪೂಜೆ' : 'King Bali Remembrance & Cow Worship',
      deity: isKn ? 'ವಾಮನ ಮೂರ್ತಿ & ಕಾಮಧೇನು' : 'Lord Vamana & Kamadhenu',
      significance: isKn
          ? 'ವಾಮನಾವತಾರದಲ್ಲಿ ಭಗವಂತನು ಬಲಿ ಚಕ್ರವರ್ತಿಗೆ ನೀಡಿದ ವರದಂತೆ ಬಲಿ ರಾಜನು ಭೂಮಿಗೆ ಬರುವ ದಿನ. ಗೋಪೂಜೆ ಅತ್ಯಂತ ಪುಣ್ಯಪ್ರದ.'
          : 'Day of king Bali returning to earth and honored for his immense charity. Cows (Gomata) are decorated and worshiped.',
      rituals: isKn
          ? ['ಹಸುವಿಗೆ ಅರಿಶಿನ-ಕುಂಕುಮ ಹಚ್ಚಿ ಗೋಪೂಜೆ ಮಾಡುವುದು', 'ಬಲಿ ಪಾಡ್ಯಮಿ ದೀಪಾರಾಧನೆ', 'ನವೀನ ವಸ್ತ್ರಧಾರಣೆ']
          : ['Worshiping and feeding cows', 'Bali Padyami deepa lighting', 'Wearing new attire'],
      mantra: 'ಓಂ ನಮೋ ನಾರಾಯಣಾಯ • Om Namo Narayanaya',
      recommendedStotram: 'Vamana Stotram',
      badgeText: isKn ? 'ದೀಪಾವಳಿ ದಿನ ೪' : 'Deepavali Day 4',
    );
  }

  static SpecialDayInfo _getMahaShivaratriInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'maha_shivaratri',
      title: isKn ? 'ಮಹಾ ಶಿವರಾತ್ರಿ ಮಹಾಪರ್ವ' : 'Maha Shivaratri Grand Festival',
      subtitle: isKn ? 'ಜಾಗರಣೆ, ರುದ್ರಾಭಿಷೇಕ & ಲಿಂಗೋದ್ಭವ' : 'All-Night Vigil & Divine Rudrabhisheka',
      deity: isKn ? 'ಶ್ರೀ ಪರಮೇಶ್ವರ (ಮಹಾಲಿಂಗ)' : 'Lord Shiva (Mahalinga)',
      significance: isKn
          ? 'ಶಿವ-ಪಾರ್ವತಿಯರ ಕಲ್ಯಾಣ ಮಹೋತ್ಸವ ಮತ್ತು ಲಿಂಗೋದ್ಭವ ಪುಣ್ಯಕಾಲ. ಇಡೀ ರಾತ್ರಿ ಜಾಗರಣೆ ಹಾಗೂ ರುದ್ರಾಭಿಷೇಕದಿಂದ ಮುಕ್ತಿ ಪ್ರಾಪ್ತಿಯಾಗುತ್ತದೆ.'
          : 'The great night of Lord Shiva when cosmic energy is at its peak. Fasting, night vigil, and chanting bring immense peace.',
      rituals: isKn
          ? ['ನಾಲ್ಕು ಜಾವದ ಶಿವಲಿಂಗ ಪೂಜೆ & ಬಿಲ್ವಾರ್ಚನೆ', 'ರಾತ್ರಿ ಜಾಗರಣೆ & ಓಂ ನಮಃ ಶಿವಾಯ ಜಪ', 'ಉಪವಾಸ ವ್ರತ']
          : ['Four Prahar Rudrabhishekam with Bilva leaves', 'All-night Jaagarane vigil', 'Strict fasting and meditation'],
      mantra: 'ಓಂ ನಮಃ ಶಿವಾಯ • Om Namah Shivaya',
      recommendedStotram: 'Sri Rudram & Shiva Tandava Stotram',
      badgeText: isKn ? 'ಮಹಾ ಶಿವರಾತ್ರಿ' : 'Maha Shivaratri',
    );
  }

  static SpecialDayInfo _getGaneshChaturthiInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'ganesh_chaturthi',
      title: isKn ? 'ಶ್ರೀ ಗಣೇಶ ಚತುರ್ಥಿ (ವಿನಾಯಕ ಹಬ್ಬ)' : 'Sri Vinayaka Chaturthi Festival',
      subtitle: isKn ? 'ಮಹಾಗಣಪತಿಯ ಅವತಾರ ದಿನ' : 'Birth Day of Lord Ganesha',
      deity: isKn ? 'ಶ್ರೀ ವರಸಿದ್ಧಿ ವಿನಾಯಕ' : 'Lord Varasiddhi Vinayaka',
      significance: isKn
          ? 'ವಿಘ್ನರಾಜನ ಅವತಾರ ದಿನ. ಮನೆಯಲ್ಲಿ ಮಣ್ಣಿನ ಗಣಪತಿಯನ್ನು ಪ್ರತಿಷ್ಠಾಪಿಸಿ ೨೧ ಬಗೆಯ ಪತ್ರೆಗಳಿಂದ ಪೂಜಿಸಿದರೆ ಸಕಲ ಕಾರ್ಯಗಳು ಸಿದ್ಧಿಯಾಗುತ್ತವೆ.'
          : 'Arrival of Lord Ganesha to bestow auspicious beginnings and remove all obstacles. Celebrated with 21 varieties of leaves and modakas.',
      rituals: isKn
          ? ['ಮಣ್ಣಿನ ಗಣೇಶನ ಪ್ರತಿಷ್ಠಾಪನೆ & ೨೧ ಪತ್ರೆಗಳ ಪೂಜೆ', '೨೧ ಮೋದಕ, ಕಡುಬು, ಮೋದಕ ನೈವೇದ್ಯ', 'ಅಥರ್ವಶೀರ್ಷ ಪಠಣ']
          : ['Clay Ganesha installation & 21 Patra Puja', 'Offering modakas and laddu', 'Ganesha Atharvashirsha chanting'],
      mantra: 'ಓಂ ಗಂ ಗಣಪತಯೇ ನಮಃ • Om Gam Ganapataye Namah',
      recommendedStotram: 'Ganesha Atharvashirsha',
      badgeText: isKn ? 'ಗಣೇಶ ಹಬ್ಬ' : 'Ganesh Chaturthi',
    );
  }

  static SpecialDayInfo _getKrishnaJanmashtamiInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'krishna_janmashtami',
      title: isKn ? 'ಶ್ರೀ ಕೃಷ್ಣ ಜನ್ಮಾಷ್ಟಮಿ (ಗೋಕುಲಾಷ್ಟಮಿ)' : 'Sri Krishna Janmashtami',
      subtitle: isKn ? 'ಭಗವಾನ್ ಶ್ರೀಕೃಷ್ಣನ ಅವತಾರ ಮಹೋತ್ಸವ' : 'Divine Advent of Lord Sri Krishna',
      deity: isKn ? 'ಬಾಲಕೃಷ್ಣ & ಶ್ರೀ ವಾಸುದೇವ' : 'Lord Sri Krishna',
      significance: isKn
          ? 'ಮಧ್ಯರಾತ್ರಿ ರೋಹಿಣಿ ನಕ್ಷತ್ರದಲ್ಲಿ ಕೃಷ್ಣನ ಅವತಾರ. ಮನೆಯಲ್ಲಿ ಬಾಲಕೃಷ್ಣನ ಪುಟ್ಟ ಪಾದಗಳನ್ನು ಬಿಡಿಸಿ, ಬೆಣ್ಣೆ, ಅವಲಕ್ಕಿ ನೈವೇದ್ಯ ಮಾಡಿ ಸಂಭ್ರಮಿಸುವುದು.'
          : 'Celebrates the midnight advent of Lord Krishna to protect righteousness. Homes are decorated with butter and baby Krishna footsteps.',
      rituals: isKn
          ? ['ಬಾಲಕೃಷ್ಣನ ಪುಟ್ಟ ಪಾದಗಳ ರಂಗೋಲಿ', 'ಬೆಣ್ಣೆ, ಮೊಸರು, ಚಕ್ಕುಲಿ, ಕೋಡುಬಳೆ ನೈವೇದ್ಯ', 'ಮಧ್ಯರಾತ್ರಿ ಅರ್ಘ್ಯ ಪ್ರದಾನ']
          : ['Drawing little Krishna feet into the home', 'Offering butter, avalakki, and festive treats', 'Midnight arghya'],
      mantra: 'ಕೃಷ್ಣಾಯ ವಾಸುದೇವಾಯ ಹರಯೇ ಪರಮಾತ್ಮನೇ • Om Namo Bhagavate Vasudevaya',
      recommendedStotram: 'Madhurashtakam & Krishna Ashtakam',
      badgeText: isKn ? 'ಕೃಷ್ಣ ಜನ್ಮಾಷ್ಟಮಿ' : 'Janmashtami',
    );
  }

  static SpecialDayInfo _getRamaNavamiInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'rama_navami',
      title: isKn ? 'ಶ್ರೀ ರಾಮನವಮಿ ಮಹೋತ್ಸವ' : 'Sri Rama Navami Festival',
      subtitle: isKn ? 'ಮರ್ಯಾದಾ ಪುರುಷೋತ್ತಮ ಶ್ರೀರಾಮನ ಜನ್ಮದಿನ' : 'Birth Day of Lord Sri Rama',
      deity: isKn ? 'ಸೀತಾ ಲಕ್ಷ್ಮಣ ಸಮೇತ ಶ್ರೀರಾಮಚಂದ್ರ' : 'Lord Sri Ramachandra',
      significance: isKn
          ? 'ಧರ್ಮರಕ್ಷಕ ಶ್ರೀರಾಮನ ಆವಿರ್ಭಾವ ದಿನ. ಮಧ್ಯಾಹ್ನ ೧೨ ಗಂಟೆಗೆ ರಾಮ ಜನನೋತ್ಸವ, ಪಾನಕ, ಮಜ್ಜಿಗೆ, ಕೋಸಂಬರಿ ವಿತರಣೆ ಅತ್ಯಂತ ಶ್ರೇಷ್ಠ.'
          : 'Appearance day of Lord Rama at noon. Celebrated with cooling Panakam (jaggery beverage), buttermilk, and Kosambari.',
      rituals: isKn
          ? ['ಮಧ್ಯಾಹ್ನ ೧೨ ಗಂಟೆಗೆ ರಾಮ ಜನನೋತ್ಸವ ಪೂಜೆ', 'ಪಾನಕ, ಮಜ್ಜಿಗೆ, ಹೆಸರುಬೇಳೆ ಕೋಸಂಬರಿ ನೈವೇದ್ಯ', 'ರಾಮ ರಕ್ಷಾ ಸ್ತೋತ್ರ ಪಠಣ']
          : ['Noon Rama Janma celebration', 'Panakam and Kosambari distribution', 'Rama Raksha Stotram chanting'],
      mantra: 'ಶ್ರೀ ರಾಮ ರಾಮ ರಾಮೇತಿ ರಮೇ ರಾಮೇ ಮನೋರಮೇ • Sri Rama Jaya Rama Jaya Jaya Rama',
      recommendedStotram: 'Sri Rama Raksha Stotram',
      badgeText: isKn ? 'ರಾಮನವಮಿ' : 'Rama Navami',
    );
  }

  static SpecialDayInfo _getUgadiInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'ugadi',
      title: isKn ? 'ಯುಗಾದಿ ಹಬ್ಬ (ಹೊಸ ಸಂವತ್ಸರದ ಆದಿ)' : 'Ugadi / Gudi Padwa (New Year)',
      subtitle: isKn ? 'ಸನಾತನ ವೈದಿಕ ಹೊಸ ವರ್ಷದ ಪುಣ್ಯದಿನ' : 'Vedic New Year Day',
      deity: isKn ? 'ಸೃಷ್ಟಿಕರ್ತ ಬ್ರಹ್ಮದೇವ & ಕುಲದೇವತೆ' : 'Lord Brahma & Kuladevata',
      significance: isKn
          ? 'ಬ್ರಹ್ಮದೇವನು ಜಗತ್ತನ್ನು ಸೃಷ್ಟಿಸಲು ಪ್ರಾರಂಭಿಸಿದ ದಿನ. ಬೇವು-ಬೆಲ್ಲ ಸೇವನೆಯು ಜೀವನದ ಸುಖ-ದುಃಖಗಳನ್ನು ಸಮಾನವಾಗಿ ಸ್ವೀಕರಿಸುವ ಸಂಕೇತ.'
          : 'The dawn of the new Vedic era (Yuga-Adi). Eating neem and jaggery symbolizes accepting life with grace and equanimity.',
      rituals: isKn
          ? ['ಮಾವು-ಬೇವಿನ ತೋರಣ ಕಟ್ಟುವಿಕೆ', 'ಬೇವು-ಬೆಲ್ಲ ಪ್ರಸಾದ ಸ್ವೀಕಾರ', 'ಹೊಸ ಪಂಚಾಂಗ ಶ್ರವಣ']
          : ['Mango leaf torana at entrance', 'Tasting Neem & Jaggery (Bevu-Bella)', 'Panchanga Shravana for the year'],
      mantra: 'ಶತಾಯುರ್ವಜ್ರದೇಹಾಯ ಸರ್ವಸಂಪತ್ಕರಾಯ ಚ • Om Brahmane Namah',
      recommendedStotram: 'Panchanga Shravana Prayers',
      badgeText: isKn ? 'ಯುಗಾದಿ ಹಬ್ಬ' : 'Ugadi New Year',
    );
  }

  static SpecialDayInfo _getMakaraSankrantiInfo(String lang) {
    final isKn = lang == 'kn';
    return SpecialDayInfo(
      id: 'makara_sankranti',
      title: isKn ? 'ಮಕರ ಸಂಕ್ರಾಂತಿ (ಸುಗ್ಗಿ ಹಬ್ಬ)' : 'Makara Sankranti (Harvest Festival)',
      subtitle: isKn ? 'ಉತ್ತರಾಯಣ ಪುಣ್ಯಕಾಲದ ಆರಂಭ' : 'Dawn of Uttarayana & Sun Transiting to Makara',
      deity: isKn ? 'ಭಗವಾನ್ ಸೂರ್ಯನಾರಾಯಣ' : 'Lord Surya Narayana',
      significance: isKn
          ? 'ಸೂರ್ಯನು ದಕ್ಷಿಣಾಯನದಿಂದ ಉತ್ತರಾಯಣಕ್ಕೆ ಪಥ ಬದಲಿಸುವ ಪುಣ್ಯ ಕಾಲ. ಎಳ್ಳು-ಬೆಲ್ಲ ಹಂಚಿ ಒಳ್ಳೆಯ ಮಾತುಗಳನ್ನಾಡುವ ಸೌಹಾರ್ದದ ಹಬ್ಬ.'
          : 'Sun moves into Makara rashi initiating the auspicious Uttarayana. Exchanging sesame-jaggery signifies warmth and sweet speech.',
      rituals: isKn
          ? ['ಎಳ್ಳು-ಬೆಲ್ಲ, ಕೊಬ್ಬರಿ, ಕಬ್ಬು ವಿನಿಮಯ', 'ಸೂರ್ಯದೇವರಿಗೆ ತರ್ಪಣ & ಗಾಯತ್ರೀ ಜಪ', 'ಹಸುಗಳಿಗೆ ಕಿಚ್ಚು ಹಾಯಿಸುವುದು']
          : ['Exchanging Ellu-Bella and sugarcane', 'Surya Arghya and Gayatri japa', 'Honoring cattle and nature'],
      mantra: 'ಓಂ ಸೂರ್ಯಾಯ ನಮಃ • Om Suryaya Namah',
      recommendedStotram: 'Aditya Hridaya Stotram',
      badgeText: isKn ? 'ಸಂಕ್ರಾಂತಿ ಹಬ್ಬ' : 'Sankranti',
    );
  }
}
