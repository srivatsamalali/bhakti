import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhakti/services/security/virus_scan_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final scanner = VirusScanService.instance;

  group('VirusScanService - Malware, Header & Security Tests', () {
    test('Accepts valid MP3 audio header with ID3 tag', () async {
      // ID3v2 tag header
      final bytes = Uint8List.fromList([
        0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
        ...List.filled(50, 0x00),
      ]);

      final result = await scanner.scanFileBytes(
        bytes: bytes,
        fileName: 'hanuman_chalisa.mp3',
        isAudio: true,
      );

      expect(result.isSafe, isTrue);
      expect(result.detectedMimeType, 'audio/mpeg');
      expect(result.riskLevel, SecurityRiskLevel.safe);
    });

    test('Accepts valid WAV audio header', () async {
      final bytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00,
        0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20,
      ]);

      final result = await scanner.scanFileBytes(
        bytes: bytes,
        fileName: 'gayatri_mantra.wav',
        isAudio: true,
      );

      expect(result.isSafe, isTrue);
      expect(result.detectedMimeType, 'audio/wav');
    });

    test('Accepts valid PNG image header', () async {
      final bytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      ]);

      final result = await scanner.scanFileBytes(
        bytes: bytes,
        fileName: 'lord_shiva.png',
        isAudio: false,
      );

      expect(result.isSafe, isTrue);
      expect(result.detectedMimeType, 'image/png');
    });

    test('Accepts valid JPEG image header', () async {
      final bytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      ]);

      final result = await scanner.scanFileBytes(
        bytes: bytes,
        fileName: 'venkateshwara.jpg',
        isAudio: false,
      );

      expect(result.isSafe, isTrue);
      expect(result.detectedMimeType, 'image/jpeg');
    });

    test('Rejects dangerous Windows Executable (MZ/PE)', () async {
      final bytes = Uint8List.fromList([
        0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00,
        0x04, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00,
      ]);

      final result = await scanner.scanFileBytes(
        bytes: bytes,
        fileName: 'song.exe.mp3',
        isAudio: true,
      );

      expect(result.isSafe, isFalse);
      expect(result.detectedThreat, contains('Windows Executable'));
      expect(result.riskLevel, SecurityRiskLevel.dangerous);
    });

    test('Rejects Linux/Android ELF binary payload', () async {
      final bytes = Uint8List.fromList([
        0x7F, 0x45, 0x4C, 0x46, 0x02, 0x01, 0x01, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      ]);

      final result = await scanner.scanFileBytes(
        bytes: bytes,
        fileName: 'trojan_audio.mp3',
        isAudio: true,
      );

      expect(result.isSafe, isFalse);
      expect(result.detectedThreat, contains('ELF executable'));
    });

    test('Rejects disguised ZIP / RAR archive payloads', () async {
      final bytes = Uint8List.fromList([
        0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x00, 0x00,
        0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      ]);

      final result = await scanner.scanFileBytes(
        bytes: bytes,
        fileName: 'archive_disguised.mp3',
        isAudio: true,
      );

      expect(result.isSafe, isFalse);
      expect(result.detectedThreat, contains('ZIP/RAR archive'));
    });

    test('Rejects embedded script injections', () async {
      final header = [0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20];
      final script = '<script>evil_payload()</script>'.codeUnits;
      final bytes = Uint8List.fromList([...header, ...script]);

      final result = await scanner.scanFileBytes(
        bytes: bytes,
        fileName: 'injected_song.mp3',
        isAudio: true,
      );

      expect(result.isSafe, isFalse);
      expect(result.detectedThreat, contains('Malicious script injection'));
    });
  });
}
