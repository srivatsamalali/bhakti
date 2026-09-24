import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/song_model.dart';
import '../analytics/analytics_service.dart';
import '../preferences/preferences_service.dart';
import 'ai_tools_service.dart';
import 'devotional_knowledge_engine.dart';
import 'intent_detector.dart';
import 'language_detector.dart';
import 'voice_service.dart';

enum AiSender { user, ai, system }

enum AiMessageActionType {
  none,
  playSong,
  pauseSong,
  resumeSong,
  showLyrics,
  showMeaning,
  showFavorites,
  showRecents,
  openCategories,
}

class AiMessage {
  final String id;
  final String text;
  final AiSender sender;
  final DateTime timestamp;
  final String detectedLanguage;
  final AiIntentType? intent;
  final AiMessageActionType actionType;
  final SongModel? song;
  final List<SongModel>? songList;
  final Map<String, dynamic>? extraData;
  final bool isVoice;

  AiMessage({
    String? id,
    required this.text,
    required this.sender,
    DateTime? timestamp,
    this.detectedLanguage = AiLanguage.english,
    this.intent,
    this.actionType = AiMessageActionType.none,
    this.song,
    this.songList,
    this.extraData,
    this.isVoice = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
}

/// Primary Bhakti AI service coordinating multi-language voice and text interaction,
/// fast deterministic playback intents, authorized content retrieval, and safe spiritual Q&A.
class BhaktiAiService extends ChangeNotifier {
  final PreferencesService preferencesService;
  final AiToolsService toolsService;
  final VoiceService voiceService;
  final DevotionalKnowledgeEngine knowledgeEngine;

  final List<AiMessage> _messages = [];
  bool _isProcessing = false;
  String? _activeDetectedLanguage;

  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;
  String? get activeDetectedLanguage => _activeDetectedLanguage;

  BhaktiAiService({
    required this.preferencesService,
    required this.toolsService,
    required this.voiceService,
    DevotionalKnowledgeEngine? knowledgeEngine,
  }) : knowledgeEngine = knowledgeEngine ?? DevotionalKnowledgeEngine() {
    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    if (_messages.isNotEmpty) return;
    final appLang = preferencesService.getSelectedLanguage();
    String welcomeText;

    switch (appLang) {
      case AiLanguage.kannada:
        welcomeText = 'ನಮಸ್ಕಾರ! ನಾನು ನಿಮ್ಮ ಭಕ್ತಿ ಎಐ ಸಹಾಯಕ. ನೀವು ಯಾವುದೇ ಭಕ್ತಿ ಗೀತೆ, ಸ್ತೋತ್ರ, ಸಹಸ್ರನಾಮ ಪ್ಲೇ ಮಾಡಲು ಅಥವಾ ಅವುಗಳ ಅರ್ಥ ಮತ್ತು ಸಾಹಿತ್ಯವನ್ನು ಕೇಳಬಹುದು.';
        break;
      case AiLanguage.hindi:
        welcomeText = 'नमस्ते! मैं आपका भक्ति एआई साथी हूँ। आप किसी भी भजन, स्तोत्र, चालीसा को सुनने, उनके बोल या अर्थ जानने के लिए बोल या लिख सकते हैं।';
        break;
      case AiLanguage.tamil:
        welcomeText = 'வணக்கம்! நான் உங்கள் பக்தி ஏஐ உதவியாளர். நீங்கள் எந்தவொரு ஸ்தோத்திரம், பாடல் அல்லது சஹஸ்ரநாமத்தை இயக்க அல்லது அதன் பொருள் மற்றும் வரிகளைக் கேட்கலாம்.';
        break;
      case AiLanguage.malayalam:
        welcomeText = 'നമസ്കാരം! ഞാൻ നിങ്ങളുടെ ഭക്തി എഐ സഹായിയാണ്. ഭക്തിഗാനങ്ങൾ, സ്തോത്രങ്ങൾ എന്നിവ കേൾക്കാനും അവയുടെ വരികളും അർത്ഥവും അറിയാനും ചോദിക്കാം.';
        break;
      case AiLanguage.english:
      default:
        welcomeText = 'Namaste! I am your Bhakti AI companion. You can ask me to play any devotional chant, explain meanings, or show authentic lyrics in your preferred language.';
        break;
    }

    _messages.add(
      AiMessage(
        text: welcomeText,
        sender: AiSender.ai,
        detectedLanguage: appLang,
      ),
    );
  }

  /// Clears in-memory conversation history for privacy
  void clearConversation() {
    _messages.clear();
    _initWelcomeMessage();
    notifyListeners();
  }

  /// Sends a text or speech query to Bhakti AI
  Future<void> processQuery(String rawInput, {bool isVoice = false}) async {
    final input = rawInput.trim();
    if (input.isEmpty) return;

    // Check if AI is enabled
    if (!preferencesService.isAiAssistantEnabled() || !preferencesService.isAdminAiGlobalEnabled()) {
      _messages.add(
        AiMessage(
          text: 'Bhakti AI is currently disabled in settings.',
          sender: AiSender.ai,
        ),
      );
      notifyListeners();
      return;
    }

    // 1. Add User Message
    final currentAppLang = preferencesService.getSelectedLanguage();
    final langResult = LanguageDetector.detectLanguage(input, defaultAppLanguage: currentAppLang);
    final targetLang = langResult.languageCode;
    _activeDetectedLanguage = targetLang;

    _messages.add(
      AiMessage(
        text: input,
        sender: AiSender.user,
        detectedLanguage: targetLang,
        isVoice: isVoice,
      ),
    );

    _isProcessing = true;
    notifyListeners();

    // Log Analytics
    AnalyticsService.instance.logSearchUsed('ai_query: $input');

    try {
      // 2. Intent Detection
      final intent = IntentDetector.detectIntent(input, targetLang);

      // 3. Action Execution & Response Building
      final aiResponse = await _executeIntent(intent, targetLang, input, isVoice);

      _messages.add(aiResponse);

      // 4. Voice Output (TTS) if enabled in settings
      if (preferencesService.isAiVoiceOutputEnabled() && aiResponse.text.isNotEmpty) {
        voiceService.speakText(aiResponse.text, targetLang);
      }
    } catch (e) {
      debugPrint('Bhakti AI query processing error: $e');
      _messages.add(
        AiMessage(
          text: _getErrorMessage(targetLang),
          sender: AiSender.ai,
          detectedLanguage: targetLang,
        ),
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Executes specific intent through application tools or devotional knowledge engine
  Future<AiMessage> _executeIntent(
    AiParsedIntent intent,
    String langCode,
    String rawQuery,
    bool isVoice,
  ) async {
    switch (intent.type) {
      case AiIntentType.playSong:
        final query = intent.targetSongId ?? intent.songQuery ?? rawQuery;
        final songs = toolsService.songRepository.searchSongs(query, langCode);
        final song = (songs.isNotEmpty)
            ? songs.first
            : toolsService.songRepository.getSongById(query);

        if (song != null) {
          final localizedTitle = song.getLocalizedTitle(langCode);
          final meaning = song.getLocalizedMeaning(langCode);
          String text;
          switch (langCode) {
            case AiLanguage.kannada:
              text = '« $localizedTitle »\n$meaning\n\nಈ ಪವಿತ್ರ ಗೀತೆಯನ್ನು ಆಲಿಸಲು ಕೆಳಗಿನ ಪ್ಲೇ ಬಟನ್ ಒತ್ತಿ.';
              break;
            case AiLanguage.hindi:
              text = '« $localizedTitle »\n$meaning\n\nइस पावन स्तोत्र को सुनने के लिए नीचे दिए गए प्ले बटन पर टैप करें।';
              break;
            case AiLanguage.tamil:
              text = '« $localizedTitle »\n$meaning\n\nஇந்த புனித பாடலை கேட்க கீழே உள்ள ப்ளே பொத்தானை அழுத்தவும்.';
              break;
            case AiLanguage.malayalam:
              text = '« $localizedTitle »\n$meaning\n\nഈ പവിത്രമായ സ്തോത്രം കേൾക്കാൻ താഴെയുള്ള പ്ലേ ബട്ടൺ അമർത്താം.';
              break;
            case AiLanguage.english:
            default:
              text = '$localizedTitle:\n$meaning\n\nYou can listen to this sacred chant using the play button below.';
          }

          return AiMessage(
            text: text,
            sender: AiSender.ai,
            detectedLanguage: langCode,
            intent: intent.type,
            actionType: AiMessageActionType.playSong,
            song: song,
            isVoice: isVoice,
          );
        } else {
          return AiMessage(
            text: _getSongNotFoundMessage(langCode, query),
            sender: AiSender.ai,
            detectedLanguage: langCode,
            intent: intent.type,
          );
        }

      case AiIntentType.pauseSong:
        await toolsService.pauseSong();
        String text;
        switch (langCode) {
          case AiLanguage.kannada:
            text = 'ಹಾಡನ್ನು ವಿರಾಮಗೊಳಿಸಲಾಗಿದೆ.';
            break;
          case AiLanguage.hindi:
            text = 'गाना रोक दिया गया है।';
            break;
          case AiLanguage.tamil:
            text = 'பாடல் இடைநிறுத்தப்பட்டது.';
            break;
          case AiLanguage.malayalam:
            text = 'പാട്ട് നിർത്തിവെച്ചു.';
            break;
          case AiLanguage.english:
          default:
            text = 'Devotional playback paused.';
        }
        return AiMessage(
          text: text,
          sender: AiSender.ai,
          detectedLanguage: langCode,
          intent: intent.type,
          actionType: AiMessageActionType.pauseSong,
        );

      case AiIntentType.resumeSong:
        await toolsService.resumeSong();
        String text;
        switch (langCode) {
          case AiLanguage.kannada:
            text = 'ಹಾಡು ಮುಂದುವರಿಯುತ್ತಿದೆ.';
            break;
          case AiLanguage.hindi:
            text = 'गाना पुनः चालू कर दिया गया है।';
            break;
          case AiLanguage.tamil:
            text = 'பாடல் மீண்டும் தொடர்கிறது.';
            break;
          case AiLanguage.malayalam:
            text = 'പാട്ട് പുനരാരംഭിച്ചു.';
            break;
          case AiLanguage.english:
          default:
            text = 'Devotional playback resumed.';
        }
        return AiMessage(
          text: text,
          sender: AiSender.ai,
          detectedLanguage: langCode,
          intent: intent.type,
          actionType: AiMessageActionType.resumeSong,
        );

      case AiIntentType.nextSong:
        await toolsService.nextSong();
        String text;
        switch (langCode) {
          case AiLanguage.kannada:
            text = 'ಮುಂದಿನ ಸ್ತೋತ್ರಕ್ಕೆ ಬದಲಾಯಿಸಲಾಗುತ್ತಿದೆ.';
            break;
          case AiLanguage.hindi:
            text = 'अगला स्तोत्र चलाया जा रहा है।';
            break;
          case AiLanguage.tamil:
            text = 'அடுத்த ஸ்தோத்திரம் இசைக்கப்படுகிறது.';
            break;
          case AiLanguage.malayalam:
            text = 'അടുത്ത സ്തോത്രം പ്ലേ ചെയ്യുന്നു.';
            break;
          case AiLanguage.english:
          default:
            text = 'Skipping to next devotional chant.';
        }
        return AiMessage(
          text: text,
          sender: AiSender.ai,
          detectedLanguage: langCode,
          intent: intent.type,
        );

      case AiIntentType.previousSong:
        await toolsService.previousSong();
        String text;
        switch (langCode) {
          case AiLanguage.kannada:
            text = 'ಹಿಂದಿನ ಸ್ತೋತ್ರಕ್ಕೆ ಮರಳಲಾಗುತ್ತಿದೆ.';
            break;
          case AiLanguage.hindi:
            text = 'पिछला स्तोत्र चलाया जा रहा है।';
            break;
          case AiLanguage.tamil:
            text = 'முந்தைய ஸ்தோத்திரம் இசைக்கப்படுகிறது.';
            break;
          case AiLanguage.malayalam:
            text = 'മുമ്പത്തെ സ്തോത്രം പ്ലേ ചെയ്യുന്നു.';
            break;
          case AiLanguage.english:
          default:
            text = 'Returning to previous chant.';
        }
        return AiMessage(
          text: text,
          sender: AiSender.ai,
          detectedLanguage: langCode,
          intent: intent.type,
        );

      case AiIntentType.showLyrics:
        final query = intent.targetSongId ?? intent.songQuery ?? 'lalitha_sahasranamam';
        final result = toolsService.getLyrics(query, langCode: langCode);

        if (result.success && result.data is Map) {
          final data = result.data as Map<String, dynamic>;
          final song = data['song'] as SongModel;
          final lyrics = data['lyrics'] as String;
          final license = data['licenseInfo'] as String;

          String intro;
          switch (langCode) {
            case AiLanguage.kannada:
              intro = '${song.getLocalizedTitle(langCode)} ಸಾಹಿತ್ಯ:';
              break;
            case AiLanguage.hindi:
              intro = '${song.getLocalizedTitle(langCode)} के पावन बोल:';
              break;
            case AiLanguage.tamil:
              intro = '${song.getLocalizedTitle(langCode)} பாடல் வரிகள்:';
              break;
            case AiLanguage.malayalam:
              intro = '${song.getLocalizedTitle(langCode)} വരികൾ:';
              break;
            case AiLanguage.english:
            default:
              intro = 'Lyrics for ${song.getLocalizedTitle(langCode)}:';
          }

          return AiMessage(
            text: '$intro\n\n$lyrics\n\n📜 $license',
            sender: AiSender.ai,
            detectedLanguage: langCode,
            intent: intent.type,
            actionType: AiMessageActionType.showLyrics,
            song: song,
            extraData: data,
          );
        } else {
          return AiMessage(
            text: _getLyricsNotFoundMessage(langCode),
            sender: AiSender.ai,
            detectedLanguage: langCode,
            intent: intent.type,
          );
        }

      case AiIntentType.showMeaning:
        final query = intent.targetSongId ?? intent.songQuery ?? 'lalitha_sahasranamam';
        final result = toolsService.getSongMeaning(query, langCode: langCode);

        if (result.success && result.data is Map) {
          final data = result.data as Map<String, dynamic>;
          final song = data['song'] as SongModel;
          final meaning = data['meaning'] as String;

          return AiMessage(
            text: meaning,
            sender: AiSender.ai,
            detectedLanguage: langCode,
            intent: intent.type,
            actionType: AiMessageActionType.showMeaning,
            song: song,
          );
        } else {
          final generalResponse = await knowledgeEngine.answerQuery(
            query: rawQuery,
            languageCode: langCode,
            matchedSongId: intent.targetSongId,
          );
          return AiMessage(
            text: generalResponse,
            sender: AiSender.ai,
            detectedLanguage: langCode,
            intent: intent.type,
          );
        }

      case AiIntentType.showFavorites:
        final favs = toolsService.getFavorites();
        String text;
        if (favs.isEmpty) {
          switch (langCode) {
            case AiLanguage.kannada:
              text = 'ನಿಮ್ಮ ಮೆಚ್ಚಿನ ಪಟ್ಟಿಯಲ್ಲಿ ಇನ್ನೂ ಯಾವುದೇ ಹಾಡುಗಳನ್ನು ಸೇರಿಸಲಾಗಿಲ್ಲ. ಹಾಡಿನ ಹೃದಯ ಐಕಾನ್ ಒತ್ತುವ ಮೂಲಕ ಸೇರಿಸಬಹುದು.';
              break;
            case AiLanguage.hindi:
              text = 'आपकी पसंदीदा सूची में अभी कोई गाना नहीं है। दिल के निशान को दबाकर जोड़ें।';
              break;
            case AiLanguage.tamil:
              text = 'உங்கள் விருப்பப்பட்டியலில் பாடல்கள் எதுவும் சேர்க்கப்படவில்லை.';
              break;
            case AiLanguage.malayalam:
              text = 'നിങ്ങളുടെ പ്രിയപ്പെട്ടവയിൽ ഇതുവരെ പാട്ടുകൾ ചേർത്തിട്ടില്ല.';
              break;
            case AiLanguage.english:
            default:
              text = 'You have not added any favorite songs yet. Tap the heart icon on any chant to save it.';
          }
          return AiMessage(
            text: text,
            sender: AiSender.ai,
            detectedLanguage: langCode,
            intent: intent.type,
          );
        }

        switch (langCode) {
          case AiLanguage.kannada:
            text = 'ನಿಮ್ಮ ಮೆಚ್ಚಿನ ಭಕ್ತಿ ಗೀತೆಗಳು ಇಲ್ಲಿವೆ:';
            break;
          case AiLanguage.hindi:
            text = 'आपकी पसंदीदा भक्ति रचनाएं:';
            break;
          case AiLanguage.tamil:
            text = 'உங்கள் விருப்பமான பாடல்கள்:';
            break;
          case AiLanguage.malayalam:
            text = 'നിങ്ങളുടെ പ്രിയപ്പെട്ട ഗാനങ്ങൾ:';
            break;
          case AiLanguage.english:
          default:
            text = 'Here are your favorite devotional songs:';
        }

        return AiMessage(
          text: text,
          sender: AiSender.ai,
          detectedLanguage: langCode,
          intent: intent.type,
          actionType: AiMessageActionType.showFavorites,
          songList: favs,
        );

      case AiIntentType.showRecentlyPlayed:
        final recents = toolsService.getRecentlyPlayed();
        String text;
        if (recents.isEmpty) {
          switch (langCode) {
            case AiLanguage.kannada:
              text = 'ಇತ್ತೀಚೆಗೆ ನೀವು ಯಾವುದೇ ಹಾಡುಗಳನ್ನು ಆಲಿಸಿಲ್ಲ.';
              break;
            case AiLanguage.hindi:
              text = 'हाल ही में कोई गाना नहीं सुना गया है।';
              break;
            case AiLanguage.tamil:
              text = 'சமீபத்தில் பாடல்கள் எதுவும் இயக்கப்படவில்லை.';
              break;
            case AiLanguage.malayalam:
              text = 'അടുത്തിടെ ഗാനങ്ങളൊന്നും കേട്ടിട്ടില്ല.';
              break;
            case AiLanguage.english:
            default:
              text = 'No recently played history found.';
          }
          return AiMessage(
            text: text,
            sender: AiSender.ai,
            detectedLanguage: langCode,
            intent: intent.type,
          );
        }

        switch (langCode) {
          case AiLanguage.kannada:
            text = 'ಇತ್ತೀಚೆಗೆ ಆಲಿಸಿದ ಸ್ತೋತ್ರಗಳು:';
            break;
          case AiLanguage.hindi:
            text = 'हाल ही में सुने गए भजन:';
            break;
          case AiLanguage.tamil:
            text = 'சமீபத்தில் கேட்ட பாடல்கள்:';
            break;
          case AiLanguage.malayalam:
            text = 'അടുത്തിടെ കേട്ട സ്തോത്രങ്ങൾ:';
            break;
          case AiLanguage.english:
          default:
            text = 'Here is your recently played chanting history:';
        }

        return AiMessage(
          text: text,
          sender: AiSender.ai,
          detectedLanguage: langCode,
          intent: intent.type,
          actionType: AiMessageActionType.showRecents,
          songList: recents,
        );

      case AiIntentType.searchLanguage:
        final lang = intent.requestedLanguage ?? langCode;
        final songs = toolsService.songRepository.getSongsByLanguage(lang);
        String text;
        switch (langCode) {
          case AiLanguage.kannada:
            text = 'ಈ ಭಾಷೆಯಲ್ಲಿ ಲಭ್ಯವಿರುವ ಭಕ್ತಿ ಗೀತೆಗಳು:';
            break;
          case AiLanguage.hindi:
            text = 'इस भाषा में उपलब्ध रचनाएं:';
            break;
          case AiLanguage.tamil:
            text = 'இந்த மொழியில் உள்ள பக்தி பாடல்கள்:';
            break;
          case AiLanguage.malayalam:
            text = 'ഈ ഭാഷയിൽ ലഭ്യമായ സ്തോത്രങ്ങൾ:';
            break;
          case AiLanguage.english:
          default:
            text = 'Devotional chants available in this language:';
        }

        return AiMessage(
          text: text,
          sender: AiSender.ai,
          detectedLanguage: langCode,
          intent: intent.type,
          songList: songs.isNotEmpty ? songs : toolsService.songRepository.allSongs,
        );

      case AiIntentType.searchCategory:
        final catId = intent.categoryQuery ?? 'stotras';
        final songs = toolsService.songRepository.getSongsByCategory(catId);
        String text;
        switch (langCode) {
          case AiLanguage.kannada:
            text = 'ಈ ವಿಭಾಗದಲ್ಲಿ ಲಭ್ಯವಿರುವ ಸ್ತೋತ್ರಗಳು:';
            break;
          case AiLanguage.hindi:
            text = 'इस श्रेणी में उपलब्ध स्तोत्र:';
            break;
          case AiLanguage.tamil:
            text = 'இந்த பிரிவில் உள்ள ஸ்தோத்திரங்கள்:';
            break;
          case AiLanguage.malayalam:
            text = 'ഈ വിഭാഗത്തിൽ ലഭ്യമായ സ്തോത്രങ്ങൾ:';
            break;
          case AiLanguage.english:
          default:
            text = 'Devotionals in this sacred category:';
        }

        return AiMessage(
          text: text,
          sender: AiSender.ai,
          detectedLanguage: langCode,
          intent: intent.type,
          songList: songs.isNotEmpty ? songs : toolsService.songRepository.allSongs,
        );

      case AiIntentType.appHelp:
        String text;
        switch (langCode) {
          case AiLanguage.kannada:
            text = 'ಭಕ್ತಿ ಆ್ಯಪ್‌ನಲ್ಲಿ ನೀವು:\n1. 🎤 ಮೈಕ್ ಒತ್ತಿ ಧ್ವನಿ ಮೂಲಕ "ಲಲಿತಾ ಸಹಸ್ರನಾಮ ಪ್ಲೇ ಮಾಡಿ" ಎನ್ನಬಹುದು.\n2. "ಹನುಮಾನ್ ಚಾಲೀಸಾದ ಸಾಹಿತ್ಯ ಕೊಡಿ" ಎಂದು ಸಾಹಿತ್ಯ ಪಡೆಯಬಹುದು.\n3. ಸ್ತೋತ್ರಗಳ ಅರ್ಥ ಮತ್ತು ಹಿನ್ನೆಲೆ ತಿಳಿಯಬಹುದು.';
            break;
          case AiLanguage.hindi:
            text = 'भक्ति ऐप पर आप:\n1. 🎤 माइक दबाकर "हनुमान चालीसा बजाओ" कह सकते हैं।\n2. किसी भी स्तोत्र के बोल और अर्थ पूछ सकते हैं।\n3. अपनी पसंदीदा रचनाएं संजो सकते हैं।';
            break;
          case AiLanguage.tamil:
            text = 'பக்தி செயலியில் நீங்கள்:\n1. 🎤 மைக் அழுத்தி "லலிதா சஹஸ்ரநாமம் ப்ளே பண்ணு" என்று குரல் மூலம் இயக்கலாம்.\n2. பாடல்களின் வரிகள் மற்றும் பொருளை அறியலாம்.';
            break;
          case AiLanguage.malayalam:
            text = 'ഭക്തി ആപ്പിൽ നിങ്ങൾക്ക്:\n1. 🎤 മൈക്ക് അമർത്തി ശബ്ദത്തിലൂടെ പാട്ടുകൾ പ്ലേ ചെയ്യാം.\n2. സ്തോത്രങ്ങളുടെ വരികളും അർത്ഥവും അറിയാം.';
            break;
          case AiLanguage.english:
          default:
            text = 'With Bhakti AI you can:\n1. 🎤 Tap the mic and say "Play Lalitha Sahasranamam".\n2. Ask for lyrics: "Give me Hanuman Chalisa lyrics".\n3. Learn spiritual significance: "What is Lalitha Sahasranamam?".';
        }
        return AiMessage(
          text: text,
          sender: AiSender.ai,
          detectedLanguage: langCode,
          intent: intent.type,
        );

      case AiIntentType.generalDevotionalQuestion:
      case AiIntentType.searchSong:
      case AiIntentType.unknown:
        final answer = await knowledgeEngine.answerQuery(

          query: rawQuery,
          languageCode: langCode,
          matchedSongId: intent.targetSongId,
        );
        return AiMessage(
          text: answer,
          sender: AiSender.ai,
          detectedLanguage: langCode,
          intent: intent.type,
        );
    }
  }

  String _getSongNotFoundMessage(String langCode, String query) {
    switch (langCode) {
      case AiLanguage.kannada:
        return 'ಕ್ಷಮಿಸಿ, "$query" ಸದ್ಯಕ್ಕೆ ಭಕ್ತಿ ಲೈಬ್ರರಿಯಲ್ಲಿ ಲಭ್ಯವಿಲ್ಲ. ಲಭ್ಯವಿರುವ ಶ್ರೀ ಲಲಿತಾ ಸಹಸ್ರನಾಮ, ವಿಷ್ಣು ಸಹಸ್ರನಾಮ ಅಥವಾ ಶಿವ ಸ್ತೋತ್ರಗಳನ್ನು ಆಲಿಸಬಹುದು.';
      case AiLanguage.hindi:
        return 'क्षमा करें, "$query" अभी भक्ति लाइब्रेरी में उपलब्ध नहीं है। आप उपलब्ध ललिता सहस्रनाम या विष्णु सहस्रनाम सुन सकते हैं।';
      case AiLanguage.tamil:
        return 'மன்னிக்கவும், "$query" தற்போது பக்தி நூலகத்தில் இல்லை. உள்ள சஹஸ்ரநாமங்களை கேட்டு மகிழுங்கள்.';
      case AiLanguage.malayalam:
        return 'ക്ഷമിക്കണം, "$query" നിലവിൽ ഭക്തി ലൈബ്രറിയിൽ ലഭ്യമല്ല.';
      case AiLanguage.english:
      default:
        return 'Sorry, "$query" is not currently available in the Bhakti library. You can enjoy Sri Lalitha Sahasranamam, Vishnu Sahasranamam, or Shiva Panchakshari.';
    }
  }

  String _getLyricsNotFoundMessage(String langCode) {
    switch (langCode) {
      case AiLanguage.kannada:
        return 'ಈ ಸ್ತೋತ್ರದ ಅಧಿಕೃತ ಸಾಹಿತ್ಯ ಸದ್ಯಕ್ಕೆ ಲಭ್ಯವಿಲ್ಲ.';
      case AiLanguage.hindi:
        return 'इस स्तोत्र के अधिकृत बोल अभी उपलब्ध नहीं हैं।';
      case AiLanguage.tamil:
        return 'இந்த ஸ்தோத்திரத்தின் அதிகாரப்பூர்வ வரிகள் தற்போது கிடைக்கவில்லை.';
      case AiLanguage.malayalam:
        return 'ഈ സ്തോത്രത്തിന്റെ വരികൾ നിലവിൽ ലഭ്യമല്ല.';
      case AiLanguage.english:
      default:
        return 'Authorized lyrics for this chant are not currently available in the library.';
    }
  }

  String _getErrorMessage(String langCode) {
    switch (langCode) {
      case AiLanguage.kannada:
        return 'ಭಕ್ತಿ ಎಐ ಸದ್ಯಕ್ಕೆ ಪ್ರತಿಕ್ರಿಯಿಸಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ. ದಯವಿಟ್ಟು ಪುನಃ ಪ್ರಯತ್ನಿಸಿ.';
      case AiLanguage.hindi:
        return 'भक्ति एआई अभी अनुत्तरदायी है। कृपया पुनः प्रयास करें।';
      case AiLanguage.tamil:
        return 'பக்தி ஏஐ தற்போது கிடைக்கவில்லை. மீண்டும் முயற்சிக்கவும்.';
      case AiLanguage.malayalam:
        return 'ഭക്തി എഐ താൽക്കാലികമായി ലഭ്യമല്ല. ദയവായി വീണ്ടും ശ്രമിക്കുക.';
      case AiLanguage.english:
      default:
        return 'Bhakti AI is temporarily unavailable. Please try again.';
    }
  }
}
