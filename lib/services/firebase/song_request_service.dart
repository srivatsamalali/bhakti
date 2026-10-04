import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/song_request_model.dart';
import '../rewards/seva_token_service.dart';

class SongRequestService extends ChangeNotifier {
  static const String _keyCachedRequests = 'bhakti_cached_song_requests';
  final SevaTokenService _tokenService;

  List<SongRequestModel> _requests = [];
  bool _isLoading = false;

  SongRequestService(this._tokenService) {
    loadRequests();
  }

  List<SongRequestModel> get requests => List.unmodifiable(_requests);
  bool get isLoading => _isLoading;

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Try fetching from Firestore
      final fs = _firestore;
      if (fs != null) {
        final snap = await fs
            .collection('song_requests')
            .orderBy('requestedAt', descending: true)
            .limit(50)
            .get();

        if (snap.docs.isNotEmpty) {
          _requests = snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return SongRequestModel.fromJson(data);
          }).toList();

          await _cacheRequestsLocally();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Notice loading Firestore song requests: $e');
    }

    // 2. Load from local cache fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyCachedRequests);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _requests = list.map((e) => SongRequestModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error reading local song requests: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitRequest({
    required String songTitle,
    required String deity,
    required String language,
    String singerOrComposer = '',
    String referenceUrl = '',
    String notes = '',
  }) async {
    if (songTitle.trim().isEmpty) return false;

    final id = 'req_${DateTime.now().millisecondsSinceEpoch}';
    final request = SongRequestModel(
      id: id,
      songTitle: songTitle.trim(),
      deity: deity.trim().isEmpty ? 'General' : deity.trim(),
      language: language,
      singerOrComposer: singerOrComposer.trim(),
      referenceUrl: referenceUrl.trim(),
      notes: notes.trim(),
      requestedAt: DateTime.now(),
      status: 'pending',
      votesCount: 1,
    );

    // Save to Firestore if available
    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('song_requests').doc(id).set(request.toJson());
      }
    } catch (e) {
      debugPrint('Notice saving request to Firestore: $e');
    }

    // Add to local state
    _requests.insert(0, request);
    await _cacheRequestsLocally();

    // 🌟 Award +5 Seva Tokens for active community contribution!
    await _tokenService.awardTokens(
      amount: 5,
      title: 'Devotional Song Request 📜',
      description: 'Requested "${request.songTitle}" for the community',
    );

    notifyListeners();
    return true;
  }

  Future<void> updateStatus(String requestId, String newStatus) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: newStatus);
      await _cacheRequestsLocally();

      try {
        final fs = _firestore;
        if (fs != null) {
          await fs.collection('song_requests').doc(requestId).update({'status': newStatus});
        }
      } catch (e) {
        debugPrint('Notice updating status in Firestore: $e');
      }

      notifyListeners();
    }
  }

  Future<void> deleteRequest(String requestId) async {
    _requests.removeWhere((r) => r.id == requestId);
    await _cacheRequestsLocally();

    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('song_requests').doc(requestId).delete();
      }
    } catch (e) {
      debugPrint('Notice deleting request from Firestore: $e');
    }

    notifyListeners();
  }

  Future<void> _cacheRequestsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_requests.map((r) => r.toJson()).toList());
      await prefs.setString(_keyCachedRequests, jsonStr);
    } catch (_) {}
  }
}
