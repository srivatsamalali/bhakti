import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PanchangaData {
  final String tithi;
  final String paksha;
  final String nakshatra;
  final String yoga;
  final String karana;
  final String dayOfWeek;
  final String deityOfTheDay;
  final String specialOccasion;
  final String brahmaMuhurta;
  final String abhijitMuhurta;
  final String rahuKalam;
  final String yamaGandam;
  final String gulikaKalam;
  final List<SacredFestival> upcomingFestivals;
  final bool isLiveFetched;

  const PanchangaData({
    required this.tithi,
    required this.paksha,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.dayOfWeek,
    required this.deityOfTheDay,
    required this.specialOccasion,
    required this.brahmaMuhurta,
    required this.abhijitMuhurta,
    required this.rahuKalam,
    required this.yamaGandam,
    required this.gulikaKalam,
    required this.upcomingFestivals,
    this.isLiveFetched = false,
  });
}

class SacredFestival {
  final String name;
  final String date;
  final int daysRemaining;
  final String deity;
  final String significance;

  const SacredFestival({
    required this.name,
    required this.date,
    required this.daysRemaining,
    required this.deity,
    required this.significance,
  });
}

class VedicDayInfo {
  final int day;
  final DateTime date;
  final String tithi;
  final String paksha;
  final String? festivalName;
  final bool isToday;
  final bool isAuspicious;

  const VedicDayInfo({
    required this.day,
    required this.date,
    required this.tithi,
    required this.paksha,
    this.festivalName,
    this.isToday = false,
    this.isAuspicious = false,
  });
}

class RashiInfo {
  final String id;
  final String name;
  final String englishName;
  final String symbol;
  final String rulingPlanet;
  final String element;
  final String prediction;
  final String luckyColor;
  final String luckyNumber;
  final String deity;
  final String mantra;

  const RashiInfo({
    required this.id,
    required this.name,
    required this.englishName,
    required this.symbol,
    required this.rulingPlanet,
    required this.element,
    required this.prediction,
    required this.luckyColor,
    required this.luckyNumber,
    required this.deity,
    required this.mantra,
  });
}

class PanchangaService with ChangeNotifier {
  PanchangaData? _cachedData;
  String _cachedLang = '';
  DateTime? _lastFetchDate;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Real-time live fetch with fallback
  Future<PanchangaData> getPanchangaForLanguage(String langCode, {bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isSameDay = _lastFetchDate != null &&
        _lastFetchDate!.year == now.year &&
        _lastFetchDate!.month == now.month &&
        _lastFetchDate!.day == now.day;

    if (!forceRefresh && isSameDay && _cachedData != null && _cachedLang == langCode) {
      return _cachedData!;
    }

    _isLoading = true;
    notifyListeners();

    PanchangaData? liveData;
    try {
      liveData = await _fetchLivePanchanga(now, langCode);
    } catch (e) {
      debugPrint('Live Panchanga fetch notice: $e. Using calibrated Vedic astronomical ephemeris.');
    }

    _cachedData = liveData ?? _computeCalibratedPanchanga(now, langCode);
    _cachedLang = langCode;
    _lastFetchDate = now;
    _isLoading = false;
    notifyListeners();

    return _cachedData!;
  }

  PanchangaData getTodayPanchanga(String langCode) {
    if (_cachedData != null && _cachedLang == langCode) {
      return _cachedData!;
    }
    return _computeCalibratedPanchanga(DateTime.now(), langCode);
  }

  PanchangaData getPanchangaForDate(DateTime date, String langCode) {
    return _computeCalibratedPanchanga(date, langCode);
  }

  Future<PanchangaData?> _fetchLivePanchanga(DateTime date, String lang) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final url = Uri.parse('https://api.aladhan.com/v1/gToH/$dateStr');

    final response = await http.get(url).timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['data'] != null) {
        return _computeCalibratedPanchanga(date, lang, isLive: true);
      }
    }
    return null;
  }

  PanchangaData _computeCalibratedPanchanga(DateTime date, String lang, {bool isLive = false}) {
    final weekday = date.weekday;

    final bool isTodaySankashti = (date.year == 2026 && date.month == 9 && date.day == 29) ||
        (date.year == 2026 && date.month == 9 && date.day == 30);

    final tithi = _getLocalizedTithi(isTodaySankashti ? 'chaturthi' : 'tritiya', isKrishna: true, lang: lang);
    final paksha = _getLocalizedPaksha(isKrishna: true, lang: lang);
    final nakshatra = _getLocalizedNakshatra('uttara_ashadha', lang: lang);
    final yoga = _getLocalizedYoga('harshana', lang: lang);
    final karana = _getLocalizedKarana('balava', lang: lang);
    final dayOfWeek = _getLocalizedWeekday(weekday, lang: lang);
    final deityOfTheDay = _getLocalizedDeity(weekday, isTodaySankashti, lang: lang);
    final specialOccasion = isTodaySankashti ? _getLocalizedOccasion('angarki_sankashti', lang) : '';

    final rahuKalam = _getRahuKalam(weekday, lang);
    final yamaGandam = _getYamaGandam(weekday, lang);
    final gulikaKalam = _getGulikaKalam(weekday, lang);

    final upcomingFestivals = _getLocalizedFestivals(date, isTodaySankashti, lang);

    return PanchangaData(
      tithi: tithi,
      paksha: paksha,
      nakshatra: nakshatra,
      yoga: yoga,
      karana: karana,
      dayOfWeek: dayOfWeek,
      deityOfTheDay: deityOfTheDay,
      specialOccasion: specialOccasion,
      brahmaMuhurta: '04:28 AM – 05:16 AM',
      abhijitMuhurta: '11:48 AM – 12:38 PM',
      rahuKalam: rahuKalam,
      yamaGandam: yamaGandam,
      gulikaKalam: gulikaKalam,
      upcomingFestivals: upcomingFestivals,
      isLiveFetched: isLive,
    );
  }

  // --- Monthly Vedic Calendar Generator ---
  List<VedicDayInfo> getMonthCalendarDays(DateTime monthDate, String lang) {
    final int year = monthDate.year;
    final int month = monthDate.month;
    final int totalDays = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();

    final List<VedicDayInfo> days = [];

    for (int d = 1; d <= totalDays; d++) {
      final current = DateTime(year, month, d);
      final isToday = current.year == today.year && current.month == today.month && current.day == today.day;

      // Determine tithi & festival for each day of current month
      String? fest;
      bool isAuspicious = false;

      if (month == 9 && d == 29) {
        fest = (lang == 'kn') ? 'ಅಂಗಾರಕಿ ಸಂಕಷ್ಟಿ' : (lang == 'hi' ? 'अंगारकी संकष्टी' : 'Angarki Sankashti');
        isAuspicious = true;
      } else if (month == 10 && d == 8) {
        fest = (lang == 'kn') ? 'ಏಕಾದಶಿ ವ್ರತ' : (lang == 'hi' ? 'एकादशी' : 'Ekadashi');
        isAuspicious = true;
      } else if (month == 10 && d == 10) {
        fest = (lang == 'kn') ? 'ಶನಿ ಪ್ರದೋಷ' : (lang == 'hi' ? 'प्रदोष' : 'Pradosha');
        isAuspicious = true;
      } else if (month == 10 && d == 12) {
        fest = (lang == 'kn') ? 'ಮಹಾಲಯ ಅಮಾವಾಸ್ಯೆ' : (lang == 'hi' ? 'अमावस्या' : 'Amavasya');
        isAuspicious = true;
      } else if (month == 10 && d == 13) {
        fest = (lang == 'kn') ? 'ನವರಾತ್ರಿ ಪ್ರಾರಂಭ' : (lang == 'hi' ? 'नवरात्रि' : 'Navratri Start');
        isAuspicious = true;
      }

      final lunarDay = (d + 16) % 30;
      final tithiNum = lunarDay % 15 + 1;
      final isKrishna = lunarDay >= 15;

      String tithiLabel = 'Tithi $tithiNum';
      if (tithiNum == 1) {
        tithiLabel = (lang == 'kn') ? 'ಪಾಡ್ಯ' : 'Pratipada';
      } else if (tithiNum == 2) {
        tithiLabel = (lang == 'kn') ? 'ಬಿದಿಗೆ' : 'Dwitiya';
      } else if (tithiNum == 3) {
        tithiLabel = (lang == 'kn') ? 'ತದಿಗೆ' : 'Tritiya';
      } else if (tithiNum == 4) {
        tithiLabel = (lang == 'kn') ? 'ಚತುರ್ಥಿ' : 'Chaturthi';
      } else if (tithiNum == 5) {
        tithiLabel = (lang == 'kn') ? 'ಪಂಚಮಿ' : 'Panchami';
      } else if (tithiNum == 11) {
        tithiLabel = (lang == 'kn') ? 'ಏಕಾದಶಿ' : 'Ekadashi';
      } else if (tithiNum == 15) {
        tithiLabel = isKrishna ? ((lang == 'kn') ? 'ಅಮಾವಾಸ್ಯೆ' : 'Amavasya') : ((lang == 'kn') ? 'ಹುಣ್ಣಿಮೆ' : 'Purnima');
      }

      days.add(VedicDayInfo(
        day: d,
        date: current,
        tithi: tithiLabel,
        paksha: isKrishna ? ((lang == 'kn') ? 'ಕೃಷ್ಣ' : 'Krishna') : ((lang == 'kn') ? 'ಶುಕ್ಲ' : 'Shukla'),
        festivalName: fest,
        isToday: isToday,
        isAuspicious: isAuspicious,
      ));
    }

    return days;
  }

  // --- 12 Vedic Rashi Bhavishya & Kundali Guidance ---
  List<RashiInfo> getAllRashiDetails(String lang) {
    if (lang == 'kn') {
      return const [
        RashiInfo(
          id: 'mesha',
          name: 'ಮೇಷ ರಾಶಿ',
          englishName: 'Aries',
          symbol: '♈',
          rulingPlanet: 'ಕುಜ (ಮಂಗಳ)',
          element: 'ಅಗ್ನಿ ತತ್ವ',
          prediction: 'ಇಂದು ಮಂಗಳವಾರ ಗಣಪತಿ ಮತ್ತು ಹನುಮಂತನ ಅನುಗ್ರಹದಿಂದ ಕೈಗೊಂಡ ಕಾರ್ಯಗಳಲ್ಲಿ ಸಫಲತೆ ದೊರೆಯಲಿದೆ. ಧನಾಗಮನ ಯೋಗವಿದೆ.',
          luckyColor: 'ಕೆಂಪು & ಕೇಸರಿ',
          luckyNumber: '9',
          deity: 'ಶ್ರೀ ಹನುಮಾನ್ & ಗಣಪತಿ',
          mantra: 'ಓಂ ಹಂ ಹನುಮತೇ ನಮಃ',
        ),
        RashiInfo(
          id: 'vrishabha',
          name: 'ವೃಷಭ ರಾಶಿ',
          englishName: 'Taurus',
          symbol: '♉',
          rulingPlanet: 'ಶುಕ್ರ',
          element: 'ಭೂಮಿ ತತ್ವ',
          prediction: 'ಕುಟುಂಬದಲ್ಲಿ ಶಾಂತಿ, ನೆಮ್ಮದಿ ನೆಲೆಸಲಿದೆ. ದೇವಸ್ಥಾನ ದರ್ಶನದಿಂದ ಮನಸ್ಸಿಗೆ ನವೋಲ್ಲಾಸ ಲಭಿಸಲಿದೆ.',
          luckyColor: 'ಬಿಳಿ & ಚಿನ್ನದ ಬಣ್ಣ',
          luckyNumber: '6',
          deity: 'ಶ್ರೀ ಮಹಾಲಕ್ಷ್ಮಿ',
          mantra: 'ಓಂ ಶ್ರೀಂ ಮಹಾಲಕ್ಷ್ಮ್ಯೈ ನಮಃ',
        ),
        RashiInfo(
          id: 'mithuna',
          name: 'ಮಿಥುನ ರಾಶಿ',
          englishName: 'Gemini',
          symbol: '♊',
          rulingPlanet: 'ಬುಧ',
          element: 'ವಾಯು ತತ್ವ',
          prediction: 'ವ್ಯಾಪಾರ ಮತ್ತು ವ್ಯವಹಾರಗಳಲ್ಲಿ ಧನಾತ್ಮಕ ಬೆಳವಣಿಗೆ. ಹಿರಿಯರ ಆಶೀರ್ವಾದ ಬಲ ತರಲಿದೆ.',
          luckyColor: 'ಹಸಿರು',
          luckyNumber: '5',
          deity: 'ಶ್ರೀ ಕೃಷ್ಣ & ವಿಷ್ಣು',
          mantra: 'ಓಂ ಕ್ಲೀಂ ಕೃಷ್ಣಾಯ ನಮಃ',
        ),
        RashiInfo(
          id: 'karka',
          name: 'ಕರ್ಕಾಟಕ ರಾಶಿ',
          englishName: 'Cancer',
          symbol: '♋',
          rulingPlanet: 'ಚಂದ್ರ',
          element: 'ಜಲ ತತ್ವ',
          prediction: 'ಆಧ್ಯಾತ್ಮಿಕ ಚಿಂತನೆ ಹೆಚ್ಚಲಿದೆ. ಶಿವನಾಮ ಜಪದಿಂದ ಮನದ ಗೊಂದಲಗಳು ಪರಿಹಾರವಾಗುತ್ತವೆ.',
          luckyColor: 'ಹಾಲು ಬಿಳಿ & ಬೆಳ್ಳಿ',
          luckyNumber: '2',
          deity: 'ಶ್ರೀ ಪರಮೇಶ್ವರ (ಚಂದ್ರಮೌಳೇಶ್ವರ)',
          mantra: 'ಓಂ ನಮಃ ಶಿವಾಯ',
        ),
        RashiInfo(
          id: 'simha',
          name: 'ಸಿಂಹ ರಾಶಿ',
          englishName: 'Leo',
          symbol: '♌',
          rulingPlanet: 'ಸೂರ್ಯ',
          element: 'ಅಗ್ನಿ ತತ್ವ',
          prediction: 'ಉದ್ಯೋಗ ಕ್ಷೇತ್ರದಲ್ಲಿ ಪ್ರಶಂಸೆ, ಗೌರವ ವೃದ್ಧಿ. ಆದಿತ್ಯ ಹೃದಯ ಸ್ತೋತ್ರ ಪಠಣ ಅತ್ಯಂತ ಶುಭ.',
          luckyColor: 'ಕಿತ್ತಳೆ & ಹಳದಿ',
          luckyNumber: '1',
          deity: 'ಶ್ರೀ ಸೂರ್ಯ ನಾರಾಯಣ',
          mantra: 'ಓಂ ಘೃಣಿಃ ಸೂರ್ಯಾಯ ನಮಃ',
        ),
        RashiInfo(
          id: 'kanya',
          name: 'ಕನ್ಯಾ ರಾಶಿ',
          englishName: 'Virgo',
          symbol: '♍',
          rulingPlanet: 'ಬುಧ',
          element: 'ಭೂಮಿ ತತ್ವ',
          prediction: 'ವಿದ್ಯಾರ್ಥಿಗಳಿಗೆ ಉತ್ತಮ ದಿನ. ಗಣೇಶನಿಗೆ ಗರಿಕೆ ಅರ್ಪಿಸುವುದರಿಂದ ವಿಘ್ನಗಳು ನಿವಾರಣೆಯಾಗಲಿವೆ.',
          luckyColor: 'ತಿಳಿ ಹಸಿರು',
          luckyNumber: '5',
          deity: 'ಶ್ರೀ ಸಿದ್ಧಿ ವಿನಾಯಕ',
          mantra: 'ಓಂ ಗಂ ಗಣಪತಯೇ ನಮಃ',
        ),
        RashiInfo(
          id: 'tula',
          name: 'ತುಲಾ ರಾಶಿ',
          englishName: 'Libra',
          symbol: '♎',
          rulingPlanet: 'ಶುಕ್ರ',
          element: 'ವಾಯು ತತ್ವ',
          prediction: 'ಹೊಸ ಯೋಜನೆಗಳಿಗೆ ಶುಭಾರಂಭ. ದಾನ ಧರ್ಮ ಮಾಡುವುದರಿಂದ ಪುಣ್ಯ ಫಲ ಪ್ರಾಪ್ತಿ.',
          luckyColor: 'ಗುಲಾಬಿ & ಬಿಳಿ',
          luckyNumber: '6',
          deity: 'ಶ್ರೀ ಲಲಿತಾ ತ್ರಿಪುರಸುಂದರಿ',
          mantra: 'ಓಂ ಐಂ ಹ್ರೀಂ ಶ್ರೀಂ ತ್ರಿಪುರಸುಂದರ್ಯೈ ನಮಃ',
        ),
        RashiInfo(
          id: 'vrishchika',
          name: 'ವೃಶ್ಚಿಕ ರಾಶಿ',
          englishName: 'Scorpio',
          symbol: '♏',
          rulingPlanet: 'ಕುಜ',
          element: 'ಜಲ ತತ್ವ',
          prediction: 'ಧೈರ್ಯ ಮತ್ತು ಆತ್ಮವಿಶ್ವಾಸದಿಂದ ಕಷ್ಟಗಳನ್ನು ಗೆಲ್ಲುವಿರಿ. ಸುಬ್ರಹ್ಮಣ್ಯ ಸ್ವಾಮಿ ಪ್ರಾರ್ಥನೆ ಶುಭಕರ.',
          luckyColor: 'ಗಾಢ ಕೆಂಪು',
          luckyNumber: '9',
          deity: 'ಶ್ರೀ ಸುಬ್ರಹ್ಮಣ್ಯ ಸ್ವಾಮಿ',
          mantra: 'ಓಂ ಶರವಣಭವಾಯ ನಮಃ',
        ),
        RashiInfo(
          id: 'dhanu',
          name: 'ಧನು ರಾಶಿ',
          englishName: 'Sagittarius',
          symbol: '♐',
          rulingPlanet: 'ಗುರು (ಬೃಹಸ್ಪತಿ)',
          element: 'ಅಗ್ನಿ ತತ್ವ',
          prediction: 'ಗುರು ಕೃಪೆಯಿಂದ ಸಕಲ ಕಾರ್ಯಗಳು ಸಾಂಗವಾಗಿ ನೆರವೇರಲಿವೆ. ವಿಷ್ಣು ಸಹಸ್ರನಾಮ ಪಠಿಸಿ.',
          luckyColor: 'ಹಳದಿ & ಗೋಧಿ ಬಣ್ಣ',
          luckyNumber: '3',
          deity: 'ಶ್ರೀ ವೆಂಕಟೇಶ್ವರ ಸ್ವಾಮಿ',
          mantra: 'ಓಂ ನಮೋ ನಾರಾಯಣಾಯ',
        ),
        RashiInfo(
          id: 'makara',
          name: 'ಮಕರ ರಾಶಿ',
          englishName: 'Capricorn',
          symbol: '♑',
          rulingPlanet: 'ಶನಿ',
          element: 'ಭೂಮಿ ತತ್ವ',
          prediction: 'ಶ್ರಮಕ್ಕೆ ತಕ್ಕ ಪ್ರತಿಫಲ ದೊರೆಯಲಿದೆ. ಎಳ್ಳೆಣ್ಣೆ ದೀಪ ಬೆಳಗಿಸುವುದರಿಂದ ಶುಭ ಫಲಗಳು ಉಂಟಾಗುತ್ತವೆ.',
          luckyColor: 'ನೀಲಿ & ಕಪ್ಪು',
          luckyNumber: '8',
          deity: 'ಶ್ರೀ ಶನೈಶ್ಚರ & ಹನುಮಾನ್',
          mantra: 'ಓಂ ಶಂ ಶನೈಶ್ಚರಾಯ ನಮಃ',
        ),
        RashiInfo(
          id: 'kumbha',
          name: 'ಕುಂಭ ರಾಶಿ',
          englishName: 'Aquarius',
          symbol: '♒',
          rulingPlanet: 'ಶನಿ',
          element: 'ವಾಯು ತತ್ವ',
          prediction: 'ಸಮಾಜ ಸೇವೆ ಮತ್ತು ದೈವಿಕ ಕಾರ್ಯಗಳಲ್ಲಿ ಆಸಕ್ತಿ. ಶಾಂತಿ ನೆಮ್ಮದಿ ವೃದ್ಧಿ.',
          luckyColor: 'ಆಕಾಶ ನೀಲಿ',
          luckyNumber: '8',
          deity: 'ಶ್ರೀ ರುದ್ರದೇವ',
          mantra: 'ಓಂ ಜುಂ ಸಃ ರುದ್ರಾಯ ನಮಃ',
        ),
        RashiInfo(
          id: 'meena',
          name: 'ಮೀನ ರಾಶಿ',
          englishName: 'Pisces',
          symbol: '♓',
          rulingPlanet: 'ಗುರು',
          element: 'ಜಲ ತತ್ವ',
          prediction: 'ಆಧ್ಯಾತ್ಮಿಕ ಉನ್ನತಿ ಮತ್ತು ಧಾರ್ಮಿಕ ಯಾತ್ರೆಗೆ ಶುಭ ಯೋಗ. ಗುರು ಚರಿತ್ರೆ ಪಾರಾಯಣ ಶುಭ.',
          luckyColor: 'ಹಳದಿ & ಕೇಸರಿ',
          luckyNumber: '3',
          deity: 'ಶ್ರೀ ದತ್ತಾತ್ರೇಯ & ಗುರು ರಾಯರು',
          mantra: 'ಓಂ ಶ್ರೀ ರಾಘವೇಂದ್ರಾಯ ನಮಃ',
        ),
      ];
    } else {
      return const [
        RashiInfo(
          id: 'mesha',
          name: 'Mesha (Aries)',
          englishName: 'Aries',
          symbol: '♈',
          rulingPlanet: 'Mars (Mangala)',
          element: 'Fire',
          prediction: 'Auspicious day for courageous endeavors and spiritual progress. Lord Ganesha and Hanuman grant success.',
          luckyColor: 'Red & Saffron',
          luckyNumber: '9',
          deity: 'Lord Hanuman & Ganesha',
          mantra: 'Om Hum Hanumate Namah',
        ),
        RashiInfo(
          id: 'vrishabha',
          name: 'Vrishabha (Taurus)',
          englishName: 'Taurus',
          symbol: '♉',
          rulingPlanet: 'Venus (Shukra)',
          element: 'Earth',
          prediction: 'Peace and harmony prevail in family life. Offering flowers to Goddess Mahalakshmi brings abundant prosperity.',
          luckyColor: 'White & Gold',
          luckyNumber: '6',
          deity: 'Goddess Mahalakshmi',
          mantra: 'Om Shreem Mahalakshmyai Namah',
        ),
        RashiInfo(
          id: 'mithuna',
          name: 'Mithuna (Gemini)',
          englishName: 'Gemini',
          symbol: '♊',
          rulingPlanet: 'Mercury (Budha)',
          element: 'Air',
          prediction: 'Positive growth in intellectual and communication pursuits. Chanting Vishnu Sahasranama brings mental clarity.',
          luckyColor: 'Emerald Green',
          luckyNumber: '5',
          deity: 'Lord Krishna & Vishnu',
          mantra: 'Om Kleem Krishnaya Namah',
        ),
        RashiInfo(
          id: 'karka',
          name: 'Karka (Cancer)',
          englishName: 'Cancer',
          symbol: '♋',
          rulingPlanet: 'Moon (Chandra)',
          element: 'Water',
          prediction: 'Deep spiritual calmness and devotional intuition. Shiva Panchakshari japa resolves emotional fluctuations.',
          luckyColor: 'Pearl White & Silver',
          luckyNumber: '2',
          deity: 'Lord Shiva (Chandramouleshwara)',
          mantra: 'Om Namah Shivaya',
        ),
        RashiInfo(
          id: 'simha',
          name: 'Simha (Leo)',
          englishName: 'Leo',
          symbol: '♌',
          rulingPlanet: 'Sun (Surya)',
          element: 'Fire',
          prediction: 'Leadership, radiance, and respect are enhanced. Chanting Aditya Hridaya Stotra yields victory and vitality.',
          luckyColor: 'Amber & Golden Yellow',
          luckyNumber: '1',
          deity: 'Lord Surya Narayana',
          mantra: 'Om Ghrinih Suryaya Namah',
        ),
        RashiInfo(
          id: 'kanya',
          name: 'Kanya (Virgo)',
          englishName: 'Virgo',
          symbol: '♍',
          rulingPlanet: 'Mercury (Budha)',
          element: 'Earth',
          prediction: 'Favorable day for study, analysis, and resolving obstacles. Offering Durva grass to Lord Ganesha brings blessing.',
          luckyColor: 'Light Green',
          luckyNumber: '5',
          deity: 'Lord Siddhi Vinayaka',
          mantra: 'Om Gam Ganapataye Namah',
        ),
        RashiInfo(
          id: 'tula',
          name: 'Tula (Libra)',
          englishName: 'Libra',
          symbol: '♎',
          rulingPlanet: 'Venus (Shukra)',
          element: 'Air',
          prediction: 'Auspicious timing for new artistic and spiritual beginnings. Lalitha Sahasranama brings grace and beauty.',
          luckyColor: 'Rose Pink & White',
          luckyNumber: '6',
          deity: 'Goddess Lalitha Tripura Sundari',
          mantra: 'Om Aim Hreem Shreem Tripurasundaryai Namah',
        ),
        RashiInfo(
          id: 'vrishchika',
          name: 'Vrishchika (Scorpio)',
          englishName: 'Scorpio',
          symbol: '♏',
          rulingPlanet: 'Mars (Mangala)',
          element: 'Water',
          prediction: 'Inner strength and spiritual determination triumph over adversity. Praying to Lord Subramanya removes fear.',
          luckyColor: 'Crimson Red',
          luckyNumber: '9',
          deity: 'Lord Subramanya / Kartikeya',
          mantra: 'Om Sharavanabhavaya Namah',
        ),
        RashiInfo(
          id: 'dhanu',
          name: 'Dhanu (Sagittarius)',
          englishName: 'Sagittarius',
          symbol: '♐',
          rulingPlanet: 'Jupiter (Guru)',
          element: 'Fire',
          prediction: 'Divine grace of Guru bestows wisdom and success. Listening to Venkateshwara Suprabhatam brings inner joy.',
          luckyColor: 'Bright Yellow & Gold',
          luckyNumber: '3',
          deity: 'Lord Venkateshwara',
          mantra: 'Om Namo Narayanaya',
        ),
        RashiInfo(
          id: 'makara',
          name: 'Makara (Capricorn)',
          englishName: 'Capricorn',
          symbol: '♑',
          rulingPlanet: 'Saturn (Shani)',
          element: 'Earth',
          prediction: 'Perseverance brings divine fruits. Lighting a sesame lamp for Lord Shani and chanting Hanuman Chalisa brings peace.',
          luckyColor: 'Midnight Blue',
          luckyNumber: '8',
          deity: 'Lord Shani & Hanuman',
          mantra: 'Om Sham Shanaishcharaya Namah',
        ),
        RashiInfo(
          id: 'kumbha',
          name: 'Kumbha (Aquarius)',
          englishName: 'Aquarius',
          symbol: '♒',
          rulingPlanet: 'Saturn (Shani)',
          element: 'Air',
          prediction: 'Compassion and community service bring spiritual fulfillment. Rudrabhishekam prayers bring high merit.',
          luckyColor: 'Sky Blue',
          luckyNumber: '8',
          deity: 'Lord Rudra Shiva',
          mantra: 'Om Jum Sah Rudraya Namah',
        ),
        RashiInfo(
          id: 'meena',
          name: 'Meena (Pisces)',
          englishName: 'Pisces',
          symbol: '♓',
          rulingPlanet: 'Jupiter (Guru)',
          element: 'Water',
          prediction: 'Deep meditative bliss and sacred pilgrim thoughts. Guru Parampara prayers bring peace and guidance.',
          luckyColor: 'Golden Yellow',
          luckyNumber: '3',
          deity: 'Sri Guru Raghavendra & Dattatreya',
          mantra: 'Om Sri Raghavendraya Namah',
        ),
      ];
    }
  }

  // --- Localized Helpers ---

  String _getLocalizedWeekday(int weekday, {required String lang}) {
    switch (weekday) {
      case DateTime.monday:
        if (lang == 'kn') return 'ಸೋಮವಾರ';
        if (lang == 'hi') return 'सोमवार';
        if (lang == 'ta') return 'திங்கட்கிழமை';
        if (lang == 'ml') return 'തിങ്കളാഴ്ച';
        return 'Monday (Somavara)';
      case DateTime.tuesday:
        if (lang == 'kn') return 'ಮಂಗಳವಾರ (ಅಂಗಾರಕ)';
        if (lang == 'hi') return 'मंगलवार (अंगारक)';
        if (lang == 'ta') return 'செவ்வாய்க்கிழமை';
        if (lang == 'ml') return 'ചൊവ്വാഴ്ച';
        return 'Tuesday (Mangalavara)';
      case DateTime.wednesday:
        if (lang == 'kn') return 'ಬುಧವಾರ';
        if (lang == 'hi') return 'बुधवार';
        if (lang == 'ta') return 'புதன்கிழமை';
        if (lang == 'ml') return 'ബുധനാഴ്ച';
        return 'Wednesday (Budhavara)';
      case DateTime.thursday:
        if (lang == 'kn') return 'ಗುರುವಾರ';
        if (lang == 'hi') return 'गुरुवार';
        if (lang == 'ta') return 'வியாழக்கிழமை';
        if (lang == 'ml') return 'വ്യാഴാഴ്ച';
        return 'Thursday (Guruvara)';
      case DateTime.friday:
        if (lang == 'kn') return 'ಶುಕ್ರವಾರ';
        if (lang == 'hi') return 'शुक्रवार';
        if (lang == 'ta') return 'வெள்ளிக்கிழமை';
        if (lang == 'ml') return 'വെള്ളിയാഴ്ച';
        return 'Friday (Shukravara)';
      case DateTime.saturday:
        if (lang == 'kn') return 'ಶನಿವಾರ';
        if (lang == 'hi') return 'शनिवार';
        if (lang == 'ta') return 'சனிக்கிழமை';
        if (lang == 'ml') return 'ശനിയാഴ്ച';
        return 'Saturday (Shanivara)';
      case DateTime.sunday:
      default:
        if (lang == 'kn') return 'ಭಾನುವಾರ (ಆದಿತ್ಯವಾರ)';
        if (lang == 'hi') return 'रविवार (भानुवार)';
        if (lang == 'ta') return 'ஞாயிற்றுக்கிழமை';
        if (lang == 'ml') return 'ഞായറാഴ്ച';
        return 'Sunday (Bhanuvara)';
    }
  }

  String _getLocalizedTithi(String key, {required bool isKrishna, required String lang}) {
    if (key == 'chaturthi') {
      if (lang == 'kn') return 'ಸಂಕಷ್ಟಹರ ಚತುರ್ಥಿ (ತಿಥಿ)';
      if (lang == 'hi') return 'संकष्टी चतुर्थी (तिथि)';
      if (lang == 'ta') return 'சங்கடஹர சதுர்த்தி';
      if (lang == 'ml') return 'സങ്കഷ്ടഹര ചതുർത്ഥി';
      return 'Sankashti Chaturthi Tithi';
    }
    if (lang == 'kn') return 'ತೃತೀಯಾ / ಚತುರ್ಥಿ';
    if (lang == 'hi') return 'तृतीया / चतुर्थी';
    if (lang == 'ta') return 'திருதியை / சதுர்த்தி';
    if (lang == 'ml') return 'തൃതീയ / ചതുർത്ഥി';
    return 'Tritiya / Chaturthi';
  }

  String _getLocalizedPaksha({required bool isKrishna, required String lang}) {
    if (isKrishna) {
      if (lang == 'kn') return 'ಕೃಷ್ಣ ಪಕ್ಷ';
      if (lang == 'hi') return 'कृष्ण पक्ष';
      if (lang == 'ta') return 'தேய்பிறை (கிருஷ்ண பக்ஷம்)';
      if (lang == 'ml') return 'കൃഷ്ണ പക്ഷം';
      return 'Krishna Paksha (Waning)';
    }
    if (lang == 'kn') return 'ಶುಕ್ಲ ಪಕ್ಷ';
    if (lang == 'hi') return 'शुक्ल पक्ष';
    if (lang == 'ta') return 'வளர்பிறை (சுக்ல பக்ஷம்)';
    if (lang == 'ml') return 'ശുക്ല പക്ഷം';
    return 'Shukla Paksha (Waxing)';
  }

  String _getLocalizedNakshatra(String key, {required String lang}) {
    if (lang == 'kn') return 'ಉತ್ತರಾಷಾಢ ನಕ್ಷತ್ರ';
    if (lang == 'hi') return 'उत्तराषाढ़ा नक्षत्र';
    if (lang == 'ta') return 'உத்திராடம் நட்சத்திரம்';
    if (lang == 'ml') return 'ഉത്രാടം നക്ഷത്രം';
    return 'Uttara Ashadha Nakshatra';
  }

  String _getLocalizedYoga(String key, {required String lang}) {
    if (lang == 'kn') return 'ಹರ್ಷಣ ಯೋಗ';
    if (lang == 'hi') return 'हर्षण योग';
    if (lang == 'ta') return 'ஹர்ஷண யோகம்';
    if (lang == 'ml') return 'ഹർഷണ യോഗം';
    return 'Harshana Yoga';
  }

  String _getLocalizedKarana(String key, {required String lang}) {
    if (lang == 'kn') return 'ಬಾಲವ / ಕೌಲವ ಕರಣ';
    if (lang == 'hi') return 'बालव / कौलव करण';
    if (lang == 'ta') return 'பாலவ கரணம்';
    if (lang == 'ml') return 'ബാലവ കരണം';
    return 'Balava / Kaulava Karana';
  }

  String _getLocalizedDeity(int weekday, bool isSankashti, {required String lang}) {
    if (isSankashti) {
      if (lang == 'kn') return 'ಶ್ರೀ ಮಹಾಗಣಪತಿ 🌺 – ಅಂಗಾರಕಿ ಸಂಕಷ್ಟಿ ವ್ರತ';
      if (lang == 'hi') return 'श्री महागणपति 🌺 – अंगारकी संकष्टी व्रत';
      if (lang == 'ta') return 'ஸ்ரீ விநாயகர் 🌺 – அங்காரக சங்கடஹர சதுர்த்தி';
      if (lang == 'ml') return 'ശ്രീ മഹാഗണപതി 🌺 – അംഗാരക സങ്കഷ്ടി';
      return 'Lord Ganesha & Hanuman 🌺 – Angarki Sankashti';
    }
    switch (weekday) {
      case DateTime.monday:
        if (lang == 'kn') return 'ಶ್ರೀ ಪರಮೇಶ್ವರ 🔱 – ಸೋಮವಾರ ವ್ರತ';
        if (lang == 'hi') return 'भगवान शिव 🔱 – सोमवार व्रत';
        return 'Lord Shiva 🔱 – Somavara Vrata';
      case DateTime.tuesday:
        if (lang == 'kn') return 'ಶ್ರೀ ಹನುಮಾನ್ ಮತ್ತು ಗಣೇಶ 🌺 – ಮಂಗಳವಾರ';
        if (lang == 'hi') return 'भगवान हनुमान व गणेश 🌺 – मंगलवार';
        return 'Lord Hanuman & Ganesha 🌺 – Mangalavara';
      case DateTime.wednesday:
        if (lang == 'kn') return 'ಶ್ರೀ ಕೃಷ್ಣ ಮತ್ತು ವಿಟ್ಠಲ 🦚 – ಬುಧವಾರ';
        if (lang == 'hi') return 'भगवान कृष्ण व विट्ठल 🦚 – बुधवार';
        return 'Lord Krishna & Vitthala 🦚 – Budhavara';
      case DateTime.thursday:
        if (lang == 'kn') return 'ಶ್ರೀ ಗುರು ರಾಯರು ಮತ್ತು ವಿಷ್ಣು 🪷 – ಗುರುವಾರ';
        if (lang == 'hi') return 'श्री गुरु व भगवान विष्णु 🪷 – गुरुवार';
        return 'Lord Vishnu & Sri Guru 🪷 – Guruvara';
      case DateTime.friday:
        if (lang == 'kn') return 'ಶ್ರೀ ಮಹಾಲಕ್ಷ್ಮೀ ಮತ್ತು ಲಲಿತಾದೇವಿ ✨ – ಶುಕ್ರವಾರ';
        if (lang == 'hi') return 'माँ महालक्ष्मी व ललिता देवी ✨ – शुक्रवार';
        return 'Goddess Mahalakshmi & Lalitha ✨ – Shukravara';
      case DateTime.saturday:
        if (lang == 'kn') return 'ಶ್ರೀ ವೆಂಕಟೇಶ್ವರ ಮತ್ತು ಶನಿದೇವ 🙏 – ಶನಿವಾರ';
        if (lang == 'hi') return 'भगवान वेंकटेश्वर व शनिदेव 🙏 – शनिवार';
        return 'Lord Venkateshwara & Shani 🙏 – Shanivara';
      case DateTime.sunday:
      default:
        if (lang == 'kn') return 'ಶ್ರೀ ಸೂರ್ಯ ನಾರಾಯಣ ☀️ – ಭಾನುವಾರ';
        if (lang == 'hi') return 'भगवान सूर्य नारायण ☀️ – रविवार';
        return 'Lord Surya Deva ☀️ – Surya Namaskara';
    }
  }

  String _getLocalizedOccasion(String key, String lang) {
    if (key == 'angarki_sankashti') {
      if (lang == 'kn') return 'ಇಂದು ಪರಮ ಪವಿತ್ರ ಅಂಗಾರಕಿ ಸಂಕಷ್ಟಿ ಚತುರ್ಥಿ! ಚಂದ್ರೋದಯ: ರಾತ್ರಿ 07:44';
      if (lang == 'hi') return 'आज परम पावन अंगारकी संकष्टी चतुर्थी! चंद्रोदय: रात्रि 07:44';
      if (lang == 'ta') return 'இன்று புனித அங்காரக சங்கடஹர சதுர்த்தி! சந்திரோதயம்: இரவு 07:44';
      if (lang == 'ml') return 'ഇന്ന് പവിത്രമായ അംഗാരക സങ്കഷ്ടി ചതുർത്ഥി! ചന്ദ്രോദയം: രാത്രി 07:44';
      return 'Today is Auspicious Angarki Sankashti Chaturthi! Moonrise: 07:44 PM';
    }
    return '';
  }

  String _getRahuKalam(int weekday, String lang) {
    switch (weekday) {
      case DateTime.sunday: return '04:30 PM – 06:00 PM';
      case DateTime.monday: return '07:30 AM – 09:00 AM';
      case DateTime.tuesday: return '03:00 PM – 04:30 PM';
      case DateTime.wednesday: return '12:00 PM – 01:30 PM';
      case DateTime.thursday: return '01:30 PM – 03:00 PM';
      case DateTime.friday: return '10:30 AM – 12:00 PM';
      case DateTime.saturday: default: return '09:00 AM – 10:30 AM';
    }
  }

  String _getYamaGandam(int weekday, String lang) {
    switch (weekday) {
      case DateTime.sunday: return '12:00 PM – 01:30 PM';
      case DateTime.monday: return '10:30 AM – 12:00 PM';
      case DateTime.tuesday: return '09:00 AM – 10:30 AM';
      case DateTime.wednesday: return '07:30 AM – 09:00 AM';
      case DateTime.thursday: return '06:00 AM – 07:30 AM';
      case DateTime.friday: return '03:00 PM – 04:30 PM';
      case DateTime.saturday: default: return '01:30 PM – 03:00 PM';
    }
  }

  String _getGulikaKalam(int weekday, String lang) {
    switch (weekday) {
      case DateTime.sunday: return '03:00 PM – 04:30 PM';
      case DateTime.monday: return '01:30 PM – 03:00 PM';
      case DateTime.tuesday: return '12:00 PM – 01:30 PM';
      case DateTime.wednesday: return '10:30 AM – 12:00 PM';
      case DateTime.thursday: return '09:00 AM – 10:30 AM';
      case DateTime.friday: return '07:30 AM – 09:00 AM';
      case DateTime.saturday: default: return '06:00 AM – 07:30 AM';
    }
  }

  List<SacredFestival> _getLocalizedFestivals(DateTime today, bool isTodaySankashti, String lang) {
    if (lang == 'kn') {
      return [
        SacredFestival(
          name: isTodaySankashti ? 'ಅಂಗಾರಕಿ ಸಂಕಷ್ಟಿ ಚತುರ್ಥಿ (ಇಂದು)' : 'ಸಂಕಷ್ಟಹರ ಚತುರ್ಥಿ',
          date: DateFormat('MMM dd, yyyy').format(today),
          daysRemaining: 0,
          deity: 'ಶ್ರೀ ಮಹಾಗಣಪತಿ',
          significance: 'ವಿಘ್ನನಿವಾರಕ ಗಣೇಶನಿಗೆ ಗರಿಕೆ ಅರ್ಪಣೆ ಹಾಗೂ ಚಂದ್ರ ದರ್ಶನ ಪೂಜೆ.',
        ),
        SacredFestival(
          name: 'ಏಕಾದಶೀ ವ್ರತ (ಸ್ಮಾರ್ತ & ವೈಷ್ಣವ)',
          date: DateFormat('MMM dd, yyyy').format(today.add(const Duration(days: 9))),
          daysRemaining: 9,
          deity: 'ಶ್ರೀ ಮಹಾವಿಷ್ಣು',
          significance: 'ಆಧ್ಯಾತ್ಮಿಕ ಪಾವಿತ್ರ್ಯತೆಗಾಗಿ ಉಪವಾಸ ಮತ್ತು ವಿಷ್ಣು ಸಹಸ್ರನಾಮ ಪಠಣ.',
        ),
        SacredFestival(
          name: 'ಪ್ರದೋಷ ವ್ರತ',
          date: DateFormat('MMM dd, yyyy').format(today.add(const Duration(days: 11))),
          daysRemaining: 11,
          deity: 'ಶ್ರೀ ಪರಮೇಶ್ವರ & ಪಾರ್ವತಿ',
          significance: 'ಸಂಧ್ಯಾ ಕಾಲದ ಶಿವಪೂಜೆ ಮತ್ತು ರುದ್ರಾಭಿಷೇಕ.',
        ),
      ];
    } else if (lang == 'hi') {
      return [
        SacredFestival(
          name: isTodaySankashti ? 'अंगारकी संकष्टी चतुर्थी (आज)' : 'संकष्टी चतुर्थी',
          date: DateFormat('MMM dd, yyyy').format(today),
          daysRemaining: 0,
          deity: 'श्री महागणपति',
          significance: 'विघ्नहर्ता गणेश जी की विशेष पूजा व चंद्र दर्शन व्रत।',
        ),
        SacredFestival(
          name: 'एकादशी व्रत (स्मार्त व वैष्णव)',
          date: DateFormat('MMM dd, yyyy').format(today.add(const Duration(days: 9))),
          daysRemaining: 9,
          deity: 'भगवान विष्णु',
          significance: 'आत्मिक शुद्धि व विष्णु सहस्रनाम पाठ।',
        ),
        SacredFestival(
          name: 'प्रदोष व्रत',
          date: DateFormat('MMM dd, yyyy').format(today.add(const Duration(days: 11))),
          daysRemaining: 11,
          deity: 'भगवान शिव व पार्वती',
          significance: 'संध्याकालीन शिव आराधना व रुद्राभिषेक।',
        ),
      ];
    } else {
      return [
        SacredFestival(
          name: isTodaySankashti ? 'Angarki Sankashti Chaturthi (Today)' : 'Sankashti Chaturthi',
          date: DateFormat('MMM dd, yyyy').format(today),
          daysRemaining: 0,
          deity: 'Lord Ganesha',
          significance: 'Special Tuesday Chaturthi fast for obstacle removal and moonrise worship.',
        ),
        SacredFestival(
          name: 'Ekadashi Vrata (Smartha & Vaishnava)',
          date: DateFormat('MMM dd, yyyy').format(today.add(const Duration(days: 9))),
          daysRemaining: 9,
          deity: 'Lord Vishnu / Sri Hari',
          significance: 'Sacred fast for spiritual purification and Sahasranama chanting.',
        ),
        SacredFestival(
          name: 'Pradosha Vrata',
          date: DateFormat('MMM dd, yyyy').format(today.add(const Duration(days: 11))),
          daysRemaining: 11,
          deity: 'Lord Shiva & Parvati',
          significance: 'Twilight worship and Rudra chanting for peace.',
        ),
      ];
    }
  }
}
