import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../models/song_model.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.bhakti.bhakti';
  static const String iOSWidgetName = 'BhaktiWidget';
  static const String androidWidgetName = 'BhaktiWidgetProvider';

  static Future<void> initialize() async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
    } catch (e) {
      debugPrint('HomeWidgetService init error: $e');
    }
  }

  /// Dynamically syncs whatever songs exist in the app database to the widget
  static Future<void> syncSongsWithWidget(
    List<SongModel> songs, {
    SongModel? currentSong,
    bool isPlaying = false,
  }) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid) || songs.isEmpty) return;
    try {
      final jsonList = songs.map((song) {
        return {
          'id': song.id,
          'title': song.title,
          'subtitle': song.deity.isNotEmpty ? song.deity : (song.description.isNotEmpty ? song.description : 'Sacred Devotional'),
          'duration': _formatDuration(song.duration),
          'category': song.categoryName?.isNotEmpty == true ? song.categoryName! : (song.categoryId.isNotEmpty ? song.categoryId : 'All'),
          'audioUrl': song.audioUrl,
          'emoji': _getDeityEmoji(song.deity, song.title),
        };
      }).toList();

      final jsonString = jsonEncode(jsonList);
      await HomeWidget.saveWidgetData<String>('widget_songs_json', jsonString);

      // Extract unique categories dynamically from current songs
      final categories = <String>['All'];
      for (final s in songs) {
        final cat = s.categoryName?.isNotEmpty == true ? s.categoryName! : s.categoryId;
        if (cat.isNotEmpty && !categories.any((c) => c.toLowerCase() == cat.toLowerCase())) {
          categories.add(cat);
        }
      }
      await HomeWidget.saveWidgetData<String>('widget_categories_json', jsonEncode(categories));

      final active = currentSong ?? songs.first;
      await HomeWidget.saveWidgetData<String>('widget_active_song_id', active.id);
      await HomeWidget.saveWidgetData<String>('widget_title', active.title);
      await HomeWidget.saveWidgetData<String>('widget_subtitle', active.deity.isNotEmpty ? active.deity : 'Sacred Chant');
      await HomeWidget.saveWidgetData<String>('widget_duration', _formatDuration(active.duration));
      await HomeWidget.saveWidgetData<String>('widget_emoji', _getDeityEmoji(active.deity, active.title));
      await HomeWidget.saveWidgetData<bool>('widget_is_playing', isPlaying);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      debugPrint('HomeWidgetService syncSongsWithWidget error: $e');
    }
  }

  static Future<void> updateCurrentPlayingSong(
    SongModel song, {
    bool isPlaying = true,
    String? deity,
  }) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
    try {
      await HomeWidget.saveWidgetData<String>('widget_active_song_id', song.id);
      await HomeWidget.saveWidgetData<String>('widget_title', song.title);
      await HomeWidget.saveWidgetData<String>('widget_subtitle', deity ?? (song.deity.isNotEmpty ? song.deity : 'Sacred Chant'));
      await HomeWidget.saveWidgetData<String>('widget_duration', _formatDuration(song.duration));
      await HomeWidget.saveWidgetData<String>('widget_emoji', _getDeityEmoji(song.deity, song.title));
      await HomeWidget.saveWidgetData<bool>('widget_is_playing', isPlaying);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      debugPrint('HomeWidgetService updateCurrentPlayingSong error: $e');
    }
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String _getDeityEmoji(String deity, String title) {
    final text = '$deity $title'.toLowerCase();
    if (text.contains('ganesh') || text.contains('ganapati')) return '🐘';
    if (text.contains('shiva') || text.contains('mrityunjaya') || text.contains('rudra')) return '🔱';
    if (text.contains('krishna') || text.contains('achyutam') || text.contains('govinda')) return '🪈';
    if (text.contains('rama') || text.contains('raghupati')) return '🏹';
    if (text.contains('hanuman') || text.contains('anjaneya')) return '🚩';
    if (text.contains('lakshmi') || text.contains('bhagyada')) return '🪷';
    if (text.contains('venkateshwara') || text.contains('venkateswara') || text.contains('govinda') || text.contains('balaji') || text.contains('tirupati')) return '👑';
    if (text.contains('durga') || text.contains('devi') || text.contains('lalitha') || text.contains('chamundi')) return '🌺';
    if (text.contains('gayathri') || text.contains('gayatri')) return '🪷';
    return 'ॐ';
  }
}
