import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'language_detector.dart';

enum VoiceListeningState {
  idle,
  initializing,
  listening,
  processing,
  error,
}

class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isSpeechAvailable = false;
  VoiceListeningState _listeningState = VoiceListeningState.idle;
  String _lastRecognizedWords = '';
  String? _errorMessage;

  bool get isSpeechAvailable => _isSpeechAvailable;
  VoiceListeningState get listeningState => _listeningState;
  String get lastRecognizedWords => _lastRecognizedWords;
  String? get errorMessage => _errorMessage;
  bool get isListening => _listeningState == VoiceListeningState.listening;

  VoiceService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('TTS init notice: $e');
    }
  }

  /// Initialize speech recognition engine
  Future<bool> initSpeech() async {
    if (_isSpeechAvailable) return true;
    _listeningState = VoiceListeningState.initializing;
    notifyListeners();

    try {
      _isSpeechAvailable = await _speech.initialize(
        onError: (val) {
          debugPrint('STT error: ${val.errorMsg}');
          _listeningState = VoiceListeningState.idle;
          _errorMessage = val.errorMsg;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'listening') {
            _listeningState = VoiceListeningState.listening;
          } else if (status == 'notListening' || status == 'done') {
            if (_listeningState == VoiceListeningState.listening) {
              _listeningState = VoiceListeningState.processing;
            }
          }
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Speech init failed or platform unsupported: $e');
      _isSpeechAvailable = false;
      _listeningState = VoiceListeningState.idle;
    }
    notifyListeners();
    return _isSpeechAvailable;
  }

  /// Start listening for voice input
  Future<void> startListening({
    required Function(String text) onResult,
    String? languageLocale,
  }) async {
    _errorMessage = null;
    _lastRecognizedWords = '';

    final hasInit = await initSpeech();
    if (!hasInit) {
      _listeningState = VoiceListeningState.error;
      _errorMessage = 'Speech recognition unavailable on this device.';
      notifyListeners();
      return;
    }

    _listeningState = VoiceListeningState.listening;
    notifyListeners();

    try {
      await _speech.listen(
        onResult: (result) {
          _lastRecognizedWords = result.recognizedWords;
          notifyListeners();
          if (result.finalResult) {
            _listeningState = VoiceListeningState.processing;
            notifyListeners();
            onResult(result.recognizedWords);
          }
        },
        localeId: languageLocale,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      debugPrint('Error starting speech listen: $e');
      _listeningState = VoiceListeningState.idle;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Stop listening explicitly
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _listeningState = VoiceListeningState.idle;
    notifyListeners();
  }

  /// Speak devotional text in requested language with auto locale matching
  Future<void> speakText(String text, String langCode) async {
    if (text.trim().isEmpty) return;
    try {
      final locale = AiLanguage.getSpeechLocale(langCode);
      await _tts.setLanguage(locale);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak notice: $e');
    }
  }

  /// Stop active TTS speech
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}
