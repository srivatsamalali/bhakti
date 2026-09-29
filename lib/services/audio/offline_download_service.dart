import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/song_model.dart';

class OfflineDownloadService with ChangeNotifier {
  static const String _keyDownloadedSongs = 'offline_downloaded_songs_v1';

  final Map<String, SongModel> _downloadedSongs = {};
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadingSongIds = {};

  Map<String, SongModel> get downloadedSongs => Map.unmodifiable(_downloadedSongs);
  Map<String, double> get downloadProgress => Map.unmodifiable(_downloadProgress);
  Set<String> get downloadingSongIds => Set.unmodifiable(_downloadingSongIds);

  OfflineDownloadService() {
    _loadDownloadedSongs();
  }

  bool isDownloaded(String songId) => _downloadedSongs.containsKey(songId);
  bool isDownloading(String songId) => _downloadingSongIds.contains(songId);
  double getProgress(String songId) => _downloadProgress[songId] ?? 0.0;

  String? getLocalAudioPath(String songId) {
    final song = _downloadedSongs[songId];
    return song?.audioUrl;
  }

  Future<void> _loadDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyDownloadedSongs);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((key, value) {
          final song = SongModel.fromJson(Map<String, dynamic>.from(value));
          // Verify file actually exists on disk
          if (File(song.audioUrl).existsSync()) {
            _downloadedSongs[key] = song;
          }
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading downloaded songs: $e');
    }
  }

  Future<void> _saveDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {};
      _downloadedSongs.forEach((key, song) {
        data[key] = song.toJson();
      });
      await prefs.setString(_keyDownloadedSongs, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving downloaded songs: $e');
    }
  }

  Future<bool> downloadSong(SongModel song) async {
    if (isDownloaded(song.id) || isDownloading(song.id)) return true;

    try {
      _downloadingSongIds.add(song.id);
      _downloadProgress[song.id] = 0.05;
      notifyListeners();

      final docDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${docDir.path}/devotional_downloads');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final cleanTitle = song.title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final localFile = File('${downloadsDir.path}/${song.id}_$cleanTitle.mp3');

      final request = http.Request('GET', Uri.parse(song.audioUrl));
      final response = await http.Client().send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final sink = localFile.openWrite();

        await response.stream.listen((chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            _downloadProgress[song.id] = (receivedBytes / totalBytes).clamp(0.0, 1.0);
            notifyListeners();
          }
        }).asFuture();

        await sink.flush();
        await sink.close();

        // Create offline song copy with local file path
        final offlineSong = song.copyWith(
          audioUrl: localFile.path,
        );

        _downloadedSongs[song.id] = offlineSong;
        _downloadingSongIds.remove(song.id);
        _downloadProgress.remove(song.id);
        await _saveDownloadedSongs();
        notifyListeners();
        return true;
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to download stotra audio: $e');
      _downloadingSongIds.remove(song.id);
      _downloadProgress.remove(song.id);
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteDownloadedSong(String songId) async {
    try {
      final song = _downloadedSongs[songId];
      if (song != null) {
        final file = File(song.audioUrl);
        if (file.existsSync()) {
          file.deleteSync();
        }
        _downloadedSongs.remove(songId);
        await _saveDownloadedSongs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting downloaded song: $e');
    }
  }

  Future<double> getTotalStorageUsedMb() async {
    double totalBytes = 0;
    for (final song in _downloadedSongs.values) {
      final file = File(song.audioUrl);
      if (file.existsSync()) {
        totalBytes += file.lengthSync();
      }
    }
    return totalBytes / (1024 * 1024);
  }
}
