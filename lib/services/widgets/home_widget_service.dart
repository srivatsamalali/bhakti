import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../models/song_model.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.bhakti.bhakti';
  static const String iOSWidgetName = 'BhaktiWidget';
  static const String androidWidgetName = 'BhaktiWidgetProvider';

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
      await updateDefaultWidgetData();
    } catch (e) {
      debugPrint('HomeWidgetService init error: $e');
    }
  }

  static Future<void> updateDefaultWidgetData() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>('widget_title', 'Gayatri Maha Mantra');
      await HomeWidget.saveWidgetData<String>('widget_subtitle', 'Om Bhur Bhuvaḥ Swaḥ • Divine Blessings');
      await HomeWidget.saveWidgetData<String>('widget_panchanga', 'Wednesday • Daily Vedic Panchanga');
      await HomeWidget.saveWidgetData<bool>('widget_is_playing', false);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      debugPrint('HomeWidgetService updateDefaultWidgetData error: $e');
    }
  }

  static Future<void> updateCurrentPlayingSong(SongModel song, {bool isPlaying = true, String? deity}) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>('widget_title', song.title);
      await HomeWidget.saveWidgetData<String>('widget_subtitle', deity ?? song.deity);
      await HomeWidget.saveWidgetData<bool>('widget_is_playing', isPlaying);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      debugPrint('HomeWidgetService updateCurrentPlayingSong error: $e');
    }
  }

  static Future<void> updateShlokaOfTheDay({required String title, required String sanskritText, String? meaning}) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>('widget_title', title);
      await HomeWidget.saveWidgetData<String>('widget_subtitle', sanskritText);
      if (meaning != null) {
        await HomeWidget.saveWidgetData<String>('widget_meaning', meaning);
      }
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      debugPrint('HomeWidgetService updateShlokaOfTheDay error: $e');
    }
  }
}
