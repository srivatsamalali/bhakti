import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhakti/services/firebase/song_request_service.dart';
import 'package:bhakti/services/preferences/preferences_service.dart';
import 'package:bhakti/services/rewards/seva_token_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService prefsService;
  late SevaTokenService sevaService;
  late SongRequestService requestService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefsService = await PreferencesService.create();
    sevaService = SevaTokenService(prefsService);
    await Future.delayed(const Duration(milliseconds: 10));
    requestService = SongRequestService(sevaService);
  });

  group('SongRequestService Tests', () {
    test('Submitting a song request adds request and awards +20 tokens', () async {
      final initialBalance = sevaService.tokenBalance;

      final success = await requestService.submitRequest(
        songTitle: 'Jagadodharana Aadisidale Yashode',
        deity: 'Lord Krishna',
        language: 'kn',
        singerOrComposer: 'Purandara Dasa',
        notes: 'Classic Kannada Carnatic Kriti',
      );

      expect(success, isTrue);
      expect(requestService.requests.length, 1);
      expect(requestService.requests.first.songTitle, 'Jagadodharana Aadisidale Yashode');
      expect(requestService.requests.first.deity, 'Lord Krishna');
      expect(requestService.requests.first.status, 'pending');

      // Verify +20 tokens awarded
      expect(sevaService.tokenBalance, initialBalance + 20);
      expect(sevaService.history.first.title, contains('Song Request'));
    });

    test('Empty title is rejected', () async {
      final success = await requestService.submitRequest(
        songTitle: '   ',
        deity: 'Shiva',
        language: 'sa',
      );

      expect(success, isFalse);
      expect(requestService.requests.isEmpty, isTrue);
    });
  });
}
