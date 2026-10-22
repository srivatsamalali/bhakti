import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhakti/services/wisdom/daily_gita_service.dart';
import 'package:bhakti/models/category_model.dart';
import 'package:bhakti/features/pooja/garbhagruha/sanctum_registry.dart';
import 'package:bhakti/core/localization/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Requirement 1: Daily Bhagavad Gita Shloka in Opening Modal', () {
    test('DailyBhagavadGitaService returns authentic Gita verses with meanings', () {
      final todayGita = DailyBhagavadGitaService.getTodayGitaShloka();
      expect(todayGita.id, isNotEmpty);
      expect(todayGita.chapter, greaterThan(0));
      expect(todayGita.verse, greaterThan(0));
      expect(todayGita.sanskrit, isNotEmpty);

      // Verify all 6 languages are available
      for (final lang in ['kn', 'te', 'hi', 'ta', 'ml', 'en']) {
        expect(todayGita.getVerse(lang), isNotEmpty, reason: 'Missing verse in $lang');
        expect(todayGita.getMeaning(lang), isNotEmpty, reason: 'Missing meaning in $lang');
        expect(todayGita.getChapterName(lang), isNotEmpty);
        expect(todayGita.getReference(lang), isNotEmpty);
        expect(todayGita.getTheme(lang), isNotEmpty);
      }
    });

    test('Rotates daily verse across consecutive days', () {
      final day1 = DailyBhagavadGitaService.getTodayGitaShloka(DateTime(2026, 1, 1));
      final day2 = DailyBhagavadGitaService.getTodayGitaShloka(DateTime(2026, 1, 2));
      expect(day1.id, isNot(equals(day2.id)));
    });
  });

  group('Requirement 2: Asthotara and Stuti as Song Types', () {
    test('sample_categories.json contains asthotara and stuti', () async {
      final jsonString = await rootBundle.loadString('assets/data/sample_categories.json');
      final List list = jsonDecode(jsonString);
      final categories = list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();

      final asthotara = categories.firstWhere((c) => c.id == 'asthotara');
      expect(asthotara, isNotNull);
      expect(asthotara.getLocalizedName('en'), 'Asthotara');
      expect(asthotara.getLocalizedName('kn'), 'ಅಷ್ಟೋತ್ತರ');
      expect(asthotara.getLocalizedName('te'), 'అష్టోత్తర శతనామావళి');

      final stuti = categories.firstWhere((c) => c.id == 'stuti');
      expect(stuti, isNotNull);
      expect(stuti.getLocalizedName('en'), 'Stuti');
      expect(stuti.getLocalizedName('kn'), 'ಸ್ತುತಿ');
      expect(stuti.getLocalizedName('te'), 'స్తుతి');
    });

    test('sample_songs.json contains songs with category asthotara and stuti', () async {
      final jsonString = await rootBundle.loadString('assets/data/sample_songs.json');
      final List songs = jsonDecode(jsonString);

      final hasAsthotara = songs.any((s) => s['categoryId'] == 'asthotara');
      final hasStuti = songs.any((s) => s['categoryId'] == 'stuti');

      expect(hasAsthotara, isTrue, reason: 'sample_songs.json should contain an asthotara song');
      expect(hasStuti, isTrue, reason: 'sample_songs.json should contain a stuti song');
    });
  });

  group('Requirement 3: Dynamic Language Button Switch', () {
    test('Button text reflects the selected language dynamically', () {
      final kanContinue = AppStrings.localizedValues['kn']?['continueButton'];
      final telContinue = AppStrings.localizedValues['te']?['continueButton'];
      final hiContinue = AppStrings.localizedValues['hi']?['continueButton'];
      final taContinue = AppStrings.localizedValues['ta']?['continueButton'];
      final mlContinue = AppStrings.localizedValues['ml']?['continueButton'];
      final enContinue = AppStrings.localizedValues['en']?['continueButton'];

      expect(kanContinue, 'ಮುಂದುವರಿಯಿರಿ');
      expect(telContinue, 'కొనసాగించండి');
      expect(hiContinue, 'आगे बढ़ें');
      expect(taContinue, 'தொடர்க');
      expect(mlContinue, 'തുടരുക');
      expect(enContinue, 'Continue');

      expect(telContinue, isNot(equals(kanContinue)));
    });
  });

  group('Requirement 4: Maps Location Details & Google Maps Navigation', () {
    test('Sanctum environments contain exact coordinates and Google Maps URLs', () {
      expect(allSanctumEnvironments.length, 4);

      // 1. Chamundeshwari / Chamundi Hills
      final chamundi = allSanctumEnvironments.firstWhere((s) => s.deityId == 'chamundi');
      expect(chamundi.locationName, contains('Chamundi Hills'));
      expect(chamundi.latitude, closeTo(12.2725, 0.01));
      expect(chamundi.longitude, closeTo(76.6713, 0.01));
      expect(chamundi.fullAddress, contains('Chamundi Hill Road, Mysuru'));
      expect(chamundi.googleMapsUrl, contains('Chamundeshwari'));

      // 2. Venkateshwara / Tirumala Hills
      final venkateshwara = allSanctumEnvironments.firstWhere((s) => s.deityId == 'venkateshwara');
      expect(venkateshwara.locationName, contains('Tirumala'));
      expect(venkateshwara.latitude, closeTo(13.6833, 0.01));
      expect(venkateshwara.longitude, closeTo(79.3472, 0.01));
      expect(venkateshwara.fullAddress, contains('Tirumala, Tirupati'));
      expect(venkateshwara.googleMapsUrl, contains('google.com/maps'));

      // 3. Ganesha / Southadka
      final ganesha = allSanctumEnvironments.firstWhere((s) => s.deityId == 'ganesha');
      expect(ganesha.locationName, contains('Southadka'));
      expect(ganesha.latitude, closeTo(12.8335, 0.01));
      expect(ganesha.longitude, closeTo(75.3621, 0.01));
      expect(ganesha.fullAddress, contains('Southadka Maha Ganapathi'));
      expect(ganesha.googleMapsUrl, contains('google.com/maps'));

      // 4. Lakshmi / Kolhapur
      final lakshmi = allSanctumEnvironments.firstWhere((s) => s.deityId == 'lakshmi');
      expect(lakshmi.locationName, contains('Kolhapur'));
      expect(lakshmi.latitude, closeTo(16.6946, 0.01));
      expect(lakshmi.longitude, closeTo(74.2238, 0.01));
      expect(lakshmi.fullAddress, contains('Kolhapur'));
      expect(lakshmi.googleMapsUrl, contains('google.com/maps'));
    });
  });

  group('New Features: 701 Progressive Gita & Song Translation', () {
    test('getChapterAndVerseForShlokaNumber maps all 701 verses correctly', () {
      // Day 1 -> Ch 1, Verse 1
      final day1 = DailyBhagavadGitaService.getChapterAndVerseForShlokaNumber(1);
      expect(day1['chapter'], 1);
      expect(day1['verse'], 1);

      // Day 5 -> Ch 1, Verse 5 (user prompt example)
      final day5 = DailyBhagavadGitaService.getChapterAndVerseForShlokaNumber(5);
      expect(day5['chapter'], 1);
      expect(day5['verse'], 5);

      // Ch 1 last verse (verse 47)
      final endCh1 = DailyBhagavadGitaService.getChapterAndVerseForShlokaNumber(47);
      expect(endCh1['chapter'], 1);
      expect(endCh1['verse'], 47);

      // Ch 2 first verse (shloka 48)
      final startCh2 = DailyBhagavadGitaService.getChapterAndVerseForShlokaNumber(48);
      expect(startCh2['chapter'], 2);
      expect(startCh2['verse'], 1);

      // Last verse of Gita (shloka 701) -> Ch 18, Verse 78
      final endGita = DailyBhagavadGitaService.getChapterAndVerseForShlokaNumber(701);
      expect(endGita['chapter'], 18);
      expect(endGita['verse'], 78);
    });

    test('getInitialVerseForNumber returns valid verse instantly without latency', () {
      final verse1 = DailyBhagavadGitaService.getInitialVerseForNumber(1);
      expect(verse1.chapter, 1);
      expect(verse1.verse, 1);
      expect(verse1.sanskrit, isNotEmpty);

      final verse5 = DailyBhagavadGitaService.getInitialVerseForNumber(5);
      expect(verse5.chapter, 1);
      expect(verse5.verse, 5);
      expect(verse5.sanskrit, isNotEmpty);
    });
  });
}
