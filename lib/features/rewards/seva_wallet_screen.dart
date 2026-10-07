import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/temple_theme.dart';
import '../../services/ads/ad_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../services/rewards/seva_token_service.dart';
import '../../widgets/sacred_back_button.dart';
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
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: const SacredBackButton(),
        title: const Text('Seva Karma & Rewards 🪙'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _showPointsRestoreSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_sync_rounded, color: Color(0xFFC77800), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'How Restore Works',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7A4A00),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.info_outline_rounded, color: Color(0xFFC77800), size: 13),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          // --- Hero Golden Seva Balance Card ---
          Container(
            width: double.infinity,
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
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                        Row(
                          children: [
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
                            Flexible(
                              child: Text(
                                'VIP Ad-Free Pass Active until ${sevaService.adFreeExpiryDate!.day}/${sevaService.adFreeExpiryDate!.month}/${sevaService.adFreeExpiryDate!.year}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
          ),

          // --- Cloud Reinstall Protection Banner ---
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _showPointsRestoreSheet(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Cloud Protected & Auto-Restore',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 14),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'If you uninstall or switch phones, points are credited back on reinstall. Tap to see how it works ›',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF33691E),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF2E7D32), size: 22),
                ],
              ),
            ),
          ),

          // --- Sacred Recovery Passkey Card (100% Anonymous Point Retention) ---
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2B258), width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.key_rounded, color: Color(0xFF8D5B00), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Your Sacred Devotee Passkey',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showPointsRestoreSheet(context),
                      child: const Text(
                        'Why save this? ⓘ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8D5B00),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          sevaService.devoteePasskey,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Color(0xFF7A4A00),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy Passkey',
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFFC77800), size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: sevaService.devoteePasskey));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✨ Sacred Passkey copied to clipboard! Save it to restore points anytime.'),
                              backgroundColor: Color(0xFF2E7D32),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No login or personal data needed. Save this passkey to restore 100% of your points if you reinstall or switch phones.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6D4C41),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8D5B00),
                          side: const BorderSide(color: Color(0xFFE2B258)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.copy_all_rounded, size: 15),
                        label: const Text('Copy Key', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: sevaService.devoteePasskey));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✨ Sacred Passkey copied to clipboard!'),
                              backgroundColor: Color(0xFF2E7D32),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D5B00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: const Text('Restore Points', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () => _showRestorePasskeyDialog(context, sevaService),
                      ),
                    ),
                  ],
                ),
              ],
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
            costTokens: 200,
            userTokens: sevaService.tokenBalance,
            onRedeem: () async {
              final ok = await sevaService.redeemAdFreePass(days: 1, costTokens: 200);
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
            costTokens: 500,
            userTokens: sevaService.tokenBalance,
            onRedeem: () async {
              final ok = await sevaService.redeemAdFreePass(days: 3, costTokens: 500);
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

          const SizedBox(height: 10),

          _buildPerkCard(
            context: context,
            icon: Icons.stars_rounded,
            iconBgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFF57F17),
            title: '7-Day Divine Moksha Pass',
            subtitle: 'One full week of sacred continuous chanting without any ads',
            costTokens: 1000,
            userTokens: sevaService.tokenBalance,
            onRedeem: () async {
              final ok = await sevaService.redeemAdFreePass(days: 7, costTokens: 1000);
              if (ok) {
                AdService.instance.setPremium(true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 7-Day Divine Moksha Pass activated! May your chanting be blissful.'),
                      backgroundColor: Color(0xFFF57F17),
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
            rewardText: '+15 Tokens',
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
            rewardText: '+5 Tokens',
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
            width: double.infinity,
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
                  width: double.infinity,
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8D5B00).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E1A11),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF736155),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2B258)),
                  ),
                  child: Text(
                    'Cost: $costTokens 🪙',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8D5B00),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: canAfford ? onRedeem : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D5B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: canAfford ? 1 : 0,
                  ),
                  child: Text(
                    canAfford ? 'Redeem Perk' : 'Need ${costTokens - userTokens} more',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: templeTheme.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: templeTheme.primaryColor.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: templeTheme.heroGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E1A11),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF736155),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Text(
                    'Earn: $rewardText 🪙',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC77800),
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: templeTheme.primaryColor,
                    side: BorderSide(color: templeTheme.primaryColor, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPointsRestoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFCF9F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7CCC8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFD54F)),
                      ),
                      child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFFC77800), size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How Points Restore Works',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Uninstall & Reinstall Data Protection Policy',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF795548),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF795548)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24, thickness: 1, color: Color(0xFFEFEBE9)),

              // Scrollable Content
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  children: [
                    // Cloud Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cloud Ledger Active: Every token earned or spent is backed up in real-time to Cloud Firestore.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B5E20),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 1: Sacred Passkey basis
                    _buildRestoreInfoCard(
                      icon: Icons.vpn_key_rounded,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1565C0),
                      title: '1. 100% Anonymous & Privacy-First',
                      description:
                          'We do not collect names, emails, or phone numbers. Instead, your points are tied to your unique Sacred Devotee Passkey (e.g. BHAKTI-4829-KRISHNA) stored safely in Cloud Firestore.',
                    ),

                    const SizedBox(height: 12),

                    // Card 2: If you uninstall
                    _buildRestoreInfoCard(
                      icon: Icons.delete_outline_rounded,
                      iconBg: const Color(0xFFFFEBEE),
                      iconColor: const Color(0xFFC62828),
                      title: '2. If You Uninstall the App',
                      description:
                          'Uninstalling only deletes local device cache. Your points balance, earned badges, and active VIP passes remain 100% intact in the cloud under your Sacred Passkey.',
                    ),

                    const SizedBox(height: 12),

                    // Card 3: When you reinstall
                    _buildRestoreInfoCard(
                      icon: Icons.restore_rounded,
                      iconBg: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFF57F17),
                      title: '3. When You Reinstall or Change Phones',
                      description:
                          'Simply open the Seva Wallet, tap "Restore Points", and enter your saved Sacred Passkey. The app verifies the ledger and immediately credits back 100% of your points.',
                    ),

                    const SizedBox(height: 12),

                    // Card 4: Multi-device & Device Switch
                    _buildRestoreInfoCard(
                      icon: Icons.devices_rounded,
                      iconBg: const Color(0xFFF3E5F5),
                      iconColor: const Color(0xFF7B1FA2),
                      title: '4. Multi-Device & Switching Devices',
                      description:
                          'You can use the same Sacred Passkey on your tablet, iPhone, Android, or Mac desktop to share and synchronize your Seva Karma and VIP privileges everywhere.',
                    ),

                    const SizedBox(height: 18),

                    // What is Restored List
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Guaranteed Cloud Restored Assets:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildRestoreCheckRow('🪙 Complete Seva Karma Token Balance'),
                          const SizedBox(height: 6),
                          _buildRestoreCheckRow('🕊️ Remaining Ad-Free VIP Pass Duration'),
                          const SizedBox(height: 6),
                          _buildRestoreCheckRow('🏅 All Unlocked Devotional Badges & Titles'),
                          const SizedBox(height: 6),
                          _buildRestoreCheckRow('📈 Total Lifetime Karma Punya Count'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Got it button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D5B00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Understood, Jai Shri Krishna 🙏',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestoreInfoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7F6).withOpacity(0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5D4037),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreCheckRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E1A11),
            ),
          ),
        ),
      ],
    );
  }

  void _showRestorePasskeyDialog(BuildContext context, SevaTokenService sevaService) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFCF9F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2B258), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: const Icon(Icons.key_rounded, color: Color(0xFFC77800), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Restore with Passkey',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E2723),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your saved Sacred Passkey to restore 100% of your Seva Karma points, badges, and VIP passes:',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF5D4037), height: 1.3),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: textController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF3E2723),
                    letterSpacing: 1.1,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. BHAKTI-4829-KRISHNA',
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: Colors.brown.withOpacity(0.4),
                      letterSpacing: 0.8,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2B258)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF8D5B00), width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Paste from clipboard',
                      icon: const Icon(Icons.paste_rounded, color: Color(0xFF8D5B00), size: 20),
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null && data!.text!.isNotEmpty) {
                          textController.text = data.text!.trim().toUpperCase();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '💡 Privacy Note: We do not store personal data. Passkeys are 100% anonymous & secure.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8D6E63)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF8D6E63), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D5B00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final inputKey = textController.text.trim().toUpperCase();
                if (inputKey.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid passkey'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Verifying Sacred Passkey...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );

                final success = await sevaService.restoreFromPasskey(inputKey);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  if (success) {
                    showDialog(
                      context: context,
                      builder: (sCtx) => AlertDialog(
                        backgroundColor: const Color(0xFFFCF9F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 26),
                            SizedBox(width: 10),
                            Text('Points Restored! ✨', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        content: Text(
                          'Your Sacred Wallet has been successfully restored with ${sevaService.tokenBalance} 🪙 Seva Karma tokens and active VIP perks.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF3E2723)),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.of(sCtx).pop(),
                            child: const Text('Jai Shri Krishna 🙏', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not find cloud record for Passkey: $inputKey. Please double-check the code.'),
                        backgroundColor: Colors.red.shade800,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              child: const Text('Restore Karma', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}


