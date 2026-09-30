import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhakti/core/constants/app_constants.dart';
import 'package:bhakti/services/audio/audio_compression_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioCompressionService Tests', () {
    test('exceedsThreshold accurately detects files > AppConstants.maxUploadAudioSizeBytes', () {
      final smallSize = AppConstants.maxUploadAudioSizeBytes ~/ 2;
      final exactLimit = AppConstants.maxUploadAudioSizeBytes;
      final largeSize = AppConstants.maxUploadAudioSizeBytes + (10 * 1024 * 1024);

      expect(AudioCompressionService.exceedsThreshold(smallSize), isFalse);
      expect(AudioCompressionService.exceedsThreshold(exactLimit), isFalse);
      expect(AudioCompressionService.exceedsThreshold(largeSize), isTrue);
    });

    test('formatBytes returns clean formatted size', () {
      expect(AudioCompressionService.formatBytes(1024), '1.0 KB');
      expect(AudioCompressionService.formatBytes(10 * 1024 * 1024), '10.0 MB');
      expect(AudioCompressionService.formatBytes(68 * 1024 * 1024), '68.0 MB');
    });

    test('compressIfNeeded preserves original uncompressed bytes', () async {
      final sampleBytes = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      final result = await AudioCompressionService.compressIfNeeded(
        originalBytes: sampleBytes,
        fileName: 'short_bhajan.mp3',
      );

      expect(result.wasCompressed, isFalse);
      expect(result.compressedSize, equals(sampleBytes.length));
      expect(result.bytes, equals(sampleBytes));
    });
  });
}
