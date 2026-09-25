import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../models/category_model.dart';
import '../../models/song_model.dart';

class FirestoreService {
  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore? get _firestore {
    try {
      if (_firestoreInstance == null) {
        final instance = FirebaseFirestore.instance;
        if (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux) {
          instance.settings = const Settings(
            persistenceEnabled: false,
          );
        }
        _firestoreInstance = instance;
      }
      return _firestoreInstance;
    } catch (_) {
      return null;
    }
  }

  // Cached fallback content in case Firebase is not connected or offline
  List<SongModel> _fallbackSongs = [];
  List<CategoryModel> _fallbackCategories = [];
  bool _fallbackLoaded = false;

  Future<void> _loadFallbackData() async {
    if (_fallbackLoaded) return;
    try {
      final songsString = await rootBundle.loadString('assets/data/sample_songs.json');
      final List songsJson = json.decode(songsString);
      _fallbackSongs = songsJson.map((e) => SongModel.fromJson(e as Map<String, dynamic>)).toList();

      final catString = await rootBundle.loadString('assets/data/sample_categories.json');
      final List catJson = json.decode(catString);
      _fallbackCategories = catJson.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      _fallbackLoaded = true;
    } catch (e) {
      debugPrint('Error loading bundled fallback content: $e');
    }
  }

  // --- Public Read (All Users) ---

  /// Stream of all published devotional songs
  Stream<List<SongModel>> streamPublishedSongs({String? language, String? categoryId}) {
    try {
      final fs = _firestore;
      if (fs == null) {
        return Stream.value(_filterFallbackSongs(language, categoryId));
      }

      Query query = fs
          .collection(AppConstants.colSongs)
          .where('published', isEqualTo: true);

      if (language != null && language.isNotEmpty) {
        query = query.where('language', isEqualTo: language);
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      return query.snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((doc) => SongModel.fromFirestore(doc))
            .toList();
        if (list.isNotEmpty) {
          return list;
        }
        return _fallbackSongs.isNotEmpty ? _filterFallbackSongs(language, categoryId) : <SongModel>[];
      }).handleError((error) {
        debugPrint('Firestore stream error, falling back to local: $error');
        return _filterFallbackSongs(language, categoryId);
      });
    } catch (e) {
      debugPrint('Firestore stream init exception: $e');
      return Stream.value(_filterFallbackSongs(language, categoryId));
    }
  }

  /// One-time fetch of songs with local fallback
  Future<List<SongModel>> getPublishedSongs({String? language, String? categoryId}) async {
    await _loadFallbackData();
    try {
      final fs = _firestore;
      if (fs != null) {
        Query query = fs
            .collection(AppConstants.colSongs)
            .where('published', isEqualTo: true);

        if (language != null && language.isNotEmpty) {
          query = query.where('language', isEqualTo: language);
        }
        if (categoryId != null && categoryId.isNotEmpty) {
          query = query.where('categoryId', isEqualTo: categoryId);
        }

        final snapshot = await query.get().timeout(const Duration(seconds: 4));
        final list = snapshot.docs
            .map((doc) => SongModel.fromFirestore(doc))
            .toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch error: $e, using local sample songs.');
    }
    return _filterFallbackSongs(language, categoryId);
  }

  List<SongModel> _filterFallbackSongs(String? language, String? categoryId) {
    var result = List<SongModel>.from(_fallbackSongs);
    if (language != null && language.isNotEmpty) {
      result = result.where((s) => s.language == language).toList();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((s) => s.categoryId == categoryId).toList();
    }
    return result;
  }


  /// Get categories stream
  Stream<List<CategoryModel>> streamCategories() {
    try {
      final fs = _firestore;
      if (fs == null) {
        return Stream.value(_fallbackCategories);
      }
      return fs
          .collection(AppConstants.colCategories)
          .orderBy('order')
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty && _fallbackCategories.isNotEmpty) {
          return _fallbackCategories;
        }
        return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
      }).handleError((_) => _fallbackCategories);
    } catch (_) {
      return Stream.value(_fallbackCategories);
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    await _loadFallbackData();
    try {
      final fs = _firestore;
      if (fs != null) {
        final snapshot = await fs
            .collection(AppConstants.colCategories)
            .orderBy('order')
            .get()
            .timeout(const Duration(seconds: 4));
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
        }
      }
    } catch (e) {
      debugPrint('Firestore categories fetch error: $e');
    }
    return _fallbackCategories;
  }

  // --- Admin Mutations (Authenticated Admin) ---

  /// Get all songs for admin management (both published and drafts)
  Future<List<SongModel>> getAllSongsForAdmin() async {
    await _loadFallbackData();
    try {
      final fs = _firestore;
      if (fs != null) {
        final snapshot = await fs
            .collection(AppConstants.colSongs)
            .orderBy('createdAt', descending: true)
            .get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => SongModel.fromFirestore(doc)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting admin songs: $e');
    }
    return _fallbackSongs;
  }

  /// Create a new song document in Firestore
  Future<String> createSong(SongModel song) async {
    final fs = _firestore;
    final songId = song.id.isNotEmpty ? song.id : 'song_${DateTime.now().millisecondsSinceEpoch}';
    final newSong = song.copyWith(id: songId);

    if (fs != null) {
      try {
        final docRef = fs.collection(AppConstants.colSongs).doc(songId);
        await docRef.set(newSong.toFirestore()).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Firestore write timed out.'),
        );
      } catch (e) {
        debugPrint('Firestore createSong error: $e');
        rethrow;
      }
    }
    
    // Also add to local in-memory fallback list
    _fallbackSongs.removeWhere((s) => s.id == songId);
    _fallbackSongs.insert(0, newSong);
    return songId;
  }

  /// Update an existing song
  Future<void> updateSong(SongModel song) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection(AppConstants.colSongs)
            .doc(song.id)
            .update(song.toFirestore())
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Firestore update timed out.'),
            );
      } catch (e) {
        debugPrint('Firestore updateSong error: $e');
        rethrow;
      }
    }

    final idx = _fallbackSongs.indexWhere((s) => s.id == song.id);
    if (idx != -1) {
      _fallbackSongs[idx] = song;
    } else {
      _fallbackSongs.insert(0, song);
    }
  }

  /// Delete a song
  Future<void> deleteSong(String songId) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        await fs.collection(AppConstants.colSongs).doc(songId).delete().timeout(
          const Duration(seconds: 30),
          onTimeout: () => debugPrint('Firestore delete timed out, proceeding locally.'),
        );
      } catch (e) {
        debugPrint('Firestore delete error: $e');
      }
    }
    _fallbackSongs.removeWhere((s) => s.id == songId);
  }

  /// Toggle published status
  Future<void> setPublishedStatus(String songId, bool published) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection(AppConstants.colSongs)
            .doc(songId)
            .update({'published': published, 'updatedAt': Timestamp.now()}).timeout(
          const Duration(seconds: 4),
          onTimeout: () => debugPrint('Firestore toggle status timed out, proceeding locally.'),
        );
      } catch (e) {
        debugPrint('Firestore setPublishedStatus error: $e');
      }
    }

    final idx = _fallbackSongs.indexWhere((s) => s.id == songId);
    if (idx != -1) {
      _fallbackSongs[idx] = _fallbackSongs[idx].copyWith(published: published);
    }
  }

  /// Update song duration in Firestore
  Future<void> updateSongDuration(String songId, int durationInSeconds) async {
    if (durationInSeconds <= 0) return;
    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection(AppConstants.colSongs)
            .doc(songId)
            .update({'duration': durationInSeconds, 'updatedAt': Timestamp.now()}).timeout(
          const Duration(seconds: 10),
          onTimeout: () => debugPrint('Firestore update duration timed out.'),
        );
      } catch (e) {
        debugPrint('Firestore updateSongDuration error: $e');
      }
    }

    final idx = _fallbackSongs.indexWhere((s) => s.id == songId);
    if (idx != -1) {
      _fallbackSongs[idx] = _fallbackSongs[idx].copyWith(duration: durationInSeconds);
    }
  }

}
