import 'package:flutter_test/flutter_test.dart';
import 'package:bhakti/models/song_model.dart';
import 'package:bhakti/models/category_model.dart';
import 'package:bhakti/models/language_model.dart';

void main() {
  group('SongModel Tests', () {
    test('Serializes to and from JSON correctly', () {
      final song = SongModel(
        id: 'test_1',
        title: 'Lalitha Sahasranamam',
        titleLocalized: {
          'en': 'Lalitha Sahasranamam',
          'kn': 'ಲಲಿತಾ ಸಹಸ್ರನಾಮ',
          'hi': 'ललिता सहस्रनाम',
        },
        language: 'kn',
        categoryId: 'sahasranamam',
        categoryName: 'Sahasranamam',
        deity: 'Goddess Lalitha',
        deityLocalized: {
          'en': 'Goddess Lalitha',
          'kn': 'ಶ್ರೀ ಲಲಿತಾ ದೇವಿ',
        },
        description: 'Sacred hymn of 1000 names',
        artist: 'Traditional Vedic Chants',
        album: 'Divine Mother',
        imageUrl: 'assets/images/lalitha_sahasranamam.jpg',
        audioUrl: 'https://example.com/lalitha.mp3',
        duration: 1800,
        lyrics: 'Om Sri Matre Namah',
        published: true,
      );

      final json = song.toJson();
      expect(json['id'], 'test_1');
      expect(json['title'], 'Lalitha Sahasranamam');
      expect(json['duration'], 1800);

      final restored = SongModel.fromJson(json);
      expect(restored.id, song.id);
      expect(restored.title, song.title);
      expect(restored.getLocalizedTitle('kn'), 'ಲಲಿತಾ ಸಹಸ್ರನಾಮ');
      expect(restored.getLocalizedDeity('kn'), 'ಶ್ರೀ ಲಲಿತಾ ದೇವಿ');
      expect(restored.formattedDuration, '30:00');
    });

    test('CategoryModel handles localized names', () {
      final category = CategoryModel(
        id: 'stotras',
        name: {
          'en': 'Stotras',
          'kn': 'ಸ್ತೋತ್ರಗಳು',
          'hi': 'स्तोत्र',
        },
        icon: 'temple',
        order: 1,
      );

      expect(category.getLocalizedName('kn'), 'ಸ್ತೋತ್ರಗಳು');
      expect(category.getLocalizedName('hi'), 'स्तोत्र');
      expect(category.getLocalizedName('ta'), 'Stotras'); // Fallback to en
    });

    test('LanguageModel contains all 5 supported sacred languages', () {
      expect(LanguageModel.supported.length, 5);
      final codes = LanguageModel.supported.map((l) => l.code).toList();
      expect(codes, containsAll(['kn', 'en', 'hi', 'ta', 'ml']));
    });
  });
}
