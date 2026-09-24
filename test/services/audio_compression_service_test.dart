import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhakti/services/audio/audio_compression_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioCompressionService Tests', () {
    test('exceedsThreshold accurately detects files > 50MB', () {
      const smallSize = 25 * 1024 * 1024; // 25MB
      const exactLimit = 50 * 1024 * 1024; // 50MB
      const largeSize = 65 * 1024 * 1024; // 65MB

      expect(AudioCompressionService.exceedsThreshold(smallSize), isFalse);
      expect(AudioCompressionService.exceedsThreshold(exactLimit), isFalse);
      expect(AudioCompressionService.exceedsThreshold(largeSize), isTrue);
    });

    test('formatBytes returns clean formatted size', () {
      expect(AudioCompressionService.formatBytes(1024), '1.0 KB');
      expect(AudioCompressionService.formatBytes(10 * 1024 * 1024), '10.0 MB');
      expect(AudioCompressionService.formatBytes(68 * 1024 * 1024), '68.0 MB');
    });

    test('compressIfNeeded does not alter files under 50MB', () async {
      final sampleBytes = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      final result = await AudioCompressionService.compressIfNeeded(
        originalBytes: sampleBytes,
        fileName: 'short_bhajan.mp3',
      );

      expect(result.wasCompressed, isFalse);
      expect(result.compressedSize, equals(sampleBytes.length));
      expect(result.bytes, equals(sampleBytes));
    });

    test('compressIfNeeded compresses simulated > 50MB data to < 50MB', () async {
      // 52MB mock byte buffer
      final largeBytes = Uint8List(52 * 1024 * 1024);
      final result = await AudioCompressionService.compressIfNeeded(
        originalBytes: largeBytes,
        fileName: 'large_stotram.mp3',
      );

      expect(result.wasCompressed, isTrue);
      expect(result.compressedSize, isNotNull);
      expect(result.compressedSize, lessThanOrEqualTo(48 * 1024 * 1024));
      expect(result.summary, contains('Compressed from 52.0 MB to'));
    });
  });
}
