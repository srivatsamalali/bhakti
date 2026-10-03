import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhakti/services/preferences/preferences_service.dart';
import 'package:bhakti/services/premium/premium_service.dart';
import 'package:bhakti/services/ads/ad_service.dart';

void main() {
  group('PremiumService & In-App Purchase Tests', () {
    late PreferencesService prefsService;
    late PremiumService premiumService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      prefsService = PreferencesService(prefs);
      premiumService = PremiumService(prefsService);
    });

    test('All 4 requested pricing tiers are correctly configured', () {
      final plans = PremiumService.availablePlans;
      expect(plans.length, 4);

      // Monthly: ₹29
      final monthly = plans.firstWhere((p) => p.type == PremiumPlanType.monthly);
      expect(monthly.priceInr, 29);
      expect(monthly.priceDisplay, '₹29');

      // Quarterly: ₹99
      final quarterly = plans.firstWhere((p) => p.type == PremiumPlanType.quarterly);
      expect(quarterly.priceInr, 99);
      expect(quarterly.priceDisplay, '₹99');

      // Yearly: ₹249
      final yearly = plans.firstWhere((p) => p.type == PremiumPlanType.yearly);
      expect(yearly.priceInr, 249);
      expect(yearly.priceDisplay, '₹249');
      expect(yearly.isPopular, true);

      // Lifetime: ₹499
      final lifetime = plans.firstWhere((p) => p.type == PremiumPlanType.lifetime);
      expect(lifetime.priceInr, 499);
      expect(lifetime.priceDisplay, '₹499');
    });

    test('Purchasing a plan activates premium and silences all ads in AdService', () async {
      expect(premiumService.isPremium, false);
      expect(AdService.instance.frequencyManager.isPremiumUser, false);

      final lifetimePlan = PremiumService.availablePlans.firstWhere(
        (p) => p.type == PremiumPlanType.lifetime,
      );

      final success = await premiumService.purchasePlan(lifetimePlan);
      expect(success, true);
      expect(premiumService.isPremium, true);
      expect(premiumService.currentPlan?.priceInr, 499);

      // AdMob frequency manager immediately disables all ads
      expect(AdService.instance.frequencyManager.isPremiumUser, true);
      expect(AdService.instance.frequencyManager.isEligibleForInterstitial(), false);
    });

    test('Restoring purchases reflects stored premium state', () async {
      final yearlyPlan = PremiumService.availablePlans.firstWhere(
        (p) => p.type == PremiumPlanType.yearly,
      );
      await premiumService.purchasePlan(yearlyPlan);

      // Create new instance simulating app restart
      final newPremiumService = PremiumService(prefsService);
      expect(newPremiumService.isPremium, true);
      expect(AdService.instance.frequencyManager.isPremiumUser, true);
    });
  });
}
