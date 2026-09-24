import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class CacheService {
  static final CacheService instance = CacheService._internal();
  CacheService._internal();

  /// Calculates approximate size of cached images and temporary audio files
  Future<String> getApproximateCacheSize() async {
    if (kIsWeb) return '0.0 MB';
    try {
      int totalBytes = 0;
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        totalBytes += _getDirSize(tempDir);
      }

      final appSupportDir = await getApplicationSupportDirectory();
      if (appSupportDir.existsSync()) {
        totalBytes += _getDirSize(appSupportDir);
      }

      final mb = totalBytes / (1024 * 1024);
      if (mb < 0.1) {
        return '< 1.0 MB';
      }
      return '${mb.toStringAsFixed(1)} MB';
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return '0.0 MB';
    }
  }

  int _getDirSize(Directory dir) {
    int bytes = 0;
    try {
      final List<FileSystemEntity> entities = dir.listSync(recursive: true, followLinks: false);
      for (var entity in entities) {
        if (entity is File) {
          bytes += entity.lengthSync();
        }
      }
    } catch (_) {}
    return bytes;
  }

  /// Clears network image cache and temporary downloaded media
  Future<bool> clearAllCache() async {
    try {
      await DefaultCacheManager().emptyCache();

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
          tempDir.createSync();
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      return false;
    }
  }
}
