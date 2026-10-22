import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Intelligent on-device & online translation service for Devotional Songs & Wisdom texts.
/// Translates uploaded or English song titles and meanings automatically to the user's
/// preferred language (Kannada, Telugu, Hindi, Tamil, Malayalam) and caches results locally.
class SongTranslationService extends ChangeNotifier {
  static final SongTranslationService _instance = SongTranslationService._internal();
  static SongTranslationService get instance => _instance;
  SongTranslationService._internal();

  static const String _prefCacheKey = 'devotional_translations_cache_v2';

  // Cache: _cache[targetLang][sourceText] = translatedText
  final Map<String, Map<String, String>> _cache = {};
  final Set<String> _inFlight = {};
  bool _initialized = false;

  /// Initializes the local translation cache from SharedPreferences
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((lang, map) {
          if (map is Map) {
            _cache[lang] = Map<String, String>.from(
              map.map((k, v) => MapEntry(k.toString(), v.toString())),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[SongTranslationService] Error loading cache: $e');
    }
    _initialized = true;
  }

  /// Synchronously returns cached translation if present
  String? getCachedTranslation(String text, String targetLang) {
    if (targetLang == 'en' || text.trim().isEmpty) return null;
    return _cache[targetLang]?[text.trim()];
  }

  /// Fire-and-forget translation request for background fetching
  void requestTranslation(String text, String targetLang, {String sourceLang = 'en'}) {
    if (targetLang == 'en' || text.trim().isEmpty) return;
    final trimmed = text.trim();
    if (_cache[targetLang]?.containsKey(trimmed) == true) return;

    final flightKey = '$targetLang::$trimmed';
    if (_inFlight.contains(flightKey)) return;

    translate(trimmed, targetLang, sourceLang: sourceLang);
  }

  /// Translates text to target language via high-speed translation endpoint with caching
  Future<String> translate(
    String text,
    String targetLang, {
    String sourceLang = 'en',
  }) async {
    final trimmed = text.trim();
    if (targetLang == 'en' || trimmed.isEmpty) return trimmed;

    // Check in-memory cache
    if (_cache[targetLang]?.containsKey(trimmed) == true) {
      return _cache[targetLang]![trimmed]!;
    }

    final flightKey = '$targetLang::$trimmed';
    if (_inFlight.contains(flightKey)) {
      return trimmed;
    }
    _inFlight.add(flightKey);

    try {
      final encoded = Uri.encodeComponent(trimmed);
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=$encoded&langpair=$sourceLang|$targetLang',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'Mozilla/5.0 (Bhakti Devotional App)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['responseData'] != null) {
          String translated = data['responseData']['translatedText']?.toString() ?? '';
          translated = _decodeHtmlEntities(translated);
          if (translated.isNotEmpty &&
              !translated.toUpperCase().startsWith('MYMEMORY WARNING')) {
            _cache.putIfAbsent(targetLang, () => {})[trimmed] = translated;
            _persistCache();
            notifyListeners();
            return translated;
          }
        }
      }
    } catch (e) {
      debugPrint('[SongTranslationService] Translation failed for "$trimmed": $e');
    } finally {
      _inFlight.remove(flightKey);
    }

    return trimmed;
  }

  /// Prefetches translations for an entire song collection asynchronously
  Future<void> prefetchSongTitles(List<dynamic> songs, String targetLang) async {
    if (targetLang == 'en' || songs.isEmpty) return;
    for (final song in songs) {
      try {
        final title = (song.title as String?)?.trim();
        if (title != null && title.isNotEmpty) {
          final titleLoc = song.titleLocalized as Map<String, String>?;
          final alreadyLocalized = titleLoc?[targetLang] != null &&
              titleLoc![targetLang]!.trim().isNotEmpty;
          if (!alreadyLocalized && getCachedTranslation(title, targetLang) == null) {
            // Queue translation
            translate(title, targetLang);
          }
        }
      } catch (e) {
        // Continue silently for next track
      }
    }
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  Future<void> _persistCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefCacheKey, jsonEncode(_cache));
    } catch (e) {
      debugPrint('[SongTranslationService] Error saving cache: $e');
    }
  }
}
