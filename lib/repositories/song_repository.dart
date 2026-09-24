import 'package:flutter/foundation.dart';
import '../models/song_model.dart';
import '../services/firebase/firestore_service.dart';
import '../services/preferences/preferences_service.dart';

class SongRepository extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final PreferencesService _prefs;

  List<SongModel> _allSongs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SongModel> get allSongs => _allSongs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SongRepository(this._firestoreService, this._prefs) {
    _prefs.addListener(_onPrefsChanged);
    loadSongs();
  }

  void _onPrefsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  Future<void> loadSongs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allSongs = await _firestoreService.getPublishedSongs();
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
