import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;

  void initialize() {
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('Firebase Analytics initialize skipped: $e');
    }
  }

  Future<void> logAppOpen() async {
    try {
      await _analytics?.logAppOpen();
    } catch (_) {}
  }

  Future<void> logLanguageSelected(String langCode) async {
    try {
      await _analytics?.logEvent(
        name: 'language_selected',
        parameters: {'language': langCode},
      );
    } catch (_) {}
  }

  Future<void> logSongViewed(String songId, String songTitle) async {
    try {
      await _analytics?.logEvent(
        name: 'song_viewed',
        parameters: {
          'song_id': songId,
          'song_title': songTitle,
        },
      );
    } catch (_) {}
  }

  Future<void> logSongStarted(String songId, String songTitle, String category) async {
    try {
      await _analytics?.logEvent(
        name: 'song_started',
        parameters: {
          'song_id': songId,
          'song_title': songTitle,
          'category': category,
        },
      );
    } catch (_) {}
  }

  Future<void> logSongCompleted(String songId, String songTitle) async {
    try {
      await _analytics?.logEvent(
        name: 'song_completed',
        parameters: {
          'song_id': songId,
          'song_title': songTitle,
        },
      );
    } catch (_) {}
  }

  Future<void> logSongFavorited(String songId, bool favorited) async {
    try {
      await _analytics?.logEvent(
        name: favorited ? 'song_favorited' : 'song_unfavorited',
        parameters: {'song_id': songId},
      );
    } catch (_) {}
  }

  Future<void> logSearchUsed(String query) async {
    try {
      await _analytics?.logSearch(searchTerm: query);
    } catch (_) {}
  }

  Future<void> logCategoryOpened(String categoryId) async {
    try {
      await _analytics?.logEvent(
        name: 'category_opened',
        parameters: {'category_id': categoryId},
      );
    } catch (_) {}
  }
}
