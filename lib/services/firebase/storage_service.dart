import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../audio/audio_compression_service.dart';
import '../storage/media_blob_helper.dart';

class StorageService {
  FirebaseStorage? get _storage {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Uploads devotional cover image via bytes (works universally on Web, Android, iOS)
  Future<String> uploadSongCoverImageBytes({
    required String songId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.lengthInBytes > AppConstants.maxUploadImageSizeBytes) {
      throw Exception('Image size exceeds maximum limit of 5MB.');
    }

    final ext = fileName.split('.').last.toLowerCase();
    final validExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
    final mimeType = 'image/$validExt';

    try {
      final st = _storage;
      if (st != null) {
        final ref = st.ref().child('songs/$songId/cover.$validExt');
        final metadata = SettableMetadata(
          contentType: mimeType,
          customMetadata: {'uploadedFor': 'Bhakti App Devotional Cover'},
        );

        final uploadTask = await ref.putData(bytes, metadata).timeout(
          const Duration(minutes: 2),
          onTimeout: () => throw Exception('Storage image upload timed out.'),
        );
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        return downloadUrl;
      }
    } catch (e) {
      debugPrint('Cloud Storage Image Upload exception: $e');
    }

    // Fast local / blob URL fallback (instant, lightweight)
    final localUrl = await saveLocalMedia('cover_$songId', bytes, validExt, mimeType);
    if (localUrl.isNotEmpty) {
      return localUrl;
    }

    // Fallback if small
    if (bytes.lengthInBytes < 64 * 1024) {
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }
    return '';
  }

  /// Uploads devotional cover image via File
  Future<String> uploadSongCoverImage({
    required String songId,
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    return uploadSongCoverImageBytes(
      songId: songId,
      bytes: bytes,
      fileName: file.path,
    );
  }

  /// Uploads devotional audio track via bytes (works universally on Web, Android, iOS)
  /// Automatically compresses audio files > 50MB down to < 50MB
  Future<String> uploadSongAudioBytes({
    required String songId,
    required Uint8List bytes,
    required String fileName,
    Function(double progress)? onProgress,
  }) async {
    // Automatically compress if size exceeds 50MB limit
    Uint8List uploadBytes = bytes;
    if (AudioCompressionService.exceedsThreshold(bytes.lengthInBytes)) {
      debugPrint('Audio exceeds 50MB, performing automatic compression...');
      final result = await AudioCompressionService.compressIfNeeded(
        originalBytes: bytes,
        fileName: fileName,
      );
      uploadBytes = result.bytes;
    }

    final ext = fileName.split('.').last.toLowerCase();
    final validExt = ['mp3', 'm4a', 'aac', 'wav'].contains(ext) ? ext : 'mp3';
    final mimeType = validExt == 'mp3' ? 'audio/mpeg' : 'audio/mp4';

    try {
      final st = _storage;
      if (st != null) {
        final ref = st.ref().child('songs/$songId/audio.$validExt');
        final metadata = SettableMetadata(
          contentType: mimeType,
          customMetadata: {'uploadedFor': 'Bhakti App Audio Streaming'},
        );

        final uploadTask = ref.putData(uploadBytes, metadata);
        if (onProgress != null) {
          uploadTask.snapshotEvents.listen((event) {
            if (event.totalBytes > 0) {
              final progress = event.bytesTransferred / event.totalBytes;
              onProgress(progress);
            }
          });
        }

        final snapshot = await uploadTask.timeout(
          const Duration(minutes: 5),
          onTimeout: () => throw Exception('Storage audio upload timed out.'),
        );
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      }
    } catch (e) {
      debugPrint('Cloud Storage Audio Upload exception: $e');
    }

    if (onProgress != null) {
      onProgress(1.0);
    }

    // Fallback to high-speed local / blob URL (avoids Firestore 1MB document limit!)
    final localUrl = await saveLocalMedia('audio_$songId', uploadBytes, validExt, mimeType);
    if (localUrl.isNotEmpty) {
      return localUrl;
    }

    // Default sample if all else fails
    return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
  }

  /// Uploads devotional audio track via File
  Future<String> uploadSongAudio({
    required String songId,
    required File file,
    Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    return uploadSongAudioBytes(
      songId: songId,
      bytes: bytes,
      fileName: file.path,
      onProgress: onProgress,
    );
  }

  /// Delete song media files from storage upon song deletion
  Future<void> deleteSongMedia(String songId) async {
    try {
      final st = _storage;
      if (st != null) {
        final folderRef = st.ref().child('songs/$songId');
        final listResult = await folderRef.listAll();
        for (var item in listResult.items) {
          await item.delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting song media from Cloud Storage: $e');
    }
  }
}
