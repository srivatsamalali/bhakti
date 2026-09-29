import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevotionalReminderService with ChangeNotifier {
  static const String _keyMorningEnabled = 'reminder_morning_enabled';
  static const String _keyMorningTime = 'reminder_morning_time';
  static const String _keyEveningEnabled = 'reminder_evening_enabled';
  static const String _keyEveningTime = 'reminder_evening_time';
  static const String _keyFestivalAlerts = 'reminder_festival_alerts';
  static const String _keyDailyShloka = 'reminder_daily_shloka';

  bool _morningEnabled = true;
  String _morningTime = '05:30 AM';
  bool _eveningEnabled = true;
  String _eveningTime = '06:30 PM';
  bool _festivalAlerts = true;
  bool _dailyShlokaEnabled = true;

  bool get morningEnabled => _morningEnabled;
  String get morningTime => _morningTime;
  bool get eveningEnabled => _eveningEnabled;
  String get eveningTime => _eveningTime;
  bool get festivalAlerts => _festivalAlerts;
  bool get dailyShlokaEnabled => _dailyShlokaEnabled;

  DevotionalReminderService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _morningEnabled = prefs.getBool(_keyMorningEnabled) ?? true;
    _morningTime = prefs.getString(_keyMorningTime) ?? '05:30 AM';
    _eveningEnabled = prefs.getBool(_keyEveningEnabled) ?? true;
    _eveningTime = prefs.getString(_keyEveningTime) ?? '06:30 PM';
    _festivalAlerts = prefs.getBool(_keyFestivalAlerts) ?? true;
    _dailyShlokaEnabled = prefs.getBool(_keyDailyShloka) ?? true;
    notifyListeners();
  }

  Future<void> toggleMorning(bool enabled) async {
    _morningEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMorningEnabled, enabled);
  }

  Future<void> setMorningTime(String time) async {
    _morningTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMorningTime, time);
  }

  Future<void> toggleEvening(bool enabled) async {
    _eveningEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEveningEnabled, enabled);
  }

  Future<void> setEveningTime(String time) async {
    _eveningTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEveningTime, time);
  }

  Future<void> toggleFestivalAlerts(bool enabled) async {
    _festivalAlerts = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFestivalAlerts, enabled);
  }

  Future<void> toggleDailyShloka(bool enabled) async {
    _dailyShlokaEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyShloka, enabled);
  }
}
