import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/song_model.dart';
import '../services/firebase/firestore_service.dart';
import '../services/preferences/preferences_service.dart';

class SongRepository extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final PreferencesService _prefs;
  StreamSubscription<List<SongModel>>? _songsSubscription;

  List<SongModel> _allSongs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SongModel> get allSongs => _allSongs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SongRepository(this._firestoreService, this._prefs) {
    _loadFromLocalCache();
    _prefs.addListener(_onPrefsChanged);
    _initSongStream();
  }

  void _loadFromLocalCache() {
    final cached = _prefs.getCachedSongsJson();
    if (cached != null && cached.isNotEmpty) {
      try {
        final List list = jsonDecode(cached);
        final cachedSongs = list.map((e) => SongModel.fromJson(e as Map<String, dynamic>)).toList();
        if (cachedSongs.isNotEmpty) {
          _allSongs = cachedSongs;
          _isLoading = false;
        }
      } catch (e) {
        debugPrint('Error loading cached songs: $e');
      }
    }
  }

  void _saveToLocalCache(List<SongModel> songs) {
    try {
      final jsonString = jsonEncode(songs.map((s) => s.toJson()).toList());
      _prefs.saveCachedSongsJson(jsonString);
    } catch (e) {
      debugPrint('Error saving songs to local cache: $e');
    }
  }

  void _precacheAudioFiles(List<SongModel> songs) {
    if (kIsWeb) return;
    // Pre-cache audio files in background so clicking play is instantaneous
    for (final song in songs) {
      if (song.audioUrl.startsWith('http')) {
        DefaultCacheManager().getFileFromCache(song.audioUrl).then((cached) {
          if (cached == null) {
            DefaultCacheManager().downloadFile(song.audioUrl).catchError((_) => null);
          }
        }).catchError((_) => null);
      }
    }
  }

  void _initSongStream() {
    if (_allSongs.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    _songsSubscription = _firestoreService.streamPublishedSongs().listen(
      (songs) {
        _allSongs = songs;
        _isLoading = false;
        _errorMessage = null;
        _saveToLocalCache(songs);
        _precacheAudioFiles(songs);
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _onPrefsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _songsSubscription?.cancel();
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  Future<void> loadSongs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final songs = await _firestoreService.getPublishedSongs();
      if (songs.isNotEmpty) {
        _allSongs = songs;
        _saveToLocalCache(songs);
        _precacheAudioFiles(songs);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dynamically updates duration for a song when audio stream loads
  void updateSongDuration(String songId, int durationInSeconds) {
    if (durationInSeconds <= 0) return;
    final index = _allSongs.indexWhere((s) => s.id == songId);
    if (index != -1 && _allSongs[index].duration != durationInSeconds) {
      _allSongs[index] = _allSongs[index].copyWith(duration: durationInSeconds);
      notifyListeners();
    }
  }

  /// Get favorite songs matching saved local IDs
  List<SongModel> getFavoriteSongs() {
    final favIds = _prefs.getFavoriteSongIds();
    return _allSongs.where((s) => favIds.contains(s.id)).toList();
  }

  /// Get recently played songs matching saved local IDs
  List<SongModel> getRecentlyPlayedSongs() {
    final recentIds = _prefs.getRecentlyPlayedIds();
    final List<SongModel> result = [];
    for (var id in recentIds) {
      final match = _allSongs.firstWhere(
        (s) => s.id == id,
        orElse: () => SongModel(
          id: '',
          title: '',
          language: '',
          categoryId: '',
          deity: '',
          description: '',
          imageUrl: '',
          audioUrl: '',
          duration: 0,
        ),
      );
      if (match.id.isNotEmpty) {
        result.add(match);
      }
    }
    return result;
  }

  /// Filter songs by language
  List<SongModel> getSongsByLanguage(String langCode) {
    return _allSongs.where((s) => s.language == langCode).toList();
  }

  /// Filter songs by category
  List<SongModel> getSongsByCategory(String categoryId) {
    return _allSongs.where((s) => s.categoryId == categoryId).toList();
  }

  /// Filter songs by deity
  List<SongModel> getSongsByDeity(String deity) {
    return _allSongs
        .where((s) => s.deity.toLowerCase().contains(deity.toLowerCase()))
        .toList();
  }

  /// Lookup a single song by its unique ID
  SongModel? getSongById(String id) {
    if (id.trim().isEmpty) return null;
    try {
      return _allSongs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Search songs across title, deity, category, and language
  List<SongModel> searchSongs(String query, String currentLangCode) {
    if (query.trim().isEmpty) return [];
    final cleanQuery = query.trim().toLowerCase();

    return _allSongs.where((song) {
      final title = song.title.toLowerCase();
      final localTitle = song.getLocalizedTitle(currentLangCode).toLowerCase();
      final deity = song.deity.toLowerCase();
      final localDeity = song.getLocalizedDeity(currentLangCode).toLowerCase();
      final category = (song.categoryName ?? song.categoryId).toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();

      return song.id.toLowerCase() == cleanQuery ||
          title.contains(cleanQuery) ||
          localTitle.contains(cleanQuery) ||
          deity.contains(cleanQuery) ||
          localDeity.contains(cleanQuery) ||
          category.contains(cleanQuery) ||
          artist.contains(cleanQuery);
    }).toList();
  }
}
