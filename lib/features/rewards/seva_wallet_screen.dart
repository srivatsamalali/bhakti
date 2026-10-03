import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/temple_theme.dart';
import '../../services/ads/ad_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../services/rewards/seva_token_service.dart';
import '../../widgets/sacred_filigree_border.dart';
import '../requests/song_request_dialog.dart';
import '../admin/admin_add_edit_song_screen.dart';

class SevaWalletScreen extends StatelessWidget {
  const SevaWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final templeTheme = TempleTheme.fromId(prefs.getTempleThemeId());
    final sevaService = context.watch<SevaTokenService>();

    return Scaffold(
      backgroundColor: templeTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Seva Karma & Rewards 🪙'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Hero Golden Seva Balance Card ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8E7), Color(0xFFFDE8BA), Color(0xFFF5D07A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2B258), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE2B258).withOpacity(0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SacredCornerFiligree(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF8D5B00),
                cornerSize: 22,
                strokeWidth: 1.4,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF633800),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.goldLight, size: 13),
                              SizedBox(width: 4),
                              Text(
                                'SEVA KARMA BALANCE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2B258)),
                          ),
                          child: Text(
                            sevaService.currentBadge.title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF633800),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 36)),
                        const SizedBox(width: 10),
                        Text(
                          '${sevaService.tokenBalance}',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF422400),
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Text(
                            'Tokens',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF734200),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Total Karma Punya Earned: ${sevaService.totalTokensEarned} 🪙',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B4512),
                      ),
                    ),

                    if (sevaService.hasActiveAdFreePass) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: Colors.white, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              'VIP Ad-Free Pass Active until ${sevaService.adFreeExpiryDate!.day}/${sevaService.adFreeExpiryDate!.month}/${sevaService.adFreeExpiryDate!.year}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // --- Section: Redeem Perks ---
            Text(
              'Redeem Sacred Perks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: templeTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),

            _buildPerkCard(
              context: context,
              icon: Icons.music_off_rounded,
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              title: '1-Day Ad-Free Sacred Listening',
              subtitle: 'Enjoy complete peaceful, uninterrupted chanting and bhajans',
              costTokens: 100,
              userTokens: sevaService.tokenBalance,
              onRedeem: () async {
                final ok = await sevaService.redeemAdFreePass(days: 1, costTokens: 100);
                if (ok) {
                  AdService.instance.setPremium(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 1-Day Ad-Free Pass activated! Enjoy peaceful chanting.'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 10),

            _buildPerkCard(
              context: context,
              icon: Icons.diamond_rounded,
              iconBgColor: const Color(0xFFEDE7F6),
              iconColor: const Color(0xFF512DA8),
              title: '3-Day Ad-Free VIP Devotee Pass',
              subtitle: 'Extended divine playback without interruptions',
              costTokens: 250,
              userTokens: sevaService.tokenBalance,
              onRedeem: () async {
                final ok = await sevaService.redeemAdFreePass(days: 3, costTokens: 250);
                if (ok) {
                  AdService.instance.setPremium(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 3-Day Ad-Free VIP Pass activated! Enjoy peaceful chanting.'),
                        backgroundColor: Color(0xFF512DA8),
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 22),

            // --- Section: Ways to Earn Seva Tokens ---
            Text(
              'Ways to Earn Seva Karma Tokens',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: templeTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),

            _buildEarnActionCard(
              context: context,
              icon: Icons.cloud_upload_rounded,
              title: 'Upload / Contribute a Devotional Song',
              description: 'Share authentic stotrams, keerthanas, or bhajans with devotees worldwide',
              rewardText: '+50 Tokens',
              actionLabel: 'Upload Song',
              templeTheme: templeTheme,
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminAddEditSongScreen()),
                );
              },
            ),

            const SizedBox(height: 10),

            _buildEarnActionCard(
              context: context,
              icon: Icons.queue_music_rounded,
              title: 'Request a Devotional Song',
              description: 'Help us expand the community catalog by requesting missing devotional hymns',
              rewardText: '+20 Tokens',
              actionLabel: 'Request Song',
              templeTheme: templeTheme,
              onAction: () {
                SongRequestDialog.show(context);
              },
            ),

            const SizedBox(height: 22),

            // --- Section: Devotee Badges ---
            Text(
              'Sacred Seva Badges',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: templeTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: templeTheme.borderColor),
              ),
              child: Column(
                children: SevaBadge.values.map((badge) {
                  final isUnlocked = sevaService.totalTokensEarned >= badge.minTokensEarned;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(badge.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                badge.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? const Color(0xFF2E1A11) : Colors.grey,
                                ),
                              ),
                              Text(
                                badge.description,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isUnlocked ? const Color(0xFF6B584C) : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isUnlocked ? const Color(0xFFE8F5E9) : const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isUnlocked ? 'Unlocked ✅' : '${badge.minTokensEarned} 🪙',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? const Color(0xFF2E7D32) : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 22),

            // --- Section: Karma Transaction History ---
            Text(
              'Recent Seva Karma History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: templeTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),

            if (sevaService.history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No transactions yet. Start contributing today!'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sevaService.history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final tx = sevaService.history[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: templeTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tx.isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFBE9E7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            tx.isCredit ? Icons.add_rounded : Icons.remove_rounded,
                            color: tx.isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C1E18),
                                ),
                              ),
                              Text(
                                tx.description,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF75655B)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${tx.isCredit ? '+' : '-'}${tx.amount} 🪙',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: tx.isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int costTokens,
    required int userTokens,
    required VoidCallback onRedeem,
  }) {
    final canAfford = userTokens >= costTokens;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECD7B8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E1A11),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF736155)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: canAfford ? onRedeem : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8D5B00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              '$costTokens 🪙',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String rewardText,
    required String actionLabel,
    required TempleTheme templeTheme,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: templeTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: templeTheme.heroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E1A11),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFD54F)),
                      ),
                      child: Text(
                        rewardText,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC77800),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF736155)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: templeTheme.primaryColor,
              side: BorderSide(color: templeTheme.primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
