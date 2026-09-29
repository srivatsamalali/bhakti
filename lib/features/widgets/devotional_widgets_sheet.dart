import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/temple_theme.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/panchanga/panchanga_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/moon_phase_dial.dart';

enum WidgetType {
  panchanga('Panchanga & Moon', 'Live Tithi, Nakshatra, Rahu Kalam & Moon Phase', Icons.nights_stay_rounded),
  shloka('Daily Shloka', 'Daily Sanskrit mantra & spiritual blessings', Icons.auto_awesome_rounded),
  player('Mini Player', 'Currently chanting stotra with live controls', Icons.music_note_rounded),
  lockScreen('Lock Screen Pill', 'Always-On Display & Live Activity glance bar', Icons.screen_lock_portrait_rounded);

  final String title;
  final String description;
  final IconData icon;
  const WidgetType(this.title, this.description, this.icon);
}

enum WidgetSize {
  small('Small (2x2)'),
  medium('Medium (4x2)'),
  large('Large (4x4)');

  final String label;
  const WidgetSize(this.label);
}

class DevotionalWidgetsSheet extends StatefulWidget {
  const DevotionalWidgetsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DevotionalWidgetsSheet(),
    );
  }

  @override
  State<DevotionalWidgetsSheet> createState() => _DevotionalWidgetsSheetState();
}

class _DevotionalWidgetsSheetState extends State<DevotionalWidgetsSheet> {
  WidgetType _selectedType = WidgetType.panchanga;
  WidgetSize _selectedSize = WidgetSize.medium;
  int _activeGuideTab = 0; // 0: iOS, 1: Android

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();
    final activeTheme = TempleTheme.fromId(prefs.getTempleThemeId());
    final panchanga = context.watch<PanchangaService>().getTodayPanchanga(currentLang);
    final player = context.watch<AudioPlayerService>();
    final currentSong = player.currentSong;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: activeTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: activeTheme.borderColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: activeTheme.heroGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Devotional Lock & Home Widgets',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: activeTheme.primaryColor,
                            ),
                          ),
                          Text(
                            'Live Tithi, Shlokas & Chants on your phone screen',
                            style: TextStyle(fontSize: 12, color: activeTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content Scroll Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // Widget Type Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: WidgetType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            type.icon,
                            size: 16,
                            color: isSelected ? Colors.white : activeTheme.primaryColor,
                          ),
                          label: Text(type.title),
                          selected: isSelected,
                          selectedColor: activeTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : activeTheme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedType = type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // Size Selector (if not lockScreen pill)
                if (_selectedType != WidgetType.lockScreen) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: WidgetSize.values.map((size) {
                      final isSelected = _selectedSize == size;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(size.label),
                          selected: isSelected,
                          selectedColor: activeTheme.surfaceColor,
                          checkmarkColor: activeTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? activeTheme.primaryColor : activeTheme.textMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedSize = size);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Live Widget Mockup Canvas (Simulated phone desktop)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Deep phone wallpaper background
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Simulated Phone Status bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('h:mm').format(DateTime.now()),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.wifi, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Icon(Icons.battery_full_rounded, size: 14, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // The Rendered Widget
                      _buildWidgetPreview(activeTheme, panchanga, currentSong, player),

                      const SizedBox(height: 16),
                      Text(
                        'Live Interactive Preview (${_selectedType.title})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Interactive Setup Guide Tabs
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: activeTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: activeTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 18, color: AppColors.goldDark),
                          const SizedBox(width: 8),
                          Text(
                            'How to Add to Home & Lock Screen',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: activeTheme.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Platform selector tabs
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _activeGuideTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _activeGuideTab == 0 ? activeTheme.primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    ' iOS (iPhone / iPad)',
                                    style: TextStyle(
                                      color: _activeGuideTab == 0 ? Colors.white : activeTheme.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _activeGuideTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _activeGuideTab == 1 ? activeTheme.primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '🤖 Android (Phone / Tablet)',
                                    style: TextStyle(
                                      color: _activeGuideTab == 1 ? Colors.white : activeTheme.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Guide steps
                      if (_activeGuideTab == 0) ...[
                        _buildStepItem('1', 'Touch and hold an empty area on your iPhone Home Screen until the apps jiggle.'),
                        _buildStepItem('2', 'Tap the (+) Add button in the upper-left corner.'),
                        _buildStepItem('3', 'Search for "Bhakti" and select your preferred widget size.'),
                        _buildStepItem('4', 'Tap "Add Widget" and place it on your Home or Lock Screen.'),
                      ] else ...[
                        _buildStepItem('1', 'Touch and hold any empty space on your Android Home Screen.'),
                        _buildStepItem('2', 'Tap the "Widgets" option in the popup menu.'),
                        _buildStepItem('3', 'Scroll down to "Bhakti" Devotional App.'),
                        _buildStepItem('4', 'Drag and drop the widget onto your home screen grid.'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action: Sync Widgets Now
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: activeTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync_rounded, color: Colors.white),
              label: const Text('Sync Widgets with Current Temple Theme'),
              style: ElevatedButton.styleFrom(
                backgroundColor: activeTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.goldLight),
                        const SizedBox(width: 8),
                        Text('Widgets synchronized with ${activeTheme.name}! 🙏'),
                      ],
                    ),
                    backgroundColor: activeTheme.primaryColor,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF4A3B32)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetPreview(
    TempleTheme theme,
    dynamic panchanga,
    dynamic currentSong,
    AudioPlayerService player,
  ) {
    switch (_selectedType) {
      case WidgetType.panchanga:
        return _buildPanchangaWidget(theme, panchanga);
      case WidgetType.shloka:
        return _buildShlokaWidget(theme);
      case WidgetType.player:
        return _buildPlayerWidget(theme, currentSong, player);
      case WidgetType.lockScreen:
        return _buildLockScreenPill(theme, panchanga);
    }
  }

  // --- Widget 1: Panchanga & Moon Phase ---
  Widget _buildPanchangaWidget(TempleTheme theme, dynamic panchanga) {
    final tithi = panchanga?.tithi ?? 'Shukla Navami';
    final paksha = panchanga?.paksha ?? 'Shukla Paksha';
    final nakshatra = panchanga?.nakshatra ?? 'Rohini';
    final rahu = panchanga?.rahuKalam ?? '04:30 PM - 06:00 PM';

    if (_selectedSize == WidgetSize.small) {
      return Container(
        width: 140,
        height: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: theme.heroGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.wb_sunny_rounded, size: 16, color: AppColors.goldLight),
                Text(
                  DateFormat('EEE, d').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Center(
              child: SizedBox(
                width: 44,
                height: 44,
                child: MoonPhaseDial(
                  tithiName: tithi,
                  paksha: paksha,
                  size: 44,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tithi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  nakshatra,
                  maxLines: 1,
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Medium or Large
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: theme.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Moon Phase Dial
          SizedBox(
            width: 60,
            height: 60,
            child: MoonPhaseDial(
              tithiName: tithi,
              paksha: paksha,
              size: 60,
            ),
          ),
          const SizedBox(width: 16),

          // Tithi & Timings
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tithi.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('d MMM').format(DateTime.now()),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Nakshatra: $nakshatra',
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'Rahu Kalam: $rahu',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget 2: Shloka of the Day ---
  Widget _buildShlokaWidget(TempleTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.accentGold.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: theme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'SHLOKA OF THE DAY',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.spa_rounded, size: 16, color: AppColors.goldDark),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं ।\nभर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF261102),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gayatri Mantra • Radiance & Intellect',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B584C), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // --- Widget 3: Mini Chant Player ---
  Widget _buildPlayerWidget(TempleTheme theme, dynamic currentSong, AudioPlayerService player) {
    final title = currentSong?.title ?? 'Venkateshwara Suprabhatam';
    final deity = currentSong?.deity ?? 'Lord Venkateshwara';
    final isPlaying = player.isPlaying;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: theme.playerGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.accentGold.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Album / Chakra icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: theme.heroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.music_note_rounded, color: AppColors.goldLight, size: 24),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Deity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  deity,
                  style: TextStyle(color: theme.auraGlowColor, fontSize: 11),
                ),
              ],
            ),
          ),

          // Play/Pause button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget 4: Lock Screen Pill ---
  Widget _buildLockScreenPill(TempleTheme theme, dynamic panchanga) {
    final tithi = panchanga?.tithi ?? 'Shukla Navami';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(theme.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${theme.deityName} • $tithi',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Brahma Muhurta: 04:42 AM',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(color: AppColors.goldLight, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
