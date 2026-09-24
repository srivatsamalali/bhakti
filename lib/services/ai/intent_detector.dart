enum AiIntentType {
  playSong,
  pauseSong,
  resumeSong,
  nextSong,
  previousSong,
  showLyrics,
  showMeaning,
  searchSong,
  searchCategory,
  searchLanguage,
  showFavorites,
  showRecentlyPlayed,
  generalDevotionalQuestion,
  appHelp,
  unknown,
}

class AiParsedIntent {
  final AiIntentType type;
  final String? songQuery;
  final String? targetSongId;
  final String? categoryQuery;
  final String? requestedLanguage;
  final String? generalQuery;
  final double confidence;

  const AiParsedIntent({
    required this.type,
    this.songQuery,
    this.targetSongId,
    this.categoryQuery,
    this.requestedLanguage,
    this.generalQuery,
    this.confidence = 1.0,
  });
}

/// Normalizes text and extracts deterministic devotional intents and entities
class IntentDetector {
  // Known canonical song IDs and their aliases across 5 languages & transliterations
  static const Map<String, List<String>> _songAliases = {
    'lalitha_sahasranamam': [
      'lalitha sahasranamam', 'lalitha sahasranama', 'lalita sahasranamam', 'lalita sahasranama',
      'lalitha sahasra', 'lalita sahasra', 'lalitha', 'lalita', 'tripura sundari',
      'ಲಲಿತಾ ಸಹಸ್ರನಾಮ', 'ಲಲಿತಾ ಸಹಸ್ರನಾಮಂ', 'ಲಲಿತಾ', 'ಶ್ರೀ ಲಲಿತಾ',
      'ललिता सहस्रनाम', 'ललिता सहस्रनामम', 'ललिता', 'श्री ललिता',
      'லலிதா சஹஸ்ரநாமம்', 'லலிதா', 'ஸ்ரீ லலிதா',
      'ലളിതാ സഹസ്രനാമം', 'ലളിത', 'ശ്രീ ലളിത'
    ],
    'vishnu_sahasranamam': [
      'vishnu sahasranamam', 'vishnu sahasranama', 'vishnusahasranamam', 'maha vishnu', 'vishnu',
      'ವಿಷ್ಣು ಸಹಸ್ರನಾಮ', 'ವಿಷ್ಣು ಸಹಸ್ರನಾಮಂ', 'ವಿಷ್ಣು', 'ಮಹಾವಿಷ್ಣು',
      'विष्णु सहस्रनाम', 'विष्णु सहस्रनामम', 'विष्णु', 'महाविष्णु',
      'விஷ்ணு சஹஸ்ரநாமம்', 'விஷ்ணு', 'மகாவிஷ்ணு',
      'വിഷ്ണു സഹസ്രനാമം', 'വിഷ്ണു', 'മഹാവിഷ്ണു'
    ],
    'hanuman_chalisa': [
      'hanuman chalisa', 'hanuman chalisaa', 'hanuman', 'anjaneya', 'maruti',
      'ಹನುಮಾನ್ ಚಾಲೀಸಾ', 'ಹನುಮಾನ್ ಚಾಲೀಸ', 'ಹನುಮಂತ', 'ಆಂಜನೇಯ',
      'हनुमान चालीसा', 'हनुमान', 'बजरंगबली', 'अंजनेय',
      'அனுமன் சாலிசா', 'ஹனுமான் சாலீஸா', 'ஆஞ்சநேயர்',
      'ഹനുമാൻ ചാലീസ', 'ഹനുമാൻ', 'ആഞ്ജനേയ'
    ],
    'shiva_panchakshari': [
      'shiva panchakshari', 'shiva panchakshara', 'om namah shivaya', 'panchakshari', 'shiva stotra', 'shiva', 'mahadev',
      'ಶಿವ ಪಂಚಾಕ್ಷರಿ', 'ಶಿವ ಪಂಚಾಕ್ಷರ', 'ಓಂ ನಮಃ ಶಿವಾಯ', 'ಪಂಚಾಕ್ಷರಿ', 'ಶಿವ', 'ಮಹಾದೇವ',
      'शिव पंचाक्षर', 'शिव पंचाक्षरी', 'ॐ नमः शिवाय', 'पंचाक्षर', 'शिव', 'महादेव',
      'சிவ பஞ்சாட்சர', 'ஓம் நம சிவாய', 'பஞ்சாட்சரம்', 'சிவன்',
      'ശിവ പഞ്ചാക്ഷര', 'ഓം നമഃ ശിവായ', 'പഞ്ചാക്ഷരി', 'ശിവൻ'
    ],
  };

  /// Parses user natural language query into high-confidence intent and extracted entities
  static AiParsedIntent detectIntent(String rawInput, String detectedLang) {
    final input = rawInput.trim();
    final lower = input.toLowerCase();

    // 1. Match Known Devotional Song Entities First
    String? matchedSongId;
    for (var entry in _songAliases.entries) {
      for (var alias in entry.value) {
        if (lower.contains(alias.toLowerCase())) {
          matchedSongId = entry.key;
          break;
        }
      }
      if (matchedSongId != null) break;
    }

    // 2. Lyrics Intent (e.g. "Give me lyrics of Lalitha Sahasranamam", "Nanage Lalitha Sahasra na Maada Sahitya Kodu", "ಸಾಹಿತ್ಯ ಕೊಡಿ", "बोल चाहिए")
    if (_isLyricsCommand(lower)) {
      return AiParsedIntent(
        type: AiIntentType.showLyrics,
        targetSongId: matchedSongId,
        songQuery: matchedSongId ?? input,
        requestedLanguage: detectedLang,
        confidence: 0.95,
      );
    }

    // 3. Meaning & Significance Intent (e.g. "Kannada dalli Hanuman Chalisa meaning kodi", "ಭಾವಾರ್ಥ ತಿಳಿಸಿ")
    if (_isMeaningCommand(lower)) {
      return AiParsedIntent(
        type: AiIntentType.showMeaning,
        targetSongId: matchedSongId,
        songQuery: matchedSongId ?? input,
        requestedLanguage: detectedLang,
        confidence: 0.95,
      );
    }

    // 4. Play Song Intent (If song entity matches or play verb exists)
    if (_isPlayCommand(lower) || (matchedSongId != null && _isDirectPlayContext(lower))) {
      return AiParsedIntent(
        type: AiIntentType.playSong,
        targetSongId: matchedSongId,
        songQuery: matchedSongId ?? _extractSongEntity(input),
        requestedLanguage: detectedLang,
        confidence: 0.95,
      );
    }

    // 5. Playback Controls without specific song (Pause / Resume / Next / Prev)
    if (_isPauseCommand(lower)) {
      return const AiParsedIntent(type: AiIntentType.pauseSong, confidence: 0.99);
    }
    if (_isResumeCommand(lower)) {
      return const AiParsedIntent(type: AiIntentType.resumeSong, confidence: 0.99);
    }
    if (_isNextCommand(lower)) {
      return const AiParsedIntent(type: AiIntentType.nextSong, confidence: 0.99);
    }
    if (_isPreviousCommand(lower)) {
      return const AiParsedIntent(type: AiIntentType.previousSong, confidence: 0.99);
    }

    // 6. Favorites & Recents
    if (_isFavoritesCommand(lower)) {
      return const AiParsedIntent(type: AiIntentType.showFavorites, confidence: 0.95);
    }
    if (_isRecentsCommand(lower)) {
      return const AiParsedIntent(type: AiIntentType.showRecentlyPlayed, confidence: 0.95);
    }

    // 7. App Help
    if (_isHelpCommand(lower)) {
      return const AiParsedIntent(type: AiIntentType.appHelp, confidence: 0.95);
    }

    // 8. Language Search Intent (e.g. "What is available in Kannada?")
    if (lower.contains('available in kannada') || lower.contains('kannada songs') || lower.contains('ಕನ್ನಡದಲ್ಲಿ ಯಾವ ಹಾಡುಗಳು') || lower.contains('ಕನ್ನಡ ಹಾಡುಗಳು')) {
      return const AiParsedIntent(type: AiIntentType.searchLanguage, requestedLanguage: 'kn', confidence: 0.90);
    }
    if (lower.contains('available in hindi') || lower.contains('hindi songs') || lower.contains('हिन्दी में क्या है') || lower.contains('हिंदी गाने')) {
      return const AiParsedIntent(type: AiIntentType.searchLanguage, requestedLanguage: 'hi', confidence: 0.90);
    }
    if (lower.contains('available in tamil') || lower.contains('tamil songs') || lower.contains('தமிழில் உள்ளவை') || lower.contains('தமிழ் பாடல்கள்')) {
      return const AiParsedIntent(type: AiIntentType.searchLanguage, requestedLanguage: 'ta', confidence: 0.90);
    }
    if (lower.contains('available in malayalam') || lower.contains('malayalam songs') || lower.contains('മലയാളത്തിലുള്ളവ')) {
      return const AiParsedIntent(type: AiIntentType.searchLanguage, requestedLanguage: 'ml', confidence: 0.90);
    }

    // 9. Category Search Intent
    if (lower.contains('stotra') || lower.contains('ಸ್ತೋತ್ರ') || lower.contains('स्तोत्र')) {
      return const AiParsedIntent(type: AiIntentType.searchCategory, categoryQuery: 'stotras', confidence: 0.90);
    }
    if (lower.contains('sahasranama') || lower.contains('ಸಹಸ್ರನಾಮ') || lower.contains('सहस्रनाम')) {
      return const AiParsedIntent(type: AiIntentType.searchCategory, categoryQuery: 'sahasranamam', confidence: 0.90);
    }
    if (lower.contains('chalisa') || lower.contains('ಚಾಲೀಸಾ') || lower.contains('चालीसा')) {
      return const AiParsedIntent(type: AiIntentType.searchCategory, categoryQuery: 'chalisa', confidence: 0.90);
    }

    // 10. General Devotional Questions (e.g. "What is...", "Who is...", "Explain...", "ಏನು?", "क्या है?", "என்ன?")
    if (_isQuestionCommand(lower)) {
      return AiParsedIntent(
        type: AiIntentType.generalDevotionalQuestion,
        targetSongId: matchedSongId,
        generalQuery: input,
        requestedLanguage: detectedLang,
        confidence: 0.90,
      );
    }

    // 11. Generic Search / Fallback
    if (matchedSongId != null) {
      return AiParsedIntent(
        type: AiIntentType.playSong,
        targetSongId: matchedSongId,
        songQuery: matchedSongId,
        requestedLanguage: detectedLang,
        confidence: 0.85,
      );
    }

    return AiParsedIntent(
      type: AiIntentType.generalDevotionalQuestion,
      generalQuery: input,
      requestedLanguage: detectedLang,
      confidence: 0.70,
    );
  }

  static bool _isPauseCommand(String text) {
    return text == 'pause' || text == 'stop' ||
        text.contains('pause') || text.contains('stop song') ||
        text.contains('ನಿಲ್ಲಿಸಿ') || text.contains('ಸ್ಟಾಪ್') ||
        text.contains('रोकें') || text.contains('बंद करो') ||
        text.contains('நிறுத்து') || text.contains('നിർത്തുക');
  }

  static bool _isResumeCommand(String text) {
    return text == 'resume' || text == 'continue' ||
        text.contains('resume') || text.contains('play again') ||
        (text.contains('ಮುಂದುವರಿಸಿ') || (text.contains('ಪ್ಲೇ ಮಾಡಿ') && !text.contains('ಹಾಡು'))) ||
        text.contains('चालू करें') || text.contains('पुनः चलाएं') ||
        text.contains('தொடரவும்') || text.contains('തുടരുക');
  }

  static bool _isNextCommand(String text) {
    return text.contains('next') || text.contains('ಮುಂದಿನ') || text.contains('अगला') ||
        text.contains('அடுத்த') || text.contains('അടുത്ത');
  }

  static bool _isPreviousCommand(String text) {
    return text.contains('previous') || text.contains('prev') || text.contains('ಹಿಂದಿನ') ||
        text.contains('पिछला') || text.contains('முந்தைய') || text.contains('മുമ്പത്തെ');
  }

  static bool _isFavoritesCommand(String text) {
    return text.contains('favorite') || text.contains('favourites') || text.contains('liked') ||
        text.contains('ಮೆಚ್ಚಿನ') || text.contains('ಪಸಂದ್') ||
        text.contains('पसंदीदा') || text.contains('मनपसंद') ||
        text.contains('விருப்பமான') || text.contains('പ്രിയപ്പെട്ട');
  }

  static bool _isRecentsCommand(String text) {
    return text.contains('recent') || text.contains('history') ||
        text.contains('ಇತ್ತೀಚೆಗೆ') || text.contains('ಹಿಂದೆ ಕೇಳಿದ') ||
        text.contains('हाल ही में') || text.contains('इतिहास') ||
        text.contains('சமீபத்திய') || text.contains('അടുത്തിടെ');
  }

  static bool _isHelpCommand(String text) {
    return text == 'help' || text.contains('how to use') || text.contains('help me') ||
        text.contains('ಸಹಾಯ') || text.contains('ಮಾರ್ಗದರ್ಶನ') ||
        text.contains('मदद') || text.contains('सहायता') ||
        text.contains('உதவி') || text.contains('സഹായം');
  }

  static bool _isLyricsCommand(String text) {
    return text.contains('lyrics') || text.contains('lyric') || text.contains('words') || text.contains('text') ||
        text.contains('sahitya') || text.contains('sahithya') || text.contains('saahitya') ||
        text.contains('ಸಾಹಿತ್ಯ') || text.contains('ಪದಗಳು') || text.contains('ವರಹಾ') ||
        text.contains('bol') || text.contains('boliye') || text.contains('गीत के बोल') || text.contains('बोल') || text.contains('लिरिक्स') ||
        text.contains('varigal') || text.contains('varigalai') || text.contains('வரிகள்') || text.contains('பாடல் வரிகள்') ||
        text.contains('varikal') || text.contains('വരികൾ') || text.contains('സാഹിത്യം');
  }

  static bool _isMeaningCommand(String text) {
    return text.contains('meaning') || text.contains('significance') || text.contains('explain meaning') ||
        text.contains('artha') || text.contains('artham') || text.contains('bhavartha') || text.contains('mahatva') || text.contains('bhavarth') ||
        text.contains('ಅರ್ಥ') || text.contains('ಮಹತ್ವ') || text.contains('ಭಾವಾರ್ಥ') ||
        text.contains('अर्थ') || text.contains('महत्व') || text.contains('भावार्थ') ||
        text.contains('பொருள்') || text.contains('அர்த்தம்') || text.contains('விளக்கம்') ||
        text.contains('അർത്ഥം') || text.contains('പ്രാധാന്യം');
  }

  static bool _isPlayCommand(String text) {
    return text.startsWith('play') || text.contains('play ') || text.contains(' play') ||
        text.contains('play madi') || text.contains('play maadi') || text.contains('haaku') || text.contains('haaki') ||
        text.contains('keli') || text.contains('kelisi') || text.contains('ಪ್ಲೇ ಮಾಡಿ') || text.contains('ಹಾಕಿ') ||
        text.contains('ಬಜಾವೋ') || text.contains('बजाओ') || text.contains('सुनाओ') || text.contains('चलाओ') || text.contains('chalao') || text.contains('bajao') || text.contains('sunao') ||
        text.contains('padu') || text.contains('paadu') || text.contains('பாடு') || text.contains('பாடவும்') || text.contains('போடு') ||
        text.contains('paduka') || text.contains('പാടുക') || text.contains('കേൾപ്പിക്കുക');
  }

  static bool _isDirectPlayContext(String text) {
    return !text.contains('?') && !text.contains('what') && !text.contains('meaning') &&
        !text.contains('lyrics') && !text.contains('sahitya') && !text.contains('sahithya') &&
        !text.contains('artha') && !text.contains('who') && !text.contains('ಏನು') &&
        !text.contains('ಅರ್ಥ') && !text.contains('ಸಾಹಿತ್ಯ') && !text.contains('क्या') &&
        !text.contains('बोल') && !text.contains('வரிகள்');
  }

  static bool _isQuestionCommand(String text) {
    return text.contains('?') || text.contains('what is') || text.contains('who is') ||
        text.contains('tell me about') || text.contains('explain') || text.contains('vivarisi') || text.contains('tilisi') ||
        text.contains('ಏನು') || text.contains('ಹೇಳಿ') || text.contains('ತಿಳಿಸಿ') || text.contains('ಯಾರು') ||
        text.contains('क्या है') || text.contains('बताएं') || text.contains('बताओ') || text.contains('कौन है') ||
        text.contains('என்ன') || text.contains('சொல்லுங்கள்') || text.contains('யார்') ||
        text.contains('എന്താണ്') || text.contains('പറയൂ') || text.contains('ആരാണ്');
  }

  static String _extractSongEntity(String input) {
    return input
        .replaceAll(RegExp(r'(play|song|sing|listen|keli|haadu|madi|maadi|bajao|karo|batao|chalao|kodi|beku|sahitya|sahithya|lyrics|meaning|artha)', caseSensitive: false), '')
        .trim();
  }
}
