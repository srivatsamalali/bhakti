/// Core language codes supported by Bhakti AI
class AiLanguage {
  static const String kannada = 'kn';
  static const String english = 'en';
  static const String hindi = 'hi';
  static const String tamil = 'ta';
  static const String malayalam = 'ml';

  static const List<String> all = [kannada, english, hindi, tamil, malayalam];

  static String getDisplayName(String code) {
    switch (code) {
      case kannada:
        return 'ಕನ್ನಡ (Kannada)';
      case hindi:
        return 'हिन्दी (Hindi)';
      case tamil:
        return 'தமிழ் (Tamil)';
      case malayalam:
        return 'മലയാളം (Malayalam)';
      case english:
      default:
        return 'English';
    }
  }

  static String getSpeechLocale(String code) {
    switch (code) {
      case kannada:
        return 'kn-IN';
      case hindi:
        return 'hi-IN';
      case tamil:
        return 'ta-IN';
      case malayalam:
        return 'ml-IN';
      case english:
      default:
        return 'en-IN';
    }
  }
}

class LanguageDetectionResult {
  final String languageCode;
  final double confidence; // 0.0 to 1.0
  final bool isExplicitlyRequested;

  const LanguageDetectionResult({
    required this.languageCode,
    required this.confidence,
    this.isExplicitlyRequested = false,
  });
}

/// Robust Language Detection layer supporting native scripts,
/// transliterated Indian language queries, and mixed-language devotional commands.
class LanguageDetector {
  // Unicode ranges for Indic scripts
  static final RegExp _kannadaRegex = RegExp(r'[\u0C80-\u0CFF]');
  static final RegExp _devanagariRegex = RegExp(r'[\u0900-\u097F]');
  static final RegExp _tamilRegex = RegExp(r'[\u0B80-\u0BFF]');
  static final RegExp _malayalamRegex = RegExp(r'[\u0D00-\u0D7F]');

  // Common transliterated verb/particle markers
  static final List<String> _kannadaKeywords = [
    'madi', 'maadi', 'kodi', 'koDi', 'beku', 'bekku', 'bidi', 'yelli', 'hege',
    'yaaru', 'dalli', 'alli', 'illi', 'haaku', 'shuru', 'sahitya', 'arthagalu',
    'artha', 'kelu', 'helu', 'banni', 'nanna', 'nange', 'nanage', 'haadugalu',
    'haadu', 'hadugalu', 'kannadadalli', 'kannada'
  ];

  static final List<String> _hindiKeywords = [
    'karo', 'kijiye', 'bajao', 'batao', 'suno', 'sunao', 'chahiye', 'kya',
    'kaise', 'kaun', 'mein', 'dikhao', 'arth', 'sahitya', 'bol',
    'shuru', 'gaana', 'bhajan', 'chalisa', 'hindi mein', 'hindi'
  ];


  static final List<String> _tamilKeywords = [
    'pannu', 'pannunga', 'podu', 'kudu', 'kudunga', 'venum', 'vendum', 'sollu',
    'sollunga', 'keal', 'kettka', 'enna', 'paadunga', 'paadal', 'artham', 'varigal',
    'tamilil', 'tamizhil', 'tamil'
  ];

  static final List<String> _malayalamKeywords = [
    'cheyyu', 'cheyyuka', 'parayu', 'parayuka', 'tharu', 'venam', 'enthaanu',
    'enganeya', 'varikal', 'kaattu', 'kelkkanam', 'paattu', 'artham',
    'malayalathil', 'malayalam'
  ];

  /// Detects the target language from user input (text or speech transcript)
  static LanguageDetectionResult detectLanguage(String input, {String? defaultAppLanguage}) {
    final clean = input.trim();
    if (clean.isEmpty) {
      return LanguageDetectionResult(
        languageCode: defaultAppLanguage ?? AiLanguage.kannada,
        confidence: 0.5,
      );
    }

    final lower = clean.toLowerCase();

    // 1. Explicit Language Directives (e.g. "Kannada dalli...", "in Tamil", "Hindi mein...")
    if (lower.contains('kannada dalli') || lower.contains('in kannada') || lower.contains('kannada version')) {
      return const LanguageDetectionResult(languageCode: AiLanguage.kannada, confidence: 0.98, isExplicitlyRequested: true);
    }
    if (lower.contains('hindi mein') || lower.contains('in hindi') || lower.contains('hindi version')) {
      return const LanguageDetectionResult(languageCode: AiLanguage.hindi, confidence: 0.98, isExplicitlyRequested: true);
    }
    if (lower.contains('tamilil') || lower.contains('in tamil') || lower.contains('tamil version')) {
      return const LanguageDetectionResult(languageCode: AiLanguage.tamil, confidence: 0.98, isExplicitlyRequested: true);
    }
    if (lower.contains('malayalathil') || lower.contains('in malayalam') || lower.contains('malayalam version')) {
      return const LanguageDetectionResult(languageCode: AiLanguage.malayalam, confidence: 0.98, isExplicitlyRequested: true);
    }
    if (lower.contains('in english') || lower.contains('english version')) {
      return const LanguageDetectionResult(languageCode: AiLanguage.english, confidence: 0.98, isExplicitlyRequested: true);
    }

    // 2. Native Script Character Count Analysis
    int knCount = _kannadaRegex.allMatches(clean).length;
    int hiCount = _devanagariRegex.allMatches(clean).length;
    int taCount = _tamilRegex.allMatches(clean).length;
    int mlCount = _malayalamRegex.allMatches(clean).length;

    int totalIndic = knCount + hiCount + taCount + mlCount;
    if (totalIndic > 0) {
      if (knCount >= hiCount && knCount >= taCount && knCount >= mlCount) {
        return LanguageDetectionResult(languageCode: AiLanguage.kannada, confidence: 0.95);
      }
      if (hiCount >= knCount && hiCount >= taCount && hiCount >= mlCount) {
        return LanguageDetectionResult(languageCode: AiLanguage.hindi, confidence: 0.95);
      }
      if (taCount >= knCount && taCount >= hiCount && taCount >= mlCount) {
        return LanguageDetectionResult(languageCode: AiLanguage.tamil, confidence: 0.95);
      }
      if (mlCount >= knCount && mlCount >= hiCount && mlCount >= taCount) {
        return LanguageDetectionResult(languageCode: AiLanguage.malayalam, confidence: 0.95);
      }
    }

    // 3. Transliterated Keyword Token Matching
    final tokens = lower.split(RegExp(r'[\s,?.!]+'));
    int knScore = 0;
    int hiScore = 0;
    int taScore = 0;
    int mlScore = 0;

    for (var token in tokens) {
      if (_kannadaKeywords.contains(token)) knScore += 2;
      if (_hindiKeywords.contains(token)) hiScore += 2;
      if (_tamilKeywords.contains(token)) taScore += 2;
      if (_malayalamKeywords.contains(token)) mlScore += 2;
    }

    int maxScore = [knScore, hiScore, taScore, mlScore].reduce((a, b) => a > b ? a : b);
    if (maxScore > 0) {
      if (knScore == maxScore) return LanguageDetectionResult(languageCode: AiLanguage.kannada, confidence: 0.85);
      if (hiScore == maxScore) return LanguageDetectionResult(languageCode: AiLanguage.hindi, confidence: 0.85);
      if (taScore == maxScore) return LanguageDetectionResult(languageCode: AiLanguage.tamil, confidence: 0.85);
      if (mlScore == maxScore) return LanguageDetectionResult(languageCode: AiLanguage.malayalam, confidence: 0.85);
    }

    // 4. Default to English or current active app language
    return LanguageDetectionResult(
      languageCode: defaultAppLanguage ?? AiLanguage.english,
      confidence: 0.70,
    );
  }
}
