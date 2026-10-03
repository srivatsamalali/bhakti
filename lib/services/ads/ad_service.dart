import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';
import 'ad_frequency_manager.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  final AdFrequencyManager _frequencyManager = AdFrequencyManager();
  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  bool _isLoadingInterstitial = false;

  bool get isInitialized => _isInitialized;
  AdFrequencyManager get frequencyManager => _frequencyManager;

  /// Update premium status across all ad controllers
  void setPremium(bool isPremium) {
    _frequencyManager.setPremiumUser(isPremium);
  }

  static const List<String> defaultTestDevices = [
    '9e8f5c48-a289-4d95-87bb-360ed33fc0c0',
  ];

  /// Initialize Google Mobile Ads SDK with Test Device support
  Future<void> initialize({List<String>? testDeviceIds}) async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await MobileAds.instance.initialize();
        _isInitialized = true;

        // Configure test devices
        final allTestDevices = <String>{
          ...defaultTestDevices,
          if (testDeviceIds != null) ...testDeviceIds,
        }.toList();

        final config = RequestConfiguration(testDeviceIds: allTestDevices);
        await MobileAds.instance.updateRequestConfiguration(config);

        loadInterstitialAd();
      }
    } catch (e) {
      debugPrint('AdMob Initialization notice: $e');
    }
  }

  // --- Ad Unit IDs ---
  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return kReleaseMode
          ? AppConstants.prodAndroidBannerId
          : AppConstants.testAndroidBannerId;
    }
    if (Platform.isIOS) return AppConstants.testIosBannerId;
    return '';
  }

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return kReleaseMode
          ? AppConstants.prodAndroidInterstitialId
          : AppConstants.testAndroidInterstitialId;
    }
    if (Platform.isIOS) return AppConstants.testIosInterstitialId;
    return '';
  }

  // --- Interstitial Ads Loading ---
  void loadInterstitialAd() {
    if (!_isInitialized || kIsWeb || _isLoadingInterstitial || _frequencyManager.isPremiumUser) return;
    if (_interstitialAd != null) return; // Already cached and ready

    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitial = false;
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          debugPrint('🎯 [AdService] Interstitial Ad loaded and ready for transition.');
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          debugPrint('⚠️ [AdService] Interstitial failed to load: ${error.message} (attempt $_interstitialLoadAttempts)');
          if (_interstitialLoadAttempts <= 3) {
            Future.delayed(const Duration(seconds: 30), loadInterstitialAd);
          }
        },
      ),
    );
  }

  /// Shows interstitial ad ONLY at natural content transitions with strict frequency validation.
  ///
  /// Guarantees:
  /// - Never shown during active playback.
  /// - Never shown immediately when a user clicks play.
  /// - If no ad is ready or frequency limits not met, [onDismissedOrCompleted] is invoked immediately
  ///   so devotional music playback is NEVER delayed or interrupted.
  void showInterstitialAtNaturalTransition({
    required VoidCallback onDismissedOrCompleted,
    bool isAudioCurrentlyPlaying = false,
  }) {
    // Check devotional frequency rules
    final eligible = _frequencyManager.isEligibleForInterstitial(
      isAudioCurrentlyPlaying: isAudioCurrentlyPlaying,
    );

    if (!eligible || _interstitialAd == null) {
      // Continue playback immediately without interruption
      onDismissedOrCompleted();
      // Ensure we have a fresh ad cached in background for the next opportunity
      if (_interstitialAd == null) {
        loadInterstitialAd();
      }
      return;
    }

    // Interstitial is ready and frequency rules are satisfied
    final ad = _interstitialAd!;
    _interstitialAd = null; // Consume reference

    bool hasCalledCallback = false;
    void safeCallback() {
      if (!hasCalledCallback) {
        hasCalledCallback = true;
        onDismissedOrCompleted();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('📺 [AdService] Interstitial dismissed by user.');
        ad.dispose();
        safeCallback();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('⚠️ [AdService] Interstitial failed to show: ${error.message}');
        ad.dispose();
        safeCallback();
        loadInterstitialAd();
      },
    );

    _frequencyManager.recordInterstitialShown();
    ad.show();
  }
}
