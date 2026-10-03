import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/ads/ad_service.dart';
import '../services/premium/premium_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!AdService.instance.frequencyManager.isPremiumUser) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    if (kIsWeb || !AdService.instance.isInitialized || AdService.instance.frequencyManager.isPremiumUser) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.instance.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            if (AdService.instance.frequencyManager.isPremiumUser) {
              ad.dispose();
              setState(() {
                _isLoaded = false;
                _bannerAd = null;
              });
              return;
            }
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premiumService = context.watch<PremiumService?>();
    final isPremium = premiumService?.isPremium ?? AdService.instance.frequencyManager.isPremiumUser;

    // 100% Ad-Free for VIP/Premium subscribers
    if (isPremium) {
      if (_bannerAd != null) {
        _bannerAd?.dispose();
        _bannerAd = null;
        _isLoaded = false;
      }
      return const SizedBox.shrink();
    }

    if (kIsWeb || !AdService.instance.isInitialized) {
      return const SizedBox.shrink();
    }

    if (_isLoaded && _bannerAd != null) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Return an empty sized box while loading or if failed
    return const SizedBox.shrink();
  }
}

