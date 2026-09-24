import 'package:flutter_test/flutter_test.dart';
import 'package:bhakti/services/ai/language_detector.dart';
import 'package:bhakti/services/ai/intent_detector.dart';
import 'package:bhakti/services/ai/devotional_knowledge_engine.dart';

void main() {
  group('Bhakti AI Acceptance Tests', () {
    // TEST 1: English Play Song
    test('TEST 1: English Play Lalitha Sahasranamam', () {
      final lang = LanguageDetector.detectLanguage('Play Lalitha Sahasranamam');
      expect(lang.languageCode, equals(AiLanguage.english));

      final intent = IntentDetector.detectIntent('Play Lalitha Sahasranamam', lang.languageCode);
      expect(intent.type, equals(AiIntentType.playSong));
      expect(intent.targetSongId, equals('lalitha_sahasranamam'));
    });

    // TEST 2: Kannada Play Song
    test('TEST 2: Kannada Play Lalitha Sahasranamam', () {
      final input = 'ಲಲಿತಾ ಸಹಸ್ರನಾಮವನ್ನು ಪ್ಲೇ ಮಾಡಿ';
      final lang = LanguageDetector.detectLanguage(input);
      expect(lang.languageCode, equals(AiLanguage.kannada));

      final intent = IntentDetector.detectIntent(input, lang.languageCode);
      expect(intent.type, equals(AiIntentType.playSong));
      expect(intent.targetSongId, equals('lalitha_sahasranamam'));
    });

    // TEST 3: Hindi Play Hanuman Chalisa
    test('TEST 3: Hindi Play Hanuman Chalisa', () {
      final input = 'हनुमान चालीसा बजाओ';
      final lang = LanguageDetector.detectLanguage(input);
      expect(lang.languageCode, equals(AiLanguage.hindi));

      final intent = IntentDetector.detectIntent(input, lang.languageCode);
      expect(intent.type, equals(AiIntentType.playSong));
      expect(intent.targetSongId, equals('hanuman_chalisa'));
    });

    // TEST 4: Tamil Question
    test('TEST 4: Tamil Question on Lalitha Sahasranamam', () async {
      final input = 'லலிதா சஹஸ்ரநாமம் என்ன?';
      final lang = LanguageDetector.detectLanguage(input);
      expect(lang.languageCode, equals(AiLanguage.tamil));

      final intent = IntentDetector.detectIntent(input, lang.languageCode);
      expect(intent.targetSongId, equals('lalitha_sahasranamam'));

      final knowledge = DevotionalKnowledgeEngine();
      final answer = await knowledge.answerQuery(query: input, languageCode: lang.languageCode, matchedSongId: intent.targetSongId);
      expect(answer, contains('ஸ்ரீ லலிதா சஹஸ்ரநாமம்'));
    });

    // TEST 5: Malayalam Question
    test('TEST 5: Malayalam Question on Lalitha Sahasranamam', () async {
      final input = 'ലളിതാ സഹസ്രനാമം എന്താണ്?';
      final lang = LanguageDetector.detectLanguage(input);
      expect(lang.languageCode, equals(AiLanguage.malayalam));

      final intent = IntentDetector.detectIntent(input, lang.languageCode);
      expect(intent.targetSongId, equals('lalitha_sahasranamam'));

      final knowledge = DevotionalKnowledgeEngine();
      final answer = await knowledge.answerQuery(query: input, languageCode: lang.languageCode, matchedSongId: intent.targetSongId);
      expect(answer, contains('ശ്രീ ലളിതാ സഹസ്രനാമം'));
    });

    // TEST 6: English Lyrics Request
    test('TEST 6: Give me the lyrics of Lalitha Sahasranamam', () {
      final input = 'Give me the lyrics of Lalitha Sahasranamam';
      final lang = LanguageDetector.detectLanguage(input);
      expect(lang.languageCode, equals(AiLanguage.english));

      final intent = IntentDetector.detectIntent(input, lang.languageCode);
      expect(intent.type, equals(AiIntentType.showLyrics));
      expect(intent.targetSongId, equals('lalitha_sahasranamam'));
    });

    // TEST 7: Kannada Lyrics Request
    test('TEST 7: Kannada Lyrics Request', () {
      final input = 'ಲಲಿತಾ ಸಹಸ್ರನಾಮದ ಸಾಹಿತ್ಯ ಕೊಡಿ';
      final lang = LanguageDetector.detectLanguage(input);
      expect(lang.languageCode, equals(AiLanguage.kannada));

      final intent = IntentDetector.detectIntent(input, lang.languageCode);
      expect(intent.type, equals(AiIntentType.showLyrics));
      expect(intent.targetSongId, equals('lalitha_sahasranamam'));
    });

    // TEST 8: Mixed Language Meaning Request
    test('TEST 8: Kannada dalli Hanuman Chalisa meaning kodi', () async {
      final input = 'Kannada dalli Hanuman Chalisa meaning kodi';
      final lang = LanguageDetector.detectLanguage(input);
      expect(lang.languageCode, equals(AiLanguage.kannada));

      final intent = IntentDetector.detectIntent(input, lang.languageCode);
      expect(intent.type, equals(AiIntentType.showMeaning));
      expect(intent.targetSongId, equals('hanuman_chalisa'));

      final knowledge = DevotionalKnowledgeEngine();
      final answer = await knowledge.answerQuery(query: input, languageCode: lang.languageCode, matchedSongId: intent.targetSongId);
      expect(answer, contains('ಹನುಮಾನ್ ಚಾಲೀಸಾ'));
    });

    // TEST 9: Mixed Kannada-English Play
    test('TEST 9: Lalitha Sahasranamam play madi', () {
      final input = 'Lalitha Sahasranamam play madi';
      final lang = LanguageDetector.detectLanguage(input);
      expect(lang.languageCode, equals(AiLanguage.kannada));

      final intent = IntentDetector.detectIntent(input, lang.languageCode);
      expect(intent.type, equals(AiIntentType.playSong));
      expect(intent.targetSongId, equals('lalitha_sahasranamam'));
    });

    // TEST 10: Show Favorites Command
    test('TEST 10: Show my favorites', () {
      final input = 'Show my favorites';
      final lang = LanguageDetector.detectLanguage(input);
      final intent = IntentDetector.detectIntent(input, lang.languageCode);
      expect(intent.type, equals(AiIntentType.showFavorites));
    });

    // TEST 11: Transliterated Kannada Voice Lyrics Request
    test('TEST 11: Nanage Lalitha Sahasra na Maada Sahitya Kodu', () {
      final input = 'Nanage Lalitha Sahasra na Maada Sahitya Kodu';
      final lang = LanguageDetector.detectLanguage(input);
      expect(lang.languageCode, equals(AiLanguage.kannada));

      final intent = IntentDetector.detectIntent(input, lang.languageCode);
      expect(intent.type, equals(AiIntentType.showLyrics));
      expect(intent.targetSongId, equals('lalitha_sahasranamam'));
    });
  });
}
