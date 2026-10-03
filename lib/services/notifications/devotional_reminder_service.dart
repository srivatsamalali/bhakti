import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import '../panchanga/panchanga_service.dart';
import '../wisdom/daily_wisdom_service.dart';

class DevotionalNotificationPayload {
  final String id;
  final String title;
  final String body;
  final String time;
  final String icon;
  final DateTime scheduledFor;

  const DevotionalNotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.scheduledFor,
  });
}

class DevotionalReminderService with ChangeNotifier {
  static const MethodChannel _nativeChannel = MethodChannel('com.bhakti.devotional/notifications');
  static const String _keyMorningEnabled = 'reminder_morning_enabled';
  static const String _keyMorningTime = 'reminder_morning_time';
  static const String _keyMidDayWisdomEnabled = 'reminder_midday_wisdom_enabled';
  static const String _keyEveningEnabled = 'reminder_evening_enabled';
  static const String _keyEveningTime = 'reminder_evening_time';
  static const String _keyNightNidraEnabled = 'reminder_night_nidra_enabled';
  static const String _keyFestivalAlerts = 'reminder_festival_alerts';
  static const String _keyDailyShloka = 'reminder_daily_shloka';
  static const String _keyBrahmaMuhurtaDynamic = 'reminder_brahma_muhurta_dynamic';

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool _morningEnabled = true;
  String _morningTime = '05:15 AM';
  bool _midDayWisdomEnabled = true;
  bool _eveningEnabled = true;
  String _eveningTime = '06:30 PM';
  bool _nightNidraEnabled = true;
  bool _festivalAlerts = true;
  bool _dailyShlokaEnabled = true;
  bool _isBrahmaMuhurtaDynamic = true;

  bool get morningEnabled => _morningEnabled;
  String get morningTime => _morningTime;
  bool get midDayWisdomEnabled => _midDayWisdomEnabled;
  bool get eveningEnabled => _eveningEnabled;
  String get eveningTime => _eveningTime;
  bool get nightNidraEnabled => _nightNidraEnabled;
  bool get festivalAlerts => _festivalAlerts;
  bool get dailyShlokaEnabled => _dailyShlokaEnabled;
  bool get isBrahmaMuhurtaDynamic => _isBrahmaMuhurtaDynamic;
  bool get isInitialized => _isInitialized;

  DevotionalReminderService() {
    _initService();
  }

  Future<void> _initService() async {
    await _initTimeZones();
    await _initLocalNotifications();
    await _loadPreferences();
    await scheduleSmartDevotionalNotifications('en');
  }

  Future<void> _initTimeZones() async {
    try {
      tz.initializeTimeZones();
      // Default to Asia/Kolkata or device local
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        // Fallback to local timezone
      }
    } catch (e) {
      debugPrint('Error initializing timezones: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Devotional notification tapped: ${response.payload}');
        },
      );

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  /// Explicitly requests notification permissions from iOS / Android
  Future<bool> requestNotificationPermissions() async {
    try {
      if (!_isInitialized) {
        await _initLocalNotifications();
      }
      if (Platform.isIOS) {
        final ios = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (ios != null) {
          final bool? result = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
          if (result == true) return true;
        }
        try {
          final bool? granted = await _nativeChannel.invokeMethod<bool>('requestNativePermissions');
          return granted ?? true;
        } catch (_) {
          return true;
        }
      } else if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final bool? granted = await androidImplementation?.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _morningEnabled = prefs.getBool(_keyMorningEnabled) ?? true;
    _morningTime = prefs.getString(_keyMorningTime) ?? '05:15 AM';
    _midDayWisdomEnabled = prefs.getBool(_keyMidDayWisdomEnabled) ?? true;
    _eveningEnabled = prefs.getBool(_keyEveningEnabled) ?? true;
    _eveningTime = prefs.getString(_keyEveningTime) ?? '06:30 PM';
    _nightNidraEnabled = prefs.getBool(_keyNightNidraEnabled) ?? true;
    _festivalAlerts = prefs.getBool(_keyFestivalAlerts) ?? true;
    _dailyShlokaEnabled = prefs.getBool(_keyDailyShloka) ?? true;
    _isBrahmaMuhurtaDynamic = prefs.getBool(_keyBrahmaMuhurtaDynamic) ?? true;
    notifyListeners();
  }

  Future<void> toggleMorning(bool enabled) async {
    _morningEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMorningEnabled, enabled);
    await scheduleSmartDevotionalNotifications('en');
  }

  Future<void> setMorningTime(String time) async {
    _morningTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMorningTime, time);
    await scheduleSmartDevotionalNotifications('en');
  }

  Future<void> toggleMidDayWisdom(bool enabled) async {
    _midDayWisdomEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMidDayWisdomEnabled, enabled);
    await scheduleSmartDevotionalNotifications('en');
  }

  Future<void> toggleEvening(bool enabled) async {
    _eveningEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEveningEnabled, enabled);
    await scheduleSmartDevotionalNotifications('en');
  }

  Future<void> setEveningTime(String time) async {
    _eveningTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEveningTime, time);
    await scheduleSmartDevotionalNotifications('en');
  }

  Future<void> toggleNightNidra(bool enabled) async {
    _nightNidraEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNightNidraEnabled, enabled);
    await scheduleSmartDevotionalNotifications('en');
  }

  Future<void> toggleFestivalAlerts(bool enabled) async {
    _festivalAlerts = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFestivalAlerts, enabled);
    await scheduleSmartDevotionalNotifications('en');
  }

  Future<void> toggleDailyShloka(bool enabled) async {
    _dailyShlokaEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyShloka, enabled);
    await scheduleSmartDevotionalNotifications('en');
  }

  Future<void> toggleBrahmaMuhurtaDynamic(bool enabled) async {
    _isBrahmaMuhurtaDynamic = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBrahmaMuhurtaDynamic, enabled);
    await scheduleSmartDevotionalNotifications('en');
  }

  /// Calculates dynamic Brahma Muhurta for today (1 hr 36 min prior to astronomical sunrise)
  String getCalculatedBrahmaMuhurtaTime() {
    final now = DateTime.now();
    final panchanga = PanchangaService().getPanchangaForDate(now, 'en');
    return panchanga.brahmaMuhurta;
  }

  /// Schedules rolling dynamic smart notifications for the next 7 days with healthy intervals
  Future<void> scheduleSmartDevotionalNotifications(String langCode) async {
    try {
      // 1. Cancel previous pending notifications
      await _notificationsPlugin.cancelAll();

      final now = DateTime.now();

      const NotificationDetails platformDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'devotional_reminders_channel',
          'Devotional Reminders & Shlokas',
          channelDescription: 'Sacred daily prayer, tithi alerts and wisdom notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      // Schedule for next 7 days
      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final targetDate = now.add(Duration(days: dayOffset));
        final panchanga = PanchangaService().getPanchangaForDate(targetDate, langCode);
        final wisdom = DailyWisdomService.getWisdomForDate(targetDate);

        // 1. Slot 1: 🌅 Brahma Muhurta / Morning Suprabhatam (~05:15 AM)
        if (_morningEnabled) {
          int hour = 5;
          int minute = 15;
          if (!_isBrahmaMuhurtaDynamic) {
            final parsed = _parseTimeString(_morningTime);
            hour = parsed['hour']!;
            minute = parsed['minute']!;
          }

          final scheduledDate = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
          if (scheduledDate.isAfter(now)) {
            final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
            final title = _getLocalizedMorningTitle(langCode);
            final body = _getLocalizedMorningBody(langCode, panchanga);

            await _notificationsPlugin.zonedSchedule(
              100 + dayOffset,
              title,
              body,
              tzDate,
              platformDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'morning_brahma_muhurta',
            );
          }
        }

        // 2. Slot 2: 🌸 Mid-Day Sacred Wisdom / Vachana (~01:00 PM) - 7.5 hours after morning
        if (_midDayWisdomEnabled || _dailyShlokaEnabled) {
          final scheduledDate = DateTime(targetDate.year, targetDate.month, targetDate.day, 13, 0);
          if (scheduledDate.isAfter(now)) {
            final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
            final author = wisdom.getAuthor(langCode);
            final verseSnippet = wisdom.getVerse(langCode).split('\n').first;

            await _notificationsPlugin.zonedSchedule(
              200 + dayOffset,
              '🌸 $author • Sacred Wisdom',
              '॥ $verseSnippet ॥ ${wisdom.getMeaning(langCode)}',
              tzDate,
              platformDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'midday_wisdom',
            );
          }
        }

        // 3. Slot 3: 🪔 Evening Sandhya Deepam & Aarti (~06:30 PM) - 5.5 hours after midday
        if (_eveningEnabled) {
          final parsed = _parseTimeString(_eveningTime);
          final scheduledDate = DateTime(targetDate.year, targetDate.month, targetDate.day, parsed['hour']!, parsed['minute']!);
          if (scheduledDate.isAfter(now)) {
            final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
            final title = _getLocalizedEveningTitle(langCode);
            final body = _getLocalizedEveningBody(langCode, panchanga);

            await _notificationsPlugin.zonedSchedule(
              300 + dayOffset,
              title,
              body,
              tzDate,
              platformDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'evening_sandhya_deepam',
            );
          }
        }

        // 4. Slot 4: 🌙 Night Shantih & Bedtime Prayer (~09:45 PM) - 3.25 hours after evening
        if (_nightNidraEnabled) {
          final scheduledDate = DateTime(targetDate.year, targetDate.month, targetDate.day, 21, 45);
          if (scheduledDate.isAfter(now)) {
            final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
            final title = _getLocalizedNightTitle(langCode);
            final body = _getLocalizedNightBody(langCode);

            await _notificationsPlugin.zonedSchedule(
              400 + dayOffset,
              title,
              body,
              tzDate,
              platformDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'night_nidra',
            );
          }
        }

        // 5. Special Festival / Auspicious Tithi Alert (~08:00 AM on festival days)
        if (_festivalAlerts && (panchanga.specialOccasion.isNotEmpty || panchanga.upcomingFestivals.isNotEmpty)) {
          final scheduledDate = DateTime(targetDate.year, targetDate.month, targetDate.day, 8, 0);
          if (scheduledDate.isAfter(now)) {
            final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
            final festivalName = panchanga.specialOccasion.isNotEmpty ? panchanga.specialOccasion : panchanga.upcomingFestivals.first;

            await _notificationsPlugin.zonedSchedule(
              500 + dayOffset,
              '✨ $festivalName Today',
              'Today is auspicious $festivalName (${panchanga.tithi}). May the Divine grace fill your home.',
              tzDate,
              platformDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'festival_alert',
            );
          }
        }
      }

      debugPrint('Successfully scheduled 7-day rolling smart devotional notifications.');
    } catch (e) {
      debugPrint('Error scheduling smart devotional notifications: $e');
    }
  }

  /// Sends an immediate test notification to verify notification permissions and sound on device
  Future<bool> sendInstantTestNotification(String langCode) async {
    try {
      final granted = await requestNotificationPermissions();
      final now = DateTime.now();
      final panchanga = PanchangaService().getPanchangaForDate(now, langCode);
      final wisdom = DailyWisdomService.getWisdomForDate(now);
      final title = '🕉️ Bhakti • Sacred Devotional Alert';
      final body = 'Today: ${panchanga.tithi} (${panchanga.dayOfWeek}). "${wisdom.getVerse(langCode).split('\n').first}"';

      const NotificationDetails platformDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'devotional_reminders_channel',
          'Devotional Reminders & Shlokas',
          channelDescription: 'Sacred daily prayer, tithi alerts and wisdom notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      await _notificationsPlugin.show(
        999,
        title,
        body,
        platformDetails,
        payload: 'test_notification_instant',
      );

      return granted;
    } catch (e) {
      debugPrint('Error sending instant test notification: $e');
      return false;
    }
  }

  /// Opens iOS / Android system settings for this app so user can enable notifications
  Future<void> openNotificationSettings() async {
    try {
      if (Platform.isIOS) {
        final uri = Uri.parse('app-settings:');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      debugPrint('Error opening system notification settings: $e');
    }
  }

  /// Delivers a warm, divine welcome notification right after app installation / launch
  Future<void> sendWelcomeInstallationNotification(String langCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadySent = prefs.getBool('has_sent_welcome_notification') ?? false;
      if (alreadySent) return;

      await requestNotificationPermissions();

      final title = _getLocalizedWelcomeTitle(langCode);
      final body = _getLocalizedWelcomeBody(langCode);

      if (Platform.isIOS) {
        Future.delayed(const Duration(seconds: 3), () async {
          await _nativeChannel.invokeMethod('showNativeNotification', {
            'title': title,
            'body': body,
          });
          await prefs.setBool('has_sent_welcome_notification', true);
          debugPrint('Native iOS welcome notification successfully dispatched.');
        });
        return;
      }

      const NotificationDetails platformDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'devotional_reminders_channel',
          'Devotional Reminders & Shlokas',
          channelDescription: 'Sacred daily prayer, tithi alerts and wisdom notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );

      final tzTarget = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3));
      await _notificationsPlugin.zonedSchedule(
        1,
        title,
        body,
        tzTarget,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'welcome_onboarding',
      );
      await prefs.setBool('has_sent_welcome_notification', true);
      debugPrint('Welcome notification successfully scheduled for first launch.');
    } catch (e) {
      debugPrint('Error sending welcome notification: $e');
    }
  }

  String _getLocalizedWelcomeTitle(String lang) {
    switch (lang) {
      case 'kn':
        return '🙏 ಭಕ್ತಿ ಆ್ಯಪ್‌ಗೆ ಆತ್ಮೀಯ ಸ್ವಾಗತ!';
      case 'hi':
        return '🙏 भक्ति ऐप में आपका हार्दिक स्वागत है!';
      case 'ta':
        return '🙏 பக்தி செயலியில் நல்வரவு!';
      case 'ml':
        return '🙏 ഭക്തി ആപ്പിലേക്ക് ഹൃദ്യമായ സ്വാഗതം!';
      default:
        return '🙏 Welcome to Bhakti!';
    }
  }

  String _getLocalizedWelcomeBody(String lang) {
    switch (lang) {
      case 'kn':
        return 'ಭಕ್ತಿ ಆ್ಯಪ್ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿದ್ದಕ್ಕಾಗಿ ಧನ್ಯವಾದಗಳು. ಲೈವ್ ಪಂಚಾಂಗ, ದಿನದ ರಾಶಿ ವಿವರಗಳು, ಪವಿತ್ರ ಶ್ಲೋಕಗಳು ಮತ್ತು ಭಕ್ತಿಗೀತೆಗಳೊಂದಿಗೆ ದೈವೀ ಅನುಭವ ಪಡೆಯಿರಿ.';
      case 'hi':
        return 'भक्ति ऐप डाउनलोड करने के लिए धन्यवाद! दैनिक पंचांग, दैनिक ज्ञान, राशि विवरण और भक्ति गीतों के साथ दिव्य अनुभव प्राप्त करें।';
      case 'ta':
        return 'பக்தி செயலியை பதிவிறக்கம் செய்ததற்கு நன்றி! தினசரி பஞ்சாங்கம், ராசி பலன்கள் மற்றும் பக்திப் பாடல்களுடன் தெய்வீக அனுபவத்தைப் பெறுங்கள்.';
      case 'ml':
        return 'ഭക്തി ആപ്പ് ഡൗൺലോഡ് ചെയ്തതിന് നന്ദി! ദിന പഞ്ചാംഗം, രാശിഫലം, ഭക്തിഗാനങ്ങൾ എന്നിവയിലൂടെ ദിവ്യമായ അനുഭവം നേടുക.';
      default:
        return 'Thanks for downloading Bhakti app! You\'ll get a divine experience with live Panchanga, Daily Sacred Notes, Rashi details & Devotional songs.';
    }
  }

  Map<String, int> _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';

      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      return {'hour': hour, 'minute': minute};
    } catch (_) {
      return {'hour': 5, 'minute': 15};
    }
  }

  String _getLocalizedMorningTitle(String lang) {
    switch (lang) {
      case 'kn':
        return '🌅 ಬ್ರಾಹ್ಮೀ ಮುಹೂರ್ತ ಮತ್ತು ಸುಪ್ರಭಾತ';
      case 'hi':
        return '🌅 ब्रह्म मुहूर्त एवं सुप्रभातम्';
      case 'ta':
        return '🌅 பிரம்ம முகூர்த்தம் & சுப்ரபாதம்';
      case 'ml':
        return '🌅 ബ്രഹ്മമുഹൂർത്തവും സുപ്രഭാതവും';
      default:
        return '🌅 Brahma Muhurta & Suprabhatam';
    }
  }

  String _getLocalizedMorningBody(String lang, PanchangaData p) {
    switch (lang) {
      case 'kn':
        return 'ಇಂದು ${p.tithi} (${p.dayOfWeek}). ಶ್ರೀ ವೆಂಕಟೇಶ್ವರ ಸುಪ್ರಭಾತದೊಂದಿಗೆ ದಿನವನ್ನು ಆರಂಭಿಸಿ.';
      case 'hi':
        return 'आज ${p.tithi} (${p.dayOfWeek}) है। श्री वेंकटेश्वर सुप्रभातम् के साथ दिन की शुरुआत करें।';
      case 'ta':
        return 'இன்று ${p.tithi} (${p.dayOfWeek}). ஸ்ரீ வெங்கடேஸ்வர சுப்ரபாதத்துடன் நாளைத் தொடங்குங்கள்.';
      case 'ml':
        return 'ഇന്ന് ${p.tithi} (${p.dayOfWeek}). ശ്രീ വെങ്കടേശ്വര സുപ്രഭാതത്തോടെ ദിനം ആരംഭിക്കുക.';
      default:
        return 'Today is ${p.tithi} (${p.dayOfWeek}). Begin your morning with sacred Sri Venkateswara Suprabhatam.';
    }
  }

  String _getLocalizedEveningTitle(String lang) {
    switch (lang) {
      case 'kn':
        return '🪔 ಸಂಧ್ಯಾ ದೀಪ ಮತ್ತು ಆರತಿ';
      case 'hi':
        return '🪔 संध्या दीप एवं आरती';
      case 'ta':
        return '🪔 அந்தி மாலை தீபம் & ஆரத்தி';
      case 'ml':
        return '🪔 സന്ധ്യാ ദീപവും ആരതിയും';
      default:
        return '🪔 Sandhya Aarti & Diya Lighting';
    }
  }

  String _getLocalizedEveningBody(String lang, PanchangaData p) {
    switch (lang) {
      case 'kn':
        return 'ಪವಿತ್ರ ಸಂಧ್ಯಾ ಸಮಯ. ದೀಪ ಬೆಳಗಿಸಿ ಶ್ರೀ ಲಲಿತಾ ಸಹಸ್ರನಾಮ ಅಥವಾ ವಿಷ್ಣು ಸಹಸ್ರನಾಮ ಪಠಿಸಿ.';
      case 'hi':
        return 'शुभ संध्या काल। पावन दीप प्रज्वलित कर श्री ललिता सहस्रनाम का पाठ करें।';
      case 'ta':
        return 'புனிதமான மாலை நேரம். தீபம் ஏற்றி ஸ்ரீ லலிதா சஹஸ்ரநாமம் கேளுங்கள்.';
      case 'ml':
        return 'പവിത്രമായ സന്ധ്യാ സമയം. ദീപം കൊളുത്തി ശ്രീ ലളിതാ സഹസ്രനാമം ജപിക്കുക.';
      default:
        return 'Auspicious dusk hour. Light your sacred diya and immerse in Sri Lalitha Sahasranamam.';
    }
  }

  String _getLocalizedNightTitle(String lang) {
    switch (lang) {
      case 'kn':
        return '🌙 ಶಾಂತಿ ಮಂತ್ರ ಮತ್ತು ರಾತ್ರಿ ಪ್ರಾರ್ಥನೆ';
      case 'hi':
        return '🌙 शांति मंत्र एवं रात्रि प्रार्थना';
      case 'ta':
        return '🌙 சாந்தி மந்திரம் & இரவு பிரார்த்தனை';
      case 'ml':
        return '🌙 ശാന്തി മന്ത്രവും രാത്രി പ്രാർത്ഥനയും';
      default:
        return '🌙 Shanti Mantra & Night Serenity';
    }
  }

  String _getLocalizedNightBody(String lang) {
    switch (lang) {
      case 'kn':
        return '॥ ॐ ಶಾಂತಿಃ ಶಾಂತಿಃ ಶಾಂತಿಃ ॥ ಮನಸ್ಸಿಗೆ ಶಾಂತಿ, ನೆಮ್ಮದಿಯ ನಿದ್ರೆ ಪ್ರಾಪ್ತಿಯಾಗಲಿ.';
      case 'hi':
        return '॥ ॐ शान्तिः शान्तिः शान्तिः ॥ आपका मन शांत रहे और सुखद निद्रा प्राप्त हो।';
      case 'ta':
        return '॥ ஓம் சாந்தி சாந்தி சாந்தி ॥ மனம் அமைதி பெற்று இனிய தூக்கம் உண்டாகட்டும்.';
      case 'ml':
        return '॥ ഓം ശാന്തിഃ ശാന്തിഃ ശാന്തിഃ ॥ മനസ്സിന് ശാന്തിയും സുഖനിദ്രയും ലഭിക്കട്ടെ.';
      default:
        return '॥ Om Shantih Shantih Shantih ॥ Conclude your day in divine gratitude and peaceful sleep.';
    }
  }

  /// Generates the upcoming smart notification preview payloads for today
  List<DevotionalNotificationPayload> getUpcomingSmartNotifications(String langCode) {
    final now = DateTime.now();
    final panchanga = PanchangaService().getPanchangaForDate(now, langCode);
    final wisdom = DailyWisdomService.getWisdomForDate(now);
    final List<DevotionalNotificationPayload> list = [];

    if (_morningEnabled) {
      final timeStr = _isBrahmaMuhurtaDynamic ? panchanga.brahmaMuhurta : _morningTime;
      list.add(
        DevotionalNotificationPayload(
          id: 'morning_brahma_muhurta',
          title: _getLocalizedMorningTitle(langCode),
          body: _getLocalizedMorningBody(langCode, panchanga),
          time: timeStr,
          icon: '🕉️',
          scheduledFor: DateTime(now.year, now.month, now.day, 5, 15),
        ),
      );
    }

    if (_midDayWisdomEnabled || _dailyShlokaEnabled) {
      final author = wisdom.getAuthor(langCode);
      final verse = wisdom.getVerse(langCode).split('\n').first;
      list.add(
        DevotionalNotificationPayload(
          id: 'daily_sacred_shloka',
          title: '🌸 $author • Sacred Wisdom',
          body: '॥ $verse ॥ ${wisdom.getMeaning(langCode)}',
          time: '01:00 PM',
          icon: '📿',
          scheduledFor: DateTime(now.year, now.month, now.day, 13, 0),
        ),
      );
    }

    if (_eveningEnabled) {
      list.add(
        DevotionalNotificationPayload(
          id: 'evening_sandhya_deepam',
          title: _getLocalizedEveningTitle(langCode),
          body: _getLocalizedEveningBody(langCode, panchanga),
          time: _eveningTime,
          icon: '🪔',
          scheduledFor: DateTime(now.year, now.month, now.day, 18, 30),
        ),
      );
    }

    if (_nightNidraEnabled) {
      list.add(
        DevotionalNotificationPayload(
          id: 'night_nidra',
          title: _getLocalizedNightTitle(langCode),
          body: _getLocalizedNightBody(langCode),
          time: '09:45 PM',
          icon: '🌙',
          scheduledFor: DateTime(now.year, now.month, now.day, 21, 45),
        ),
      );
    }

    if (_festivalAlerts && (panchanga.specialOccasion.isNotEmpty || panchanga.upcomingFestivals.isNotEmpty)) {
      final title = panchanga.specialOccasion.isNotEmpty ? panchanga.specialOccasion : 'Auspicious ${panchanga.tithi}';
      list.add(
        DevotionalNotificationPayload(
          id: 'special_tithi_alert',
          title: '✨ $title Today',
          body: 'Today is an auspicious day for fasting, sacred chanting and temple darshan.',
          time: '08:00 AM',
          icon: '🔔',
          scheduledFor: DateTime(now.year, now.month, now.day, 8, 0),
        ),
      );
    }

    return list;
  }
}
