import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhakti/core/localization/app_localizations.dart';
import 'package:bhakti/core/localization/app_strings.dart';

void main() {
  group('Localization Tests', () {
    test('All 5 languages have essential key translations', () {
      final requiredKeys = [
        'appName',
        'appTagline',
        'spiritualTagline',
        'navHome',
        'navSongs',
        'navFavorites',
        'navSettings',
        'play',
        'pause',
        'queue',
        'sleepTimer',
        'adminPortal',
      ];

      for (var lang in ['en', 'kn', 'hi', 'ta', 'ml']) {
        final dict = AppStrings.localizedValues[lang];
        expect(dict, isNotNull, reason: 'Language $lang dictionary should exist');

        for (var key in requiredKeys) {
          expect(dict![key], isNotNull, reason: 'Key $key must exist in $lang');
          expect(dict[key]!.isNotEmpty, true, reason: 'Key $key in $lang must not be empty');
        }
      }
    });

    test('AppLocalizations translates correctly per locale', () {
      final knLoc = AppLocalizations(const Locale('kn'));
      expect(knLoc.translate('play'), 'ಪ್ಲೇ');

      final hiLoc = AppLocalizations(const Locale('hi'));
      expect(hiLoc.translate('play'), 'चलाएं');

      final enLoc = AppLocalizations(const Locale('en'));
      expect(enLoc.translate('play'), 'Play');

      final taLoc = AppLocalizations(const Locale('ta'));
      expect(taLoc.translate('play'), 'இயக்கு');

      final mlLoc = AppLocalizations(const Locale('ml'));
      expect(mlLoc.translate('play'), 'പ്ലേ ചെയ്യുക');
    });
  });
}
