import 'package:flutter_test/flutter_test.dart';
import 'package:bhakti/services/ads/ad_frequency_manager.dart';

void main() {
  group('AdFrequencyManager - Devotional Listening Ad Rules', () {
    late AdFrequencyManager manager;

    setUp(() {
      manager = AdFrequencyManager(
        minSongsBetweenInterstitials: 3,
        minMinutesBetweenInterstitials: 10,
      );
    });

    test('Initial state requires 3 songs before showing an interstitial', () {
      expect(manager.naturallyCompletedSongs, 0);
      expect(manager.isEligibleForInterstitial(), false);

      // Song 1 completed
      manager.recordSongCompletedNaturally();
      expect(manager.naturallyCompletedSongs, 1);
      expect(manager.isEligibleForInterstitial(), false);

      // Song 2 completed
      manager.recordSongCompletedNaturally();
      expect(manager.naturallyCompletedSongs, 2);
      expect(manager.isEligibleForInterstitial(), false);

      // Song 3 completed -> Now eligible
      manager.recordSongCompletedNaturally();
      expect(manager.naturallyCompletedSongs, 3);
      expect(manager.isEligibleForInterstitial(), true);
    });

    test('Never shows interstitial during active audio playback', () {
      manager.recordSongCompletedNaturally();
      manager.recordSongCompletedNaturally();
      manager.recordSongCompletedNaturally();

      expect(manager.isEligibleForInterstitial(isAudioCurrentlyPlaying: true), false);
      expect(manager.isEligibleForInterstitial(isAudioCurrentlyPlaying: false), true);
    });

    test('Never shows interstitial to Premium users', () {
      manager.recordSongCompletedNaturally();
      manager.recordSongCompletedNaturally();
      manager.recordSongCompletedNaturally();

      manager.setPremiumUser(true);
      expect(manager.isEligibleForInterstitial(), false);

      manager.setPremiumUser(false);
      expect(manager.isEligibleForInterstitial(), true);
    });

    test('Respects minimum 10-minute time interval between interstitials', () {
      // Qualify and show 1st interstitial
      manager.recordSongCompletedNaturally();
      manager.recordSongCompletedNaturally();
      manager.recordSongCompletedNaturally();
      expect(manager.isEligibleForInterstitial(), true);

      manager.recordInterstitialShown();
      expect(manager.naturallyCompletedSongs, 0);
      expect(manager.lastInterstitialShownTime, isNotNull);

      // Even if 3 songs complete within the next 2 minutes, time interval blocks it
      manager.recordSongCompletedNaturally();
      manager.recordSongCompletedNaturally();
      manager.recordSongCompletedNaturally();
      expect(manager.isEligibleForInterstitial(), false);
    });
  });
}
