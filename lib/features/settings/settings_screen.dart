import 'package:flutter/material.dart';
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

import 'package:package_info_plus/package_info_plus.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section: Preferences
          _buildSectionHeader('Preferences & Experience'),
          Card(
            child: Column(
              children: [
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

          // Section: Storage & Cache
          _buildSectionHeader('Storage & History'),

          Card(
            child: Column(
              children: [
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

  Widget _buildSectionHeader(String title) {
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
