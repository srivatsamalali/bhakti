import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  DateTime? _lastInterstitialShownTime;

  bool get isInitialized => _isInitialized;

  /// Initialize Google Mobile Ads SDK
  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await MobileAds.instance.initialize();
        _isInitialized = true;
        loadInterstitialAd();
      }
    } catch (e) {
      debugPrint('AdMob Initialization notice: $e');
    }
  }

  // --- Ad Unit IDs ---
  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return AppConstants.testAndroidBannerId;
    if (Platform.isIOS) return AppConstants.testIosBannerId;
    return '';
  }

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return AppConstants.testAndroidInterstitialId;
    if (Platform.isIOS) return AppConstants.testIosInterstitialId;
    return '';
  }

  // --- Interstitial Ads (Rate limited: max once every 4 minutes, never during audio playback) ---
  void loadInterstitialAd() {
    if (!_isInitialized || kIsWeb) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= 3) {
            Future.delayed(const Duration(seconds: 30), loadInterstitialAd);
          }
        },
      ),
    );
  }

  /// Shows interstitial ad only at natural navigation boundaries
  void showInterstitialIfAppropriate() {
    if (_interstitialAd == null) return;
    final now = DateTime.now();
    if (_lastInterstitialShownTime != null &&
        now.difference(_lastInterstitialShownTime!).inMinutes < 4) {
      // Don't show ads too frequently
      return;
    }
    _interstitialAd?.show();
    _lastInterstitialShownTime = now;
  }
}
