import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/premium/premium_service.dart';
import '../../widgets/liquid_glass/glass_style.dart';
import '../../widgets/liquid_glass/liquid_glass.dart';
import '../../widgets/sacred_back_button.dart';

class BhaktiPremiumScreen extends StatefulWidget {
  const BhaktiPremiumScreen({super.key});

  static Future<void> show(BuildContext context) {
    if (!PremiumService.isFeatureEnabled) {
      return Future.value();
    }
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BhaktiPremiumScreen()),
    );
  }

  @override
  State<BhaktiPremiumScreen> createState() => _BhaktiPremiumScreenState();
}

class _BhaktiPremiumScreenState extends State<BhaktiPremiumScreen> {
  PremiumPlanType _selectedPlanType = PremiumPlanType.yearly;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final premiumService = context.watch<PremiumService>();
    final isPremium = premiumService.isPremium;
    final currentPlan = premiumService.currentPlan;

    return Scaffold(
      backgroundColor: const Color(0xFF140808), // Deep Sacred Maroon Black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: const SacredBackButton(
          color: AppColors.goldLight,
          backgroundColor: Color(0xFF2E1212),
          borderColor: Color(0x66C8A050),
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing
                ? null
                : () async {
                    setState(() => _isProcessing = true);
                    final restored = await premiumService.restorePurchases();
                    if (!mounted) return;
                    setState(() => _isProcessing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          restored ? '✅ Purchases successfully restored!' : 'ℹ️ No active purchases found.',
                        ),
                      ),
                    );
                  },
            child: const Text(
              'Restore',
              style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          children: [
            // Sacred Crown / Diya Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [AppColors.goldLight, Color(0xFFC8A050), Color(0xFF704010)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldPrimary.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 16),

            // Title & Subtitle
            const Text(
              'Bhakti Premium',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.goldLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pure Devotion • 100% Ad-Free • Unlimited Offline Stotras',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFD0C0A8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Active Premium Badge if already subscribed
            if (isPremium) ...[
              LiquidGlass(
                style: GlassStyle.card,
                tint: AppColors.goldPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.goldLight, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active VIP Membership',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            currentPlan?.title ?? 'Ad-Free Devotional Sanctum',
                            style: const TextStyle(fontSize: 12, color: AppColors.goldLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Feature Highlights
            _buildFeatureList(),
            const SizedBox(height: 28),

            // Pricing Tier Cards
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Your Sacred Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldLight,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ...PremiumService.availablePlans.map((plan) {
              final isSelected = _selectedPlanType == plan.type;
              return _buildPlanCard(plan, isSelected);
            }),

            const SizedBox(height: 24),

            // Action CTA Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        final chosenPlan = PremiumService.availablePlans.firstWhere(
                          (p) => p.type == _selectedPlanType,
                        );
                        setState(() => _isProcessing = true);
                        final success = await premiumService.purchasePlan(chosenPlan);
                        if (!mounted) return;
                        setState(() => _isProcessing = false);

                        if (success) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF2A1010),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: AppColors.goldLight),
                                  SizedBox(width: 8),
                                  Text(
                                    'Divya Anubhuti Unlocked!',
                                    style: TextStyle(color: AppColors.goldLight, fontSize: 18),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Thank you for supporting Bhakti. You now enjoy a 100% ad-free experience with full offline and temple features under the ${chosenPlan.title}.',
                                style: const TextStyle(color: Color(0xFFE0D0C0)),
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary),
                                  child: const Text('Enter Sanctuary', style: TextStyle(color: Colors.black)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: Colors.black,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_open_rounded, size: 20, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(
                            _getButtonText(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer note
            const Text(
              'Recurring billing for subscriptions. Cancel anytime in Google Play Store settings. Lifetime plan requires no renewal.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF887060), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    final chosen = PremiumService.availablePlans.firstWhere((p) => p.type == _selectedPlanType);
    if (chosen.type == PremiumPlanType.lifetime) {
      return 'Get Lifetime Ad-Free (${chosen.priceDisplay})';
    }
    return 'Start ${chosen.title} (${chosen.priceDisplay})';
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.block_flipped, 'title': '100% Ad-Free', 'desc': 'Zero banners and zero interruptions between songs'},
      {'icon': Icons.download_for_offline_rounded, 'title': 'Unlimited Offline Stotras', 'desc': 'Download full albums & high-def audio to listen anywhere'},
      {'icon': Icons.temple_hindu_rounded, 'title': 'All 3D Temple Sanctums', 'desc': 'Full access to Tirupati, Chamundi & Lakshmi Darshans'},
      {'icon': Icons.graphic_eq_rounded, 'title': 'Lossless HD Audio Streaming', 'desc': 'Crystal-clear 320kbps Vedic chants and bhajans'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33C8A050)),
      ),
      child: Column(
        children: features.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldPrimary.withOpacity(0.18),
                  ),
                  child: Icon(f['icon'] as IconData, color: AppColors.goldLight, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        f['desc'] as String,
                        style: const TextStyle(
                          color: Color(0xFFB0A090),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanCard(PremiumPlan plan, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanType = plan.type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x33C8A050) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.goldPrimary : const Color(0x22FFFFFF),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.goldPrimary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Radio Circle
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.goldLight : const Color(0xFF887060),
                  width: 2,
                ),
                color: isSelected ? AppColors.goldLight : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),

            // Plan Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        plan.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.goldLight : Colors.white,
                        ),
                      ),
                      if (plan.savingsBadge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: plan.isPopular
                                ? const Color(0xFFE5A820)
                                : const Color(0x33E5A820),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            plan.savingsBadge!,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: plan.isPopular ? Colors.black : AppColors.goldLight,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${plan.priceDisplay} ${plan.billingPeriod}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFC0B0A0)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Big Price Tag
            Text(
              plan.priceDisplay,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.goldLight : const Color(0xFFE0D0C0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

