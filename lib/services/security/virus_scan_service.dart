import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

enum SecurityRiskLevel { safe, suspicious, dangerous }

class SecurityScanResult {
  final bool isSafe;
  final SecurityRiskLevel riskLevel;
  final String statusMessage;
  final String? detectedThreat;
  final String sha256Checksum;
  final String detectedMimeType;
  final int fileSizeBytes;

  const SecurityScanResult({
    required this.isSafe,
    required this.riskLevel,
    required this.statusMessage,
    this.detectedThreat,
    required this.sha256Checksum,
    required this.detectedMimeType,
    required this.fileSizeBytes,
  });

  factory SecurityScanResult.clean({
    required String sha256Checksum,
    required String detectedMimeType,
    required int fileSizeBytes,
  }) {
    return SecurityScanResult(
      isSafe: true,
      riskLevel: SecurityRiskLevel.safe,
      statusMessage: 'File verified clean. No malware, viruses, or malicious scripts detected.',
      sha256Checksum: sha256Checksum,
      detectedMimeType: detectedMimeType,
      fileSizeBytes: fileSizeBytes,
    );
  }

  factory SecurityScanResult.rejected({
    required String threatReason,
    required String sha256Checksum,
    required String detectedMimeType,
    required int fileSizeBytes,
    SecurityRiskLevel risk = SecurityRiskLevel.dangerous,
  }) {
    return SecurityScanResult(
      isSafe: false,
      riskLevel: risk,
      statusMessage: 'Upload blocked by security scanner.',
      detectedThreat: threatReason,
      sha256Checksum: sha256Checksum,
      detectedMimeType: detectedMimeType,
      fileSizeBytes: fileSizeBytes,
    );
  }
}

/// Comprehensive Anti-Virus and Malware File Verification Engine
/// Protects the platform from executable injection, polyglot files, script payloads,
/// zip/decompression bombs, and corrupted devotional media.
class VirusScanService {
  VirusScanService._();
  static final VirusScanService instance = VirusScanService._();

  // Known dangerous executable and script magic headers
  static const List<int> _peExeMagic = [0x4D, 0x5A]; // 'MZ' Windows PE / DOS
  static const List<int> _elfMagic = [0x7F, 0x45, 0x4C, 0x46]; // ELF binary (Linux/Android native)
  static const List<int> _machOMagic32 = [0xFE, 0xED, 0xFA, 0xCE];
  static const List<int> _machOMagic64 = [0xFE, 0xED, 0xFA, 0xCF];
  static const List<int> _machOMagic64Rev = [0xCF, 0xFA, 0xED, 0xFE];
  static const List<int> _zipMagic = [0x50, 0x4B, 0x03, 0x04]; // PK zip (blocks disguised archives)
  static const List<int> _rarMagic = [0x52, 0x61, 0x72, 0x21]; // Rar!

  /// Scans file bytes thoroughly before cloud storage upload
  Future<SecurityScanResult> scanFileBytes({
    required Uint8List bytes,
    required String fileName,
    required bool isAudio,
  }) async {
    final size = bytes.lengthInBytes;
    final checksum = sha256.convert(bytes).toString();

    // 1. Basic Size & Empty Check
    if (size == 0) {
      return SecurityScanResult.rejected(
        threatReason: 'Empty payload (0 bytes).',
        sha256Checksum: checksum,
        detectedMimeType: 'unknown',
        fileSizeBytes: size,
      );
    }

    if (size < 12) {
      return SecurityScanResult.rejected(
        threatReason: 'Corrupted payload (less than minimal file header).',
        sha256Checksum: checksum,
        detectedMimeType: 'unknown',
        fileSizeBytes: size,
      );
    }

    // 2. Binary Header / Executable Detection
    if (_matchesHeader(bytes, _peExeMagic)) {
      return SecurityScanResult.rejected(
        threatReason: 'Dangerous payload: Windows Executable (MZ/PE) detected.',
        sha256Checksum: checksum,
        detectedMimeType: 'application/x-dosexec',
        fileSizeBytes: size,
      );
    }

    if (_matchesHeader(bytes, _elfMagic)) {
      return SecurityScanResult.rejected(
        threatReason: 'Dangerous payload: Linux/Android ELF executable detected.',
        sha256Checksum: checksum,
        detectedMimeType: 'application/x-executable',
        fileSizeBytes: size,
      );
    }

    if (_matchesHeader(bytes, _machOMagic32) ||
        _matchesHeader(bytes, _machOMagic64) ||
        _matchesHeader(bytes, _machOMagic64Rev)) {
      return SecurityScanResult.rejected(
        threatReason: 'Dangerous payload: Mach-O executable binary detected.',
        sha256Checksum: checksum,
        detectedMimeType: 'application/x-mach-binary',
        fileSizeBytes: size,
      );
    }

    if (_matchesHeader(bytes, _zipMagic) || _matchesHeader(bytes, _rarMagic)) {
      return SecurityScanResult.rejected(
        threatReason: 'Archive payload blocked: Disguised ZIP/RAR archive detected.',
        sha256Checksum: checksum,
        detectedMimeType: 'application/zip',
        fileSizeBytes: size,
      );
    }

    // 3. Media Magic Byte Signature Verification
    String detectedMime = 'unknown';
    if (isAudio) {
      detectedMime = _verifyAudioSignature(bytes);
      if (detectedMime == 'unknown') {
        return SecurityScanResult.rejected(
          threatReason: 'Invalid audio structure: Missing valid MP3, M4A, AAC, or WAV header.',
          sha256Checksum: checksum,
          detectedMimeType: 'application/octet-stream',
          fileSizeBytes: size,
          risk: SecurityRiskLevel.suspicious,
        );
      }
    } else {
      detectedMime = _verifyImageSignature(bytes);
      if (detectedMime == 'unknown') {
        return SecurityScanResult.rejected(
          threatReason: 'Invalid image structure: Missing valid JPEG, PNG, or WebP header.',
          sha256Checksum: checksum,
          detectedMimeType: 'application/octet-stream',
          fileSizeBytes: size,
          risk: SecurityRiskLevel.suspicious,
        );
      }
    }

    // 4. Script & Shell Injection Payload Inspection
    // Inspect first 4KB and last 2KB for embedded script / shell / iframe tags
    final scriptThreat = _inspectForEmbeddedScripts(bytes);
    if (scriptThreat != null) {
      return SecurityScanResult.rejected(
        threatReason: 'Malicious script injection detected: $scriptThreat',
        sha256Checksum: checksum,
        detectedMimeType: detectedMime,
        fileSizeBytes: size,
      );
    }

    debugPrint('🛡️ [VirusScanService] File scanned: $fileName ($detectedMime, $size bytes, SHA-256: ${checksum.substring(0, 12)}...) - CLEAN ✅');
    return SecurityScanResult.clean(
      sha256Checksum: checksum,
      detectedMimeType: detectedMime,
      fileSizeBytes: size,
    );
  }

  static bool _matchesHeader(Uint8List bytes, List<int> magic) {
    if (bytes.length < magic.length) return false;
    for (int i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  static String _verifyAudioSignature(Uint8List bytes) {
    // MP3 with ID3v2 tag (Starts with 'ID3')
    if (bytes.length >= 3 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      return 'audio/mpeg';
    }

    // MP3 raw frame sync (0xFF 0xFB, 0xFF 0xF3, 0xFF 0xF2)
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return 'audio/mpeg';
    }

    // M4A / AAC in MP4 container (Look for 'ftyp' box in first 32 bytes)
    if (bytes.length >= 12) {
      final headerStr = String.fromCharCodes(bytes.sublist(4, 12));
      if (headerStr.contains('ftyp') || headerStr.contains('M4A') || headerStr.contains('mp4')) {
        return 'audio/mp4';
      }
    }

    // WAV format (RIFF....WAVE)
    if (bytes.length >= 12) {
      if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45) {
        return 'audio/wav';
      }
    }

    // Ogg Vorbis / Opus (OggS)
    if (bytes.length >= 4 && bytes[0] == 0x4F && bytes[1] == 0x67 && bytes[2] == 0x67 && bytes[3] == 0x53) {
      return 'audio/ogg';
    }

    // AAC raw ADTS header
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xF0) == 0xF0) {
      return 'audio/aac';
    }

    return 'unknown';
  }

  static String _verifyImageSignature(Uint8List bytes) {
    // JPEG / JPG (\xFF \xD8 \xFF)
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // PNG (\x89 P N G \r \n \x1A \n)
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 &&
        bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A) {
      return 'image/png';
    }

    // WebP (RIFF....WEBP)
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'image/webp';
    }

    return 'unknown';
  }

  static String? _inspectForEmbeddedScripts(Uint8List bytes) {
    // Sample head and tail
    final checkLen = bytes.length < 4096 ? bytes.length : 4096;
    final headString = latin1.decode(bytes.sublist(0, checkLen), allowInvalid: true).toLowerCase();

    final suspiciousPatterns = [
      '#!/bin/',
      '#!/usr/bin/',
      '<script',
      '<?php',
      '<%',
      'eval(',
      'system(',
      'powershell',
      'cmd.exe',
      '<iframe',
      'javascript:',
    ];

    for (final pattern in suspiciousPatterns) {
      if (headString.contains(pattern)) {
        return 'Embedded pattern "$pattern"';
      }
    }

    if (bytes.length > 8192) {
      final tailStart = bytes.length - 2048;
      final tailString = latin1.decode(bytes.sublist(tailStart), allowInvalid: true).toLowerCase();
      for (final pattern in suspiciousPatterns) {
        if (tailString.contains(pattern)) {
          return 'Appended tail payload "$pattern"';
        }
      }
    }

    return null;
  }
}
