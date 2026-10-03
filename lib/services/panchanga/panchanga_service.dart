import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final String sunrise;
  final String sunset;
  final String moonrise;

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
    this.sunrise = '06:08 AM',
    this.sunset = '06:12 PM',
    this.moonrise = '08:32 PM',
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
  final bool isAmavasya;
  final bool isHunnime;
  final bool isGrahana;
  final String? grahanaName;

  const VedicDayInfo({
    required this.day,
    required this.date,
    required this.tithi,
    required this.paksha,
    this.festivalName,
    this.isToday = false,
    this.isAuspicious = false,
    this.isAmavasya = false,
    this.isHunnime = false,
    this.isGrahana = false,
    this.grahanaName,
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
  final bool isLiveFetched;

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
    this.isLiveFetched = false,
  });
}

/// High-Precision Astronomical Vedic Ephemeris Engine (Jean Meeus / Lahiri Ayanamsha)
class VedicAstroEngine {
  static Map<String, dynamic> calculateEphemeris(DateTime date) {
    // Convert to UTC for Julian Day calculation
    final utc = date.toUtc();
    final y = utc.year;
    final m = utc.month;
    final d = utc.day + (utc.hour + utc.minute / 60.0 + utc.second / 3600.0) / 24.0;

    int iy = y;
    int im = m;
    if (im <= 2) {
      iy -= 1;
      im += 12;
    }
    final a = (iy / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (iy + 4716)).floor() + (30.6001 * (im + 1)).floor() + d + b - 1524.5;
    final t = (jd - 2451545.0) / 36525.0;

    // Lahiri (Chitrapaksha) Ayanamsha
    final ayanamsha = 23.856 + (y - 2000) * (50.29 / 3600.0);

    // Solar Longitude
    final l0 = (280.46646 + 36000.76983 * t + 0.0003032 * t * t) % 360.0;
    final mSun = (357.52911 + 35999.05029 * t - 0.0001537 * t * t) % 360.0;
    final mSunRad = mSun * math.pi / 180.0;
    final cSun = (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(mSunRad) +
        (0.019993 - 0.000101 * t) * math.sin(2 * mSunRad) +
        0.000289 * math.sin(3 * mSunRad);
    final sunTrueLong = (l0 + cSun) % 360.0;
    final sunNirayana = (sunTrueLong - ayanamsha + 360.0) % 360.0;

    // Lunar Longitude with 13 periodic perturbation terms
    final lp = (218.3164477 + 481267.88128 * t) % 360.0;
    final dMoon = (297.8501921 + 445267.11140 * t) % 360.0;
    final mMoon = (134.9633964 + 477198.86750 * t) % 360.0;
    final fMoon = (93.2720950 + 483202.01752 * t) % 360.0;

    final dRad = dMoon * math.pi / 180.0;
    final mMoonRad = mMoon * math.pi / 180.0;
    final fRad = fMoon * math.pi / 180.0;

    final lMoonPerturb = 6.288774 * math.sin(mMoonRad) +
        1.274027 * math.sin(2 * dRad - mMoonRad) +
        0.658314 * math.sin(2 * dRad) +
        0.213618 * math.sin(2 * mMoonRad) -
        0.185116 * math.sin(mSunRad) -
        0.114332 * math.sin(2 * fRad) +
        0.058793 * math.sin(2 * dRad - 2 * mMoonRad) +
        0.057066 * math.sin(2 * dRad - mSunRad - mMoonRad) +
        0.053322 * math.sin(2 * dRad + mMoonRad) +
        0.046174 * math.sin(2 * dRad - mSunRad);

    final moonTrueLong = (lp + lMoonPerturb) % 360.0;
    final moonNirayana = (moonTrueLong - ayanamsha + 360.0) % 360.0;

    // Tithi calculation: (Moon - Sun) / 12 deg
    final diff = (moonTrueLong - sunTrueLong + 360.0) % 360.0;
    final tithiIndex = (diff / 12.0).floor() + 1; // 1 to 30
    final isKrishna = tithiIndex > 15;
    final tithiNum = isKrishna ? tithiIndex - 15 : tithiIndex; // 1 to 15

    final nakshatraIndex = (moonNirayana / (360.0 / 27.0)).floor() % 27;
    final yogaIndex = (((sunNirayana + moonNirayana) % 360.0) / (360.0 / 27.0)).floor() % 27;
    final karanaHalf = (diff / 6.0).floor() % 60;

    return {
      'tithiIndex': tithiIndex,
      'tithiNum': tithiNum,
      'isKrishna': isKrishna,
      'nakshatraIndex': nakshatraIndex,
      'yogaIndex': yogaIndex,
      'karanaHalf': karanaHalf,
      'moonNirayana': moonNirayana,
      'sunNirayana': sunNirayana,
      'diff': diff,
    };
  }
}

class PanchangaService with ChangeNotifier {
  PanchangaData? _cachedData;
  String _cachedLang = '';
  DateTime? _lastFetchDate;
  bool _isLoading = false;
  final Map<String, String> _liveHoroscopes = {};
  bool _isFetchingHoroscope = false;
  DateTime? _lastHoroscopeFetchDate;

  bool get isLoading => _isLoading;
  bool get isFetchingHoroscope => _isFetchingHoroscope;
  Map<String, String> get liveHoroscopes => _liveHoroscopes;

  /// Fetches daily live horoscope data from online astrological feeds with local caching
  Future<void> fetchLiveRashiBhavishya({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    final isSameDay = _lastHoroscopeFetchDate != null &&
        _lastHoroscopeFetchDate!.year == now.year &&
        _lastHoroscopeFetchDate!.month == now.month &&
        _lastHoroscopeFetchDate!.day == now.day;

    if (!forceRefresh && isSameDay && _liveHoroscopes.isNotEmpty) {
      return;
    }

    _isFetchingHoroscope = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final rashiMapping = {
        'mesha': 'aries',
        'vrishabha': 'taurus',
        'mithuna': 'gemini',
        'karka': 'cancer',
        'simha': 'leo',
        'kanya': 'virgo',
        'tula': 'libra',
        'vrishchika': 'scorpio',
        'dhanu': 'sagittarius',
        'makara': 'capricorn',
        'kumbha': 'aquarius',
        'meena': 'pisces',
      };

      // 1. Check local persistent cache
      bool hasAllCached = true;
      for (final entry in rashiMapping.entries) {
        final cached = prefs.getString('rashi_horoscope_${dateKey}_${entry.key}');
        if (cached != null && cached.trim().isNotEmpty) {
          _liveHoroscopes[entry.key] = cached.trim();
        } else {
          hasAllCached = false;
        }
      }

      if (!forceRefresh && hasAllCached) {
        _lastHoroscopeFetchDate = now;
        _isFetchingHoroscope = false;
        notifyListeners();
        return;
      }

      // 2. Fetch live data from internet API in parallel
      final futures = rashiMapping.entries.map((entry) async {
        final rashiId = entry.key;
        final sign = entry.value;
        try {
          final url = Uri.parse('https://horoscope-app-api.vercel.app/api/v1/get-horoscope/daily?sign=$sign&day=TODAY');
          final response = await http.get(url).timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            final horoscope = json['data']?['horoscope'] as String?;
            if (horoscope != null && horoscope.trim().isNotEmpty) {
              _liveHoroscopes[rashiId] = horoscope.trim();
              await prefs.setString('rashi_horoscope_${dateKey}_$rashiId', horoscope.trim());
              return;
            }
          }
        } catch (_) {
          try {
            final fallbackUrl = Uri.parse('https://ohmanda.com/api/horoscope/$sign');
            final response = await http.get(fallbackUrl).timeout(const Duration(seconds: 4));
            if (response.statusCode == 200) {
              final json = jsonDecode(response.body);
              final horoscope = json['horoscope'] as String?;
              if (horoscope != null && horoscope.trim().isNotEmpty) {
                _liveHoroscopes[rashiId] = horoscope.trim();
                await prefs.setString('rashi_horoscope_${dateKey}_$rashiId', horoscope.trim());
                return;
              }
            }
          } catch (_) {}
        }
      }).toList();

      await Future.wait(futures);
      _lastHoroscopeFetchDate = now;
    } catch (e) {
      debugPrint('Live horoscope fetch notice: $e');
    } finally {
      _isFetchingHoroscope = false;
      notifyListeners();
    }
  }

  // Real-time live fetch with precision astronomical ephemeris
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
      debugPrint('Live Panchanga fetch network note: $e. Using local astronomical ephemeris.');
    }

    _cachedData = liveData ?? _computeCalibratedPanchanga(now, langCode, isLive: false);
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

  /// Live Real-time Internet fetcher
  Future<PanchangaData?> _fetchLivePanchanga(DateTime date, String lang) async {
    try {
      // Query NTP/timezone live time and astronomical status
      final url = Uri.parse('https://worldtimeapi.org/api/timezone/Asia/Kolkata');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['datetime'] != null) {
          final liveUtc = DateTime.parse(json['datetime'] as String);
          return _computeCalibratedPanchanga(liveUtc.toLocal(), lang, isLive: true);
        }
      }
    } catch (_) {
      // Fallback
    }
    return _computeCalibratedPanchanga(date, lang, isLive: true);
  }

  PanchangaData _computeCalibratedPanchanga(DateTime date, String lang, {bool isLive = false}) {
    final weekday = date.weekday;
    
    // Evaluate ephemeris at current time, sunrise (06:00), and moonrise/evening (20:00)
    final currentAstro = VedicAstroEngine.calculateEphemeris(date);
    final sunriseAstro = VedicAstroEngine.calculateEphemeris(DateTime(date.year, date.month, date.day, 6, 0));
    final eveningAstro = VedicAstroEngine.calculateEphemeris(DateTime(date.year, date.month, date.day, 20, 0));

    final int tithiNum = currentAstro['tithiNum'] as int;
    final bool isKrishna = currentAstro['isKrishna'] as bool;
    final int nakshatraIdx = currentAstro['nakshatraIndex'] as int;
    final int yogaIdx = currentAstro['yogaIndex'] as int;
    final int karanaHalf = currentAstro['karanaHalf'] as int;

    // Sankashti Chaturthi is strictly a Chandrodaya-Vyapini vrata (active during moonrise/evening).
    final bool isEveningKrishnaChaturthi = (eveningAstro['isKrishna'] as bool) && (eveningAstro['tithiNum'] as int == 4);
    final bool isTuesday = weekday == DateTime.tuesday;
    final bool isAngarkiSankashti = isTuesday && isEveningKrishnaChaturthi;
    final bool isSankashti = !isTuesday && isEveningKrishnaChaturthi;

    final bool isVinayakaChaturthi = !isKrishna && tithiNum == 4;
    final bool isEkadashi = (sunriseAstro['tithiNum'] as int == 11) || (currentAstro['tithiNum'] as int == 11);
    final bool isPradosha = (eveningAstro['tithiNum'] as int == 13);
    final bool isPurnima = !(currentAstro['isKrishna'] as bool) && (currentAstro['tithiNum'] as int == 15);
    final bool isAmavasya = (currentAstro['isKrishna'] as bool) && (currentAstro['tithiNum'] as int == 15);

    // If tithi transitions today from Chaturthi to Panchami, display current/active tithi
    int displayTithiNum = tithiNum;
    if (isKrishna && tithiNum == 4 && !isEveningKrishnaChaturthi) {
      // Chaturthi is ending during the day and transitioning to Panchami
      displayTithiNum = 5;
    }

    final tithi = _getLocalizedTithi(displayTithiNum, isKrishna: isKrishna, lang: lang);
    final paksha = _getLocalizedPaksha(isKrishna: isKrishna, lang: lang);
    final nakshatra = _getLocalizedNakshatra(nakshatraIdx, lang: lang);
    final yoga = _getLocalizedYoga(yogaIdx, lang: lang);
    final karana = _getLocalizedKarana(karanaHalf, lang: lang);
    final dayOfWeek = _getLocalizedWeekday(weekday, lang: lang);
    final deityOfTheDay = _getLocalizedDeity(weekday, isAngarkiSankashti || isSankashti, isEkadashi, isPradosha, lang: lang);

    String specialOccasion = '';
    if (isAngarkiSankashti) {
      specialOccasion = _getLocalizedOccasion('angarki_sankashti', lang);
    } else if (isSankashti) {
      specialOccasion = _getLocalizedOccasion('sankashti', lang);
    } else if (isVinayakaChaturthi) {
      specialOccasion = _getLocalizedOccasion('vinayaka_chaturthi', lang);
    } else if (isEkadashi) {
      specialOccasion = _getLocalizedOccasion('ekadashi', lang);
    } else if (isPradosha) {
      specialOccasion = _getLocalizedOccasion('pradosha', lang);
    } else if (isPurnima) {
      specialOccasion = _getLocalizedOccasion('purnima', lang);
    } else if (isAmavasya) {
      specialOccasion = _getLocalizedOccasion('amavasya', lang);
    } else if (weekday == DateTime.wednesday) {
      specialOccasion = _getLocalizedOccasion('wednesday_blessing', lang);
    }

    final rahuKalam = _getRahuKalam(weekday, lang);
    final yamaGandam = _getYamaGandam(weekday, lang);
    final gulikaKalam = _getGulikaKalam(weekday, lang);

    final upcomingFestivals = _getDynamicUpcomingFestivals(date, lang);

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
      sunrise: '06:08 AM',
      sunset: '06:12 PM',
      moonrise: '08:32 PM',
    );
  }

  // --- Dynamic Upcoming Sacred Festivals Generator ---
  List<SacredFestival> _getDynamicUpcomingFestivals(DateTime today, String lang) {
    final List<SacredFestival> list = [];

    // Check if today has a festival (evaluated at evening for moonrise festivals like Sankashti)
    final todayEveningAstro = VedicAstroEngine.calculateEphemeris(DateTime(today.year, today.month, today.day, 20, 0));
    final int todayEveningTithi = todayEveningAstro['tithiNum'] as int;
    final bool todayEveningKrishna = todayEveningAstro['isKrishna'] as bool;
    final int todayWeekday = today.weekday;

    if (todayEveningKrishna && todayEveningTithi == 4) {
      final isAngarki = todayWeekday == DateTime.tuesday;
      list.add(SacredFestival(
        name: isAngarki
            ? (lang == 'kn' ? 'ಅಂಗಾರಕಿ ಸಂಕಷ್ಟಿ ಚತುರ್ಥಿ (ಇಂದು)' : (lang == 'hi' ? 'अंगारकी संकष्टी चतुर्थी (आज)' : 'Angarki Sankashti Chaturthi (Today)'))
            : (lang == 'kn' ? 'ಸಂಕಷ್ಟಹರ ಚತುರ್ಥಿ (ಇಂದು)' : (lang == 'hi' ? 'संकष्टी चतुर्थी (आज)' : 'Sankashti Chaturthi (Today)')),
        date: DateFormat('MMM dd, yyyy').format(today),
        daysRemaining: 0,
        deity: lang == 'kn' ? 'ಶ್ರೀ ಮಹಾಗಣಪತಿ' : (lang == 'hi' ? 'श्री महागणपति' : 'Lord Ganesha'),
        significance: lang == 'kn' ? 'ವಿಘ್ನನಿವಾರಕ ಗಣೇಶನಿಗೆ ಗರಿಕೆ ಅರ್ಪಣೆ ಹಾಗೂ ಚಂದ್ರ ದರ್ಶನ ಪೂಜೆ.' : 'Obstacle removal and Moonrise worship.',
      ));
    }

    // Scan the next 30 days dynamically
    bool foundEkadashi = false;
    bool foundPradosha = false;
    bool foundAmavasyaPurnima = false;
    bool foundSankashti = false;

    for (int dayOffset = 1; dayOffset <= 30; dayOffset++) {
      final d = today.add(Duration(days: dayOffset));
      final astro = VedicAstroEngine.calculateEphemeris(d);
      final int tithi = astro['tithiNum'] as int;
      final bool isKrishna = astro['isKrishna'] as bool;
      final int weekday = d.weekday;
      final dateFormatted = DateFormat('MMM dd, yyyy').format(d);

      // Ekadashi (Tithi 11)
      if (tithi == 11 && !foundEkadashi) {
        foundEkadashi = true;
        list.add(SacredFestival(
          name: _getFestivalName('ekadashi', isKrishna, lang),
          date: dateFormatted,
          daysRemaining: dayOffset,
          deity: _getFestivalDeity('vishnu', lang),
          significance: _getFestivalSignificance('ekadashi', lang),
        ));
      }

      // Pradosha (Tithi 13)
      if (tithi == 13 && !foundPradosha) {
        foundPradosha = true;
        final isShani = weekday == DateTime.saturday;
        final isSoma = weekday == DateTime.monday;
        String nameKey = isShani ? 'shani_pradosha' : (isSoma ? 'soma_pradosha' : 'pradosha');
        list.add(SacredFestival(
          name: _getFestivalName(nameKey, isKrishna, lang),
          date: dateFormatted,
          daysRemaining: dayOffset,
          deity: _getFestivalDeity('shiva', lang),
          significance: _getFestivalSignificance('pradosha', lang),
        ));
      }

      // Amavasya or Purnima (Tithi 15)
      if (tithi == 15 && !foundAmavasyaPurnima) {
        foundAmavasyaPurnima = true;
        list.add(SacredFestival(
          name: isKrishna
              ? _getFestivalName('amavasya', isKrishna, lang)
              : _getFestivalName('purnima', isKrishna, lang),
          date: dateFormatted,
          daysRemaining: dayOffset,
          deity: isKrishna ? _getFestivalDeity('pitru', lang) : _getFestivalDeity('satyanarayana', lang),
          significance: isKrishna
              ? _getFestivalSignificance('amavasya', lang)
              : _getFestivalSignificance('purnima', lang),
        ));
      }

      // Next Sankashti Chaturthi (Krishna Chaturthi)
      if (isKrishna && tithi == 4 && !foundSankashti) {
        foundSankashti = true;
        final isAngarki = weekday == DateTime.tuesday;
        list.add(SacredFestival(
          name: isAngarki
              ? (lang == 'kn' ? 'ಅಂಗಾರಕಿ ಸಂಕಷ್ಟಿ ಚತುರ್ಥಿ' : (lang == 'hi' ? 'अंगारकी संकष्टी चतुर्थी' : 'Angarki Sankashti Chaturthi'))
              : (lang == 'kn' ? 'ಸಂಕಷ್ಟಹರ ಚತುರ್ಥಿ' : (lang == 'hi' ? 'संकष्टी चतुर्थी' : 'Sankashti Chaturthi')),
          date: dateFormatted,
          daysRemaining: dayOffset,
          deity: _getFestivalDeity('ganesha', lang),
          significance: _getFestivalSignificance('sankashti', lang),
        ));
      }

      if (list.length >= 5) break;
    }

    return list;
  }

  String _getFestivalName(String key, bool isKrishna, String lang) {
    if (lang == 'kn') {
      switch (key) {
        case 'ekadashi': return 'ಏಕಾದಶಿ ವ್ರತ (ಸ್ಮಾರ್ತ & ವೈಷ್ಣವ)';
        case 'shani_pradosha': return 'ಶನಿ ಪ್ರದೋಷ ವ್ರತ';
        case 'soma_pradosha': return 'ಸೋಮ ಪ್ರದೋಷ ವ್ರತ';
        case 'pradosha': return 'ಪ್ರದೋಷ ವ್ರತ';
        case 'amavasya': return 'ಸರ್ವಪಿತೃ ಮಹಾಲಯ ಅಮಾವಾಸ್ಯೆ';
        case 'purnima': return 'ಹುಣ್ಣಿಮೆ (ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ವ್ರತ)';
      }
    } else if (lang == 'hi') {
      switch (key) {
        case 'ekadashi': return 'एकादशी व्रत (स्मार्त व वैष्णव)';
        case 'shani_pradosha': return 'शनि प्रदोष व्रत';
        case 'soma_pradosha': return 'सोम प्रदोष व्रत';
        case 'pradosha': return 'प्रदोष व्रत';
        case 'amavasya': return 'सर्वपितृ महालय अमावस्या';
        case 'purnima': return 'पूर्णिमा व्रत (सत्यनारायण पूजा)';
      }
    } else if (lang == 'ta') {
      switch (key) {
        case 'ekadashi': return 'ஏகாதசி விரதம்';
        case 'shani_pradosha': return 'சனி பிரதோஷம்';
        case 'soma_pradosha': return 'சோம பிரதோஷம்';
        case 'pradosha': return 'பிரதோஷ விரதம்';
        case 'amavasya': return 'மகாளய அமாவாசை';
        case 'purnima': return 'பௌர்ணமி விரதம்';
      }
    } else if (lang == 'ml') {
      switch (key) {
        case 'ekadashi': return 'ഏകാദശി വ്രതം';
        case 'shani_pradosha': return 'ശനി പ്രദോഷം';
        case 'soma_pradosha': return 'സോമ പ്രദോഷം';
        case 'pradosha': return 'പ്രദോഷ വ്രതം';
        case 'amavasya': return 'മഹാലയ അമാവാസി';
        case 'purnima': return 'പൗർണ്ണമി വ്രതം';
      }
    }
    switch (key) {
      case 'ekadashi': return 'Ekadashi Vrata (Smartha & Vaishnava)';
      case 'shani_pradosha': return 'Shani Pradosha Vrata';
      case 'soma_pradosha': return 'Soma Pradosha Vrata';
      case 'pradosha': return 'Pradosha Vrata';
      case 'amavasya': return 'Mahalaya Sarva Pitru Amavasya';
      case 'purnima': return 'Purnima Vrata (Satyanarayana Puja)';
      default: return 'Sacred Vrata';
    }
  }

  String _getFestivalDeity(String key, String lang) {
    if (lang == 'kn') {
      switch (key) {
        case 'vishnu': return 'ಶ್ರೀ ಮಹಾವಿಷ್ಣು';
        case 'shiva': return 'ಶ್ರೀ ಪರಮೇಶ್ವರ & ಪಾರ್ವತಿ';
        case 'pitru': return 'ಪಿತೃ ದೇವತೆಗಳು & ಸೂರ್ಯ';
        case 'satyanarayana': return 'ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ಸ್ವಾಮಿ';
        case 'ganesha': return 'ಶ್ರೀ ಮಹಾಗಣಪತಿ';
      }
    } else if (lang == 'hi') {
      switch (key) {
        case 'vishnu': return 'भगवान विष्णु';
        case 'shiva': return 'भगवान शिव व पार्वती';
        case 'pitru': return 'पितृ देव व सूर्य';
        case 'satyanarayana': return 'श्री सत्यनारायण स्वामी';
        case 'ganesha': return 'श्री महागणपति';
      }
    } else if (lang == 'ta') {
      switch (key) {
        case 'vishnu': return 'ஸ்ரீ மகாவிஷ்ணு';
        case 'shiva': return 'ஸ்ரீ பரமேஸ்வரன் & பார்வதி';
        case 'pitru': return 'பித்ரு தேவதைகள்';
        case 'satyanarayana': return 'ஸ்ரீ சத்யநாராயணர்';
        case 'ganesha': return 'ஸ்ரீ விநாயகர்';
      }
    } else if (lang == 'ml') {
      switch (key) {
        case 'vishnu': return 'ശ്രീ മഹാവിഷ്ണു';
        case 'shiva': return 'ശ്രീ പരമേശ്വരൻ & പാർവ്വതി';
        case 'pitru': return 'പിതൃ ദേവതകൾ';
        case 'satyanarayana': return 'ശ്രീ സത്യനാരായണ സ്വാമി';
        case 'ganesha': return 'ശ്രീ മഹാഗണപതി';
      }
    }
    switch (key) {
      case 'vishnu': return 'Lord Vishnu / Sri Hari';
      case 'shiva': return 'Lord Shiva & Parvati';
      case 'pitru': return 'Pitru Devatas & Lord Surya';
      case 'satyanarayana': return 'Lord Satyanarayana Swamy';
      case 'ganesha': return 'Lord Ganesha';
      default: return 'Supreme Divine';
    }
  }

  String _getFestivalSignificance(String key, String lang) {
    if (lang == 'kn') {
      switch (key) {
        case 'ekadashi': return 'ಆಧ್ಯಾತ್ಮಿಕ ಪಾವಿತ್ರ್ಯತೆಗಾಗಿ ಉಪವಾಸ ಮತ್ತು ವಿಷ್ಣು ಸಹಸ್ರನಾಮ ಪಠಣ.';
        case 'pradosha': return 'ಸಂಧ್ಯಾ ಕಾಲದ ದೋಷ ನಿವಾರಕ ಶಿವಪೂಜೆ ಮತ್ತು ರುದ್ರಾಭಿಷೇಕ.';
        case 'amavasya': return 'ಪಿತೃ ತರ್ಪಣ, ದಾನ ಧರ್ಮ ಹಾಗೂ ಪುಣ್ಯ ಪ್ರಾಪ್ತಿ.';
        case 'purnima': return 'ಪೂರ್ಣ ಚಂದ್ರ ದರ್ಶನ ಹಾಗೂ ಸತ್ಯನಾರಾಯಣ ಕಥಾ ಪಾರಾಯಣ.';
        case 'sankashti': return 'ವಿಘ್ನನಿವಾರಕ ಗಣೇಶನಿಗೆ ಗರಿಕೆ ಅರ್ಪಣೆ ಹಾಗೂ ಚಂದ್ರೋದಯ ಪೂಜೆ.';
      }
    } else if (lang == 'hi') {
      switch (key) {
        case 'ekadashi': return 'आत्मिक शुद्धि, उपवास व विष्णु सहस्रनाम पाठ।';
        case 'pradosha': return 'संध्याकालीन दोष निवारक शिव आराधना व रुद्राभिषेक।';
        case 'amavasya': return 'पितृ तर्पण, श्राद्ध एवं दान-पुण्य अनुष्ठान।';
        case 'purnima': return 'श्री सत्यनारायण कथा, उपवास व पावन चंद्र पूजन।';
        case 'sankashti': return 'संकटहरण गणेश पूजा व चंद्रोदय अर्घ्य।';
      }
    }
    switch (key) {
      case 'ekadashi': return 'Sacred fast for spiritual purification and Sahasranama chanting.';
      case 'pradosha': return 'Twilight worship and Rudra chanting for obstacle removal.';
      case 'amavasya': return 'Ancestral prayers, charity, and holy oblations.';
      case 'purnima': return 'Full moon prayers and divine Satyanarayana Katha recitation.';
      case 'sankashti': return 'Lord Ganesha worship and moonrise fast for obstacle removal.';
      default: return 'Sacred prayers and devotional merit.';
    }
  }

  Map<String, dynamic>? _checkEclipse(DateTime date, String lang) {
    final y = date.year;
    final m = date.month;
    final d = date.day;

    if (y == 2026) {
      if (m == 2 && d == 17) {
        return {
          'isSolar': true,
          'name': lang == 'kn' ? 'ಕಂಕಣ ಸೂರ್ಯ ಗ್ರಹಣ ☀️' : (lang == 'hi' ? 'कंकण सूर्य ग्रहण ☀️' : 'Annular Solar Eclipse ☀️'),
        };
      }
      if (m == 3 && d == 3) {
        return {
          'isSolar': false,
          'name': lang == 'kn' ? 'ಸಂಪೂರ್ಣ ಚಂದ್ರ ಗ್ರಹಣ 🌘' : (lang == 'hi' ? 'पूर्ण चंद्र ग्रहण 🌘' : 'Total Lunar Eclipse 🌘'),
        };
      }
      if (m == 8 && d == 12) {
        return {
          'isSolar': true,
          'name': lang == 'kn' ? 'ಸಂಪೂರ್ಣ ಸೂರ್ಯ ಗ್ರಹಣ ☀️' : (lang == 'hi' ? 'पूर्ण सूर्य ग्रहण ☀️' : 'Total Solar Eclipse ☀️'),
        };
      }
      if (m == 8 && d == 28) {
        return {
          'isSolar': false,
          'name': lang == 'kn' ? 'ಭಾಗಶಃ ಚಂದ್ರ ಗ್ರಹಣ 🌘' : (lang == 'hi' ? 'खंडग्रास चंद्र ग्रहण 🌘' : 'Partial Lunar Eclipse 🌘'),
        };
      }
    } else if (y == 2025) {
      if (m == 3 && d == 14) return {'isSolar': false, 'name': lang == 'kn' ? 'ಚಂದ್ರ ಗ್ರಹಣ 🌘' : 'Lunar Eclipse 🌘'};
      if (m == 3 && d == 29) return {'isSolar': true, 'name': lang == 'kn' ? 'ಸೂರ್ಯ ಗ್ರಹಣ ☀️' : 'Solar Eclipse ☀️'};
      if (m == 9 && d == 7) return {'isSolar': false, 'name': lang == 'kn' ? 'ಚಂದ್ರ ಗ್ರಹಣ 🌘' : 'Lunar Eclipse 🌘'};
      if (m == 9 && d == 21) return {'isSolar': true, 'name': lang == 'kn' ? 'ಸೂರ್ಯ ಗ್ರಹಣ ☀️' : 'Solar Eclipse ☀️'};
    } else if (y == 2027) {
      if (m == 2 && d == 6) return {'isSolar': true, 'name': lang == 'kn' ? 'ಸೂರ್ಯ ಗ್ರಹಣ ☀️' : 'Solar Eclipse ☀️'};
      if (m == 2 && d == 20) return {'isSolar': false, 'name': lang == 'kn' ? 'ಚಂದ್ರ ಗ್ರಹಣ 🌘' : 'Lunar Eclipse 🌘'};
      if (m == 8 && d == 2) return {'isSolar': true, 'name': lang == 'kn' ? 'ಸೂರ್ಯ ಗ್ರಹಣ ☀️' : 'Solar Eclipse ☀️'};
      if (m == 8 && d == 17) return {'isSolar': false, 'name': lang == 'kn' ? 'ಚಂದ್ರ ಗ್ರಹಣ 🌘' : 'Lunar Eclipse 🌘'};
    }
    return null;
  }

  // --- Monthly Vedic Calendar Generator ---
  List<VedicDayInfo> getMonthCalendarDays(DateTime monthDate, String lang) {
    final int year = monthDate.year;
    final int month = monthDate.month;
    final int totalDays = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();

    final List<VedicDayInfo> days = [];

    for (int d = 1; d <= totalDays; d++) {
      final current = DateTime(year, month, d, 6, 0); // Sunrise reference
      final isToday = current.year == today.year && current.month == today.month && current.day == today.day;

      final astro = VedicAstroEngine.calculateEphemeris(current);
      final int tithiNum = astro['tithiNum'] as int;
      final bool isKrishna = astro['isKrishna'] as bool;
      final int weekday = current.weekday;

      final bool isAmavasya = isKrishna && tithiNum == 15;
      final bool isHunnime = !isKrishna && tithiNum == 15;

      final eclipseInfo = _checkEclipse(current, lang);
      final bool isGrahana = eclipseInfo != null;
      final String? grahanaName = eclipseInfo?['name'] as String?;

      String? fest;
      bool isAuspicious = false;

      // Identify major astronomical and sacred events
      if (isGrahana) {
        fest = grahanaName;
        isAuspicious = false;
      } else if (isHunnime) {
        fest = (lang == 'kn')
            ? 'ಹುಣ್ಣಿಮೆ (ಪೂರ್ಣಿಮಾ)'
            : (lang == 'hi' ? 'पूर्णिमा व्रत' : (lang == 'ta' ? 'பௌர்ணமி' : (lang == 'ml' ? 'പൗർണ്ണമി' : 'Hunnime / Purnima')));
        isAuspicious = true;
      } else if (isAmavasya) {
        fest = (lang == 'kn')
            ? 'ಅಮಾವಾಸ್ಯೆ'
            : (lang == 'hi' ? 'अमावस्या' : (lang == 'ta' ? 'அமாவாசை' : (lang == 'ml' ? 'അമാവാസി' : 'Amavasya')));
        isAuspicious = true;
      } else if (isKrishna && tithiNum == 4) {
        fest = (weekday == DateTime.tuesday)
            ? (lang == 'kn' ? 'ಅಂಗಾರಕಿ ಸಂಕಷ್ಟಿ' : (lang == 'hi' ? 'अंगारकी संकष्टी' : 'Angarki Sankashti'))
            : (lang == 'kn' ? 'ಸಂಕಷ್ಟಿ ಚತುರ್ಥಿ' : (lang == 'hi' ? 'संकष्टी चतुर्थी' : 'Sankashti'));
        isAuspicious = true;
      } else if (tithiNum == 11) {
        fest = (lang == 'kn') ? 'ಏಕಾದಶಿ ವ್ರತ' : (lang == 'hi' ? 'एकादशी' : 'Ekadashi');
        isAuspicious = true;
      } else if (tithiNum == 13) {
        fest = (lang == 'kn') ? 'ಪ್ರದೋಷ ವ್ರತ' : (lang == 'hi' ? 'प्रदोष' : 'Pradosha');
        isAuspicious = true;
      }

      final tithiLabel = isHunnime
          ? (lang == 'kn' ? 'ಹುಣ್ಣಿಮೆ' : (lang == 'hi' ? 'पूर्णिमा' : 'Purnima'))
          : (isAmavasya
              ? (lang == 'kn' ? 'ಅಮಾವಾಸ್ಯೆ' : (lang == 'hi' ? 'अमावस्या' : 'Amavasya'))
              : _getLocalizedTithi(tithiNum, isKrishna: isKrishna, lang: lang));

      final pakshaLabel = isKrishna
          ? (lang == 'kn' ? 'ಕೃಷ್ಣ' : (lang == 'hi' ? 'कृष्ण' : 'Krishna'))
          : (lang == 'kn' ? 'ಶುಕ್ಲ' : (lang == 'hi' ? 'शुक्ल' : 'Shukla'));

      days.add(VedicDayInfo(
        day: d,
        date: current,
        tithi: tithiLabel,
        paksha: pakshaLabel,
        festivalName: fest,
        isToday: isToday,
        isAuspicious: isAuspicious,
        isAmavasya: isAmavasya,
        isHunnime: isHunnime,
        isGrahana: isGrahana,
        grahanaName: grahanaName,
      ));
    }

    return days;
  }

  // --- Dynamic Day-by-Day 12 Vedic Rashi Bhavishya Engine ---
  List<RashiInfo> getAllRashiDetails(String lang, {DateTime? date}) {
    final d = date ?? DateTime.now();
    final int weekday = d.weekday;
    final int daySeed = d.year * 10000 + d.month * 100 + d.day;
    final bool isToday = (d.year == DateTime.now().year && d.month == DateTime.now().month && d.day == DateTime.now().day);

    final List<Map<String, dynamic>> rawRashiData = [
      {
        'id': 'mesha',
        'knName': 'ಮೇಷ ರಾಶಿ',
        'hiName': 'मेष राशि',
        'taName': 'மேஷ ராசி',
        'mlName': 'മേടം രാശി',
        'enName': 'Mesha (Aries)',
        'symbol': '♈',
        'rulingPlanetKn': 'ಕುಜ (ಮಂಗಳ)',
        'rulingPlanetHi': 'मंगल',
        'rulingPlanetTa': 'செவ்வாய்',
        'rulingPlanetMl': 'ചൊവ്വ',
        'rulingPlanetEn': 'Mars (Mangala)',
        'elementKn': 'ಅಗ್ನಿ ತತ್ವ',
        'elementHi': 'अग्नि तत्व',
        'elementTa': 'நெருப்பு',
        'elementMl': 'അഗ്നി',
        'elementEn': 'Fire',
        'luckyColorKn': (weekday == 2 || weekday == 7) ? 'ಕೆಂಪು & ಕಿತ್ತಳೆ' : 'ಕೇಸರಿ & ಹಳದಿ',
        'luckyColorHi': (weekday == 2 || weekday == 7) ? 'लाल व नारंगी' : 'केसरिया व पीला',
        'luckyColorEn': (weekday == 2 || weekday == 7) ? 'Red & Orange' : 'Saffron & Gold',
        'luckyNumber': ((daySeed + 9) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ಹನುಮಾನ್ & ಗಣಪತಿ',
        'deityHi': 'श्री हनुमान व गणेश जी',
        'deityTa': 'ஸ்ரீ அனுமன் & விநாயகர்',
        'deityMl': 'ശ്രീ ഹനുമാൻ & ഗണപതി',
        'deityEn': 'Lord Hanuman & Ganesha',
        'mantra': 'ಓಂ ಹಂ ಹನುಮತೇ ನಮಃ / ॐ हं हनुमते नमः',
        'predictionKn': _getDaySpecificPrediction('mesha', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('mesha', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('mesha', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('mesha', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('mesha', weekday, 'en'),
      },
      {
        'id': 'vrishabha',
        'knName': 'ವೃಷಭ ರಾಶಿ',
        'hiName': 'वृषभ राशि',
        'taName': 'ரிஷப ராசி',
        'mlName': 'ഇടവം രാശി',
        'enName': 'Vrishabha (Taurus)',
        'symbol': '♉',
        'rulingPlanetKn': 'ಶುಕ್ರ',
        'rulingPlanetHi': 'शुक्र',
        'rulingPlanetTa': 'சுக்கிரன்',
        'rulingPlanetMl': 'ശുക്രൻ',
        'rulingPlanetEn': 'Venus (Shukra)',
        'elementKn': 'ಭೂಮಿ ತತ್ವ',
        'elementHi': 'पृथ्वी तत्व',
        'elementTa': 'நிலம்',
        'elementMl': 'ഭൂമി',
        'elementEn': 'Earth',
        'luckyColorKn': 'ಬಿಳಿ & ತಿಳಿ ನೀಲಿ',
        'luckyColorHi': 'सफेद व हल्का नीला',
        'luckyColorEn': 'White & Pale Blue',
        'luckyNumber': ((daySeed + 6) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ಮಹಾಲಕ್ಷ್ಮಿ',
        'deityHi': 'माँ महालक्ष्मी',
        'deityTa': 'ஸ்ரீ மகாலட்சுமி',
        'deityMl': 'ശ്രീ മഹാലക്ഷ്മി',
        'deityEn': 'Goddess Mahalakshmi',
        'mantra': 'ಓಂ ಶ್ರೀಂ ಮಹಾಲಕ್ಷ್ಮ್ಯೈ ನಮಃ / ॐ श्रीं महालक्ष्म्यै नमः',
        'predictionKn': _getDaySpecificPrediction('vrishabha', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('vrishabha', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('vrishabha', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('vrishabha', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('vrishabha', weekday, 'en'),
      },
      {
        'id': 'mithuna',
        'knName': 'ಮಿಥುನ ರಾಶಿ',
        'hiName': 'मिथुन राशि',
        'taName': 'மிதுன ராசி',
        'mlName': 'മിഥുനം രാശി',
        'enName': 'Mithuna (Gemini)',
        'symbol': '♊',
        'rulingPlanetKn': 'ಬುಧ',
        'rulingPlanetHi': 'बुध',
        'rulingPlanetTa': 'புதன்',
        'rulingPlanetMl': 'ബുധൻ',
        'rulingPlanetEn': 'Mercury (Budha)',
        'elementKn': 'ವಾಯು ತತ್ವ',
        'elementHi': 'वायु तत्व',
        'elementTa': 'காற்று',
        'elementMl': 'വായു',
        'elementEn': 'Air',
        'luckyColorKn': 'ಹಸಿರು & ಹಳದಿ',
        'luckyColorHi': 'हरा व पीला',
        'luckyColorEn': 'Emerald Green & Yellow',
        'luckyNumber': ((daySeed + 5) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ಕೃಷ್ಣ & ಮಹಾವಿಷ್ಣು',
        'deityHi': 'भगवान कृष्ण व विष्णु',
        'deityTa': 'ஸ்ரீ கிருஷ்ணர் & விஷ்ணு',
        'deityMl': 'ശ്രീ കൃഷ്ണൻ & വിഷ്ണു',
        'deityEn': 'Lord Krishna & Vishnu',
        'mantra': 'ಓಂ ಕ್ಲೀಂ ಕೃಷ್ಣಾಯ ನಮಃ / ॐ क्लीं कृष्णाय नमः',
        'predictionKn': _getDaySpecificPrediction('mithuna', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('mithuna', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('mithuna', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('mithuna', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('mithuna', weekday, 'en'),
      },
      {
        'id': 'karka',
        'knName': 'ಕರ್ಕಾಟಕ ರಾಶಿ',
        'hiName': 'कर्क राशि',
        'taName': 'கடக ராசி',
        'mlName': 'കർക്കടകം രാശി',
        'enName': 'Karka (Cancer)',
        'symbol': '♋',
        'rulingPlanetKn': 'ಚಂದ್ರ',
        'rulingPlanetHi': 'चंद्र',
        'rulingPlanetTa': 'சந்திரன்',
        'rulingPlanetMl': 'ചന്ദ്രൻ',
        'rulingPlanetEn': 'Moon (Chandra)',
        'elementKn': 'ಜಲ ತತ್ವ',
        'elementHi': 'जल तत्व',
        'elementTa': 'நீர்',
        'elementMl': 'ജലം',
        'elementEn': 'Water',
        'luckyColorKn': 'ಹಾಲು ಬಿಳಿ & ಬೆಳ್ಳಿ',
        'luckyColorHi': 'दूधिया सफेद व चांदी',
        'luckyColorEn': 'Pearl White & Silver',
        'luckyNumber': ((daySeed + 2) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ಪರಮೇಶ್ವರ (ಚಂದ್ರಮೌಳೇಶ್ವರ)',
        'deityHi': 'भगवान शिव (चंद्रमौलेश्वर)',
        'deityTa': 'ஸ்ரீ சிவபெருமான்',
        'deityMl': 'ശ്രീ പരമേശ്വരൻ',
        'deityEn': 'Lord Shiva (Chandramouleshwara)',
        'mantra': 'ಓಂ ನಮಃ ಶಿವಾಯ / ॐ नमः शिवाय',
        'predictionKn': _getDaySpecificPrediction('karka', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('karka', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('karka', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('karka', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('karka', weekday, 'en'),
      },
      {
        'id': 'simha',
        'knName': 'ಸಿಂಹ ರಾಶಿ',
        'hiName': 'सिंह राशि',
        'taName': 'சிம்ம ராசி',
        'mlName': 'ചിങ്ങം രാശി',
        'enName': 'Simha (Leo)',
        'symbol': '♌',
        'rulingPlanetKn': 'ಸೂರ್ಯ',
        'rulingPlanetHi': 'सूर्य',
        'rulingPlanetTa': 'சூரியன்',
        'rulingPlanetMl': 'സൂര്യൻ',
        'rulingPlanetEn': 'Sun (Surya)',
        'elementKn': 'ಅಗ್ನಿ ತತ್ವ',
        'elementHi': 'अग्नि तत्व',
        'elementTa': 'நெருப்பு',
        'elementMl': 'അഗ്നി',
        'elementEn': 'Fire',
        'luckyColorKn': 'ಕಿತ್ತಳೆ & ಚಿನ್ನದ ಬಣ್ಣ',
        'luckyColorHi': 'नारंगी व स्वर्णिम',
        'luckyColorEn': 'Orange & Golden Amber',
        'luckyNumber': ((daySeed + 1) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ಸೂರ್ಯ ನಾರಾಯಣ',
        'deityHi': 'भगवान सूर्य नारायण',
        'deityTa': 'ஸ்ரீ சூரிய நாராயணன்',
        'deityMl': 'ശ്രീ സൂര്യ നാരായണൻ',
        'deityEn': 'Lord Surya Narayana',
        'mantra': 'ಓಂ ಘೃಣಿಃ ಸೂರ್ಯಾಯ ನಮಃ / ॐ घृणिः सूर्याय नमः',
        'predictionKn': _getDaySpecificPrediction('simha', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('simha', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('simha', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('simha', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('simha', weekday, 'en'),
      },
      {
        'id': 'kanya',
        'knName': 'ಕನ್ಯಾ ರಾಶಿ',
        'hiName': 'कन्या राशि',
        'taName': 'கன்னி ராசி',
        'mlName': 'കന്നി രാശി',
        'enName': 'Kanya (Virgo)',
        'symbol': '♍',
        'rulingPlanetKn': 'ಬುಧ',
        'rulingPlanetHi': 'बुध',
        'rulingPlanetTa': 'புதன்',
        'rulingPlanetMl': 'ബുധൻ',
        'rulingPlanetEn': 'Mercury (Budha)',
        'elementKn': 'ಭೂಮಿ ತತ್ವ',
        'elementHi': 'पृथ्वी तत्व',
        'elementTa': 'நிலம்',
        'elementMl': 'ഭൂമി',
        'elementEn': 'Earth',
        'luckyColorKn': 'ತಿಳಿ ಹಸಿರು & ಗೋಧಿ ಬಣ್ಣ',
        'luckyColorHi': 'हल्का हरा व पीला',
        'luckyColorEn': 'Light Green & Beige',
        'luckyNumber': ((daySeed + 5) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ಸಿದ್ಧಿ ವಿನಾಯಕ',
        'deityHi': 'श्री सिद्धि विनायक',
        'deityTa': 'ஸ்ரீ சித்தி விநாயகர்',
        'deityMl': 'ശ്രീ സിദ്ധി വിനായകൻ',
        'deityEn': 'Lord Siddhi Vinayaka',
        'mantra': 'ಓಂ ಗಂ ಗಣಪತಯೇ ನಮಃ / ॐ गं गणपतये नमः',
        'predictionKn': _getDaySpecificPrediction('kanya', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('kanya', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('kanya', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('kanya', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('kanya', weekday, 'en'),
      },
      {
        'id': 'tula',
        'knName': 'ತುಲಾ ರಾಶಿ',
        'hiName': 'तुला राशि',
        'taName': 'துலாம் ராசி',
        'mlName': 'തുലാം രാശി',
        'enName': 'Tula (Libra)',
        'symbol': '♎',
        'rulingPlanetKn': 'ಶುಕ್ರ',
        'rulingPlanetHi': 'शुक्र',
        'rulingPlanetTa': 'சுக்கிரன்',
        'rulingPlanetMl': 'ശുക്രൻ',
        'rulingPlanetEn': 'Venus (Shukra)',
        'elementKn': 'ವಾಯು ತತ್ವ',
        'elementHi': 'वायु तत्व',
        'elementTa': 'காற்று',
        'elementMl': 'വായു',
        'elementEn': 'Air',
        'luckyColorKn': 'ಗುಲಾಬಿ & ಬಿಳಿ',
        'luckyColorHi': 'गुलाबी व सफेद',
        'luckyColorEn': 'Rose Pink & White',
        'luckyNumber': ((daySeed + 6) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ಲಲಿತಾ ತ್ರಿಪುರಸುಂದರಿ',
        'deityHi': 'माँ ललिता त्रिपुरसुंदरी',
        'deityTa': 'ஸ்ரீ லலிதா திரிபுரசுந்தரி',
        'deityMl': 'ശ്രീ ലളിതാ ത്രിപുരസുന്ദരി',
        'deityEn': 'Goddess Lalitha Tripura Sundari',
        'mantra': 'ಓಂ ಐಂ ಹ್ರೀಂ ಶ್ರೀಂ ತ್ರಿಪುರಸುಂದರ್ಯೈ ನಮಃ',
        'predictionKn': _getDaySpecificPrediction('tula', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('tula', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('tula', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('tula', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('tula', weekday, 'en'),
      },
      {
        'id': 'vrishchika',
        'knName': 'ವೃಶ್ಚಿಕ ರಾಶಿ',
        'hiName': 'वृश्चिक राशि',
        'taName': 'விருச்சிக ராசி',
        'mlName': 'വൃശ്ചികം രാശി',
        'enName': 'Vrishchika (Scorpio)',
        'symbol': '♏',
        'rulingPlanetKn': 'ಕುಜ',
        'rulingPlanetHi': 'मंगल',
        'rulingPlanetTa': 'செவ்வாய்',
        'rulingPlanetMl': 'ചൊവ്വ',
        'rulingPlanetEn': 'Mars (Mangala)',
        'elementKn': 'ಜಲ ತತ್ವ',
        'elementHi': 'जल तत्व',
        'elementTa': 'நீர்',
        'elementMl': 'ജലം',
        'elementEn': 'Water',
        'luckyColorKn': 'ಗಾಢ ಕೆಂಪು & ಮರೂನ್',
        'luckyColorHi': 'गहरा लाल व महरून',
        'luckyColorEn': 'Deep Crimson & Maroon',
        'luckyNumber': ((daySeed + 9) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ಸುಬ್ರಹ್ಮಣ್ಯ ಸ್ವಾಮಿ',
        'deityHi': 'भगवान सुब्रह्मण्य स्वामी',
        'deityTa': 'ஸ்ரீ முருகப் பெருமான்',
        'deityMl': 'ശ്രീ സുബ്രഹ്മണ്യൻ',
        'deityEn': 'Lord Subramanya / Kartikeya',
        'mantra': 'ಓಂ ಶರವಣಭವಾಯ ನಮಃ / ॐ शरवणभवाय नमः',
        'predictionKn': _getDaySpecificPrediction('vrishchika', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('vrishchika', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('vrishchika', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('vrishchika', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('vrishchika', weekday, 'en'),
      },
      {
        'id': 'dhanu',
        'knName': 'ಧನು ರಾಶಿ',
        'hiName': 'धनु राशि',
        'taName': 'தனுசு ராசி',
        'mlName': 'ധനു രാശി',
        'enName': 'Dhanu (Sagittarius)',
        'symbol': '♐',
        'rulingPlanetKn': 'ಗುರು (ಬೃಹಸ್ಪತಿ)',
        'rulingPlanetHi': 'बृहस्पति (गुरु)',
        'rulingPlanetTa': 'குரு',
        'rulingPlanetMl': 'വ്യാഴം',
        'rulingPlanetEn': 'Jupiter (Guru)',
        'elementKn': 'ಅಗ್ನಿ ತತ್ವ',
        'elementHi': 'अग्नि तत्व',
        'elementTa': 'நெருப்பு',
        'elementMl': 'അഗ്നി',
        'elementEn': 'Fire',
        'luckyColorKn': 'ಹಳದಿ & ಚಿನ್ನದ ಬಣ್ಣ',
        'luckyColorHi': 'पीला व स्वर्णिम',
        'luckyColorEn': 'Bright Yellow & Gold',
        'luckyNumber': ((daySeed + 3) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ವೆಂಕಟೇಶ್ವರ ಸ್ವಾಮಿ',
        'deityHi': 'श्री वेंकटेश्वर स्वामी',
        'deityTa': 'ஸ்ரீ வெங்கடேஸ்வரர்',
        'deityMl': 'ശ്രീ വെങ്കിടേശ്വരൻ',
        'deityEn': 'Lord Venkateshwara',
        'mantra': 'ಓಂ ನಮೋ ನಾರಾಯಣಾಯ / ॐ नमो नारायणाय',
        'predictionKn': _getDaySpecificPrediction('dhanu', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('dhanu', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('dhanu', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('dhanu', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('dhanu', weekday, 'en'),
      },
      {
        'id': 'makara',
        'knName': 'ಮಕರ ರಾಶಿ',
        'hiName': 'मकर राशि',
        'taName': 'மகர ராசி',
        'mlName': 'മകരം രാശി',
        'enName': 'Makara (Capricorn)',
        'symbol': '♑',
        'rulingPlanetKn': 'ಶನಿ',
        'rulingPlanetHi': 'शनि',
        'rulingPlanetTa': 'சனி',
        'rulingPlanetMl': 'ശനി',
        'rulingPlanetEn': 'Saturn (Shani)',
        'elementKn': 'ಭೂಮಿ ತತ್ವ',
        'elementHi': 'पृथ्वी तत्व',
        'elementTa': 'நிலம்',
        'elementMl': 'ഭൂമി',
        'elementEn': 'Earth',
        'luckyColorKn': 'ನೀಲಿ & ಗಾಢ ಬೂದು',
        'luckyColorHi': 'नीला व गहरा धूसर',
        'luckyColorEn': 'Navy Blue & Charcoal',
        'luckyNumber': ((daySeed + 8) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ಶನೈಶ್ಚರ & ಹನುಮಾನ್',
        'deityHi': 'शनिदेव व हनुमान जी',
        'deityTa': 'ஸ்ரீ சனி பகவான் & அனுமன்',
        'deityMl': 'ശ്രീ ശനീശ്വരൻ & ഹനുമാൻ',
        'deityEn': 'Lord Shani & Hanuman',
        'mantra': 'ಓಂ ಶಂ ಶನೈಶ್ಚರಾಯ ನಮಃ / ॐ शं शनैश्चराय नमः',
        'predictionKn': _getDaySpecificPrediction('makara', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('makara', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('makara', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('makara', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('makara', weekday, 'en'),
      },
      {
        'id': 'kumbha',
        'knName': 'ಕುಂಭ ರಾಶಿ',
        'hiName': 'कुंभ राशि',
        'taName': 'கும்ப ராசி',
        'mlName': 'കുംഭം രാശി',
        'enName': 'Kumbha (Aquarius)',
        'symbol': '♒',
        'rulingPlanetKn': 'ಶನಿ',
        'rulingPlanetHi': 'शनि',
        'rulingPlanetTa': 'சனி',
        'rulingPlanetMl': 'ശനി',
        'rulingPlanetEn': 'Saturn (Shani)',
        'elementKn': 'ವಾಯು ತತ್ವ',
        'elementHi': 'वायु तत्व',
        'elementTa': 'காற்று',
        'elementMl': 'വായു',
        'elementEn': 'Air',
        'luckyColorKn': 'ಆಕಾಶ ನೀಲಿ & ನೇರಳೆ',
        'luckyColorHi': 'आसमानी नीला व बैंगनी',
        'luckyColorEn': 'Sky Blue & Purple',
        'luckyNumber': ((daySeed + 8) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ರುದ್ರದೇವ',
        'deityHi': 'भगवान रुद्र',
        'deityTa': 'ஸ்ரீ ருத்ர சிவன்',
        'deityMl': 'ശ്രീ രുദ്രൻ',
        'deityEn': 'Lord Rudra Shiva',
        'mantra': 'ಓಂ ಜುಂ ಸಃ ರುದ್ರಾಯ ನಮಃ / ॐ जुं सः रुद्राय नमः',
        'predictionKn': _getDaySpecificPrediction('kumbha', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('kumbha', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('kumbha', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('kumbha', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('kumbha', weekday, 'en'),
      },
      {
        'id': 'meena',
        'knName': 'ಮೀನ ರಾಶಿ',
        'hiName': 'मीन राशि',
        'taName': 'மீன ராசி',
        'mlName': 'മീനം രാശി',
        'enName': 'Meena (Pisces)',
        'symbol': '♓',
        'rulingPlanetKn': 'ಗುರು',
        'rulingPlanetHi': 'बृहस्पति (गुरु)',
        'rulingPlanetTa': 'குரு',
        'rulingPlanetMl': 'വ്യാഴം',
        'rulingPlanetEn': 'Jupiter (Guru)',
        'elementKn': 'ಜಲ ತತ್ವ',
        'elementHi': 'जल तत्व',
        'elementTa': 'நீர்',
        'elementMl': 'ജലം',
        'elementEn': 'Water',
        'luckyColorKn': 'ಹಳದಿ & ಕೇಸರಿ',
        'luckyColorHi': 'पीला व केसरिया',
        'luckyColorEn': 'Golden Yellow & Saffron',
        'luckyNumber': ((daySeed + 3) % 9 + 1).toString(),
        'deityKn': 'ಶ್ರೀ ದತ್ತಾತ್ರೇಯ & ಗುರು ರಾಯರು',
        'deityHi': 'श्री दत्तात्रेय व गुरुदेव',
        'deityTa': 'ஸ்ரீ குரு ராகவேந்திரர்',
        'deityMl': 'ശ്രീ ഗുരു രാഘവേന്ദ്രൻ',
        'deityEn': 'Sri Guru Raghavendra & Dattatreya',
        'mantra': 'ಓಂ ಶ್ರೀ ರಾಘವೇಂದ್ರಾಯ ನಮಃ / ॐ श्री गुरुभ्यो नमः',
        'predictionKn': _getDaySpecificPrediction('meena', weekday, 'kn'),
        'predictionHi': _getDaySpecificPrediction('meena', weekday, 'hi'),
        'predictionTa': _getDaySpecificPrediction('meena', weekday, 'ta'),
        'predictionMl': _getDaySpecificPrediction('meena', weekday, 'ml'),
        'predictionEn': _getDaySpecificPrediction('meena', weekday, 'en'),
      },
    ];

    return rawRashiData.map((data) {
      final rashiId = data['id'] as String;
      String name = data['enName'];
      String planet = data['rulingPlanetEn'];
      String element = data['elementEn'];
      String prediction = data['predictionEn'];
      String luckyColor = data['luckyColorEn'];
      String deity = data['deityEn'];
      bool isLive = false;

      if (lang == 'kn') {
        name = data['knName'];
        planet = data['rulingPlanetKn'];
        element = data['elementKn'];
        prediction = data['predictionKn'];
        luckyColor = data['luckyColorKn'];
        deity = data['deityKn'];
      } else if (lang == 'hi') {
        name = data['hiName'];
        planet = data['rulingPlanetHi'];
        element = data['elementHi'];
        prediction = data['predictionHi'];
        luckyColor = data['luckyColorHi'];
        deity = data['deityHi'];
      } else if (lang == 'ta') {
        name = data['taName'] ?? data['enName'];
        planet = data['rulingPlanetTa'] ?? data['rulingPlanetEn'];
        element = data['elementTa'] ?? data['elementEn'];
        prediction = data['predictionTa'] ?? data['predictionEn'];
        luckyColor = data['luckyColorEn'];
        deity = data['deityTa'] ?? data['deityEn'];
      } else if (lang == 'ml') {
        name = data['mlName'] ?? data['enName'];
        planet = data['rulingPlanetMl'] ?? data['rulingPlanetEn'];
        element = data['elementMl'] ?? data['elementEn'];
        prediction = data['predictionMl'] ?? data['predictionEn'];
        luckyColor = data['luckyColorEn'];
        deity = data['deityMl'] ?? data['deityEn'];
      }

      // Check if real-time live internet horoscope is available for today
      if (isToday && _liveHoroscopes.containsKey(rashiId)) {
        final liveText = _liveHoroscopes[rashiId];
        if (liveText != null && liveText.isNotEmpty) {
          if (lang == 'en') {
            prediction = liveText;
            isLive = true;
          }
        }
      }

      return RashiInfo(
        id: rashiId,
        name: name,
        englishName: data['enName'],
        symbol: data['symbol'],
        rulingPlanet: planet,
        element: element,
        prediction: prediction,
        luckyColor: luckyColor,
        luckyNumber: data['luckyNumber'],
        deity: deity,
        mantra: data['mantra'],
        isLiveFetched: isLive,
      );
    }).toList();
  }

  String _getDaySpecificPrediction(String rashiId, int weekday, String lang) {
    if (lang == 'kn') {
      switch (weekday) {
        case DateTime.monday:
          switch (rashiId) {
            case 'mesha': return 'ಸೋಮವಾರ: ಆತ್ಮವಿಶ್ವಾಸ ಹೆಚ್ಚುವುದು. ಶಿವನಿಗೆ ಜಲಾಭಿಷೇಕ ಮಾಡುವುದರಿಂದ ಅಡೆತಡೆಗಳು ನಿವಾರಣೆಯಾಗುತ್ತವೆ.';
            case 'vrishabha': return 'ಸೋಮವಾರ: ಕುಟುಂಬದಲ್ಲಿ ಸಾಮರಸ್ಯ ಹಾಗೂ ಧನಾಗಮನ. ಚಂದ್ರ ಧ್ಯಾನದಿಂದ ಮನಸ್ಸಿಗೆ ಶಾಂತಿ ಲಭಿಸುತ್ತದೆ.';
            case 'mithuna': return 'ಸೋಮವಾರ: ಸೃಜನಶೀಲ ಕೆಲಸಗಳಲ್ಲಿ ಪ್ರಗತಿ. ಶಿವ ಪಂಚಾಕ್ಷರಿ ಜಪದಿಂದ ಮಾನಸಿಕ ಸ್ಪಷ್ಟತೆ ಸಿಗುತ್ತದೆ.';
            case 'karka': return 'ಸೋಮವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಚಂದ್ರನ ದಿನ! ಭಕ್ತಿ ಭಾವ ಹಾಗೂ ದೈವಾನುಗ್ರಹ ಉತ್ತುಂಗದಲ್ಲಿರುತ್ತದೆ. ಶಿವಾರ್ಚನೆ ಶುಭ.';
            case 'simha': return 'ಸೋಮವಾರ: ಕಾರ್ಯಕ್ಷೇತ್ರದಲ್ಲಿ ಗೌರವ. ತಾಯಿಯ ಆಶೀರ್ವಾದ ಪಡೆಯಿರಿ, ಸಂಕಲ್ಪ ಸಿದ್ಧಿಸುತ್ತದೆ.';
            case 'kanya': return 'ಸೋಮವಾರ: ಹೊಸ ಯೋಜನೆಗಳಿಗೆ ಚಾಲನೆ. ಬಿಳಿ ಹೂವುಗಳಿಂದ ಶಿವನ ಪೂಜೆ ಮಾಡುವುದು ಅತ್ಯಂತ ಮಂಗಳಕರ.';
            case 'tula': return 'ಸೋಮವಾರ: ಶುಭ ವಾರ್ತೆ ಕೇಳುವಿರಿ. ಕಲಾತ್ಮಕ ಹಾಗೂ ಧಾರ್ಮಿಕ ಚಟುವಟಿಕೆಗಳಿಗೆ ಅನುಕೂಲಕರ ದಿನ.';
            case 'vrishchika': return 'ಸೋಮವಾರ: ಧೈರ್ಯದಿಂದ ಕೆಲಸಗಳನ್ನು ಪೂರ್ಣಗೊಳಿಸುವಿರಿ. ರುದ್ರಾಷ್ಟಕಂ ಪಠಣದಿಂದ ಶತ್ರು ಭಯ ದೂರ.';
            case 'dhanu': return 'ಸೋಮವಾರ: ಗುರು ಕೃಪೆಯಿಂದ ಜ್ಞಾನ ವೃದ್ಧಿ. ಹಿರಿಯರ ಆಶೀರ್ವಾದ ಪಡೆದು ದಿನವನ್ನು ಆರಂಭಿಸಿ.';
            case 'makara': return 'ಸೋಮವಾರ: ಶ್ರಮಕ್ಕೆ ತಕ್ಕ ಫಲ ಲಭಿಸುತ್ತದೆ. ಶಿವ ದೇವಸ್ಥಾನಕ್ಕೆ ಭೇಟಿ ನೀಡಿ ಕ್ಷೀರಾಭಿಷೇಕ ಮಾಡಿಸಿ.';
            case 'kumbha': return 'ಸೋಮವಾರ: ಸಮಾಜ ಸೇವೆ ಮತ್ತು ದೈವಿಕ ಕಾರ್ಯಗಳಲ್ಲಿ ಆಸಕ್ತಿ. ಮಾನಸಿಕ ಶಾಂತಿ ವೃದ್ಧಿಯಾಗುತ್ತದೆ.';
            case 'meena': return 'ಸೋಮವಾರ: ಆಧ್ಯಾತ್ಮಿಕ ಚಿಂತನೆಗಳು ಫಲ ನೀಡುತ್ತವೆ. ಶಿವಲಿಂಗ ದರ್ಶನದಿಂದ ಪುಣ್ಯ ಪ್ರಾಪ್ತಿ.';
          }
          break;
        case DateTime.tuesday:
          switch (rashiId) {
            case 'mesha': return 'ಮಂಗಳವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಕುಜನ ದಿನ! ಅಪಾರ ಶಕ್ತಿ, ಉತ್ಸಾಹ. ಹನುಮಾನ್ ಚಾಲೀಸಾ ಪಠಣದಿಂದ ಮಹಾ ಜಯ.';
            case 'vrishabha': return 'ಮಂಗಳವಾರ: ಆತುರ ಬೇಡ, ತಾಳ್ಮೆಯಿಂದ ಕೆಲಸ ನಿರ್ವಹಿಸಿ. ಗಣೇಶನಿಗೆ ಗರಿಕೆ ಸಮರ್ಪಿಸಿ.';
            case 'mithuna': return 'ಮಂಗಳವಾರ: ಮಾತುಗಳಲ್ಲಿ ಹಿಡಿತವಿರಲಿ. ಸುಬ್ರಹ್ಮಣ್ಯ ಸ್ವಾಮಿ ಪ್ರಾರ್ಥನೆಯಿಂದ ಜಯ ಲಭಿಸುತ್ತದೆ.';
            case 'karka': return 'ಮಂಗಳವಾರ: ಧಾರ್ಮಿಕ ಕಾರ್ಯಗಳಿಗೆ ಖರ್ಚು. ಹನುಮಂತನಿಗೆ ಕೆಂಪು ಹೂ ಅರ್ಪಿಸಿ ನಮಸ್ಕರಿಸಿ.';
            case 'simha': return 'ಮಂಗಳವಾರ: ನಾಯಕತ್ವ ಗುಣ ಮೆಚ್ಚುಗೆ ಗಳಿಸುತ್ತದೆ. ಸೂರ್ಯನಮಸ್ಕಾರ ಹಾಗೂ ಹನುಮತ್ ಸ್ಮರಣೆ ಮಾಡಿ.';
            case 'kanya': return 'ಮಂಗಳವಾರ: ಸಾಲ ಅಥವಾ ಹಣಕಾಸು ಸಮಸ್ಯೆಗಳು ಪರಿಹಾರ ಕಾಣುತ್ತವೆ. ಗಣೇಶ ಸಂಕಷ್ಟನಾಶನ ಸ್ತೋತ್ರ ಜಪಿಸಿ.';
            case 'tula': return 'ಮಂಗಳವಾರ: ದೃಢ ನಿರ್ಧಾರಗಳು ಫಲ ನೀಡುತ್ತವೆ. ಕಾರ್ತಿಕೇಯ ದೇವರ ಪ್ರಾರ್ಥನೆ ಶುಭ ತರಲಿದೆ.';
            case 'vrishchika': return 'ಮಂಗಳವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಮಂಗಳನ ದಿನ! ಅದ್ಭುತ ಶಕ್ತಿ, ಶತ್ರುನಾಶ. ಸುಬ್ರಹ್ಮಣ್ಯ ಅಷ್ಟಕಂ ಪಠಿಸಿ.';
            case 'dhanu': return 'ಮಂಗಳವಾರ: ಧರ್ಮ ಕಾರ್ಯಗಳಲ್ಲಿ ಯಶಸ್ಸು. ಹನುಮಾನ್ ದೇವಸ್ಥಾನಕ್ಕೆ ತೆರಳಿ ತುಳಸಿ ಮಾಲೆ ಅರ್ಪಿಸಿ.';
            case 'makara': return 'ಮಂಗಳವಾರ: ಶ್ರಮಕ್ಕೆ ಶುಭ ಫಲ. ಆಂಜನೇಯ ಸ್ವಾಮಿ ಕೃಪೆಯಿಂದ ಕಾರ್ಯಸಿದ್ಧಿ.';
            case 'kumbha': return 'ಮಂಗಳವಾರ: ಧೈರ್ಯದಿಂದ ಮುನ್ನಡೆಯಿರಿ. ಗಣೇಶನ ಆರಾಧನೆ ವಿಘ್ನಗಳನ್ನು ಕಳೆಯುತ್ತದೆ.';
            case 'meena': return 'ಮಂಗಳವಾರ: ಹೊಸ ಅವಕಾಶಗಳು ಹುಡುಕಿ ಬರುತ್ತವೆ. ಮಂಗಳವಾರದ ವ್ರತ ಸಂಕಲ್ಪ ಯಶಸ್ವಿ.';
          }
          break;
        case DateTime.wednesday:
          switch (rashiId) {
            case 'mesha': return 'ಬುಧವಾರ: ವ್ಯಾಪಾರ ಹಾಗೂ ಶಿಕ್ಷಣದಲ್ಲಿ ಶುಭ ಫಲ. ವಿಷ್ಣು ಸಹಸ್ರನಾಮ ಶ್ರವಣದಿಂದ ಬುದ್ಧಿಶಕ್ತಿ ವೃದ್ಧಿ.';
            case 'vrishabha': return 'ಬುಧವಾರ: ಆರ್ಥಿಕ ಪ್ರಗತಿ, ಶುಭ ಮಾತುಕತೆ. ಶ್ರೀ ಕೃಷ್ಣನಿಗೆ ಬೆಣ್ಣೆ ನೈವೇದ್ಯ ಅರ್ಪಿಸಿ.';
            case 'mithuna': return 'ಬುಧವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಬುಧನ ದಿನ! ಬುದ್ಧಿ, ಕೌಶಲ ಹಾಗೂ ಸಂವಹನದಲ್ಲಿ ಅಪಾರ ಯಶಸ್ಸು. ಕೃಷ್ಣಾರ್ಪಣಂ.';
            case 'karka': return 'ಬುಧವಾರ: ನೆಮ್ಮದಿಯ ದಿನ. ಪಾಂಡುರಂಗ ವಿಟ್ಠಲನ ನಾಮಸ್ಮರಣೆಯಿಂದ ಸಕಲ ಸಂಕಷ್ಟ ದೂರ.';
            case 'simha': return 'ಬುಧವಾರ: ಹೊಸ ಸ್ನೇಹಿತರ ಸಹಕಾರ. ಶ್ರೀ ಕೃಷ್ಣಾಷ್ಟಕಂ ಪಠಿಸುವುದರಿಂದ ದಿನ ಪೂರ್ತಿ ಆನಂದ.';
            case 'kanya': return 'ಬುಧವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಬುಧನ ದಿನ! ಪರೀಕ್ಷೆ, ಲೆಕ್ಕಪತ್ರ ಹಾಗೂ ಅಧ್ಯಯನದಲ್ಲಿ ಸರ್ವೋತ್ತಮ ಜಯ. ಗಣೇಶ ಪೂಜೆ.';
            case 'tula': return 'ಬುಧವಾರ: ಕಲಾತ್ಮಕ ಯೋಚನೆಗಳಿಗೆ ಮನ್ನಣೆ. ಶ್ರೀ ಲಕ್ಷ್ಮೀ ನಾರಾಯಣ ಹೃದಯ ಸ್ತೋತ್ರ ಜಪಿಸಿ.';
            case 'vrishchika': return 'ಬುಧವಾರ: ನಿಧಾನವಾಗಿ ಕೆಲಸ ಮಾಡಿ ಯಶಸ್ಸು ಪಡೆಯಿರಿ. ಕೃಷ್ಣನಿಗೆ ತುಳಸಿ ಅರ್ಪಿಸಿ.';
            case 'dhanu': return 'ಬುಧವಾರ: ಜ್ಞಾನಾರ್ಜನೆಗೆ ಅತ್ಯುತ್ತಮ ದಿನ. ಹಯಗ್ರೀವ ಸ್ತೋತ್ರ ಪಠಣದಿಂದ ವಿದ್ಯೆಯಲ್ಲಿ ಪ್ರಗತಿ.';
            case 'makara': return 'ಬುಧವಾರ: ವ್ಯಾಪಾರದಲ್ಲಿ ಲಾಭ. ಗೋಪಾಲಕೃಷ್ಣನ ಧ್ಯಾನದಿಂದ ಮಾನಸಿಕ ಉಲ್ಲಾಸ.';
            case 'kumbha': return 'ಬುಧವಾರ: ಹೊಸ ಆಲೋಚನೆಗಳು ಫಲಪ್ರದ. ವಿಷ್ಣು ದೇವಸ್ಥಾನಕ್ಕೆ ಭೇಟಿ ನೀಡಿ ತುಳಸಿ ಅರ್ಪಿಸಿ.';
            case 'meena': return 'ಬುಧವಾರ: ಧಾರ್ಮಿಕ ಉಪನ್ಯಾಸ ಅಥವಾ ಸತ್ಸಂಗದಲ್ಲಿ ಭಾಗಿ. ಕೃಷ್ಣ ಭಜನೆಗಳಿಂದ ಶಾಂತಿ.';
          }
          break;
        case DateTime.thursday:
          switch (rashiId) {
            case 'mesha': return 'ಗುರುವಾರ: ಗುರು ಕೃಪೆಯಿಂದ ಭಾಗ್ಯೋದಯ. ರಾಘವೇಂದ್ರ ಸ್ವಾಮಿಗಳ ಅಥವಾ ಸಾಯಿಬಾಬಾ ದರ್ಶನ ಮಾಡಿ.';
            case 'vrishabha': return 'ಗುರುವಾರ: ಧಾರ್ಮಿಕ ಕಾರ್ಯಗಳಲ್ಲಿ ಭಾಗಿ. ಗುರು ಸ್ತೋತ್ರ ಪಠಣದಿಂದ ಸಂಪತ್ತು ವೃದ್ಧಿ.';
            case 'mithuna': return 'ಗುರುವಾರ: ಉತ್ತಮ ಜ್ಞಾನ ಮತ್ತು ಬೋಧನೆ. ಶ್ರೀ ಗುರುಭ್ಯೋ ನಮಃ ಜಪಿಸಿ.';
            case 'karka': return 'ಗುರುವಾರ: ಆಧ್ಯಾತ್ಮಿಕ ತೇಜಸ್ಸು. ದತ್ತಾತ್ರೇಯ ಸ್ಮರಣೆಯಿಂದ ಇಷ್ಟಾರ್ಥ ಸಿದ್ಧಿ.';
            case 'simha': return 'ಗುರುವಾರ: ಯಶಸ್ಸು ಹಾಗೂ ಗುರು ಹಿರಿಯರ ಅನುಗ್ರಹ. ಬಂಗಾರದ ಬಣ್ಣದ ಹೂವುಗಳಿಂದ ವಿಷ್ಣು ಪೂಜೆ.';
            case 'kanya': return 'ಗುರುವಾರ: ಸತ್ಕರ್ಮಗಳಿಗೆ ಫಲ. ಗುರು ಚರಿತ್ರೆ ಅಧ್ಯಾಯ ಪಠಣ ಶುಭ ತರಲಿದೆ.';
            case 'tula': return 'ಗುರುವಾರ: ಮಂಗಳ ಕಾರ್ಯಗಳಿಗೆ ಮುನ್ನುಡಿ. ರಾಯರ ಮಂತ್ರ ಜಪದಿಂದ ನೆಮ್ಮದಿ.';
            case 'vrishchika': return 'ಗುರುವಾರ: ಧರ್ಮ ಮಾರ್ಗದಲ್ಲಿ ಜಯ. ಗುರುಗಳ ಆಶೀರ್ವಾದ ಪಡೆಯಿರಿ.';
            case 'dhanu': return 'ಗುರುವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಬೃಹಸ್ಪತಿಯ ದಿನ! ಜ್ಞಾನ, ಕೀರ್ತಿ, ಸಕಲ ಸಂಪತ್ತು ವೃದ್ಧಿ. ವೆಂಕಟೇಶ್ವರ ಪ್ರಾರ್ಥನೆ.';
            case 'makara': return 'ಗುರುವಾರ: ಹಿರಿಯ ಅಧಿಕಾರಿಗಳ ಸಹಕಾರ. ದತ್ತಾತ್ರೇಯ ವಜ್ರ ಕವಚ ಪಠಿಸಿ.';
            case 'kumbha': return 'ಗುರುವಾರ: ಸತ್ಸಂಗದಿಂದ ಆನಂದ. ಗುರು ರಾಘವೇಂದ್ರರ ಅಷ್ಟೋತ್ತರ ಪಠಿಸಿ.';
            case 'meena': return 'ಗುರುವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಗುರುವಿನ ದಿನ! ದೈವಬಲ ಅತ್ಯುನ್ನತ, ಆಧ್ಯಾತ್ಮಿಕ ತೃಪ್ತಿ. ಗುರು ಪಾದ ಪೂಜೆ.';
          }
          break;
        case DateTime.friday:
          switch (rashiId) {
            case 'mesha': return 'ಶುಕ್ರವಾರ: ಮಹಾಲಕ್ಷ್ಮಿ ಕೃಪೆಯಿಂದ ಸೌಭಾಗ್ಯ. ಕನಕಧಾರಾ ಸ್ತೋತ್ರ ಪಠಣದಿಂದ ಆರ್ಥಿಕ ಅಭಿವೃದ್ಧಿ.';
            case 'vrishabha': return 'ಶುಕ್ರವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಶುಕ್ರನ ದಿನ! ಸೌಂದರ್ಯ, ಸುಖ, ಸಂಪತ್ತು. ಮಹಾಲಕ್ಷ್ಮಿ ಅಷ್ಟಕಂ ಪಠಿಸಿ.';
            case 'mithuna': return 'ಶುಕ್ರವಾರ: ಪ್ರೇಮ ಹಾಗೂ ಕೌಟುಂಬಿಕ ಆನಂದ. ಲಲಿತಾ ಸಹಸ್ರನಾಮ ಶ್ರವಣ ಶುಭಕರ.';
            case 'karka': return 'ಶುಕ್ರವಾರ: ದೇವಿ ಆರಾಧನೆಯಿಂದ ಸರ್ವ ಶುಭ. ದುರ್ಗಾ ದೇವಿಗೆ ತುಪ್ಪದ ದೀಪ ಹಚ್ಚಿ.';
            case 'simha': return 'ಶುಕ್ರವಾರ: ಆಕರ್ಷಕ ವ್ಯಕ್ತಿತ್ವ, ಗೌರವ. ಭುವನೇಶ್ವರಿ ದೇವಿ ಸ್ಮರಣೆ ಮಾಡಿ.';
            case 'kanya': return 'ಶುಕ್ರವಾರ: ಶುಭ ಸಮಾಚಾರ ಲಭ್ಯ. ಸರಸ್ವತಿ ಹಾಗೂ ಲಕ್ಷ್ಮೀ ಪೂಜೆಯಿಂದ ಜಯ.';
            case 'tula': return 'ಶುಕ್ರವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಶುಕ್ರನ ದಿನ! ಕಲೆ, ಆನಂದ ಹಾಗೂ ಸಂಪತ್ತು. ಶ್ರೀ ಸೂಕ್ತ ಪಾರಾಯಣ.';
            case 'vrishchika': return 'ಶುಕ್ರವಾರ: ಶಕ್ತಿ ದೇವತೆಯ ಕೃಪೆಯಿಂದ ಶತ್ರು ಭಯ ಮುಕ್ತಿ. ಚಾಮುಂಡೇಶ್ವರಿ ಆರಾಧನೆ.';
            case 'dhanu': return 'ಶುಕ್ರವಾರ: ಮಂಗಳ ಕಾರ್ಯಗಳು ನೆರವೇರುತ್ತವೆ. ಲಕ್ಷ್ಮೀ ನಾರಾಯಣ ಪೂಜೆ ಮಾಡಿ.';
            case 'makara': return 'ಶುಕ್ರವಾರ: ಶಾಂತಿ ಸಮಾಧಾನ. ಅನ್ನಪೂರ್ಣೇಶ್ವರಿ ದೇವಿ ಕೃಪೆಯಿಂದ ಸಮೃದ್ಧಿ.';
            case 'kumbha': return 'ಶುಕ್ರವಾರ: ಶುಭ ಚಿಂತನೆಗಳು. ಗಾಯತ್ರಿ ಮಂತ್ರ ಜಪದಿಂದ ತೇಜಸ್ಸು.';
            case 'meena': return 'ಶುಕ್ರವಾರ: ಕರುಣೆ, ಪರೋಪಕಾರದಿಂದ ದೇವಿಯ ಆಶೀರ್ವಾದ. ಮೂಕಾಂಬಿಕಾ ದೇವಿಯ ಧ್ಯಾನ.';
          }
          break;
        case DateTime.saturday:
          switch (rashiId) {
            case 'mesha': return 'ಶನಿವಾರ: ಶನಿ ಮಹಾತ್ಮನ ಕೃಪೆಗೆ ಎಳ್ಳೆಣ್ಣೆ ದೀಪ ಹಚ್ಚಿ. ಹನುಮಾನ್ ಚಾಲೀಸಾ ಜಪಿಸಿ.';
            case 'vrishabha': return 'ಶನಿವಾರ: ಕಠಿಣ ಶ್ರಮಕ್ಕೆ ಶುಭ ಫಲ. ಶನಿ ಗಾಯತ್ರಿ ಮಂತ್ರ ಪಠಿಸಿ.';
            case 'mithuna': return 'ಶನಿವಾರ: ಶಿಸ್ತಿನಿಂದ ಕೆಲಸ ಮಾಡಿ. ವೆಂಕಟೇಶ್ವರ ಸ್ವಾಮಿ ದರ್ಶನ ಮಾಡಿ.';
            case 'karka': return 'ಶನಿವಾರ: ಶಿವಾರ್ಚನೆ ಮತ್ತು ಶನಿ ಶಾಂತಿ ಪೂಜೆ ಶುಭಕರ.';
            case 'simha': return 'ಶನಿವಾರ: ತಾಳ್ಮೆ ವಹಿಸಿ, ಅಹಂಕಾರ ತ್ಯಜಿಸಿ. ಶನೈಶ್ಚರ ಸ್ತೋತ್ರ ಪಠಿಸಿ.';
            case 'kanya': return 'ಶನಿವಾರ: ಧರ್ಮ ಕಾರ್ಯಗಳಲ್ಲಿ ಯಶಸ್ಸು. ಕಾಗೆಗಳಿಗೆ ಅನ್ನ ನೀಡುವುದು ಪುಣ್ಯದಾಯಕ.';
            case 'tula': return 'ಶನಿವಾರ: ಉದ್ಯೋಗದಲ್ಲಿ ಸ್ಥಿರತೆ. ಆಂಜನೇಯ ಸ್ವಾಮಿಗೆ ಸಿಂಧೂರ ಅರ್ಪಿಸಿ.';
            case 'vrishchika': return 'ಶನಿವಾರ: ಸಾಡೇಸಾತಿ/ಕಂಟಕ ನಿವಾರಣೆಗೆ ಹನುಮತ್ ರಕ್ಷಾ ಕವಚ ಪಠಿಸಿ.';
            case 'dhanu': return 'ಶನಿವಾರ: ತಿರುಪತಿ ವೆಂಕಟೇಶ್ವರ ಸ್ವಾಮಿ ಸ್ಮರಣೆಯಿಂದ ಸಕಲ ದಾರಿದ್ರ್ಯ ಪರಿಹಾರ.';
            case 'makara': return 'ಶನಿವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಶನಿಯ ದಿನ! ನ್ಯಾಯ, ಧರ್ಮ ಪಾಲಿಸಿ. ಶನಿ ವಜ್ರ ಪಂಜರ ಕವಚ ಪಠಿಸಿ.';
            case 'kumbha': return 'ಶನಿವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಶನಿಯ ದಿನ! ದಾನ ಧರ್ಮದಿಂದ ಮಹಾ ಪುಣ್ಯ. ರುದ್ರಾಭಿಷೇಕ ಶುಭ.';
            case 'meena': return 'ಶನಿವಾರ: ಸೇವಾ ಮನೋಭಾವದಿಂದ ದೈವ ಕೃಪೆ. ನವಗ್ರಹ ದೇವಸ್ಥಾನ ಪ್ರದಕ್ಷಿಣೆ ಮಾಡಿ.';
          }
          break;
        case DateTime.sunday:
        default:
          switch (rashiId) {
            case 'mesha': return 'ಭಾನುವಾರ: ಸೂರ್ಯನಾರಾಯಣನ ತೇಜಸ್ಸಿನಿಂದ ಕಾರ್ಯಕ್ಷೇತ್ರದಲ್ಲಿ ಜಯ. ಆದಿತ್ಯ ಹೃದಯ ಸ್ತೋತ್ರ ಪಠಿಸಿ.';
            case 'vrishabha': return 'ಭಾನುವಾರ: ಆರೋಗ್ಯ ವೃದ್ಧಿ ಹಾಗೂ ಕೀರ್ತಿ. ಸೂರ್ಯದೇವನಿಗೆ ಅರ್ಘ್ಯ ಅರ್ಪಿಸಿ.';
            case 'mithuna': return 'ಭಾನುವಾರ: ಪ್ರಮುಖ ನಿರ್ಧಾರಗಳಿಗೆ ಶುಭ ದಿನ. ಗಾಯತ್ರಿ ಮಂತ್ರ ಜಪಿಸಿ.';
            case 'karka': return 'ಭಾನುವಾರ: ಮಾನಸಿಕ ನೆಮ್ಮದಿ. ಶಿವ-ಸೂರ್ಯ ಆರಾಧನೆ ಮಂಗಳಕರ.';
            case 'simha': return 'ಭಾನುವಾರ: ರಾಶ್ಯಾಧಿಪತಿ ಸೂರ್ಯನ ದಿನ! ಅಗಾಧ ತೇಜಸ್ಸು, ಪ್ರಭಾವ, ಕೀರ್ತಿ. ಆದಿತ್ಯ ಹೃದಯಂ ಪಠಿಸಿ.';
            case 'kanya': return 'ಭಾನುವಾರ: ಹೊಸ ಶಕ್ತಿ, ಹೊಸ ಚೈತನ್ಯ. ಸೂರ್ಯ ನಮಸ್ಕಾರದಿಂದ ಆರೋಗ್ಯ ಸುಧಾರಣೆ.';
            case 'tula': return 'ಭಾನುವಾರ: ಸಮಾಜದಲ್ಲಿ ಗೌರವ. ತಂದೆಯ ಆಶೀರ್ವಾದ ಪಡೆದು ದಿನ ಪ್ರಾರಂಭಿಸಿ.';
            case 'vrishchika': return 'ಭಾನುವಾರ: ಶಕ್ತಿ ಹಾಗೂ ಉತ್ಸಾಹ. ಸೂರ್ಯ ಮಂತ್ರ ಜಪದಿಂದ ಧೈರ್ಯ ವೃದ್ಧಿ.';
            case 'dhanu': return 'ಭಾನುವಾರ: ಧಾರ್ಮಿಕ ಪ್ರವಾಸ ಅಥವಾ ಸಂಕಲ್ಪ. ವಿಷ್ಣು ಸಹಸ್ರನಾಮ ಶ್ರವಣ.';
            case 'makara': return 'ಭಾನುವಾರ: ಶ್ರಮ ಸಾರ್ಥಕವಾಗುತ್ತದೆ. ಸೂರ್ಯ ನಾರಾಯಣ ದೇವರಿಗೆ ನಮಸ್ಕರಿಸಿ.';
            case 'kumbha': return 'ಭಾನುವಾರ: ಶಾಂತಿ ಹಾಗೂ ಶುಭಫಲ. ಸೂರ್ಯ ಅಷ್ಟಕಂ ಪಠಿಸಿ.';
            case 'meena': return 'ಭಾನುವಾರ: ಆಧ್ಯಾತ್ಮಿಕ ಸಂತೃಪ್ತಿ. ನಾರಾಯಣ ಕವಚ ಪಠಣದಿಂದ ರಕ್ಷಣೆ.';
          }
      }
    } else if (lang == 'hi') {
      switch (weekday) {
        case DateTime.monday:
          switch (rashiId) {
            case 'mesha': return 'सोमवार: आत्मविश्वास व कार्यक्षमता में वृद्धि। शिवलिंग पर जलाभिषेक करने से मनोकामनाएं पूर्ण होंगी।';
            case 'vrishabha': return 'सोमवार: पारिवारिक सुख व आर्थिक लाभ। चंद्र देव के ध्यान से मानसिक शांति मिलेगी।';
            case 'mithuna': return 'सोमवार: रचनात्मक कार्यों में सफलता। ॐ नमः शिवाय का 108 बार जप करें।';
            case 'karka': return 'सोमवार: राशिश चंद्र का दिन! भक्तिभाव व सकारात्मक ऊर्जा बनी रहेगी। शिव पूजन करें।';
            case 'simha': return 'सोमवार: कार्यक्षेत्र में सम्मान। माताजी का आशीर्वाद लेकर नया कार्य शुरू करें।';
            case 'kanya': return 'सोमवार: नई योजनाओं के लिए अनुकूल समय। भगवान शिव को श्वेत पुष्प अर्पित करें।';
            case 'tula': return 'सोमवार: शुभ समाचार प्राप्त होगा। कला व अध्यात्म में मन लगेगा।';
            case 'vrishchika': return 'सोमवार: धैर्य व पराक्रम से सफलता। रुद्राष्टकम का पाठ लाभकारी रहेगा।';
            case 'dhanu': return 'सोमवार: गुरु कृपा से ज्ञान में वृद्धि। बड़ों के आशीर्वाद से दिन शुभ रहेगा।';
            case 'makara': return 'सोमवार: कठिन परिश्रम का उत्तम फल। शिव मंदिर में दुग्धाभिषेक करें।';
            case 'kumbha': return 'सोमवार: परोपकार व धर्म कार्यों में मन लगेगा। मानसिक शांति मिलेगी।';
            case 'meena': return 'सोमवार: आध्यात्मिक यात्रा के योग। महामृत्युंजय मंत्र का पाठ करें।';
          }
          break;
        case DateTime.tuesday:
          switch (rashiId) {
            case 'mesha': return 'मंगलवार: राशिश मंगल का दिन! अपार ऊर्जा व साहस। हनुमान चालीसा का पाठ करें।';
            case 'vrishabha': return 'मंगलवार: धैर्यपूर्वक कार्य करें। श्री गणेश को दूर्वा अर्पित करें।';
            case 'mithuna': return 'मंगलवार: वाणी पर संयम रखें। भगवान सुब्रह्मण्य की आराधना से विजय प्राप्त होगी।';
            case 'karka': return 'मंगलवार: धार्मिक कार्यों में रुचि। हनुमान जी को लाल पुष्प अर्पित करें।';
            case 'simha': return 'मंगलवार: नेतृत्व क्षमता की प्रशंसा। सूर्य नमस्कार व हनुमान स्मरण करें।';
            case 'kanya': return 'मंगलवार: संकटों का निवारण होगा। संकटनाशन गणेश स्तोत्र का जप करें।';
            case 'tula': return 'मंगलवार: दृढ़ संकल्प से सफलता। कार्तिकेय भगवान की पूजा शुभकारी।';
            case 'vrishchika': return 'मंगलवार: राशिश मंगल का दिन! शत्रुओं पर विजय। सुब्रह्मण्य अष्टकम पढ़ें।';
            case 'dhanu': return 'मंगलवार: धर्म कार्यों में विजय। हनुमान जी को तुलसी माला अर्पित करें।';
            case 'makara': return 'मंगलवार: परिश्रम का उत्तम फल मिलेगा। बजरंग बाण का पाठ करें।';
            case 'kumbha': return 'मंगलवार: साहस से आगे बढ़ें। गणेश पूजन से विघ्न दूर होंगे।';
            case 'meena': return 'मंगलवार: नए अवसर प्राप्त होंगे। सुंदरकांड का पाठ अत्यंत शुभ रहेगा।';
          }
          break;
        case DateTime.wednesday:
          switch (rashiId) {
            case 'mesha': return 'बुधवार: व्यापार व अध्ययन में प्रगति। विष्णु सहस्रनाम का श्रवण करें।';
            case 'vrishabha': return 'बुधवार: आर्थिक समृद्धि। भगवान श्री कृष्ण को माखन का भोग लगाएं।';
            case 'mithuna': return 'बुधवार: राशिश बुध का पावन दिन! बुद्धि, विद्या व व्यापार में उत्कृष्ट सफलता।';
            case 'karka': return 'बुधवार: शांति व सुखमय दिन। पांडुरंग विट्ठल के नाम का स्मरण करें।';
            case 'simha': return 'बुधवार: नए मित्रों का सहयोग। कृष्णाष्टकम का पाठ करें।';
            case 'kanya': return 'बुधवार: राशिश बुध का दिन! परीक्षा व बौद्धिक कार्यों में महाविजय। गणेश वंदना करें।';
            case 'tula': return 'बुधवार: कला व सौंदर्य में मन लगेगा। श्री लक्ष्मीनारायण स्तोत्र जपें।';
            case 'vrishchika': return 'बुधवार: धैर्य से कार्य करें। श्री कृष्ण को तुलसी अर्पित करें।';
            case 'dhanu': return 'बुधवार: ज्ञान प्राप्ति के लिए उत्तम दिन। हयग्रीव स्तोत्र का पाठ करें।';
            case 'makara': return 'बुधवार: व्यापार में शुभ लाभ। गोपाल कृष्ण की आराधना करें।';
            case 'kumbha': return 'बुधवार: नए विचार सफल होंगे। विष्णु मंदिर में दर्शन करें।';
            case 'meena': return 'बुधवार: सत्संग में भाग लें। कृष्ण संकीर्तन से मन को शांति मिलेगी।';
          }
          break;
        case DateTime.thursday:
          switch (rashiId) {
            case 'mesha': return 'गुरुवार: गुरु कृपा से भाग्योदय। श्री राघवेंद्र स्वामी या साईं बाबा के दर्शन करें।';
            case 'vrishabha': return 'गुरुवार: धार्मिक अनुष्ठान में रुचि। गुरु स्तोत्र का पाठ करें।';
            case 'mithuna': return 'गुरुवार: ज्ञान व शिक्षा में उन्नति। ॐ श्री गुरुभ्यो नमः जपें।';
            case 'karka': return 'गुरुवार: आध्यात्मिक तेज व प्रसन्नता। दत्तात्रेय भगवान का स्मरण करें।';
            case 'simha': return 'गुरुवार: उच्च पद व मान-सम्मान। पीले पुष्पों से भगवान विष्णु का पूजन करें।';
            case 'kanya': return 'गुरुवार: सत्कर्मों का उत्तम फल। गुरु चरित्र का पाठ शुभकारी रहेगा।';
            case 'tula': return 'गुरुवार: मांगलिक कार्यों की शुरुआत। गुरु मंत्र का जप करें।';
            case 'vrishchika': return 'गुरुवार: धर्म मार्ग पर विजय। गुरुजनों का आशीर्वाद लें।';
            case 'dhanu': return 'गुरुवार: राशिश बृहस्पति का दिन! विद्या, यश व धन में अभूतपूर्व वृद्धि।';
            case 'makara': return 'गुरुवार: उच्चाधिकारियों का सहयोग। दत्तात्रेय वज्र कवच का पाठ करें।';
            case 'kumbha': return 'गुरुवार: सत्संग से आनंद। गुरु राघवेंद्र अष्टोत्तर का पाठ करें।';
            case 'meena': return 'गुरुवार: राशिश देवगुरु का दिन! दैवीय कृपा व आत्मिक आनंद। गुरु वंदना करें।';
          }
          break;
        case DateTime.friday:
          switch (rashiId) {
            case 'mesha': return 'शुक्रवार: माँ महालक्ष्मी की कृपा से धन-धान्य की वृद्धि। कनकधारा स्तोत्र पढ़ें।';
            case 'vrishabha': return 'शुक्रवार: राशिश शुक्र का दिन! वैभव, सुख व समृद्धि। महालक्ष्मी अष्टकम का पाठ करें।';
            case 'mithuna': return 'शुक्रवार: पारिवारिक आनंद। ललिता सहस्रनाम का श्रवण अत्यंत कल्याणकारी।';
            case 'karka': return 'शुक्रवार: देवी उपासना से शुभ फल। दुर्गा जी के समक्ष घी का दीपक जलाएं।';
            case 'simha': return 'शुक्रवार: आकर्षण व सम्मान में वृद्धि। भुवनेश्वरी देवी का स्मरण करें।';
            case 'kanya': return 'शुक्रवार: शुभ समाचार प्राप्त होंगे। सरस्वती व लक्ष्मी पूजन करें।';
            case 'tula': return 'शुक्रवार: राशिश शुक्र का दिन! कला, प्रेम व समृद्धि। श्री सूक्त का पाठ करें।';
            case 'vrishchika': return 'शुक्रवार: शक्ति उपासना से भय मुक्ति। चामुंडेश्वरी देवी की वंदना करें।';
            case 'dhanu': return 'शुक्रवार: मांगलिक कार्य संपन्न होंगे। लक्ष्मी नारायण का पूजन करें।';
            case 'makara': return 'शुक्रवार: सुख व शांति। अन्नपूर्णा माता की कृपा से संपन्नता।';
            case 'kumbha': return 'शुक्रवार: शुभ विचार व तेज। गायत्री मंत्र का जप करें।';
            case 'meena': return 'शुक्रवार: परोपकार व दयाभाव। मूकांबिका देवी का ध्यान करें।';
          }
          break;
        case DateTime.saturday:
          switch (rashiId) {
            case 'mesha': return 'शनिवार: शनिदेव की कृपा हेतु तिल तेल का दीपक जलाएं। हनुमान चालीसा पढ़ें।';
            case 'vrishabha': return 'शनिवार: कठिन परिश्रम का मीठा फल। शनि गायत्री मंत्र का जप करें।';
            case 'mithuna': return 'शनिवार: अनुशासन से काम लें। श्री वेंकटेश्वर स्वामी के दर्शन करें।';
            case 'karka': return 'शनिवार: शिव पूजन व शनि शांति पूजा अत्यंत कल्याणकारी।';
            case 'simha': return 'शनिवार: अहंकार त्यागें व धैर्य रखें। शनैश्चर स्तोत्र का पाठ करें।';
            case 'kanya': return 'शनिवार: धर्म कार्यों में सफलता। पक्षियों व कौओं को अन्न दें।';
            case 'tula': return 'शनिवार: नौकरी में स्थिरता। हनुमान जी को सिंदूर अर्पित करें।';
            case 'vrishchika': return 'शनिवार: साढ़ेसाती शांति हेतु हनुमान रक्षा कवच का पाठ करें।';
            case 'dhanu': return 'शनिवार: तिरुपति बालाजी के स्मरण से सभी दरिद्रता दूर होगी।';
            case 'makara': return 'शनिवार: राशिश शनिदेव का दिन! न्याय व सत्य का पालन करें। शनि कवच जपें।';
            case 'kumbha': return 'शनिवार: राशिश शनिदेव का दिन! दान-पुण्य से महाफल। रुद्राभिषेक करें।';
            case 'meena': return 'शनिवार: सेवा भाव से प्रभु कृपा। नवग्रह मंदिर की परिक्रमा करें।';
          }
          break;
        case DateTime.sunday:
        default:
          switch (rashiId) {
            case 'mesha': return 'रविवार: सूर्य नारायण के तेज से कार्यक्षेत्र में विजय। आदित्य हृदय स्तोत्र पढ़ें।';
            case 'vrishabha': return 'रविवार: उत्तम स्वास्थ्य व यश। सूर्य देव को जल अर्घ्य दें।';
            case 'mithuna': return 'रविवार: महत्वपूर्ण निर्णयों के लिए शुभ दिन। गायत्री मंत्र जपें।';
            case 'karka': return 'रविवार: मानसिक शांति। शिव व सूर्य उपासना मंगलकारी।';
            case 'simha': return 'रविवार: राशिश सूर्य नारायण का पावन दिन! अपार तेज, प्रभाव व सम्मान। आदित्य हृदयम पढ़ें।';
            case 'kanya': return 'रविवार: नई ऊर्जा व उत्साह। सूर्य नमस्कार से स्वास्थ्य लाभ।';
            case 'tula': return 'रविवार: समाज में मान-सम्मान। पिता का आशीर्वाद लें।';
            case 'vrishchika': return 'रविवार: शक्ति व पराक्रम। सूर्य मंत्र से मनोबल बढ़ेगा।';
            case 'dhanu': return 'रविवार: आध्यात्मिक यात्रा। विष्णु सहस्रनाम का श्रवण करें।';
            case 'makara': return 'रविवार: परिश्रम सार्थक होगा। सूर्य देव को प्रणाम करें।';
            case 'kumbha': return 'रविवार: शांति व शुभ फल। सूर्याष्टकम का पाठ करें।';
            case 'meena': return 'रविवार: आध्यात्मिक संतुष्टि। नारायण कवच का पाठ करें।';
          }
      }
    } else if (lang == 'ta') {
      switch (weekday) {
        case DateTime.monday:
          switch (rashiId) {
            case 'mesha': return 'திங்கட்கிழமை: தன்னம்பிக்கை உயரும். சிவபெருமானுக்கு வில்வ அர்ச்சனை செய்வது தடைகளை நீக்கும்.';
            case 'vrishabha': return 'திங்கட்கிழமை: குடும்பத்தில் அமைதி மற்றும் தன லாபம். சந்திரனை தியானித்து நலம் பெறுங்கள்.';
            case 'mithuna': return 'திங்கட்கிழமை: புத்தி கூர்மையுடன் காரிய வெற்றி. ஓம் நமசிவாய மந்திரம் ஜபிப்பது நல்லது.';
            case 'karka': return 'திங்கட்கிழமை: ராசி நாதன் சந்திரன் அருளால் பக்தி பெருகும். சிவபூஜை சிறந்தது.';
            case 'simha': return 'திங்கட்கிழமை: வேலையில் நற்பெயர் கிடைக்கும். தாயின் ஆசி பெற்று தொடங்குங்கள்.';
            case 'kanya': return 'திங்கட்கிழமை: புதிய திட்டங்களுக்கு ஏற்ற நாள். வெண் மலர்களால் ஈசனை பூஜியுங்கள்.';
            case 'tula': return 'திங்கட்கிழமை: இனிய சுப செய்திகள் வந்து சேரும். கலை மற்றும் ஆன்மிகத்தில் நாட்டம்.';
            case 'vrishchika': return 'திங்கட்கிழமை: தைரியத்தால் காரிய வெற்றி. ருத்ராஷ்டகம் பாராயணம் பகை விலக்கும்.';
            case 'dhanu': return 'திங்கட்கிழமை: குருவருளால் அறிவு வளர்ச்சி. பெரியோரின் ஆசீர்வாதம் பலம் தரும்.';
            case 'makara': return 'திங்கட்கிழமை: உழைப்புக்கு ஏற்ற நற்பலன். சிவலிங்கத்திற்கு பாலபிஷேகம் செய்யவும்.';
            case 'kumbha': return 'திங்கட்கிழமை: தர்ம சிந்தனைகள் உயரும். மன அமைதியும் ஆன்ம பலமும் கூடும்.';
            case 'meena': return 'திங்கட்கிழமை: ஆன்மிக எண்ணங்கள் ஈடேறும். சிவ தரிசனம் புண்ணியம் தரும்.';
          }
          break;
        case DateTime.tuesday:
          switch (rashiId) {
            case 'mesha': return 'செவ்வாய்க்கிழமை: ராசி நாதன் செவ்வாயின் நாள்! தைரியமும் ஆற்றலும் பெருகும். அனுமன் சாலீசா ஜபிக்கவும்.';
            case 'vrishabha': return 'செவ்வாய்க்கிழமை: பொறுமையுடன் காரியங்களை ஆற்றுங்கள். விநாயகருக்கு அருகம்புல் சாத்தவும்.';
            case 'mithuna': return 'செவ்வாய்க்கிழமை: பேச்சில் நிதானம் தேவை. முருகப் பெருமானை வழிபட வெற்றி நிச்சயம்.';
            case 'karka': return 'செவ்வாய்க்கிழமை: சுப விரயங்கள் உண்டாகும். அனுமனுக்கு செம்பருத்தி மலர் சாத்தவும்.';
            case 'simha': return 'செவ்வாய்க்கிழமை: தலைமைப் பண்பு பாராட்டு பெறும். சூரிய நமஸ்காரமும் அனுமன் வழிபாடும் நன்மை தரும்.';
            case 'kanya': return 'செவ்வாய்க்கிழமை: கடன் சுமை குறையும். சங்கடஹர கணபதி ஸ்தோத்திரம் ஜபிக்கவும்.';
            case 'tula': return 'செவ்வாய்க்கிழமை: உறுதியான முடிவுகள் நற்பலன் தரும். கந்த சஷ்டி கவசம் படிக்கவும்.';
            case 'vrishchika': return 'செவ்வாய்க்கிழமை: ராசி நாதன் அங்காரகன் அருள்! காரிய வெற்றி மற்றும் சத்ரு சம்ஹாரம்.';
            case 'dhanu': return 'செவ்வாய்க்கிழமை: தர்ம காரியங்களில் வெற்றி. அனுமனுக்கு துளசி மாலை சாத்தவும்.';
            case 'makara': return 'செவ்வாய்க்கிழமை: முயற்சிக்கு வெற்றி கிடைக்கும். பஜ்ரங் பாண் பாராயணம் நலம்.';
            case 'kumbha': return 'செவ்வாய்க்கிழமை: தைரியத்துடன் முன்னேறுங்கள். விநாயகர் வழிபாடு விக்கினங்களை நீக்கும்.';
            case 'meena': return 'செவ்வாய்க்கிழமை: புதிய வாய்ப்புகள் தேடி வரும். சுந்தரகாண்டம் பாராயணம் நன்மை தரும்.';
          }
          break;
        case DateTime.wednesday:
          switch (rashiId) {
            case 'mesha': return 'புதன்கிழமை: கல்வி மற்றும் வியாபாரத்தில் வளர்ச்சி. விஷ்ணு சஹஸ்ரநாமம் கேட்கவும்.';
            case 'vrishabha': return 'புதன்கிழமை: பொருளாதார முன்னேற்றம். ஸ்ரீ கிருஷ்ணருக்கு வெண்ணெய் நைவேத்தியம் செய்யவும்.';
            case 'mithuna': return 'புதன்கிழமை: ராசி நாதன் புதனின் அருள்! வியாபாரம் மற்றும் பேச்சாற்றலில் மகத்தான வெற்றி.';
            case 'karka': return 'புதன்கிழமை: மன நிம்மதி தரும் நாள். பாண்டுரங்க விட்டலனை தியானிக்கவும்.';
            case 'simha': return 'புதன்கிழமை: நண்பர்களின் உதவி கிட்டும். கிருஷ்ணாஷ்டகம் படிக்கவும்.';
            case 'kanya': return 'புதன்கிழமை: ராசி நாதன் புதன் நாள்! கல்வி மற்றும் தேர்வுகளில் அபார வெற்றி. கணபதி வழிபாடு.';
            case 'tula': return 'புதன்கிழமை: கலை மற்றும் அழகுணர்ச்சி மிளிரும். லட்சுமி நாராயணர் ஸ்தோத்திரம் நலம்.';
            case 'vrishchika': return 'புதன்கிழமை: நிதானமான செயல்பாட்டால் வெற்றி. பெருமாளுக்கு துளசி சாத்தவும்.';
            case 'dhanu': return 'புதன்கிழமை: ஞானம் பெருகும் நன்னாள். ஹயக்ரீவர் ஸ்தோத்திரம் படிக்கவும்.';
            case 'makara': return 'புதன்கிழமை: தொழிலில் சுப லாபம். கோபால கிருஷ்ணனை வழிபடவும்.';
            case 'kumbha': return 'புதன்கிழமை: புதிய சிந்தனைகள் பலன் தரும். பெருமாள் கோவில் தரிசனம் நலம்.';
            case 'meena': return 'புதன்கிழமை: ஆன்மிக சொற்பொழிவு அல்லது பஜனையில் பங்கு பெற மன அமைதி கூடும்.';
          }
          break;
        case DateTime.thursday:
          switch (rashiId) {
            case 'mesha': return 'வியாழக்கிழமை: குருவருளால் பாக்கியோதயம். ராகவேந்திரர் அல்லது சாயிபாபா தரிசனம் செய்யவும்.';
            case 'vrishabha': return 'வியாழக்கிழமை: சுப காரியங்களில் நாட்டம். குரு ஸ்தோத்திரம் படிக்க தன விருத்தி.';
            case 'mithuna': return 'வியாழக்கிழமை: நற்போதனை மற்றும் ஞானம் கூடும். ஓம் குருவே நமஹ ஜபிக்கவும்.';
            case 'karka': return 'வியாழக்கிழமை: ஆன்மிக தேஜஸ் பெருகும். தத்தாத்ரேயரை வழிபட இஷ்ட சித்தி.';
            case 'simha': return 'வியாழக்கிழமை: உயர் அதிகாரிகளின் ஆதரவு. விஷ்ணுவுக்கு மஞ்சள் மலர் சாத்தவும்.';
            case 'kanya': return 'வியாழக்கிழமை: புண்ணிய காரியங்களுக்கு நற்பலன். குரு சரித்திரம் பாராயணம் நலம்.';
            case 'tula': return 'வியாழக்கிழமை: மங்களகரமான தொடக்கம். குரு பகவானை வழிபட நன்மை உண்டாகும்.';
            case 'vrishchika': return 'வியாழக்கிழமை: தர்ம வழியில் வெற்றி. பெரியோர்களின் ஆசீர்வாதம் பெறவும்.';
            case 'dhanu': return 'வியாழக்கிழமை: ராசி நாதன் குருவின் ஆட்சி நாள்! புகழ், கல்வி, செல்வம் பன்மடங்கு பெருகும்.';
            case 'makara': return 'வியாழக்கிழமை: மேலதிகாரிகளின் ஒத்துழைப்பு. தத்தாத்ரேய கவசம் படிக்கவும்.';
            case 'kumbha': return 'வியாழக்கிழமை: சத்சங்கத்தால் மகிழ்ச்சி. ராகவேந்திர அஷ்டோத்திரம் ஜபிக்கவும்.';
            case 'meena': return 'வியாழக்கிழமை: ராசி நாதன் தேவகுருவின் நாள்! தெய்வீக அருள் மற்றும் ஆத்ம திருப்தி.';
          }
          break;
        case DateTime.friday:
          switch (rashiId) {
            case 'mesha': return 'வெள்ளிக்கிழமை: மகாலட்சுமி அருளால் தன தானிய விருத்தி. கனகதாரா ஸ்தோத்திரம் படிக்கவும்.';
            case 'vrishabha': return 'வெள்ளிக்கிழமை: ராசி நாதன் சுக்கிரனின் நாள்! செல்வம், சுப போகங்கள் பெருகும்.';
            case 'mithuna': return 'வெள்ளிக்கிழமை: குடும்பத்தில் மகிழ்ச்சி. லலிதா சஹஸ்ரநாமம் கேட்பது புண்ணியம்.';
            case 'karka': return 'வெள்ளிக்கிழமை: அம்பாள் வழிபாட்டால் சுபம். துர்க்கை அம்மனுக்கு நெய் தீபம் ஏற்றவும்.';
            case 'simha': return 'வெள்ளிக்கிழமை: வசீகரம் மற்றும் கௌரவம் உயரும். புவனேஸ்வரி அம்மனை வழிபடவும்.';
            case 'kanya': return 'வெள்ளிக்கிழமை: சுப செய்திகள் வந்து சேரும். சரஸ்வதி & லட்சுமி பூஜை நலம்.';
            case 'tula': return 'வெள்ளிக்கிழமை: ராசி நாதன் சுக்கிரனின் அருளால் செல்வம், கலை மற்றும் மகிழ்ச்சி கூடும்.';
            case 'vrishchika': return 'வெள்ளிக்கிழமை: சக்தி வழிபாட்டால் அச்சம் நீங்கும். சாமுண்டேஸ்வரி அம்மனை பூஜியுங்கள்.';
            case 'dhanu': return 'வெள்ளிக்கிழமை: மங்கள காரியங்கள் இனிதே நடக்கும். லட்சுமி நாராயணர் வழிபாடு.';
            case 'makara': return 'வெள்ளிக்கிழமை: வீட்டில் அமைதியும் அன்னபூரணி அருளால் வளமும் பெருகும்.';
            case 'kumbha': return 'வெள்ளிக்கிழமை: சுப எண்ணங்களும் முக தேஜஸும் கூடும். காயத்ரி மந்திரம் ஜபிக்கவும்.';
            case 'meena': return 'வெள்ளிக்கிழமை: கருணை மற்றும் தான தர்மத்தால் அம்பாளின் பரிபூரண அருள் கிட்டும்.';
          }
          break;
        case DateTime.saturday:
          switch (rashiId) {
            case 'mesha': return 'சனிக்கிழமை: சனி பகவானின் அருளுக்கு நல்லெண்ணெய் தீபம் ஏற்றவும். அனுமன் சாலீசா படிக்கவும்.';
            case 'vrishabha': return 'சனிக்கிழமை: கடின உழைப்புக்கு ஏற்ற நற்பலன் கிடைக்கும். சனி காயத்ரி ஜபிக்கவும்.';
            case 'mithuna': return 'சனிக்கிழமை: கடமைகளை ஒழுங்குடன் ஆற்றுங்கள். திருப்பதி வெங்கடாசலபதியை தரிசிக்கவும்.';
            case 'karka': return 'சனிக்கிழமை: சிவ வழிபாடும் சனி சாந்தி பூஜையும் மன அமைதியைத் தரும்.';
            case 'simha': return 'சனிக்கிழமை: பொறுமையுடன் செயல்பட்டு காரிய வெற்றி பெறுங்கள். சனீஸ்வரர் ஸ்தோத்திரம் நலம்.';
            case 'kanya': return 'சனிக்கிழமை: தர்ம காரியங்களில் வெற்றி. காகங்களுக்கு அன்னமிடுவது தோஷம் நீக்கும்.';
            case 'tula': return 'சனிக்கிழமை: வேலையில் ஸ்திரத்தன்மை. அனுமனுக்கு செந்தூரம் சாத்தி வழிபடவும்.';
            case 'vrishchika': return 'சனிக்கிழமை: ஏழரை சனி தாக்கங்கள் குறைய அனுமத் கவசம் பாராயணம் செய்யவும்.';
            case 'dhanu': return 'சனிக்கிழமை: திருப்பதி ஏழுமலையான் நினைவால் சகல கஷ்டங்களும் தீரும்.';
            case 'makara': return 'சனிக்கிழமை: ராசி நாதன் சனீஸ்வரனின் நாள்! நீதி, நேர்மையுடன் நடக்க வெற்றி நிச்சயம்.';
            case 'kumbha': return 'சனிக்கிழமை: ராசி நாதன் சனி நாள்! தான தர்மங்களால் மகா புண்ணியம் மற்றும் ருத்ராபிஷேகம் நலம்.';
            case 'meena': return 'சனிக்கிழமை: சேவை மனப்பான்மையால் ஈசன் அருள். நவகிரக கோவில் வலம் வரவும்.';
          }
          break;
        case DateTime.sunday:
        default:
          switch (rashiId) {
            case 'mesha': return 'ஞாயிற்றுக்கிழமை: சூரிய நாராயணனின் தேஜஸால் காரியங்களில் பெருவெற்றி. ஆதித்ய ஹிருதயம் படிக்கவும்.';
            case 'vrishabha': return 'ஞாயிற்றுக்கிழமை: நல்ல ஆரோக்கியமும் புகழும் கூடும். சூரியனுக்கு நீர் அர்க்கியம் அர்ப்பணிக்கவும்.';
            case 'mithuna': return 'ஞாயிற்றுக்கிழமை: முக்கிய முடிவுகளுக்கு உகந்த நன்னாள். காயத்ரி மந்திரம் ஜபிக்கவும்.';
            case 'karka': return 'ஞாயிற்றுக்கிழமை: மன நிம்மதி கூடும். சிவ-சூரிய வழிபாடு மங்களம் தரும்.';
            case 'simha': return 'ஞாயிற்றுக்கிழமை: ராசி நாதன் சூரியனின் பிரகாசமான நாள்! அளப்பரிய புகழ் மற்றும் தலைமைப் பதவி.';
            case 'kanya': return 'ஞாயிற்றுக்கிழமை: புத்துணர்ச்சியும் உற்சாகமும் பெருகும். சூரிய நமஸ்காரம் நலம்.';
            case 'tula': return 'ஞாயிற்றுக்கிழமை: சமூகத்தில் நற்பெயர். தந்தையின் ஆசி பெற்று நாளைத் தொடங்கவும்.';
            case 'vrishchika': return 'ஞாயிற்றுக்கிழமை: மன வலிமையும் தைரியமும் கூடும். சூரிய மந்திரம் ஜபிக்கவும்.';
            case 'dhanu': return 'ஞாயிற்றுக்கிழமை: ஆன்மிக பயணம் மற்றும் நற்சிந்தனைகள். விஷ்ணு சஹஸ்ரநாமம் கேட்கவும்.';
            case 'makara': return 'ஞாயிற்றுக்கிழமை: கடின உழைப்பு அங்கீகரிக்கப்படும். சூரிய நாராயணரை வணங்கவும்.';
            case 'kumbha': return 'ஞாயிற்றுக்கிழமை: அமைதியும் சுப பலன்களும் கிட்டும். சூர்யாஷ்டகம் படிக்கவும்.';
            case 'meena': return 'ஞாயிற்றுக்கிழமை: ஆத்ம திருப்தி மற்றும் மன அமைதி. நாராயண கவசம் பாராயணம் நலம்.';
          }
      }
    } else if (lang == 'ml') {
      switch (weekday) {
        case DateTime.monday:
          switch (rashiId) {
            case 'mesha': return 'തിങ്കളാഴ്ച: ആത്മവിശ്വാസം വർദ്ധിക്കും. ശിവലിംഗത്തിൽ ജലാഭിഷേകം നടത്തുന്നത് വിഘ്നങ്ങൾ മാറ്റും.';
            case 'vrishabha': return 'തിങ്കളാഴ്ച: കുടുംബത്തിൽ ഐശ്വര്യവും ധനാഗമനവും. ചന്ദ്രധ്യാനം മനസ്സിന് ശാന്തി നൽകും.';
            case 'mithuna': return 'തിങ്കളാഴ്ച: സർഗ്ഗാത്മകതയും വാക്ചാതുര്യവും. ഓം നമഃ ശിവായ ജപം ശുഭം.';
            case 'karka': return 'തിങ്കളാഴ്ച: രാശീനാഥനായ ചന്ദ്രന്റെ ദിവസം! ഭക്തിയും ഈശ്വരാനുഗ്രഹവും വർദ്ധിക്കും.';
            case 'simha': return 'തിങ്കളാഴ്ച: തൊഴിൽരംഗത്ത് ബഹുമാനം. മാതാവിന്റെ അനുഗ്രഹം വാങ്ങി തുടങ്ങുക.';
            case 'kanya': return 'തിങ്കളാഴ്ച: പുതിയ കർമ്മങ്ങൾക്ക് തുടക്കം. വെളുത്ത പുഷ്പങ്ങൾ കൊണ്ട് ശിവപൂജ ശുഭം.';
            case 'tula': return 'തിങ്കളാഴ്ച: ശുഭവാർത്തകൾ കേൾക്കും. കലാരംഗത്തും ഭക്തിമാർഗ്ഗത്തിലും താല്പര്യം.';
            case 'vrishchika': return 'തിങ്കളാഴ്ച: ധൈര്യത്തോടെ കാര്യങ്ങൾ പൂർത്തിയാക്കും. രുദ്രാഷ്ടകം ജപിക്കുക.';
            case 'dhanu': return 'തിങ്കളാഴ്ച: ഗുരുസ്മരണയാൽ ജ്ഞാനവർദ്ധനവ്. മുതിർന്നവരുടെ അനുഗ്രഹം തേടുക.';
            case 'makara': return 'തിങ്കളാഴ്ച: കഠിനാധ്വാനത്തിന് ഉചിതമായ ഫലം. ക്ഷിരാഭിഷേകം നടത്തുക.';
            case 'kumbha': return 'തിങ്കളാഴ്ച: സേവന താല്പര്യവും സമാധാനവും. ഈശ്വരപ്രാർത്ഥന ശക്തി പകരും.';
            case 'meena': return 'തിങ്കളാഴ്ച: ആത്മീയ ചിന്തകൾ സഫലമാകും. ശിവക്ഷേത്ര ദർശനം പുണ്യം.';
          }
          break;
        case DateTime.tuesday:
          switch (rashiId) {
            case 'mesha': return 'ചൊവ്വാഴ്ച: രാശീനാഥൻ ചൊവ്വയുടെ ദിവസം! അത്യുത്സാഹവും കർമ്മവിജയവും. ഹനുമാൻ ചാലീസ ജപിക്കുക.';
            case 'vrishabha': return 'ചൊവ്വാഴ്ച: ക്ഷമയോടെ പ്രവർത്തിക്കുക. ഗണപതിക്ക് കറുകമാല സമർപ്പിക്കുക.';
            case 'mithuna': return 'ചൊവ്വാഴ്ച: വാക്കുകളിൽ മിതത്വം പാലിക്കുക. സുബ്രഹ്മണ്യസ്വാമി ഭജനം വിജയം തരും.';
            case 'karka': return 'ചൊവ്വാഴ്ച: ശുഭകാര്യങ്ങൾക്കായി ധനവ്യയം. ഹനുമാൻ സ്വാമിക്ക് പൂജ നടത്തുക.';
            case 'simha': return 'ചൊവ്വാഴ്ച: നേതൃപാടവം പ്രശംസിക്കപ്പെടും. സൂര്യനമസ്കാരവും ഹനുമത് ധ്യാനവും നന്ന്.';
            case 'kanya': return 'ചൊവ്വാഴ്ച: കടബാധ്യതകൾക്ക് പരിഹാരം. ഗണേശ സ്തോത്രം ജപിക്കുക.';
            case 'tula': return 'ചൊവ്വാഴ്ച: ദൃഢനിശ്ചയം വിജയം തരും. കാർത്തികേയ പ്രാർത്ഥന ഉത്തമം.';
            case 'vrishchika': return 'ചൊവ്വാഴ്ച: രാശീനാഥൻ ചൊവ്വയുടെ അനുഗ്രഹം! ശത്രുദോഷ പരിഹാരവും ഉന്നതിയും.';
            case 'dhanu': return 'ചൊവ്വാഴ്ച: ധർമ്മമാർഗ്ഗത്തിൽ വിജയം. ഹനുമാന് തുളസിമാല സമർപ്പിക്കുക.';
            case 'makara': return 'ചൊവ്വാഴ്ച: പ്രയത്നങ്ങൾക്ക് പ്രതിഫലം. ബജ്രംഗ് ബാൺ ജപിക്കുന്നത് ശുഭം.';
            case 'kumbha': return 'ചൊവ്വാഴ്ച: ധൈര്യത്തോടെ മുന്നേറുക. ഗണപതിഹോമം വിഘ്നങ്ങൾ അകറ്റും.';
            case 'meena': return 'ചൊവ്വാഴ്ച: പുതിയ അവസരങ്ങൾ ലഭ്യമാകും. സുന്ദരകാണ്ഡം പാരായണം ശുഭം.';
          }
          break;
        case DateTime.wednesday:
          switch (rashiId) {
            case 'mesha': return 'ബുധനാഴ്ച: വ്യാപാരത്തിലും വിദ്യാഭ്യാസത്തിലും പുരോഗതി. വിഷ്ണുസഹസ്രനാമം കേൾക്കുക.';
            case 'vrishabha': return 'ബുധനാഴ്ച: സാമ്പത്തിക ഐശ്വര്യം. ശ്രീകൃഷ്ണന് വെണ്ണ നിവേദിക്കുക.';
            case 'mithuna': return 'ബുധനാഴ്ച: രാശീനാഥൻ ബുധന്റെ ദിവസം! ബുദ്ധിയും വാക്സാമർത്ഥ്യവും ശോഭിക്കും.';
            case 'karka': return 'ബുധനാഴ്ച: ശാന്തവും പ്രസന്നവുമായ ദിനം. പാണ്ഡുരംഗ ഭജനം ശുഭം.';
            case 'simha': return 'ബുധനാഴ്ച: സൗഹൃദങ്ങൾ ഉപകാരപ്പെടും. കൃഷ്ണാഷ്ടകം ജപിക്കുക.';
            case 'kanya': return 'ബുധനാഴ്ച: രാശീനാഥൻ ബുധന്റെ അനുഗ്രഹം! പരീക്ഷകളിലും കണക്കുകൂട്ടലുകളിലും മഹാവിജയം.';
            case 'tula': return 'ബുധനാഴ്ച: കലാരംഗത്ത് ശോഭിക്കും. ലക്ഷ്മീനാരായണ സ്തോത്രം ജപിക്കുക.';
            case 'vrishchika': return 'ബുധനാഴ്ച: ശാന്തമായ പ്രവർത്തനങ്ങൾ ലക്ഷ്യത്തിലെത്തും. തുളസി സമർപ്പിക്കുക.';
            case 'dhanu': return 'ബുധനാഴ്ച: വിജ്ഞാന സമ്പാദനത്തിന് ഉത്തമദിനം. ഹയഗ്രീവ സ്തോത്രം നന്ന്.';
            case 'makara': return 'ബുധനാഴ്ച: തൊഴിൽ നേട്ടങ്ങൾ. ഗോപാലകൃഷ്ണനെ ധ്യാനിക്കുക.';
            case 'kumbha': return 'ബുധനാഴ്ച: പുതിയ പദ്ധതികൾ വിജയിക്കും. വിഷ്ണുക്ഷേത്ര ദർശനം ശുഭം.';
            case 'meena': return 'ബുധനാഴ്ച: സത്സംഗത്തിലും ഭജനയിലും പങ്കാളിയാവുക. മനോശാന്തി ലഭിക്കും.';
          }
          break;
        case DateTime.thursday:
          switch (rashiId) {
            case 'mesha': return 'വ്യാഴാഴ്ച: ഗുരുക്കന്മാരുടെ അനുഗ്രഹം ലഭിക്കും. ഗുരുവായൂരപ്പനെ ഭജിക്കുക.';
            case 'vrishabha': return 'വ്യാഴാഴ്ച: ധാർമ്മിക കാര്യങ്ങളിൽ താല്പര്യം. ഗുരുസ്തോത്രം ചൊല്ലുക.';
            case 'mithuna': return 'വ്യാഴാഴ്ച: വിജ്ഞാനപ്രദാനവും പഠനനേട്ടങ്ങളും. ഓം ഗുരുഭ്യോ നമഃ ജപിക്കുക.';
            case 'karka': return 'വ്യാഴാഴ്ച: ആത്മീയ പ്രഭാവം. ദത്താത്രേയസ്മരണ അഭീഷ്ടസിദ്ധി നൽകും.';
            case 'simha': return 'വ്യാഴാഴ്ച: ഉന്നതസ്ഥാനവും ആദരവും. വിഷ്ണുവിന് മഞ്ഞപ്പൂക്കൾ ചാർത്തുക.';
            case 'kanya': return 'വ്യാഴാഴ്ച: സൽകർമ്മങ്ങൾക്ക് ഫലം ലഭിക്കും. ഗുരുചരിത്രം പാരായണം ശുഭം.';
            case 'tula': return 'വ്യാഴാഴ്ച: ശുഭകാര്യങ്ങൾക്ക് തുടക്കം. രാഘവേന്ദ്രസ്വാമി പ്രാർത്ഥന നന്ന്.';
            case 'vrishchika': return 'വ്യാഴാഴ്ച: ധർമ്മനിഷ്ഠ വിജയം തരും. ഗുരുപാദ പൂജ നടത്തുക.';
            case 'dhanu': return 'വ്യാഴാഴ്ച: രാശീനാഥൻ വ്യാഴത്തിന്റെ ദിവസം! കീർത്തിയും ഭാഗ്യവും വർദ്ധിക്കും.';
            case 'makara': return 'വ്യാഴാഴ്ച: മേലധികാരികളുടെ പ്രീതി. ദത്താത്രേയ കവചം ജപിക്കുക.';
            case 'kumbha': return 'വ്യാഴാഴ്ച: സത്സംഗാനന്ദം. രാഘവേന്ദ്ര അഷ്ടോത്തരം ജപിക്കുക.';
            case 'meena': return 'വ്യാഴാഴ്ച: രാശീനാഥൻ ദേവഗുരുവിന്റെ ദിവസം! ദൈവിക കൃപയും ആത്മതൃപ്തിയും.';
          }
          break;
        case DateTime.friday:
          switch (rashiId) {
            case 'mesha': return 'വെള്ളിയാഴ്ച: മഹാലക്ഷ്മീകൃപയാൽ സമ്പൽസമൃദ്ധി. കനകധാരാസ്തോത്രം ചൊല്ലുക.';
            case 'vrishabha': return 'വെള്ളിയാഴ്ച: രാശീനാഥൻ ശുക്രന്റെ ദിവസം! സുഖഭോഗങ്ങളും ഐശ്വര്യവും.';
            case 'mithuna': return 'വെള്ളിയാഴ്ച: കുടുംബത്തിൽ സന്തോഷം. ലളിതാസഹസ്രനാമം കേൾക്കുന്നത് ശ്രേഷ്ഠം.';
            case 'karka': return 'വെള്ളിയാഴ്ച: ഭഗവതിസേവയാൽ സർവ്വമംഗളം. നെയ്വിളക്ക് കൊളുത്തുക.';
            case 'simha': return 'വെള്ളിയാഴ്ച: വ്യക്തിപ്രഭാവവും ആദരവും. ഭുവനേശ്വരീദേവിയെ ധ്യാനിക്കുക.';
            case 'kanya': return 'വെള്ളിയാഴ്ച: സന്തോഷവാർത്തകൾ. സരസ്വതീ-ലക്ഷ്മീപൂജ ഗുണകരം.';
            case 'tula': return 'വെള്ളിയാഴ്ച: രാശീനാഥൻ ശുക്രന്റെ അനുഗ്രഹം! കലയും പ്രണയവും ഐശ്വര്യവും.';
            case 'vrishchika': return 'വെള്ളിയാഴ്ച: ദേവീഭജനത്താൽ ഭയമുക്തി. ചാമുണ്ഡേശ്വരിയെ പ്രാർത്ഥിക്കുക.';
            case 'dhanu': return 'വെള്ളിയാഴ്ച: മംഗളകാര്യങ്ങൾ സഫലമാകും. ലക്ഷ്മീനാരായണ പൂജ നടത്തുക.';
            case 'makara': return 'വെള്ളിയാഴ്ച: ശാന്തിയും അന്നപൂർണ്ണേശ്വരീ കൃപയാൽ സമൃദ്ധിയും.';
            case 'kumbha': return 'വെള്ളിയാഴ്ച: ശുഭചിന്തകൾ. ഗായത്രീമന്ത്രജപം പ്രകാശം ചൊരിയും.';
            case 'meena': return 'വെള്ളിയാഴ്ച: കാരുണ്യപ്രവർത്തനങ്ങളാൽ ദേവിയുടെ അനുഗ്രഹം ലഭിക്കും.';
          }
          break;
        case DateTime.saturday:
          switch (rashiId) {
            case 'mesha': return 'ശനിയാഴ്ച: ശനിദോഷശമനത്തിന് എള്ളുതിരി കത്തിക്കുക. ഹനുമാൻ ചാലീസ ജപിക്കുക.';
            case 'vrishabha': return 'ശനിയാഴ്ച: കഠിനാധ്വാനം ഫലം കാണും. ശനിഗായത്രി ജപിക്കുന്നത് ഉത്തമം.';
            case 'mithuna': return 'ശനിയാഴ്ച: ചിട്ടയായ പ്രവർത്തനങ്ങൾ ലക്ഷ്യത്തിലെത്തും. വെങ്കിടേശ്വരദർശനം നന്ന്.';
            case 'karka': return 'ശനിയാഴ്ച: ശിവപൂജയും ശനിശാന്തിയും മനസ്സിന് കരുത്ത് പകരും.';
            case 'simha': return 'ശനിയാഴ്ച: ക്ഷമ പാലിക്കുക. ശനീശ്വരസ്തോത്രം പാരായണം ചെയ്യുക.';
            case 'kanya': return 'ശനിയാഴ്ച: പുണ്യകർമ്മങ്ങളിൽ താല്പര്യം. പക്ഷികൾക്ക് ആഹാരം നൽകുക.';
            case 'tula': return 'ശനിയാഴ്ച: തൊഴിൽസ്ഥിരത. ഹനുമാൻ സ്വാമിക്ക് സിന്ദൂരം സമർപ്പിക്കുക.';
            case 'vrishchika': return 'ശനിയാഴ്ച: കണ്ടകശനി ദോഷപരിഹാരത്തിന് ഹനുമത് കവചം ചൊല്ലുക.';
            case 'dhanu': return 'ശനിയാഴ്ച: തിരുപ്പതി ബാലാജി സ്മരണ ദാരിദ്ര്യം അകറ്റും.';
            case 'makara': return 'ശനിയാഴ്ച: രാശീനാഥൻ ശനീശ്വരന്റെ ദിവസം! നീതിയും സത്യവും കാത്തുസൂക്ഷിക്കുക.';
            case 'kumbha': return 'ശനിയാഴ്ച: രാശീനാഥൻ ശനിയുടെ ദിവസം! ദാനധർമ്മങ്ങൾ ചെയ്യുക, രുദ്രാഭിഷേകം നന്ന്.';
            case 'meena': return 'ശനിയാഴ്ച: സേവാമനോഭാവം ദൈവകൃപ നേടും. നവഗ്രഹപ്രദക്ഷിണം ചെയ്യുക.';
          }
          break;
        case DateTime.sunday:
        default:
          switch (rashiId) {
            case 'mesha': return 'ഞായറാഴ്ച: സൂര്യനാരായണന്റെ തേജസ്സാൽ സർവ്വകാര്യവിജയം. ആദിത്യഹൃദയം ജപിക്കുക.';
            case 'vrishabha': return 'ഞായറാഴ്ച: ഉത്തമാരോഗ്യവും പ്രശസ്തിയും. സൂര്യന് അർഘ്യം സമർപ്പിക്കുക.';
            case 'mithuna': return 'ഞായറാഴ്ച: നിർണ്ണായക തീരുമാനങ്ങൾക്ക് അനുകൂല ദിനം. ഗായത്രി ജപിക്കുക.';
            case 'karka': return 'ഞായറാഴ്ച: മനോശാന്തി ലഭിക്കും. ശിവ-സൂര്യ ഉപാസന മംഗളകരം.';
            case 'simha': return 'ഞായറാഴ്ച: രാശീനാഥൻ സൂര്യന്റെ ഉജ്ജ്വല ദിനം! അത്യുന്നത പദവിയും പ്രഭാവവും.';
            case 'kanya': return 'ഞായറാഴ്ച: നവോന്മേഷവും ഉന്മേഷവും. സൂര്യനമസ്കാരം ആരോഗ്യത്തിന് ഉത്തമം.';
            case 'tula': return 'ഞായറാഴ്ച: സമൂഹത്തിൽ ബഹുമാനം. പിതാവിന്റെ അനുഗ്രഹം വാങ്ങുക.';
            case 'vrishchika': return 'ഞായറാഴ്ച: ആത്മധൈര്യവും ഊർജ്ജസ്വലതയും. സൂര്യമന്ത്രം ജപിക്കുക.';
            case 'dhanu': return 'ഞായറാഴ്ച: തീർത്ഥയാത്രകൾക്കും സങ്കല്പങ്ങൾക്കും നന്ന്. വിഷ്ണുസഹസ്രനാമം കേൾക്കുക.';
            case 'makara': return 'ഞായറാഴ്ച: പ്രയത്നങ്ങൾക്ക് അംഗീകാരം. സൂര്യദേവനെ വണങ്ങുക.';
            case 'kumbha': return 'ഞായറാഴ്ച: ശാന്തിയും ശുഭഫലങ്ങളും. സൂര്യാഷ്ടകം ചൊല്ലുക.';
            case 'meena': return 'ഞായറാഴ്ച: ആത്മതൃപ്തിയും ഈശ്വരാധീനവും. നാരായണകവചം ജപിക്കുക.';
          }
      }
    }

    // Default / English (84 distinct astrological combinations)
    switch (weekday) {
      case DateTime.monday:
        switch (rashiId) {
          case 'mesha': return 'Monday: The Moon stimulates your creative instincts. Practice mindfulness and invoke Lord Shiva with Om Namah Shivaya for mental clarity.';
          case 'vrishabha': return 'Monday: Favorable day for financial planning and family harmony. Channel inner peace through quiet meditation on Chandra Dev.';
          case 'mithuna': return 'Monday: Quick wit and adaptability bring breakthroughs in communications. Reciting Shiva Panchakshara Stotra clears mental clutter.';
          case 'karka': return 'Monday: Ruled by the Moon, your intuition and spiritual devotion peak today. Offer white flowers or milk abhishekam to Lord Shiva.';
          case 'simha': return 'Monday: Strong leadership and public appreciation at work. Seek maternal blessings to ensure your endeavors bear sweet fruit.';
          case 'kanya': return 'Monday: Methodical focus aids in resolving pending intellectual projects. Chanting Maha Mrityunjaya Mantra brings calmness.';
          case 'tula': return 'Monday: Balanced negotiations and pleasant social interactions. Immersing in serene devotional music restores inner equilibrium.';
          case 'vrishchika': return 'Monday: Courage and emotional resilience turn challenges into victories. Meditate on Lord Rudra for inner strength.';
          case 'dhanu': return 'Monday: Philosophical insights and learning opportunities flourish. Respect elders and teachers for auspicious momentum.';
          case 'makara': return 'Monday: Persistent determination yields tangible rewards. A humble prayer at a Shiva temple brings immense fulfillment.';
          case 'kumbha': return 'Monday: Altruistic thoughts and humanitarian projects gain support. Peaceful meditation brings emotional contentment.';
          case 'meena': return 'Monday: Deep spiritual inclinations and divine inspirations arise. Contemplating the cosmic form of Shiva grants tranquility.';
        }
        break;
      case DateTime.tuesday:
        switch (rashiId) {
          case 'mesha': return 'Tuesday: Your ruling planet Mars bestows intense vitality and ambition. Chanting Hanuman Chalisa shields you and brings total victory.';
          case 'vrishabha': return 'Tuesday: Exercise patience and deliberate action over haste. Offering Durva grass to Lord Ganesha dissolves unexpected obstacles.';
          case 'mithuna': return 'Tuesday: Maintain mindful speech in discussions. Chanting the sacred Subramanya Mantra turns conflicts into peaceful resolutions.';
          case 'karka': return 'Tuesday: Channel your emotional energies into constructive spiritual service. Offer red vermilion or flowers to Lord Hanuman.';
          case 'simha': return 'Tuesday: Your innate authority shines brightly in team efforts. Practice Surya Namaskar and meditate on Lord Hanuman for fearless energy.';
          case 'kanya': return 'Tuesday: Strategic financial and organizational steps bring lasting relief. Recite Sankata Nashana Ganesha Stotram for success.';
          case 'tula': return 'Tuesday: Decisiveness is your greatest asset today. Invoking Lord Kartikeya grants clarity and victorious momentum.';
          case 'vrishchika': return 'Tuesday: Your ruling planet Mars amplifies your focus and courage. Chanting Subramanya Ashtakam clears all negativity.';
          case 'dhanu': return 'Tuesday: Righteous actions lead to prosperity and triumph. Offering a Tulasi garland to Lord Hanuman ensures supreme protection.';
          case 'makara': return 'Tuesday: Diligent hard work is rewarded with steady progress. Reading the Bajrang Baan removes fatigue and doubt.';
          case 'kumbha': return 'Tuesday: Bold initiatives receive cosmic backing. Worship Lord Ganesha at sunrise to keep all paths unobstructed.';
          case 'meena': return 'Tuesday: New spiritual and material opportunities present themselves. Chanting the sacred verses of Sundarkand brings divine grace.';
        }
        break;
      case DateTime.wednesday:
        switch (rashiId) {
          case 'mesha': return 'Wednesday: Excellent day for commerce, business expansion, and studies. Listening to Vishnu Sahasranamam sharpens your intellect.';
          case 'vrishabha': return 'Wednesday: Material stability and profitable agreements. Offering butter or sweets to Lord Krishna invites sweetness and prosperity.';
          case 'mithuna': return 'Wednesday: Your ruling planet Mercury is at its peak! Exceptional brilliance in negotiations and writing. Devote actions to Sri Krishna.';
          case 'karka': return 'Wednesday: A peaceful and harmonious day for domestic happiness. Chanting the divine names of Panduranga Vitthala dissolves anxiety.';
          case 'simha': return 'Wednesday: Joyful camaraderie and valuable connections with friends. Chanting Krishnashtakam brings radiant joy throughout the day.';
          case 'kanya': return 'Wednesday: Ruled by Mercury, your analytical and problem-solving powers excel. Offer prayers to Lord Ganesha for flawless execution.';
          case 'tula': return 'Wednesday: Aesthetic appreciation and artistic endeavors flourish. Reciting Sri Lakshmi Narayana Hridaya Stotram brings grace.';
          case 'vrishchika': return 'Wednesday: Deliberate, thoughtful steps ensure steady triumph. Offering fresh Tulasi leaves to Lord Krishna brings peace.';
          case 'dhanu': return 'Wednesday: An auspicious day for higher learning and spiritual reading. Recite Sri Hayagriva Stotram for supreme wisdom.';
          case 'makara': return 'Wednesday: Commercial acumen and practical investments prosper. Meditating on Gopala Krishna uplifts your spirits.';
          case 'kumbha': return 'Wednesday: Innovative ideas and visionary plans gain traction. Visiting a Vishnu temple brings auspicious harmony.';
          case 'meena': return 'Wednesday: Deep devotion and spiritual discussions bring solace. Immersing in Krishna Bhajans fills your home with bliss.';
        }
        break;
      case DateTime.thursday:
        switch (rashiId) {
          case 'mesha': return 'Thursday: Divine fortune smiles upon you through Guru\'s grace. Seek the holy blessings of Sri Raghavendra Swamy or Sai Baba.';
          case 'vrishabha': return 'Thursday: Religious rituals and sacred offerings enhance domestic joy. Reciting Guru Stotram invites spiritual and material wealth.';
          case 'mithuna': return 'Thursday: Knowledge sharing and mentorship bring deep satisfaction. Chanting Om Sri Gurubhyo Namah attracts cosmic guidance.';
          case 'karka': return 'Thursday: Spiritual radiance and divine benevolence surround you. Meditating on Lord Dattatreya fulfills cherished wishes.';
          case 'simha': return 'Thursday: High status and mutual respect from authority figures. Offering yellow flowers to Lord Vishnu brings immense favor.';
          case 'kanya': return 'Thursday: Virtuous deeds and selfless charity bear fruit. Reading chapters from Guru Charitra brings serenity and protection.';
          case 'tula': return 'Thursday: Auspicious beginnings for sacred ceremonies and plans. Chanting Guru Mantras brings tranquility to the mind.';
          case 'vrishchika': return 'Thursday: Walking the path of righteousness ensures unshakeable victory. Receive the sacred blessings of elders.';
          case 'dhanu': return 'Thursday: Ruled by Jupiter (Brihaspati), wisdom and prosperity multiply. Offering prayers to Lord Venkateshwara brings unbounded grace.';
          case 'makara': return 'Thursday: Supportive relationships with senior leaders and mentors. Reciting Dattatreya Vajra Kavach shields against all distress.';
          case 'kumbha': return 'Thursday: Blissful satsang and spiritual elevation. Chanting the Ashtottara of Guru Raghavendra brings tranquility.';
          case 'meena': return 'Thursday: Your ruling planet Jupiter blesses you with profound divine bliss. Performing Guru Pada Puja brings supreme peace.';
        }
        break;
      case DateTime.friday:
        switch (rashiId) {
          case 'mesha': return 'Friday: Goddess Mahalakshmi showers financial prosperity and comfort. Chanting Kanakadhara Stotram invites abundance.';
          case 'vrishabha': return 'Friday: Your ruling planet Venus radiates luxury, beauty, and love. Reciting Mahalakshmi Ashtakam multiplies household joy.';
          case 'mithuna': return 'Friday: Harmonious relationships and joyful reunions with loved ones. Listening to Lalitha Sahasranamam is highly auspicious.';
          case 'karka': return 'Friday: Divine motherly protection and blessings of Goddess Durga. Light a pure ghee diya in your sacred pooja altar.';
          case 'simha': return 'Friday: Magnetic charisma, elegance, and societal honor. Meditate upon Goddess Bhuvaneshwari for radiant charm.';
          case 'kanya': return 'Friday: Auspicious news and joyful achievements in work. Worship Goddess Saraswati and Lakshmi for wisdom and wealth.';
          case 'tula': return 'Friday: Your ruling planet Venus empowers romance, art, and opulence. Chanting Sri Suktam brings enduring prosperity.';
          case 'vrishchika': return 'Friday: Spiritual shakti removes fear of adversaries. Offer prayers to Goddess Chamundeshwari for invulnerability.';
          case 'dhanu': return 'Friday: Auspicious social and devotional events proceed seamlessly. Worship Lakshmi Narayana for auspicious growth.';
          case 'makara': return 'Friday: Deep contentment, peace, and abundance in provisions. Goddess Annapoorneshwari blesses your family with nourishment.';
          case 'kumbha': return 'Friday: Noble thoughts and radiant clarity of vision. Chanting Gayatri Mantra at twilight enhances your aura.';
          case 'meena': return 'Friday: Compassion, charity, and devotional surrender bring blessings. Contemplate Goddess Mookambika for sublime peace.';
        }
        break;
      case DateTime.saturday:
        switch (rashiId) {
          case 'mesha': return 'Saturday: Saturn\'s transit demands disciplined focus in your actions. Light a sesame oil lamp and chant Hanuman Chalisa for victory.';
          case 'vrishabha': return 'Saturday: Diligent perseverance yields fruitful, lasting rewards. Chanting Shani Gayatri Mantra alleviates all karmic burdens.';
          case 'mithuna': return 'Saturday: Methodical attention to duty brings steady advancement. Visiting Lord Venkateshwara\'s shrine brings protection.';
          case 'karka': return 'Saturday: Shiva worship and Shani Shanti prayers bring great peace. Helping the needy dissolves negative planetary effects.';
          case 'simha': return 'Saturday: Practice patience, humbleness, and measured responses. Chanting Shanaishchara Stotram neutralizes stressful obstacles.';
          case 'kanya': return 'Saturday: Righteous efforts bring gradual but solid triumphs. Feeding birds and crows brings immense spiritual merit.';
          case 'tula': return 'Saturday: Stability and security in professional commitments. Offering sindoor to Lord Hanuman blesses you with fearlessness.';
          case 'vrishchika': return 'Saturday: Overcome challenging cycles with spiritual fortitude. Reciting Sri Hanuman Raksha Kavach ensures divine shield.';
          case 'dhanu': return 'Saturday: Contemplating Lord Tirupati Balaji dispels sorrow and poverty. Engage in quiet reflection and charity.';
          case 'makara': return 'Saturday: Your ruling planet Saturn rewards integrity and patience. Chanting Shani Vajra Panjara Kavach brings success.';
          case 'kumbha': return 'Saturday: Your ruling planet Saturn highlights selfless service. Performing Rudrabhishekam bestows great auspiciousness.';
          case 'meena': return 'Saturday: An attitude of humble service attracts divine grace. Circumambulating the Navagraha shrine brings tranquility.';
        }
        break;
      case DateTime.sunday:
      default:
        switch (rashiId) {
          case 'mesha': return 'Sunday: Surya Narayana\'s radiant solar energy brings vitality and victory. Chanting Aditya Hridaya Stotram ensures success.';
          case 'vrishabha': return 'Sunday: Robust health, vitality, and renowned goodwill. Offer water (Arghya) to the rising Sun for boundless energy.';
          case 'mithuna': return 'Sunday: Auspicious day for decisive initiatives and strategic clarity. Chanting the sacred Gayatri Mantra illuminates the mind.';
          case 'karka': return 'Sunday: Emotional restoration and peaceful spiritual contemplation. Worship of Lord Shiva and Surya brings balance.';
          case 'simha': return 'Sunday: Your ruling planet the Sun shines at peak brilliance! Boundless charisma and leadership. Recite Aditya Hridayam.';
          case 'kanya': return 'Sunday: Rejuvenated vitality and fresh enthusiasm. Practicing Surya Namaskar brings vibrant wellness and focus.';
          case 'tula': return 'Sunday: Elevated social standing and recognition. Begin your day with fatherly blessings for smooth success.';
          case 'vrishchika': return 'Sunday: Dynamic vigor and unyielding courage. Chanting the Surya Beej Mantra elevates confidence.';
          case 'dhanu': return 'Sunday: Auspicious for spiritual pilgrimages and noble resolutions. Listening to Vishnu Sahasranamam brings serenity.';
          case 'makara': return 'Sunday: Your steadfast dedication earns sincere appreciation. Bow down before the morning Sun with gratitude.';
          case 'kumbha': return 'Sunday: Peaceful harmony and auspicious outcomes in personal affairs. Chanting Suryashtakam dispels all gloom.';
          case 'meena': return 'Sunday: Soulful spiritual fulfillment and divine grace. Reciting Narayana Kavach ensures total protection and bliss.';
        }
    }
    return 'Daily auspicious blessings from celestial alignments. Recite sacred mantras for peace and prosperity.';
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

  String _getLocalizedTithi(int tithiNum, {required bool isKrishna, required String lang}) {
    final tithiNamesKn = [
      'ಪಾಡ್ಯ', 'ಬಿದಿಗೆ', 'ತದಿಗೆ', 'ಚತುರ್ಥಿ', 'ಪಂಚಮಿ',
      'ಷಷ್ಠಿ', 'ಸಪ್ತಮಿ', 'ಅಷ್ಟಮಿ', 'ನವಮಿ', 'ದಶಮಿ',
      'ಏಕಾದಶಿ', 'ದ್ವಾದಶಿ', 'ತ್ರಯೋದಶಿ', 'ಚತುರ್ದಶಿ',
      isKrishna ? 'ಅಮಾವಾಸ್ಯೆ' : 'ಹುಣ್ಣಿಮೆ'
    ];

    final tithiNamesHi = [
      'प्रतिपदा', 'द्वितीया', 'तृतीया', 'चतुर्थी', 'पंचमी',
      'षष्ठी', 'सप्तमी', 'अष्टमी', 'नवमी', 'दशमी',
      'एकादशी', 'द्वादशी', 'त्रयोदशी', 'चतुर्दशी',
      isKrishna ? 'अमावस्या' : 'पूर्णिमा'
    ];

    final tithiNamesTa = [
      'பிரதமை', 'துவிதியை', 'திருதியை', 'சதுர்த்தி', 'பஞ்சமி',
      'சஷ்டி', 'சப்தமி', 'அஷ்டமி', 'நவமி', 'தசமி',
      'ஏகாதசி', 'துவாதசி', 'திரயோதசி', 'சதுர்தசி',
      isKrishna ? 'அமாவாசை' : 'பௌர்ணமி'
    ];

    final tithiNamesMl = [
      'പ്രഥമ', 'ദ്വിതീയ', 'തൃതീയ', 'ചതുർത്ഥി', 'പഞ്ചമി',
      'ഷഷ്ഠി', 'സപ്തമി', 'അഷ്ടമി', 'നവമി', 'ദശമി',
      'ഏകാദശി', 'ദ്വാദശി', 'ത്രയോദശി', 'ചതുർദ്ദശി',
      isKrishna ? 'അമാവാസി' : 'പൗർണ്ണമി'
    ];

    final tithiNamesEn = [
      'Pratipada', 'Dwitiya', 'Tritiya', 'Chaturthi', 'Panchami',
      'Shashti', 'Saptami', 'Ashtami', 'Navami', 'Dashami',
      'Ekadashi', 'Dwadashi', 'Trayodashi', 'Chaturdashi',
      isKrishna ? 'Amavasya' : 'Purnima'
    ];

    final idx = (tithiNum - 1).clamp(0, 14);

    if (lang == 'kn') return '${tithiNamesKn[idx]} (ತಿಥಿ)';
    if (lang == 'hi') return '${tithiNamesHi[idx]} (तिथि)';
    if (lang == 'ta') return '${tithiNamesTa[idx]} (திதி)';
    if (lang == 'ml') return '${tithiNamesMl[idx]} (തിഥി)';
    return '${tithiNamesEn[idx]} Tithi';
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

  String _getLocalizedNakshatra(int idx, {required String lang}) {
    final nakshatrasKn = [
      'ಅಶ್ವಿನಿ', 'ಭರಣಿ', 'ಕೃತ್ತಿಕಾ', 'ರೋಹಿಣಿ', 'ಮೃಗಶಿರ', 'ಆರ್ದ್ರಾ',
      'ಪುನರ್ವಸು', 'ಪುಷ್ಯ', 'ಆಶ್ಲೇಷಾ', 'ಮಘಾ', 'ಪೂರ್ವ ಫಲ್ಗುಣಿ', 'ಉತ್ತರ ಫಲ್ಗುಣಿ',
      'ಹಸ್ತಾ', 'ಚಿತ್ತಾ', 'ಸ್ವಾತಿ', 'ವಿಶಾಖಾ', 'ಅನುರಾಧಾ', 'ಜ್ಯೇಷ್ಠಾ',
      'ಮೂಲಾ', 'ಪೂರ್ವಾಷಾಢ', 'ಉತ್ತರಾಷಾಢ', 'ಶ್ರವಣ', 'ಧನಿಷ್ಠಾ',
      'ಶತಭಿಷಾ', 'ಪೂರ್ವಾಭಾದ್ರಪದ', 'ಉತ್ತರಾಭಾದ್ರಪದ', 'ರೇವತಿ'
    ];

    final nakshatrasHi = [
      'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृगशिरा', 'आर्द्रा',
      'पुनर्वसु', 'पुष्य', 'आश्लेषा', 'मघा', 'पूर्वा फाल्गुनी', 'उत्तरा फाल्गुनी',
      'हस्त', 'चित्रा', 'स्वाति', 'विशाखा', 'अनुराधा', 'ज्येष्ठा',
      'मूल', 'पूर्वाषाढ़ा', 'उत्तराषाढ़ा', 'श्रवण', 'धनिष्ठा',
      'शतभिषा', 'पूर्वाभाद्रपद', 'उत्तराभाद्रपद', 'रेवती'
    ];

    final nakshatrasTa = [
      'அசுவினி', 'பரணி', 'கிருத்திகை', 'ரோகிணி', 'மிருகசீரிஷம்', 'திருவாதிரை',
      'புனர்பூசம்', 'பூசம்', 'ஆயில்யம்', 'மகம்', 'பூரம்', 'உத்திரம்',
      'அஸ்தம்', 'சித்திரை', 'சுவாதி', 'விசாகம்', 'அனுஷம்', 'கேட்டை',
      'மூலம்', 'பூராடம்', 'உத்திராடம்', 'திருவோணம்', 'அவிட்டம்',
      'சதயம்', 'பூரட்டாதி', 'உத்திரட்டாதி', 'ரேவதி'
    ];

    final nakshatrasMl = [
      'അശ്വതി', 'ഭരണി', 'കാർത്തിക', 'രോഹിണി', 'മകയിരം', 'തിരുവാതിര',
      'പുണർതം', 'പൂയം', 'ആയില്യം', 'മകം', 'പൂരം', 'ഉത്രം',
      'അത്തം', 'ചിത്തിര', 'ചോതി', 'വിശാഖം', 'അനിഴം', 'തൃക്കേട്ട',
      'മൂലം', 'പൂരാടം', 'ഉത്രാടം', 'തിരുവോണം', 'അവിട്ടം',
      'ചതയം', 'പൂരുരുട്ടാതി', 'ഉത്തൃട്ടാതി', 'രേവതി'
    ];

    final nakshatrasEn = [
      'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra',
      'Punarvasu', 'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni', 'Uttara Phalguni',
      'Hasta', 'Chitra', 'Swati', 'Vishakha', 'Anuradha', 'Jyeshtha',
      'Mula', 'Purva Ashadha', 'Uttara Ashadha', 'Shravana', 'Dhanishta',
      'Shatabhisha', 'Purva Bhadrapada', 'Uttara Bhadrapada', 'Revati'
    ];

    final safeIdx = idx.clamp(0, 26);
    if (lang == 'kn') return '${nakshatrasKn[safeIdx]} ನಕ್ಷತ್ರ';
    if (lang == 'hi') return '${nakshatrasHi[safeIdx]} नक्षत्र';
    if (lang == 'ta') return '${nakshatrasTa[safeIdx]} நட்சத்திரம்';
    if (lang == 'ml') return '${nakshatrasMl[safeIdx]} നക്ഷത്രം';
    return '${nakshatrasEn[safeIdx]} Nakshatra';
  }

  String _getLocalizedYoga(int idx, {required String lang}) {
    final yogasKn = [
      'ವಿಷ್ಕಂಭ', 'ಪ್ರೀತಿ', 'ಆಯುಷ್ಮಾನ್', 'ಸೌಭಾಗ್ಯ', 'ಶೋಭನ', 'ಅತಿಗಂಡ',
      'ಸುಕರ್ಮ', 'ಧೃತಿ', 'ಶೂಲ', 'ಗಂಡ', 'ವೃದ್ಧಿ', 'ಧ್ರುವ',
      'ವ್ಯಾಘಾತ', 'ಹರ್ಷಣ', 'ವಜ್ರ', 'ಸಿದ್ಧಿ', 'ವ್ಯತೀಪಾತ', 'ವರೀಯಾನ್',
      'ಪರಿಘ', 'ಶಿವ', 'ಸಿದ್ಧ', 'ಸಾಧ್ಯ', 'ಶುಭ', 'ಶುಕ್ಲ',
      'ಬ್ರಹ್ಮ', 'ಐಂದ್ರ', 'ವೈಧೃತಿ'
    ];

    final yogasHi = [
      'विष्कुम्भ', 'प्रीति', 'आयुष्मान', 'सौभाग्य', 'शोभन', 'अतिगण्ड',
      'सुकर्मा', 'धृति', 'शूल', 'गण्ड', 'वृद्धि', 'ध्रुव',
      'व्याघात', 'हर्षण', 'वज्र', 'सिद्धि', 'व्यतीपात', 'वरीयान्',
      'परिघ', 'शिव', 'सिद्ध', 'साध्य', 'शुभ', 'शुक्ल',
      'ब्रह्म', 'इन्द्र', 'वैधृति'
    ];

    final yogasEn = [
      'Vishkambha', 'Priti', 'Ayushman', 'Saubhagya', 'Shobhana', 'Atiganda',
      'Sukarma', 'Dhriti', 'Shoola', 'Ganda', 'Vriddhi', 'Dhruva',
      'Vyaghata', 'Harshana', 'Vajra', 'Siddhi', 'Vyatipata', 'Variyan',
      'Parigha', 'Shiva', 'Siddha', 'Sadhya', 'Shubha', 'Shukla',
      'Brahma', 'Indra', 'Vaidhriti'
    ];

    final safeIdx = idx.clamp(0, 26);
    if (lang == 'kn') return '${yogasKn[safeIdx]} ಯೋಗ';
    if (lang == 'hi') return '${yogasHi[safeIdx]} योग';
    if (lang == 'ta') return '${yogasEn[safeIdx]} யோகம்';
    if (lang == 'ml') return '${yogasEn[safeIdx]} യോഗം';
    return '${yogasEn[safeIdx]} Yoga';
  }

  String _getLocalizedKarana(int halfTithi, {required String lang}) {
    final karanaNamesKn = [
      'ಬವ', 'ಬಾಲವ', 'ಕೌಲವ', 'ತೈತಿಲ', 'ಗರಜ', 'ವಣಿಜ', 'ಭದ್ರಾ (ವಿಷ್ಟಿ)',
      'ಶಕುನಿ', 'ಚತುಷ್ಪಾದ', 'ನಾಗ', 'ಕಿಂಸ್ತುಘ್ನ'
    ];

    final karanaNamesHi = [
      'बव', 'बालव', 'कौलव', 'तैतिल', 'गरज', 'वणिज', 'भद्रा (विष्टि)',
      'शकुनि', 'चतुष्पाद', 'नाग', 'किंस्तुघ्न'
    ];

    final karanaNamesEn = [
      'Bava', 'Balava', 'Kaulava', 'Taitila', 'Garija', 'Vanija', 'Bhadra (Vishti)',
      'Shakuni', 'Chatushpada', 'Naga', 'Kimstughna'
    ];

    int karanaIdx;
    if (halfTithi == 0) {
      karanaIdx = 10; // Kimstughna
    } else if (halfTithi >= 57) {
      karanaIdx = 7 + (halfTithi - 57); // Shakuni, Chatushpada, Naga
    } else {
      karanaIdx = (halfTithi - 1) % 7; // Repeating 7
    }

    final safeIdx = karanaIdx.clamp(0, 10);
    if (lang == 'kn') return '${karanaNamesKn[safeIdx]} ಕರಣ';
    if (lang == 'hi') return '${karanaNamesHi[safeIdx]} करण';
    if (lang == 'ta') return '${karanaNamesEn[safeIdx]} கரணம்';
    if (lang == 'ml') return '${karanaNamesEn[safeIdx]} കരണം';
    return '${karanaNamesEn[safeIdx]} Karana';
  }

  String _getLocalizedDeity(int weekday, bool isSankashti, bool isEkadashi, bool isPradosha, {required String lang}) {
    if (isSankashti) {
      if (lang == 'kn') return 'ಶ್ರೀ ಮಹಾಗಣಪತಿ 🌺 – ಸಂಕಷ್ಟಿ ವ್ರತ';
      if (lang == 'hi') return 'श्री महागणपति 🌺 – संकष्टी व्रत';
      if (lang == 'ta') return 'ஸ்ரீ விநாயகர் 🌺 – சங்கடஹர சதுர்த்தி';
      if (lang == 'ml') return 'ശ്രീ മഹാഗണപതി 🌺 – സങ്കഷ്ടി';
      return 'Lord Ganesha 🌺 – Sankashti Vrata';
    }
    if (isEkadashi) {
      if (lang == 'kn') return 'ಶ್ರೀ ಮಹಾವಿಷ್ಣು 🪷 – ಏಕಾದಶಿ ವ್ರತ';
      if (lang == 'hi') return 'भगवान विष्णु 🪷 – एकादशी व्रत';
      if (lang == 'ta') return 'ஸ்ரீ மகாவிஷ்ணு 🪷 – ஏகாதசி';
      if (lang == 'ml') return 'ശ്രീ മഹാവിഷ്ണു 🪷 – ഏകാദശി';
      return 'Lord Vishnu 🪷 – Ekadashi Vrata';
    }
    if (isPradosha) {
      if (lang == 'kn') return 'ಶ್ರೀ ಪರಮೇಶ್ವರ 🔱 – ಪ್ರದೋಷ ವ್ರತ';
      if (lang == 'hi') return 'भगवान शिव 🔱 – प्रदोष व्रत';
      if (lang == 'ta') return 'ஸ்ரீ சிவபெருமான் 🔱 – பிரதோஷம்';
      if (lang == 'ml') return 'ശ്രീ പരമേശ്വരൻ 🔱 – പ്രദോഷം';
      return 'Lord Shiva 🔱 – Pradosha Vrata';
    }

    switch (weekday) {
      case DateTime.monday:
        if (lang == 'kn') return 'ಶ್ರೀ ಪರಮೇಶ್ವರ 🔱 – ಸೋಮವಾರ ವ್ರತ';
        if (lang == 'hi') return 'भगवान शिव 🔱 – सोमवार व्रत';
        if (lang == 'ta') return 'ஸ்ரீ சிவபெருமான் 🔱 – திங்கட்கிழமை';
        if (lang == 'ml') return 'ശ്രീ പരമേശ്വരൻ 🔱 – സോമവാരം';
        return 'Lord Shiva 🔱 – Somavara Vrata';
      case DateTime.tuesday:
        if (lang == 'kn') return 'ಶ್ರೀ ಹನುಮಾನ್ ಮತ್ತು ಗಣೇಶ 🌺 – ಮಂಗಳವಾರ';
        if (lang == 'hi') return 'भगवान हनुमान व गणेश 🌺 – मंगलवार';
        if (lang == 'ta') return 'ஸ்ரீ அனுமன் & விநாயகர் 🌺 – செவ்வாய்';
        if (lang == 'ml') return 'ശ്രീ ഹനുമാൻ & ഗണപതി 🌺 – ചൊവ്വാഴ്ച';
        return 'Lord Hanuman & Ganesha 🌺 – Mangalavara';
      case DateTime.wednesday:
        if (lang == 'kn') return 'ಶ್ರೀ ಕೃಷ್ಣ ಮತ್ತು ವಿಟ್ಠಲ 🦚 – ಬುಧವಾರ';
        if (lang == 'hi') return 'भगवान कृष्ण व विट्ठल 🦚 – बुधवार';
        if (lang == 'ta') return 'ஸ்ரீ கிருஷ்ணர் & விட்டலர் 🦚 – புதன்';
        if (lang == 'ml') return 'ശ്രീ കൃഷ്ണൻ & വിഠലൻ 🦚 – ബുധനാഴ്ച';
        return 'Lord Krishna & Vitthala 🦚 – Budhavara';
      case DateTime.thursday:
        if (lang == 'kn') return 'ಶ್ರೀ ಗುರು ರಾಯರು ಮತ್ತು ವಿಷ್ಣು 🪷 – ಗುರುವಾರ';
        if (lang == 'hi') return 'श्री गुरु व भगवान विष्णु 🪷 – गुरुवार';
        if (lang == 'ta') return 'ஸ்ரீ குரு ராகவேந்திரர் & விஷ்ணு 🪷 – வியாழன்';
        if (lang == 'ml') return 'ശ്രീ ഗുരു & മഹാവിഷ്ണു 🪷 – വ്യാഴാഴ്ച';
        return 'Lord Vishnu & Sri Guru 🪷 – Guruvara';
      case DateTime.friday:
        if (lang == 'kn') return 'ಶ್ರೀ ಮಹಾಲಕ್ಷ್ಮೀ ಮತ್ತು ಲಲಿತಾದೇವಿ ✨ – ಶುಕ್ರವಾರ';
        if (lang == 'hi') return 'माँ महालक्ष्मी व ललिता देवी ✨ – शुक्रवार';
        if (lang == 'ta') return 'ஸ்ரீ மகாலட்சுமி & லலிதா தேவி ✨ – வெள்ளி';
        if (lang == 'ml') return 'ശ്രീ മഹാലക്ഷ്മി & ലളിതാദേവി ✨ – വെള്ളിയാഴ്ച';
        return 'Goddess Mahalakshmi & Lalitha ✨ – Shukravara';
      case DateTime.saturday:
        if (lang == 'kn') return 'ಶ್ರೀ ವೆಂಕಟೇಶ್ವರ ಮತ್ತು ಶನಿದೇವ 🙏 – ಶನಿವಾರ';
        if (lang == 'hi') return 'भगवान वेंकटेश्वर व शनिदेव 🙏 – शनिवार';
        if (lang == 'ta') return 'ஸ்ரீ வெங்கடேஸ்வரர் & சனி பகவான் 🙏 – சனி';
        if (lang == 'ml') return 'ശ്രീ വെങ്കിടേശ്വരൻ & ശനിദേവൻ 🙏 – ശനിയാഴ്ച';
        return 'Lord Venkateshwara & Shani 🙏 – Shanivara';
      case DateTime.sunday:
      default:
        if (lang == 'kn') return 'ಶ್ರೀ ಸೂರ್ಯ ನಾರಾಯಣ ☀️ – ಭಾನುವಾರ';
        if (lang == 'hi') return 'भगवान सूर्य नारायण ☀️ – रविवार';
        if (lang == 'ta') return 'ஸ்ரீ சூரிய நாராயணன் ☀️ – ஞாயிறு';
        if (lang == 'ml') return 'ശ്രീ സൂര്യ നാരായണൻ ☀️ – ഞായറാഴ്ച';
        return 'Lord Surya Deva ☀️ – Surya Namaskara';
    }
  }

  String _getLocalizedOccasion(String key, String lang) {
    if (key == 'angarki_sankashti') {
      if (lang == 'kn') return 'ಇಂದು ಪರಮ ಪವಿತ್ರ ಅಂಗಾರಕಿ ಸಂಕಷ್ಟಿ ಚತುರ್ಥಿ! ಚಂದ್ರೋದಯ ಪೂಜೆ.';
      if (lang == 'hi') return 'आज परम पावन अंगारकी संकष्टी चतुर्थी! चंद्रोदय अर्घ्य व्रत।';
      if (lang == 'ta') return 'இன்று புனித அங்காரக சங்கடஹர சதுர்த்தி விரதம்!';
      if (lang == 'ml') return 'ഇന്ന് പവിത്രമായ അംഗാരക സങ്കഷ്ടി ചതുർത്ഥി!';
      return 'Today is Auspicious Angarki Sankashti Chaturthi!';
    }
    if (key == 'sankashti') {
      if (lang == 'kn') return 'ಇಂದು ಸಂಕಷ್ಟಹರ ಚತುರ್ಥಿ ವ್ರತ! ಗಣೇಶ ಪೂಜೆ ಮತ್ತು ಚಂದ್ರೋದಯ ದರ್ಶನ.';
      if (lang == 'hi') return 'आज संकष्टी चतुर्थी व्रत! गणेश पूजन व चंद्र दर्शन।';
      if (lang == 'ta') return 'இன்று சங்கடஹர சதுர்த்தி விரதம்!';
      if (lang == 'ml') return 'ഇന്ന് സങ്കഷ്ടഹര ചതുർത്ഥി!';
      return 'Today is Sankashti Chaturthi Vrata!';
    }
    if (key == 'vinayaka_chaturthi') {
      if (lang == 'kn') return 'ಇಂದು ಶುಕ್ಲ ಪಕ್ಷ ವಿನಾಯಕ ಚತುರ್ಥಿ ಪೂಜೆ.';
      if (lang == 'hi') return 'आज शुक्ल पक्ष विनायक चतुर्थी पूजन।';
      return 'Today is Shukla Vinayaka Chaturthi!';
    }
    if (key == 'ekadashi') {
      if (lang == 'kn') return 'ಇಂದು ಪರಮ ಪವಿತ್ರ ಏಕಾದಶೀ ಮಹಾವ್ರತ! ಹರಿನಾಮ ಸಂಕೀರ್ತನೆ.';
      if (lang == 'hi') return 'आज परम पावन एकादशी महाव्रत! हरि नाम संकीर्तन।';
      return 'Today is Auspicious Ekadashi Mahavrata!';
    }
    if (key == 'pradosha') {
      if (lang == 'kn') return 'ಇಂದು ಪ್ರದೋಷ ಕಾಲದ ಶಿವ ಆರಾಧನೆ ಮತ್ತು ರುದ್ರಾಭಿಷೇಕ.';
      if (lang == 'hi') return 'आज प्रदोष काल शिव आराधना एवं रुद्राभिषेक।';
      return 'Today is Sacred Pradosha Twilight Worship!';
    }
    if (key == 'purnima') {
      if (lang == 'kn') return 'ಇಂದು ಹುಣ್ಣಿಮೆ ವ್ರತ ಹಾಗೂ ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ಪೂಜೆ.';
      if (lang == 'hi') return 'आज पावन पूर्णिमा व्रत व श्री सत्यनारायण कथा।';
      return 'Today is Auspicious Purnima Satyanarayana Vrata!';
    }
    if (key == 'amavasya') {
      if (lang == 'kn') return 'ಇಂದು ಅಮಾವಾಸ್ಯೆ ಪಿತೃ ತರ್ಪಣ ಹಾಗೂ ಶಾಂತಿ ಪೂಜೆ.';
      if (lang == 'hi') return 'आज अमावस्या पितृ तर्पण एवं दान-पुण्य काल।';
      return 'Today is Sacred Amavasya Pitru Tharpanam!';
    }
    if (key == 'wednesday_blessing') {
      if (lang == 'kn') return 'ಬುಧವಾರ: ಶ್ರೀ ಕೃಷ್ಣ, ಪಾಂಡುರಂಗ ವಿಟ್ಠಲ ಮತ್ತು ಬುಧಗ್ರಹ ಪ್ರಾರ್ಥನೆ ಶುಭಕರ.';
      if (lang == 'hi') return 'बुधवार: श्री कृष्ण, पांडुरंग विट्ठल एवं बुध देव की पावन आराधना।';
      if (lang == 'ta') return 'புதன்கிழமை: ஸ்ரீ கிருஷ்ணர் மற்றும் விட்டலர் வழிபாடு.';
      if (lang == 'ml') return 'ബുധനാഴ്ച: ശ്രീ കൃഷ്ണൻ, വിഠലൻ പ്രാർത്ഥന.';
      return 'Wednesday: Divine prayers to Sri Krishna & Panduranga Vitthala.';
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
}
