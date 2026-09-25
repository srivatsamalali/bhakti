import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../models/song_model.dart';
import '../preferences/preferences_service.dart';

enum SleepTimerDuration {
  off,
  min15,
  min30,
  min45,
  min60,
  endOfSong,
}

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final PreferencesService _prefs;

  SongModel? _currentSong;
  List<SongModel> _queue = [];
  int _currentIndex = -1;

  double _playbackSpeed = 1.0;
  LoopMode _loopMode = LoopMode.all;
  bool _isShuffleEnabled = false;

  Timer? _sleepTimer;
  SleepTimerDuration _activeSleepTimer = SleepTimerDuration.off;
  DateTime? _sleepTimerEndTime;

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;

  SongModel? get currentSong => _currentSong;
  List<SongModel> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  double get playbackSpeed => _playbackSpeed;
  LoopMode get loopMode => _loopMode;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isPlaying => _player.playing;
  Duration get currentPosition => _player.position;
  Duration? get totalDuration => _player.duration;
  SleepTimerDuration get activeSleepTimer => _activeSleepTimer;
  DateTime? get sleepTimerEndTime => _sleepTimerEndTime;

  AudioPlayerService(this._prefs) {
    _init();
  }

  SongRepository? _songRepo;
  FirestoreService? _firestoreService;

  void setDependencies(SongRepository? songRepo, FirestoreService? firestoreService) {
    _songRepo = songRepo;
    _firestoreService = firestoreService;
  }

  void _init() {
    _playbackSpeed = _prefs.getPlaybackSpeed();
    _player.setSpeed(_playbackSpeed);
    _player.setVolume(1.0);

    // Listen to player state and notify UI immediately
    _player.playerStateStream.listen((state) {
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
    });

    _player.playingStream.listen((_) {
      notifyListeners();
    });

    _player.durationStream.listen((d) {
      if (d != null && d.inSeconds > 0 && _currentSong != null) {
        if (_currentSong!.duration != d.inSeconds) {
          _currentSong = _currentSong!.copyWith(duration: d.inSeconds);
          _songRepo?.updateSongDuration(_currentSong!.id, d.inSeconds);
          _firestoreService?.updateSongDuration(_currentSong!.id, d.inSeconds);
        }
      }
      notifyListeners();
    });

    // Listen to playback errors
    _player.playbackEventStream.listen(
      (_) {
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        debugPrint('Bhakti Audio Player Error: $e');
        notifyListeners();
      },
    );
  }

  /// Play all songs seamlessly in a continuous playlist
  Future<void> playAll(List<SongModel> songs, {bool shuffle = false, int startIndex = 0}) async {
    if (songs.isEmpty) return;
    List<SongModel> playlist = List.from(songs);
    if (shuffle) {
      playlist.shuffle();
      startIndex = 0;
    }
    final targetSong = (startIndex >= 0 && startIndex < playlist.length)
        ? playlist[startIndex]
        : playlist.first;
    await playSong(targetSong, newQueue: playlist);
  }

  /// Play a selected song and optionally set the playlist context
  Future<void> playSong(SongModel song, {List<SongModel>? newQueue}) async {
    try {
      if (newQueue != null && newQueue.isNotEmpty) {
        _queue = List.from(newQueue);
        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) {
          _queue.insert(0, song);
          _currentIndex = 0;
        }
      } else {
        if (!_queue.any((s) => s.id == song.id)) {
          _queue.add(song);
        }
        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
      }

      _currentSong = song;
      notifyListeners();

      // Record to recently played history
      await _prefs.addRecentlyPlayed(song.id);

      // Create AudioSource with Background MediaItem
      final mediaTag = MediaItem(
        id: song.id,
        album: song.album ?? 'Bhakti Devotional',
        title: song.title,
        artist: song.artist ?? song.deity,
        artUri: song.imageUrl.startsWith('http') ? Uri.parse(song.imageUrl) : null,
      );

      final AudioSource audioSource;
      final isLalitha = song.id.contains('lalitha') || song.title.toLowerCase().contains('lalitha');

      if (song.audioUrl.startsWith('assets/')) {
        audioSource = AudioSource.asset(song.audioUrl, tag: mediaTag);
      } else if (!kIsWeb && isLalitha && (song.audioUrl.startsWith('blob:') || song.audioUrl.startsWith('data:'))) {
        // Lalitha Sahasranama blob fallback to bundled authentic audio
        audioSource = AudioSource.asset('assets/audio/lalitha_sahasranamam.mp3', tag: mediaTag);
      } else if (!kIsWeb && song.audioUrl.startsWith('file://')) {
        audioSource = AudioSource.uri(Uri.parse(song.audioUrl), tag: mediaTag);
      } else if (!kIsWeb && song.audioUrl.startsWith('/')) {
        audioSource = AudioSource.file(song.audioUrl, tag: mediaTag);
      } else if (song.audioUrl.startsWith('blob:') && !kIsWeb) {
        audioSource = AudioSource.asset('assets/audio/lalitha_sahasranamam.mp3', tag: mediaTag);
      } else {
        audioSource = AudioSource.uri(Uri.parse(song.audioUrl), tag: mediaTag);
      }

      await _player.setVolume(1.0);
      try {
        await _player.setAudioSource(audioSource);
      } catch (audioSourceError) {
        debugPrint('Remote audio source failed: $audioSourceError. Falling back to local offline audio.');
        // Fallback to local high quality bundled audio
        final fallbackSource = AudioSource.asset(
          'assets/audio/lalitha_sahasranamam.mp3',
          tag: mediaTag,
        );
        await _player.setAudioSource(fallbackSource);
      }
      await _player.setSpeed(_playbackSpeed);
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio for ${song.title}: $e');
      notifyListeners();
    }
  }

  Future<void> resume() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      if (_currentSong != null) {
        await resume();
      } else if (_queue.isNotEmpty) {
        await playSong(_queue.first);
      }
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekForward15() async {
    final current = _player.position;
    final maxDuration = _player.duration ?? Duration.zero;
    final target = current + const Duration(seconds: 15);
    if (target < maxDuration) {
      await _player.seek(target);
    } else {
      await _player.seek(maxDuration);
    }
  }

  Future<void> seekBackward15() async {
    final current = _player.position;
    final target = current - const Duration(seconds: 15);
    if (target > Duration.zero) {
      await _player.seek(target);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
      await playSong(_queue[_currentIndex], newQueue: _queue);
    } else {
      // Continuous playback: Loop back to beginning of playlist
      _currentIndex = 0;
      await playSong(_queue[_currentIndex], newQueue: _queue);
    }
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    if (_player.position.inSeconds > 4) {
      // If played more than 4 seconds, restart current track
      await _player.seek(Duration.zero);
      return;
    }

    if (_currentIndex - 1 >= 0) {
      _currentIndex--;
      await playSong(_queue[_currentIndex], newQueue: _queue);
    } else {
      // Wrap around to the last song in queue
      _currentIndex = _queue.length - 1;
      await playSong(_queue[_currentIndex], newQueue: _queue);
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setSpeed(speed);
    await _prefs.setPlaybackSpeed(speed);
    notifyListeners();
  }

  Future<void> toggleLoopMode() async {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        await _player.setLoopMode(LoopMode.off);
        break;
    }
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    await _player.setShuffleModeEnabled(_isShuffleEnabled);
    notifyListeners();
  }

  // --- Queue Operations ---
  void addToQueue(SongModel song) {
    if (!_queue.any((s) => s.id == song.id)) {
      _queue.add(song);
      notifyListeners();
    }
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      final removed = _queue.removeAt(index);
      if (_currentSong?.id == removed.id) {
        if (_queue.isNotEmpty) {
          final nextIndex = index < _queue.length ? index : 0;
          playSong(_queue[nextIndex]);
        } else {
          _player.stop();
          _currentSong = null;
        }
      } else if (index < _currentIndex) {
        _currentIndex--;
      }
      notifyListeners();
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    _currentIndex = _queue.indexWhere((s) => s.id == _currentSong?.id);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    notifyListeners();
  }

  // --- Sleep Timer ---
  void setSleepTimer(SleepTimerDuration duration) {
    _sleepTimer?.cancel();
    _activeSleepTimer = duration;

    if (duration == SleepTimerDuration.off) {
      _sleepTimerEndTime = null;
      notifyListeners();
      return;
    }

    if (duration == SleepTimerDuration.endOfSong) {
      _sleepTimerEndTime = null;
      notifyListeners();
      return;
    }

    int minutes = 15;
    if (duration == SleepTimerDuration.min30) minutes = 30;
    if (duration == SleepTimerDuration.min45) minutes = 45;
    if (duration == SleepTimerDuration.min60) minutes = 60;

    _sleepTimerEndTime = DateTime.now().add(Duration(minutes: minutes));
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      pause();
      _activeSleepTimer = SleepTimerDuration.off;
      _sleepTimerEndTime = null;
      notifyListeners();
    });

    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _activeSleepTimer = SleepTimerDuration.off;
    _sleepTimerEndTime = null;
    notifyListeners();
  }

  void _handleSongCompletion() {
    if (_activeSleepTimer == SleepTimerDuration.endOfSong) {
      pause();
      _activeSleepTimer = SleepTimerDuration.off;
      return;
    }

    if (_loopMode == LoopMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else {
      playNext();
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
