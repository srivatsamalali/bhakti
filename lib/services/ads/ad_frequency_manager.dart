import 'package:flutter/foundation.dart';

/// Manages interstitial advertisement frequency specifically tailored for devotional listening.
///
/// Guarantees:
/// 1. Devotional listening is never aggressively interrupted.
/// 2. Ads appear ONLY at natural song completions/transitions.
/// 3. Never during active playback, never in the middle of a song, never immediately after starting.
/// 4. Ad frequency respects both song count (MIN_SONGS_BETWEEN_INTERSTITIALS) and time elapsed (MIN_MINUTES_BETWEEN_INTERSTITIALS).
/// 5. Premium users never see interstitial advertisements.
class AdFrequencyManager {
  static const int defaultMinSongsBetweenInterstitials = 3;
  static const int defaultMinMinutesBetweenInterstitials = 10;

  final int minSongsBetweenInterstitials;
  final int minMinutesBetweenInterstitials;

  int _naturallyCompletedSongs = 0;
  DateTime? _lastInterstitialShownTime;
  bool _isPremiumUser = false;

  AdFrequencyManager({
    this.minSongsBetweenInterstitials = defaultMinSongsBetweenInterstitials,
    this.minMinutesBetweenInterstitials = defaultMinMinutesBetweenInterstitials,
  });

  int get naturallyCompletedSongs => _naturallyCompletedSongs;
  DateTime? get lastInterstitialShownTime => _lastInterstitialShownTime;
  bool get isPremiumUser => _isPremiumUser;

  /// Update premium user status
  void setPremiumUser(bool isPremium) {
    _isPremiumUser = isPremium;
  }

  /// Call this strictly when a song finishes playing from start to finish naturally
  void recordSongCompletedNaturally() {
    _naturallyCompletedSongs++;
    debugPrint(
      '🎵 [AdFrequencyManager] Song naturally completed. Count: $_naturallyCompletedSongs / $minSongsBetweenInterstitials',
    );
  }

  /// Determines if an interstitial ad is permitted to be shown at this moment
  bool isEligibleForInterstitial({bool isAudioCurrentlyPlaying = false}) {
    // Rule 1: Never show to premium users
    if (_isPremiumUser) {
      debugPrint('🚫 [AdFrequencyManager] Blocked: User is Premium');
      return false;
    }

    // Rule 2: Never show during active audio playback or in middle of a song
    if (isAudioCurrentlyPlaying) {
      debugPrint('🚫 [AdFrequencyManager] Blocked: Audio is currently playing');
      return false;
    }

    // Rule 3: Must satisfy minimum song completion threshold
    if (_naturallyCompletedSongs < minSongsBetweenInterstitials) {
      debugPrint(
        '⏳ [AdFrequencyManager] Frequency threshold not met: $_naturallyCompletedSongs / $minSongsBetweenInterstitials songs',
      );
      return false;
    }

    // Rule 4: Must satisfy minimum minutes interval between interstitials
    if (_lastInterstitialShownTime != null) {
      final elapsedMinutes = DateTime.now().difference(_lastInterstitialShownTime!).inMinutes;
      if (elapsedMinutes < minMinutesBetweenInterstitials) {
        debugPrint(
          '⏳ [AdFrequencyManager] Time threshold not met: $elapsedMinutes / $minMinutesBetweenInterstitials minutes elapsed',
        );
        return false;
      }
    }

    debugPrint('✅ [AdFrequencyManager] Eligible for transition interstitial ad');
    return true;
  }

  /// Record that an interstitial ad was successfully displayed
  void recordInterstitialShown() {
    _naturallyCompletedSongs = 0;
    _lastInterstitialShownTime = DateTime.now();
    debugPrint('📢 [AdFrequencyManager] Interstitial shown. Counters reset.');
  }

  /// Reset counters (e.g., on test reset or new session)
  void reset() {
    _naturallyCompletedSongs = 0;
    _lastInterstitialShownTime = null;
  }
}
