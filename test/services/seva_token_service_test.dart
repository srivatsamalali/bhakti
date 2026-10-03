import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhakti/services/preferences/preferences_service.dart';
import 'package:bhakti/services/rewards/seva_token_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService prefsService;
  late SevaTokenService sevaService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefsService = await PreferencesService.create();
    sevaService = SevaTokenService(prefsService);
    // Allow initial async load
    await Future.delayed(const Duration(milliseconds: 10));
  });

  group('SevaTokenService - Devotional Token Rewards & Perks Tests', () {
    test('Initial state provides welcome blessing tokens', () {
      expect(sevaService.tokenBalance, 25);
      expect(sevaService.totalTokensEarned, 25);
      expect(sevaService.currentBadge, SevaBadge.bhaktiSadhaka);
      expect(sevaService.hasActiveAdFreePass, isFalse);
    });

    test('Awarding tokens increases balance and logs transaction', () async {
      await sevaService.awardTokens(
        amount: 50,
        title: 'Song Upload Contribution 🎵',
        description: 'Uploaded Sri Lalitha Sahasranamam',
      );

      expect(sevaService.tokenBalance, 75);
      expect(sevaService.totalTokensEarned, 75);
      expect(sevaService.currentBadge, SevaBadge.sangeetaSeva);
      expect(sevaService.history.first.title, 'Song Upload Contribution 🎵');
      expect(sevaService.history.first.amount, 50);
      expect(sevaService.history.first.isCredit, isTrue);
    });

    test('Redeeming Ad-Free pass deducts tokens and activates pass', () async {
      // Award enough tokens first
      await sevaService.awardTokens(
        amount: 100,
        title: 'Devotional Seva Reward',
        description: 'Active contribution',
      );

      expect(sevaService.tokenBalance, 125);

      final success = await sevaService.redeemAdFreePass(days: 1, costTokens: 100);
      expect(success, isTrue);
      expect(sevaService.tokenBalance, 25);
      expect(sevaService.hasActiveAdFreePass, isTrue);
      expect(sevaService.history.first.isCredit, isFalse);
      expect(sevaService.history.first.title, contains('Redeemed 1-Day Ad-Free Pass'));
    });

    test('Redeeming with insufficient tokens fails gracefully', () async {
      final success = await sevaService.redeemAdFreePass(days: 3, costTokens: 250);
      expect(success, isFalse);
      expect(sevaService.tokenBalance, 25);
      expect(sevaService.hasActiveAdFreePass, isFalse);
    });

    test('Promotes badge tiers as total earned tokens increase', () async {
      expect(sevaService.currentBadge, SevaBadge.bhaktiSadhaka);

      await sevaService.awardTokens(amount: 50, title: 'Upload', description: 'Song');
      expect(sevaService.currentBadge, SevaBadge.sangeetaSeva);

      await sevaService.awardTokens(amount: 50, title: 'Upload', description: 'Song 2');
      expect(sevaService.currentBadge, SevaBadge.shlokaPunya);

      await sevaService.awardTokens(amount: 150, title: 'Grand Seva', description: 'Major seva');
      expect(sevaService.currentBadge, SevaBadge.sevaRatna);
    });
  });
}
