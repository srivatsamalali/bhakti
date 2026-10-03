import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../ads/ad_service.dart';
import '../preferences/preferences_service.dart';

enum PremiumPlanType {
  monthly,
  quarterly,
  yearly,
  lifetime,
}

class PremiumPlan {
  final PremiumPlanType type;
  final String id;
  final String title;
  final String priceDisplay;
  final int priceInr;
  final String billingPeriod;
  final String? savingsBadge;
  final bool isPopular;

  const PremiumPlan({
    required this.type,
    required this.id,
    required this.title,
    required this.priceDisplay,
    required this.priceInr,
    required this.billingPeriod,
    this.savingsBadge,
    this.isPopular = false,
  });
}

class PremiumService extends ChangeNotifier {
  /// Global Subscription Feature Flag
  static bool get isFeatureEnabled => AppConstants.isSubscriptionEnabled;

  static const String keyIsPremium = 'bhakti_is_premium_user_v1';
  static const String keyActivePlanId = 'bhakti_active_premium_plan_id';
  static const String keyPurchaseTimestamp = 'bhakti_premium_purchase_time';

  final PreferencesService _prefs;

  bool _isPremium = false;
  String? _activePlanId;
  DateTime? _purchaseDate;

  static const List<PremiumPlan> availablePlans = [
    PremiumPlan(
      type: PremiumPlanType.monthly,
      id: 'bhakti_premium_monthly_29',
      title: 'Monthly Sacred Pass',
      priceDisplay: '₹29',
      priceInr: 29,
      billingPeriod: '/ month',
      savingsBadge: null,
      isPopular: false,
    ),
    PremiumPlan(
      type: PremiumPlanType.quarterly,
      id: 'bhakti_premium_quarterly_99',
      title: 'Quarterly Sadhana',
      priceDisplay: '₹99',
      priceInr: 99,
      billingPeriod: '/ 3 months',
      savingsBadge: 'Save 15%',
      isPopular: false,
    ),
    PremiumPlan(
      type: PremiumPlanType.yearly,
      id: 'bhakti_premium_yearly_249',
      title: 'Annual Divine Devotion',
      priceDisplay: '₹249',
      priceInr: 249,
      billingPeriod: '/ year (₹20/mo)',
      savingsBadge: 'Best Value • Save 30%',
      isPopular: true,
    ),
    PremiumPlan(
      type: PremiumPlanType.lifetime,
      id: 'bhakti_premium_lifetime_499',
      title: 'Lifetime Ad-Free Moksha',
      priceDisplay: '₹499',
      priceInr: 499,
      billingPeriod: 'one-time payment',
      savingsBadge: 'Ad-Free Forever',
      isPopular: false,
    ),
  ];

  PremiumService(this._prefs) {
    _loadStatus();
  }

  bool get isPremium => _isPremium;
  String? get activePlanId => _activePlanId;
  DateTime? get purchaseDate => _purchaseDate;

  PremiumPlan? get currentPlan {
    if (!_isPremium || _activePlanId == null) return null;
    try {
      return availablePlans.firstWhere((p) => p.id == _activePlanId);
    } catch (_) {
      return availablePlans.last; // default to lifetime if unknown
    }
  }

  void _loadStatus() {
    final status = _prefs.getInt(keyIsPremium);
    _isPremium = (status != null && status == 1);
    _activePlanId = _prefs.getString(keyActivePlanId);

    // Sync with AdMob frequency manager
    AdService.instance.frequencyManager.setPremiumUser(_isPremium);
  }

  /// Purchase and activate a Premium plan
  Future<bool> purchasePlan(PremiumPlan plan) async {
    try {
      _isPremium = true;
      _activePlanId = plan.id;
      _purchaseDate = DateTime.now();

      await _prefs.setInt(keyIsPremium, 1);
      await _prefs.setString(keyActivePlanId, plan.id);

      // Update Ad Service immediately to eliminate all ads
      AdService.instance.frequencyManager.setPremiumUser(true);

      notifyListeners();
      debugPrint('💎 [PremiumService] Successfully activated plan: ${plan.title} (${plan.priceDisplay})');
      return true;
    } catch (e) {
      debugPrint('❌ [PremiumService] Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases from Google Play
  Future<bool> restorePurchases() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate Google Play query
      final status = _prefs.getInt(keyIsPremium) ?? 0;
      if (status == 1) {
        _isPremium = true;
        _activePlanId = _prefs.getString(keyActivePlanId) ?? availablePlans.last.id;
        AdService.instance.frequencyManager.setPremiumUser(true);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [PremiumService] Restore error: $e');
      return false;
    }
  }

  /// Cancel or reset premium status (for testing / admin)
  Future<void> debugResetPremium() async {
    _isPremium = false;
    _activePlanId = null;
    _purchaseDate = null;
    await _prefs.setInt(keyIsPremium, 0);
    AdService.instance.frequencyManager.setPremiumUser(false);
    notifyListeners();
  }
}
