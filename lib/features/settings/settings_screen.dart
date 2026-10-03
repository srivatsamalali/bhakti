import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/language_model.dart';
import '../../services/ai/bhakti_ai_service.dart';
import '../../services/cache/cache_service.dart';
import '../../services/firebase/auth_service.dart';
import '../../services/preferences/preferences_service.dart';

import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_login_screen.dart';
import '../language/language_selection_screen.dart';
import '../player/sleep_timer_dialog.dart';
import '../../services/audio/offline_download_service.dart';
import '../../services/notifications/devotional_reminder_service.dart';

import '../../core/theme/temple_theme.dart';
import '../wallpaper/sacred_wallpaper_generator_dialog.dart';
import '../widgets/devotional_widgets_sheet.dart';
import 'widgets/smart_notification_sheet.dart';
import 'widgets/temple_theme_selector_sheet.dart';
import '../premium/bhakti_premium_screen.dart';
import '../../services/premium/premium_service.dart';
import '../rewards/seva_wallet_screen.dart';
import '../../services/rewards/seva_token_service.dart';
import '../requests/song_request_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _cacheSize = '...';
  String _versionStr = AppConstants.appVersion;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _versionStr = info.version;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCacheSize() async {
    final size = await CacheService.instance.getApproximateCacheSize();
    if (mounted) {
      setState(() {
        _cacheSize = size;
      });
    }
  }

  Future<void> _launchUrlString(String urlStr) async {
    final Uri url = Uri.parse(urlStr);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $urlStr')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _launchDeveloperProfile() async {
    await _launchUrlString('https://srivatsamalali.github.io/My-profile/');
  }

  Widget _buildDeveloperContactCard() {
    return const _CreativeDeveloperContactCard();
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          context.tr('clearCache'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroonPrimary),
        ),
        content: Text(context.tr('clearCacheConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CacheService.instance.clearAllCache();
              await _loadCacheSize();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('cacheCleared'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.maroonPrimary,
              minimumSize: const Size(100, 42),
            ),
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );
  }

  void _showClearRecentsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          context.tr('clearRecents'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroonPrimary),
        ),
        content: const Text('Are you sure you want to clear your recently played songs history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<PreferencesService>().clearRecentlyPlayed();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('recentsCleared'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.maroonPrimary,
              minimumSize: const Size(100, 42),
            ),
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'images/logo.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => Image.asset('assets/images/logo.png', width: 32, height: 32),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Bhakti',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroonPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appTagline,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.saffronPrimary),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bhakti is dedicated to delivering peaceful, high-quality, authentic devotional music, stotras, and sahasranamam to spiritual seekers everywhere.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Created with Devotion by:',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8D6E63), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Srivatsa Malali',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.maroonPrimary),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _launchDeveloperProfile,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.saffronPrimary),
                        SizedBox(width: 4),
                        Text(
                          'View Portfolio & Profile',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.saffronPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Version: $_versionStr',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final auth = context.watch<AuthService>();
    final currentLang = LanguageModel.fromCode(prefs.getSelectedLanguage());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('settingsTitle')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
        children: [
          // VIP Gold Bhakti Premium Card
          if (PremiumService.isFeatureEnabled)
            Consumer<PremiumService>(
              builder: (context, premium, _) {
                final isPremium = premium.isPremium;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E1212), Color(0xFF1B0A0A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x66C8A050), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldPrimary.withOpacity(0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => BhaktiPremiumScreen.show(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [AppColors.goldLight, AppColors.goldPrimary, Color(0xFF805010)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.goldPrimary.withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPremium ? Icons.verified_rounded : Icons.diamond_rounded,
                              color: Colors.black87,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isPremium ? 'Bhakti VIP Member' : 'Bhakti Premium',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.goldLight,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPremium ? const Color(0xFF208030) : const Color(0xFFC8A050),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isPremium ? 'ACTIVE' : 'AD-FREE',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isPremium
                                      ? 'Unlimited Offline Downloads • Zero Ads'
                                      : 'Ad-Free Lifetime from ₹499 • Monthly ₹29',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFC0B0A0)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.goldLight),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Seva Karma & Rewards Card
          Consumer<SevaTokenService>(
            builder: (context, seva, _) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF9E6), Color(0xFFFDE8B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2B258), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE2B258).withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SevaWalletScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF633800),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF633800).withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Text('🪙', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Seva Karma Wallet',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF422400),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8D5B00),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${seva.tokenBalance} TOKENS',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Badge: ${seva.currentBadge.title} • Redeem Ad-Free passes',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF734500)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF8D5B00)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Section: Preferences
          _buildSectionHeader('Preferences & Experience'),
          Card(
            child: Column(
              children: [
                // 1. Request a Song (Earn Tokens)
                ListTile(
                  leading: const Icon(Icons.queue_music_rounded, color: AppColors.maroonPrimary),
                  title: const Text('Request a Devotional Song', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Earn +20 Seva Tokens for your request'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD54F)),
                    ),
                    child: const Text(
                      '+20 🪙',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8D5B00)),
                    ),
                  ),
                  onTap: () {
                    SongRequestDialog.show(context);
                  },
                ),
                const Divider(height: 1),

                // 2. Temple Theme Selector
                ListTile(
                  leading: const Icon(Icons.palette_rounded, color: AppColors.maroonPrimary),
                  title: const Text('Sacred Temple Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${TempleTheme.fromId(prefs.getTempleThemeId()).emoji} ${TempleTheme.fromId(prefs.getTempleThemeId()).name}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    TempleThemeSelectorSheet.show(context);
                  },
                ),
                const Divider(height: 1),

                // 2. Lock & Home Screen Widgets
                ListTile(
                  leading: const Icon(Icons.widgets_outlined, color: AppColors.maroonPrimary),
                  title: const Text('Lock & Home Screen Widgets', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Live Tithi, Shlokas & Mini Player on phone screen'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    DevotionalWidgetsSheet.show(context);
                  },
                ),
                const Divider(height: 1),

                // 3. 1-Tap Sacred Story & Wallpaper Creator
                ListTile(
                  leading: const Icon(Icons.auto_awesome_mosaic_outlined, color: AppColors.maroonPrimary),
                  title: const Text('Sacred Story & 4K Wallpaper Creator', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Generate devotional posters for Status & Stories'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    SacredWallpaperGeneratorDialog.show(context);
                  },
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.maroonPrimary),
                  title: Text(context.tr('languageSetting')),
                  subtitle: Text('${currentLang.nativeName} (${currentLang.englishName})'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                    );
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bedtime_outlined, color: AppColors.maroonPrimary),
                  title: Text(context.tr('sleepTimer')),
                  subtitle: const Text('Set auto turn-off duration'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SleepTimerDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
          // Section: Daily Prayer & Sacred Reminders
          _buildSectionHeader('Daily Prayer & Sacred Reminders'),
          Consumer<DevotionalReminderService>(
            builder: (context, reminders, _) {
              return Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.wb_sunny_outlined, color: AppColors.saffronPrimary),
                      title: const Text('Morning Brahma Muhurta', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Dawn prayer & Suprabhatam (${reminders.morningTime})'),
                      value: reminders.morningEnabled,
                      activeColor: AppColors.maroonPrimary,
                      onChanged: (val) async {
                        await reminders.requestNotificationPermissions();
                        await reminders.toggleMorning(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.auto_stories_outlined, color: AppColors.goldDark),
                      title: const Text('Mid-Day Sacred Wisdom (01:00 PM)', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Vachana & Gita shloka with meaning'),
                      value: reminders.midDayWisdomEnabled,
                      activeColor: AppColors.maroonPrimary,
                      onChanged: (val) async {
                        await reminders.requestNotificationPermissions();
                        await reminders.toggleMidDayWisdom(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.wb_twilight_rounded, color: AppColors.maroonPrimary),
                      title: const Text('Evening Sandhya Deepam', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Sunset diya lighting & chanting (${reminders.eveningTime})'),
                      value: reminders.eveningEnabled,
                      activeColor: AppColors.maroonPrimary,
                      onChanged: (val) async {
                        await reminders.requestNotificationPermissions();
                        await reminders.toggleEvening(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.saffronPrimary),
                      title: const Text('Ekadashi & Festival Alerts', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Notifies upcoming auspicious tithis & vratas'),
                      value: reminders.festivalAlerts,
                      activeColor: AppColors.maroonPrimary,
                      onChanged: (val) async {
                        await reminders.requestNotificationPermissions();
                        await reminders.toggleFestivalAlerts(val);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.tune_rounded, color: AppColors.goldDark),
                      title: const Text('Smart Alert Schedule & Preview', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('View scheduled alerts & send test notification'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => SmartNotificationSheet.show(context),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Section: Bhakti AI Assistant
          _buildSectionHeader('Bhakti AI Assistant'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome, color: AppColors.maroonPrimary),
                  title: const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Voice & text devotional companion'),
                  value: prefs.isAiAssistantEnabled(),
                  activeColor: AppColors.maroonPrimary,
                  onChanged: (val) => prefs.setAiAssistantEnabled(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.mic, color: AppColors.maroonPrimary),
                  title: const Text('Voice Input', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Speak requests in Kannada, Hindi, Tamil, etc.'),
                  value: prefs.isAiVoiceInputEnabled(),
                  activeColor: AppColors.maroonPrimary,
                  onChanged: prefs.isAiAssistantEnabled() ? (val) => prefs.setAiVoiceInputEnabled(val) : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined, color: AppColors.maroonPrimary),
                  title: const Text('AI Voice Responses (TTS)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Hear AI responses spoken aloud'),
                  value: prefs.isAiVoiceOutputEnabled(),
                  activeColor: AppColors.maroonPrimary,
                  onChanged: prefs.isAiAssistantEnabled() ? (val) => prefs.setAiVoiceOutputEnabled(val) : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.maroonPrimary),
                  title: const Text('Clear AI Conversation', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Wipes in-memory chat session history'),
                  trailing: const Icon(Icons.cleaning_services, size: 18, color: AppColors.textMuted),
                  onTap: () {
                    context.read<BhaktiAiService>().clearConversation();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bhakti AI conversation cleared.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section: Storage & Offline Chants
          _buildSectionHeader('Storage & Offline Chants'),
          Consumer<OfflineDownloadService>(
            builder: (context, downloadService, _) {
              final downloadedCount = downloadService.downloadedSongs.length;
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download_done_rounded, color: AppColors.maroonPrimary),
                      title: const Text('Downloaded Stotras (Offline)', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('$downloadedCount stotras available for offline chanting'),
                      trailing: downloadedCount > 0
                          ? TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.creamCard,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    title: const Text('Downloaded Stotras', style: TextStyle(color: AppColors.maroonPrimary, fontWeight: FontWeight.bold)),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: downloadService.downloadedSongs.values.map((song) {
                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            subtitle: Text(song.deity, style: const TextStyle(fontSize: 11)),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                              onPressed: () {
                                                downloadService.deleteDownloadedSong(song.id);
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Manage', style: TextStyle(color: AppColors.maroonPrimary, fontWeight: FontWeight.bold)),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 14),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.maroonPrimary),
                      title: Text(context.tr('clearCache')),
                      subtitle: Text('${context.tr('cacheSize')}: $_cacheSize'),
                      trailing: const Icon(Icons.delete_outline, color: AppColors.error),
                      onTap: _showClearCacheDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.history, color: AppColors.maroonPrimary),
                      title: Text(context.tr('clearRecents')),
                      trailing: const Icon(Icons.delete_outline, color: AppColors.error),
                      onTap: _showClearRecentsDialog,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Section: App Info & Support
          _buildSectionHeader('About & Support'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.maroonPrimary),
                  title: Text(context.tr('aboutBhakti')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showAboutDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.maroonPrimary),
                  title: Text(context.tr('privacyPolicy')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showLegalDialog('Privacy Policy', 'Bhakti app respects your spiritual journey and privacy. No registration or personal data is collected from end users. All favorites and settings are saved solely on your local device.');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.maroonPrimary),
                  title: Text(context.tr('termsOfService')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showLegalDialog('Terms of Service', 'All devotional audio, sacred stotras, and artwork published on Bhakti are intended for personal worship and devotional practice.');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section: Developer & Creator Contact Card
          _buildSectionHeader('Developer & Creator'),
          _buildDeveloperContactCard(),
          const SizedBox(height: 16),

          // Section: Administrator Portal
          _buildSectionHeader('Administrator'),
          Card(
            color: AppColors.creamSurface,
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: AppColors.saffronPrimary, size: 28),
              title: Text(
                context.tr('adminPortal'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroonPrimary),
              ),
              subtitle: Text(
                auth.isAdminAuthenticated
                    ? 'Logged in as ${auth.adminUsername}'
                    : 'Manage songs, categories & media',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                if (auth.isAdminAuthenticated) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Version & Tagline footer
          Center(
            child: Column(
              children: [
                Text(
                  '${AppConstants.appName} v$_versionStr',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appUniversalPrayer,
                  style: const TextStyle(color: AppColors.goldDark, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDeveloperSectionHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Row(
        children: [
          const Text(
            'DEVELOPER & CREATOR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF7B1E28),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7B1E28).withOpacity(0.5),
                    const Color(0xFF7B1E28).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    if (title == 'Developer & Creator') {
      return _buildDeveloperSectionHeader();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.maroonPrimary,
        ),
      ),
    );
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(color: AppColors.maroonPrimary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(content, style: const TextStyle(height: 1.5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}

/// Creative & Interactive Developer Contact Card matching exact photo design
class _CreativeDeveloperContactCard extends StatefulWidget {
  const _CreativeDeveloperContactCard();

  @override
  State<_CreativeDeveloperContactCard> createState() => _CreativeDeveloperContactCardState();
}

class _CreativeDeveloperContactCardState extends State<_CreativeDeveloperContactCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  late final AnimationController _avatarBounceController;
  late final Animation<double> _avatarBounceAnimation;

  int _speechIndex = 0;
  static const List<String> _speechMessages = [
    "Let's\nBuild\nTogether! 🚀",
    "Namaskara! 🙏\nWelcome to Bhakti!",
    "5.5+ Yrs SDET\n& Architect 💻",
    "Let's connect\non LinkedIn! 💼",
    "Crafted with\nDevotion ✨",
    "Code • Devotion\n• Excellence 🕉️",
  ];

  String? _tappedSkill;

  @override
  void initState() {
    super.initState();
    // Gentle aura pulse for clouds and glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.90, end: 1.10).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Idle floating animation for 3D character
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // Bounce/reaction animation on character tap
    _avatarBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _avatarBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.18, end: 0.92).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.92, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 30),
    ]).animate(_avatarBounceController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _avatarBounceController.dispose();
    super.dispose();
  }

  void _onAvatarTapped() {
    HapticFeedback.mediumImpact();
    _avatarBounceController.forward(from: 0.0);
    setState(() {
      _speechIndex = (_speechIndex + 1) % _speechMessages.length;
    });
  }

  Future<void> _launchUrl(String urlStr) async {
    final Uri url = Uri.parse(urlStr);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $urlStr')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  static const List<Map<String, dynamic>> _skills = [
    {
      'emoji': '☕',
      'name': 'Java / SDET',
      'bg': Color(0xFFFFF0F2),
      'border': Color(0xFFFFCDD2),
      'text': Color(0xFFC62828),
    },
    {
      'emoji': '🥒',
      'name': 'Cucumber BDD',
      'bg': Color(0xFFE8F8F0),
      'border': Color(0xFFC8E6C9),
      'text': Color(0xFF2E7D32),
    },
    {
      'emoji': '⚡',
      'name': 'Rest Assured',
      'bg': Color(0xFFFFF9E6),
      'border': Color(0xFFFFE082),
      'text': Color(0xFFE65100),
    },
    {
      'emoji': '🔥',
      'name': 'Firebase Cloud',
      'bg': Color(0xFFFFF3E0),
      'border': Color(0xFFFFCC80),
      'text': Color(0xFFEF6C00),
    },
    {
      'emoji': '⚙️',
      'name': 'CI/CD Pipelines',
      'bg': Color(0xFFE3F2FD),
      'border': Color(0xFFBBDEFB),
      'text': Color(0xFF1565C0),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF3E5D4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1E28).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFFE1BEE7).withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Creative Border Clouds & Aura Painter
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _floatAnimation]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CreativeCloudBorderPainter(
                      pulseValue: _pulseAnimation.value,
                      floatValue: _floatAnimation.value,
                    ),
                  );
                },
              ),
            ),

            // 2. Subtle sacred Om watermark in background
            Positioned(
              right: -10,
              bottom: -20,
              child: Opacity(
                opacity: 0.035,
                child: const Text(
                  'ॐ',
                  style: TextStyle(
                    fontSize: 150,
                    fontWeight: FontWeight.bold,
                    color: AppColors.maroonPrimary,
                  ),
                ),
              ),
            ),

            // 3. Main Foreground Content (Header with Avatar, Bio, Skill Badges, Radiant Buttons)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TOP IDENTITY ROW: Om Badge + Info + 3D Avatar with Speech Bubble ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Om Emblem Badge with Crown
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B1E28), Color(0xFF4A0E15)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.goldPrimary, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.goldLight.withOpacity(0.35 * _pulseAnimation.value),
                                      blurRadius: 12 * _pulseAnimation.value,
                                      spreadRadius: 1.2 * _pulseAnimation.value,
                                    ),
                                    BoxShadow(
                                      color: AppColors.maroonPrimary.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'ॐ',
                                    style: TextStyle(
                                      fontSize: 26,
                                      color: AppColors.goldLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Crown Corner Badge
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(3.5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Text('👑', style: TextStyle(fontSize: 10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),

                      // Name, Creator pill, Role, Location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 5,
                              runSpacing: 2,
                              children: [
                                const Text(
                                  'Srivatsa Malali',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3E1318),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFE082), Color(0xFFFFB74D)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE65100).withOpacity(0.25),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('🏆 ', style: TextStyle(fontSize: 7)),
                                      Text(
                                        'CREATOR',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF8D2B00),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Row(
                              children: [
                                Text('🚀 ', style: TextStyle(fontSize: 10)),
                                Expanded(
                                  child: Text(
                                    'Lead Full-Stack Architect & Senior SDET',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5D4037),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              children: [
                                Text('📍 ', style: TextStyle(fontSize: 10)),
                                Flexible(
                                  child: Text(
                                    'Bengaluru, Karnataka, India 🇮🇳',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF8D6E63),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // 3D Character Avatar with Interactive Speech Bubble
                      GestureDetector(
                        onTap: _onAvatarTapped,
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_floatAnimation, _avatarBounceAnimation]),
                          builder: (context, _) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: Transform.scale(
                                scale: _avatarBounceAnimation.value,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Pointed Speech Bubble
                                    CustomPaint(
                                      painter: _SpeechBubblePainter(
                                        color: Colors.white,
                                        borderColor: const Color(0xFFD7CCC8),
                                        shadowColor: const Color(0xFF7E57C2).withOpacity(0.25),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 7),
                                        constraints: const BoxConstraints(maxWidth: 82),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 220),
                                          child: Text(
                                            _speechMessages[_speechIndex],
                                            key: ValueKey<int>(_speechIndex),
                                            style: const TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF311B92),
                                              height: 1.15,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 2),

                                    // 3D Avatar Image
                                    SizedBox(
                                      width: 58,
                                      height: 58,
                                      child: Image.asset(
                                        'assets/images/developer_avatar.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 58,
                                          height: 58,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFFFF3E0),
                                          ),
                                          child: const Center(
                                            child: Text('👨‍💻', style: TextStyle(fontSize: 28)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // Tight Snug Spacing below Header (NO divider or huge empty space!)
                  const SizedBox(height: 10),

                  // Engineering Overview Bio Paragraph (Directly below header, ZERO overlap!)
                  const Text(
                    '5.5+ years architecting enterprise automated testing frameworks & scalable software systems across Wipro, TCS, and Hexaware for global leaders like Apple, Citi Bank, and Air Canada. Designed and built the complete Bhakti ecosystem.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.44,
                      color: Color(0xFF4E342E),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Colorful Pastel Skill Chips - Row 1 (3 equal chips)
                  Row(
                    children: [
                      Expanded(child: _buildSkillChip(_skills[0])),
                      const SizedBox(width: 6),
                      Expanded(child: _buildSkillChip(_skills[1])),
                      const SizedBox(width: 6),
                      Expanded(child: _buildSkillChip(_skills[2])),
                    ],
                  ),

                  const SizedBox(height: 7),

                  // Colorful Pastel Skill Chips - Row 2 (2 equal chips)
                  Row(
                    children: [
                      Expanded(child: _buildSkillChip(_skills[3])),
                      const SizedBox(width: 6),
                      Expanded(child: _buildSkillChip(_skills[4])),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Symmetrical Equal-Sized Glowing Action Buttons
                  Row(
                    children: [
                      // 1. Portfolio Button (Equal 50% width)
                      Expanded(
                        child: _InteractiveContactButton(
                          label: 'Portfolio',
                          leadingWidget: const Icon(Icons.language_rounded, color: Colors.white, size: 17),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B1E28), Color(0xFF5E101A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: const Color(0xFFFFB300).withOpacity(0.7),
                          textColor: Colors.white,
                          shadowColor: const Color(0xFFD32F2F).withOpacity(0.45),
                          onTap: () {
                            _launchUrl('https://srivatsamalali.github.io/My-profile/');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 2. LinkedIn Button (Equal 50% width)
                      Expanded(
                        child: _InteractiveContactButton(
                          label: 'LinkedIn',
                          leadingWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'in',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0077B5),
                              ),
                            ),
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0077B5), Color(0xFF005282)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: const Color(0xFF64B5F6).withOpacity(0.8),
                          textColor: Colors.white,
                          shadowColor: const Color(0xFF0077B5).withOpacity(0.45),
                          onTap: () {
                            _launchUrl('https://www.linkedin.com/in/srivatsamalali');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(Map<String, dynamic> skill) {
    final isSelected = _tappedSkill == skill['name'];
    final Color bgColor = skill['bg'] as Color;
    final Color borderColor = skill['border'] as Color;
    final Color textColor = skill['text'] as Color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _tappedSkill = skill['name'] as String;
        });
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && _tappedSkill == skill['name']) {
            setState(() => _tappedSkill = null);
          }
        });
      },
      child: AnimatedScale(
        scale: isSelected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5.5),
          decoration: BoxDecoration(
            color: isSelected ? bgColor.withOpacity(0.9) : bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? textColor : borderColor,
              width: isSelected ? 1.5 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.4),
                blurRadius: isSelected ? 6 : 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(skill['emoji'] as String, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  skill['name'] as String,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Creative border painter that draws soft pastel cloud puffs and dreamy aura along borders
class _CreativeCloudBorderPainter extends CustomPainter {
  final double pulseValue;
  final double floatValue;

  _CreativeCloudBorderPainter({
    required this.pulseValue,
    required this.floatValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // --- 1. TOP-RIGHT CLUSTER (Behind avatar and speech bubble) ---
    // Soft Lavender & Violet Glow
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFE1BEE7).withOpacity(0.55),
        const Color(0xFFD1C4E9).withOpacity(0.30),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width - 45, 45 + floatValue * 0.5),
      radius: 70 * pulseValue,
    ));
    canvas.drawCircle(Offset(size.width - 45, 45 + floatValue * 0.5), 70 * pulseValue, paint);

    // Soft Powder Blue Cloud Puff on top border
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFB3E5FC).withOpacity(0.50),
        const Color(0xFFE1F5FE).withOpacity(0.20),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width - 95, 18 - floatValue * 0.4),
      radius: 46 * pulseValue,
    ));
    canvas.drawCircle(Offset(size.width - 95, 18 - floatValue * 0.4), 46 * pulseValue, paint);

    // Soft Rose Pink Puff on top-right edge
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFD1DC).withOpacity(0.50),
        const Color(0xFFFFF0F5).withOpacity(0.15),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width - 15, 80 + floatValue * 0.3),
      radius: 42 * pulseValue,
    ));
    canvas.drawCircle(Offset(size.width - 15, 80 + floatValue * 0.3), 42 * pulseValue, paint);

    // Fluffy cloud puffs along top-right perimeter
    _drawCloudCircle(canvas, Offset(size.width - 76, 6), 18, const Color(0xFFFFFFFF).withOpacity(0.70));
    _drawCloudCircle(canvas, Offset(size.width - 54, 4), 22, const Color(0xFFFFFFFF).withOpacity(0.80));
    _drawCloudCircle(canvas, Offset(size.width - 28, 10), 20, const Color(0xFFFFFFFF).withOpacity(0.75));
    _drawCloudCircle(canvas, Offset(size.width - 6, 28), 22, const Color(0xFFFFFFFF).withOpacity(0.65));
    _drawCloudCircle(canvas, Offset(size.width - 4, 56), 18, const Color(0xFFFFFFFF).withOpacity(0.55));
    _drawCloudCircle(canvas, Offset(size.width - 8, 82), 16, const Color(0xFFFFFFFF).withOpacity(0.45));

    // --- 2. TOP-LEFT CLOUD PUFFS (Around Om Badge) ---
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFE0B2).withOpacity(0.35),
        const Color(0xFFFFF8E1).withOpacity(0.10),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: const Offset(20, 20),
      radius: 48 * pulseValue,
    ));
    canvas.drawCircle(const Offset(20, 20), 48 * pulseValue, paint);
    _drawCloudCircle(canvas, const Offset(10, 8), 15, const Color(0xFFFFFFFF).withOpacity(0.45));
    _drawCloudCircle(canvas, const Offset(28, 4), 17, const Color(0xFFFFFFFF).withOpacity(0.50));

    // --- 3. BOTTOM-LEFT CLOUD PUFFS ---
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFCCBC).withOpacity(0.35),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(20, size.height - 15),
      radius: 38,
    ));
    canvas.drawCircle(Offset(20, size.height - 15), 38, paint);
    _drawCloudCircle(canvas, Offset(8, size.height - 10), 15, const Color(0xFFFFFFFF).withOpacity(0.45));
    _drawCloudCircle(canvas, Offset(26, size.height - 6), 17, const Color(0xFFFFFFFF).withOpacity(0.50));

    // --- 4. BOTTOM-RIGHT CLOUD PUFFS ---
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFE1BEE7).withOpacity(0.35),
        const Color(0xFFB3E5FC).withOpacity(0.20),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width - 25, size.height - 15),
      radius: 44 * pulseValue,
    ));
    canvas.drawCircle(Offset(size.width - 25, size.height - 15), 44 * pulseValue, paint);
    _drawCloudCircle(canvas, Offset(size.width - 12, size.height - 8), 16, const Color(0xFFFFFFFF).withOpacity(0.50));
    _drawCloudCircle(canvas, Offset(size.width - 32, size.height - 6), 15, const Color(0xFFFFFFFF).withOpacity(0.45));
  }

  void _drawCloudCircle(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CreativeCloudBorderPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue || oldDelegate.floatValue != floatValue;
}

/// Custom painter for Speech Bubble with downward pointing tail towards character
class _SpeechBubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final Color shadowColor;

  _SpeechBubblePainter({
    required this.color,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double borderWidth = 1.1;
    const double r = 11.0;
    const double tailW = 8.0;
    const double tailH = 5.0;
    final double tailX = size.width * 0.50; // pointing straight down to avatar

    final path = Path();
    path.moveTo(r, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, size.height - tailH - r);
    path.quadraticBezierTo(size.width, size.height - tailH, size.width - r, size.height - tailH);

    // Tail
    path.lineTo(tailX + tailW / 2, size.height - tailH);
    path.lineTo(tailX, size.height);
    path.lineTo(tailX - tailW / 2, size.height - tailH);

    path.lineTo(r, size.height - tailH);
    path.quadraticBezierTo(0, size.height - tailH, 0, size.height - tailH - r);
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();

    // Soft Purple Shadow
    canvas.drawShadow(path, shadowColor, 5, false);

    // Fill
    final paintFill = Paint()..color = color;
    canvas.drawPath(path, paintFill);

    // Border
    final paintBorder = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, paintBorder);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}

/// Symmetrical, animated bounce button with micro-haptics and outward arrow
class _InteractiveContactButton extends StatefulWidget {
  final String label;
  final Widget leadingWidget;
  final Gradient gradient;
  final Color borderColor;
  final Color textColor;
  final Color shadowColor;
  final VoidCallback onTap;

  const _InteractiveContactButton({
    required this.label,
    required this.leadingWidget,
    required this.gradient,
    required this.borderColor,
    required this.textColor,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_InteractiveContactButton> createState() => _InteractiveContactButtonState();
}

class _InteractiveContactButtonState extends State<_InteractiveContactButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderColor, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                blurRadius: _isPressed ? 3 : 10,
                spreadRadius: 1,
                offset: _isPressed ? const Offset(0, 1) : const Offset(0, 3.5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.leadingWidget,
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.arrow_outward_rounded,
                size: 15,
                color: widget.textColor.withOpacity(0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


