import '../../models/category_model.dart';
import '../../models/song_model.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/song_repository.dart';
import '../audio/audio_player_service.dart';

class AiToolExecutionResult {
  final bool success;
  final String actionName;
  final String? message;
  final dynamic data;

  const AiToolExecutionResult({
    required this.success,
    required this.actionName,
    this.message,
    this.data,
  });
}

/// Controlled application tools for Bhakti AI.
/// Strictly mediates access to the app's audio engine, repositories, and storage.
class AiToolsService {
  final SongRepository songRepository;
  final AudioPlayerService audioPlayerService;
  final CategoryRepository categoryRepository;

  AiToolsService({
    required this.songRepository,
    required this.audioPlayerService,
    required this.categoryRepository,
  });

  /// Search published songs in the library
  List<SongModel> searchSongs(String query, {String langCode = 'en'}) {
    if (query.trim().isEmpty) return [];
    return songRepository.searchSongs(query, langCode);
  }

  /// Get specific song by exact ID or best title match
  SongModel? getSong(String songIdOrQuery, {String langCode = 'en'}) {
    // 1. Exact ID
    final exact = songRepository.allSongs.where((s) => s.id == songIdOrQuery).toList();
    if (exact.isNotEmpty) return exact.first;

    // 2. Normalized search
    final results = songRepository.searchSongs(songIdOrQuery, langCode);
    if (results.isNotEmpty) return results.first;

    return null;
  }

  /// Plays a specific song by ID or query
  Future<AiToolExecutionResult> playSong(String songIdOrQuery, {String langCode = 'en'}) async {
    final song = getSong(songIdOrQuery, langCode: langCode);
    if (song != null) {
      await audioPlayerService.playSong(song, newQueue: songRepository.allSongs);
      return AiToolExecutionResult(
        success: true,
        actionName: 'playSong',
        message: 'Playing ${song.getLocalizedTitle(langCode)}',
        data: song,
      );
    }
    return AiToolExecutionResult(
      success: false,
      actionName: 'playSong',
      message: 'Song not found in library',
    );
  }

  /// Pauses audio playback
  Future<AiToolExecutionResult> pauseSong() async {
    await audioPlayerService.pause();
    return const AiToolExecutionResult(
      success: true,
      actionName: 'pauseSong',
      message: 'Playback paused',
    );
  }

  /// Resumes audio playback
  Future<AiToolExecutionResult> resumeSong() async {
    await audioPlayerService.resume();
    return const AiToolExecutionResult(
      success: true,
      actionName: 'resumeSong',
      message: 'Playback resumed',
    );
  }

  /// Skips to next track
  Future<AiToolExecutionResult> nextSong() async {
    await audioPlayerService.playNext();
    return const AiToolExecutionResult(
      success: true,
      actionName: 'nextSong',
      message: 'Playing next chant',
    );
  }

  /// Plays previous track
  Future<AiToolExecutionResult> previousSong() async {
    await audioPlayerService.playPrevious();
    return const AiToolExecutionResult(
      success: true,
      actionName: 'previousSong',
      message: 'Playing previous chant',
    );
  }

  /// Retrieve authorized lyrics in requested language
  AiToolExecutionResult getLyrics(String songIdOrQuery, {String langCode = 'en'}) {
    final song = getSong(songIdOrQuery, langCode: langCode);
    if (song == null) {
      return const AiToolExecutionResult(
        success: false,
        actionName: 'getLyrics',
        message: 'Content not found in library',
      );
    }

    final lyrics = song.getLocalizedLyrics(langCode) ?? song.lyrics;
    return AiToolExecutionResult(
      success: lyrics != null && lyrics.isNotEmpty,
      actionName: 'getLyrics',
      message: lyrics != null ? 'Lyrics retrieved' : 'Lyrics not available for this chant',
      data: {
        'song': song,
        'lyrics': lyrics,
        'language': langCode,
        'licenseInfo': song.licenseInfo ?? 'Public Domain / Authorized Devotional Text',
      },
    );
  }

  /// Retrieve spiritual meaning and significance in requested language
  AiToolExecutionResult getSongMeaning(String songIdOrQuery, {String langCode = 'en'}) {
    final song = getSong(songIdOrQuery, langCode: langCode);
    if (song == null) {
      return const AiToolExecutionResult(
        success: false,
        actionName: 'getSongMeaning',
        message: 'Song not found in library',
      );
    }

    final meaning = song.getLocalizedMeaning(langCode) ?? song.description;
    return AiToolExecutionResult(
      success: true,
      actionName: 'getSongMeaning',
      message: 'Meaning retrieved',
      data: {
        'song': song,
        'meaning': meaning,
        'language': langCode,
      },
    );
  }

  /// Get user favorites from local repository
  List<SongModel> getFavorites() {
    return songRepository.getFavoriteSongs();
  }

  /// Get user recently played history
  List<SongModel> getRecentlyPlayed() {
    return songRepository.getRecentlyPlayedSongs();
  }

  /// Get devotional categories
  List<CategoryModel> getCategories() {
    return categoryRepository.categories;
  }
}
