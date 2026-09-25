import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class PreferencesService extends ChangeNotifier {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // --- Language ---
  String getSelectedLanguage() {
    return _prefs.getString(AppConstants.keySelectedLanguage) ?? AppConstants.langKannada;
  }

  Future<bool> setSelectedLanguage(String langCode) async {
    final success = await _prefs.setString(AppConstants.keySelectedLanguage, langCode);
    notifyListeners();
    return success;
  }

  // --- First Launch ---
  bool isFirstLaunch() {
    return _prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;
  }

  Future<bool> setFirstLaunchComplete() async {
    final success = await _prefs.setBool(AppConstants.keyIsFirstLaunch, false);
    notifyListeners();
    return success;
  }

  // --- Favorites ---
  List<String> getFavoriteSongIds() {
    return List<String>.from(_prefs.getStringList(AppConstants.keyFavorites) ?? const []);
  }

  Future<bool> toggleFavorite(String songId) async {
    final list = List<String>.from(_prefs.getStringList(AppConstants.keyFavorites) ?? const []);
    if (list.contains(songId)) {
      list.remove(songId);
    } else {
      list.insert(0, songId);
    }
    final success = await _prefs.setStringList(AppConstants.keyFavorites, list);
    notifyListeners();
    return success;
  }

  bool isFavorite(String songId) {
    return getFavoriteSongIds().contains(songId);
  }

  // --- Recently Played ---
  List<String> getRecentlyPlayedIds() {
    return List<String>.from(_prefs.getStringList(AppConstants.keyRecentlyPlayed) ?? const []);
  }

  Future<bool> addRecentlyPlayed(String songId) async {
    final list = List<String>.from(_prefs.getStringList(AppConstants.keyRecentlyPlayed) ?? const []);
    list.remove(songId); // remove if exists so it moves to front
    list.insert(0, songId);
    if (list.length > AppConstants.maxRecentHistoryCount) {
      list.removeRange(AppConstants.maxRecentHistoryCount, list.length);
    }
    final success = await _prefs.setStringList(AppConstants.keyRecentlyPlayed, list);
    notifyListeners();
    return success;
  }

  Future<bool> clearRecentlyPlayed() async {
    final success = await _prefs.setStringList(AppConstants.keyRecentlyPlayed, []);
    notifyListeners();
    return success;
  }

  // --- Playback Speed ---
  double getPlaybackSpeed() {
    return _prefs.getDouble(AppConstants.keyPlaybackSpeed) ?? 1.0;
  }

  Future<bool> setPlaybackSpeed(double speed) async {
    final success = await _prefs.setDouble(AppConstants.keyPlaybackSpeed, speed);
    notifyListeners();
    return success;
  }

  // --- Admin Security Hash ---
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode('bhakti_salt_$password')).toString();
  }

  bool verifyAdminPassword(String password) {
    final storedHash = _prefs.getString(AppConstants.keyAdminHashedPass);
    final inputHash = _hashPassword(password);
    if (storedHash == null) {
      // Default initial credentials: sri / sri
      return password == AppConstants.defaultAdminPass;
    }
    return storedHash == inputHash;
  }

  Future<bool> changeAdminPassword(String newPassword) async {
    final hash = _hashPassword(newPassword);
    final success = await _prefs.setString(AppConstants.keyAdminHashedPass, hash);
    notifyListeners();
    return success;
  }

  // --- Bhakti AI Assistant Preferences ---
  bool isAiAssistantEnabled() {
    return _prefs.getBool(AppConstants.keyAiEnabled) ?? true;
  }

  Future<bool> setAiAssistantEnabled(bool enabled) async {
    final success = await _prefs.setBool(AppConstants.keyAiEnabled, enabled);
    notifyListeners();
    return success;
  }

  bool isAiVoiceInputEnabled() {
    return _prefs.getBool(AppConstants.keyAiVoiceInputEnabled) ?? true;
  }

  Future<bool> setAiVoiceInputEnabled(bool enabled) async {
    final success = await _prefs.setBool(AppConstants.keyAiVoiceInputEnabled, enabled);
    notifyListeners();
    return success;
  }

  bool isAiVoiceOutputEnabled() {
    return _prefs.getBool(AppConstants.keyAiVoiceOutputEnabled) ?? false;
  }

  Future<bool> setAiVoiceOutputEnabled(bool enabled) async {
    final success = await _prefs.setBool(AppConstants.keyAiVoiceOutputEnabled, enabled);
    notifyListeners();
    return success;
  }

  String getAiPreferredLanguage() {
    return _prefs.getString(AppConstants.keyAiPreferredLanguage) ?? 'auto';
  }

  Future<bool> setAiPreferredLanguage(String mode) async {
    final success = await _prefs.setString(AppConstants.keyAiPreferredLanguage, mode);
    notifyListeners();
    return success;
  }

  // --- Admin AI Configuration ---
  bool isAdminAiGlobalEnabled() {
    return _prefs.getBool(AppConstants.keyAdminAiGlobalEnabled) ?? true;
  }

  Future<bool> setAdminAiGlobalEnabled(bool enabled) async {
    final success = await _prefs.setBool(AppConstants.keyAdminAiGlobalEnabled, enabled);
    notifyListeners();
    return success;
  }

  int getAdminAiDailyLimit() {
    return _prefs.getInt(AppConstants.keyAdminAiDailyLimit) ?? 50;
  }

  Future<bool> setAdminAiDailyLimit(int limit) async {
    final success = await _prefs.setInt(AppConstants.keyAdminAiDailyLimit, limit);
    notifyListeners();
    return success;
  }

  int getAdminAiMaxTokens() {
    return _prefs.getInt(AppConstants.keyAdminAiMaxTokens) ?? 300;
  }

  Future<bool> setAdminAiMaxTokens(int tokens) async {
    final success = await _prefs.setInt(AppConstants.keyAdminAiMaxTokens, tokens);
    notifyListeners();
    return success;
  }

  // --- Offline Song Catalog Cache ---
  static const String keyCachedSongs = 'bhakti_offline_songs_cache_v2';

  String? getCachedSongsJson() {
    return _prefs.getString(keyCachedSongs);
  }

  Future<bool> saveCachedSongsJson(String jsonString) async {
    return _prefs.setString(keyCachedSongs, jsonString);
  }
}

