import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhakti/services/preferences/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesService Tests', () {
    late PreferencesService prefsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefsService = await PreferencesService.create();
    });

    test('Defaults to Kannada language and can be updated', () async {
      expect(prefsService.getSelectedLanguage(), 'kn');

      await prefsService.setSelectedLanguage('hi');
      expect(prefsService.getSelectedLanguage(), 'hi');
    });

    test('Favorites persistence and toggling', () async {
      expect(prefsService.getFavoriteSongIds(), isEmpty);
      expect(prefsService.isFavorite('lalitha_1'), false);

      await prefsService.toggleFavorite('lalitha_1');
      expect(prefsService.isFavorite('lalitha_1'), true);
      expect(prefsService.getFavoriteSongIds(), contains('lalitha_1'));

      await prefsService.toggleFavorite('lalitha_1');
      expect(prefsService.isFavorite('lalitha_1'), false);
    });

    test('Recently played tracking and limits', () async {
      await prefsService.addRecentlyPlayed('song_1');
      await prefsService.addRecentlyPlayed('song_2');

      final recents = prefsService.getRecentlyPlayedIds();
      expect(recents.first, 'song_2');
      expect(recents.length, 2);

      await prefsService.clearRecentlyPlayed();
      expect(prefsService.getRecentlyPlayedIds(), isEmpty);
    });

    test('Admin password verification with default dev fallback', () async {
      expect(prefsService.verifyAdminPassword('sri'), true);
      expect(prefsService.verifyAdminPassword('wrong_pass'), false);

      await prefsService.changeAdminPassword('new_secret_pass');
      expect(prefsService.verifyAdminPassword('new_secret_pass'), true);
      expect(prefsService.verifyAdminPassword('sri'), false);
    });
  });
}
