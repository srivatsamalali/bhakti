import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../repositories/song_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../ai/bhakti_ai_screen.dart';
import '../language/language_selection_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../songs/song_details_screen.dart';
import '../../widgets/ambient_diya_particles.dart';
import '../../widgets/divine_music_visualizer.dart';
import '../../widgets/liquid_glass/glass_style.dart';
import '../../widgets/liquid_glass/liquid_glass.dart';
import '../../widgets/shimmer_song_tile.dart';
import '../../widgets/sacred_filigree_border.dart';
import 'widgets/daily_panchanga_card.dart';
import 'widgets/daily_shloka_card.dart';
import 'widgets/virtual_pooja_card.dart';
import '../../core/theme/temple_theme.dart';
import '../settings/widgets/temple_theme_selector_sheet.dart';
import '../pooja/sacred_temple_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget _buildSongImage(String imageUrl, {double size = 56, double radius = 14}) {
    Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.heroMaroonGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Center(
        child: Icon(Icons.wb_sunny, color: AppColors.goldLight, size: 28),
      ),
    );

    if (imageUrl.trim().isEmpty) return fallback;

    Widget imageWidget;
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        imageWidget = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        imageWidget = fallback;
      }
    } else if (imageUrl.startsWith('blob:')) {
      imageWidget = Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (imageUrl.startsWith('http')) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: const Color(0xFFF0EBE1),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.maroonPrimary),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => fallback,
      );
    } else if (imageUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (!kIsWeb) {
      try {
        final file = File(imageUrl);
        imageWidget = Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        imageWidget = fallback;
      }
    } else {
      imageWidget = fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final songRepo = context.watch<SongRepository>();
    final prefs = context.watch<PreferencesService>();
    final player = context.watch<AudioPlayerService>();
    final currentLang = prefs.getSelectedLanguage();

    final allSongs = songRepo.allSongs;
    final displayedSongs = allSongs;

    final templeTheme = TempleTheme.fromId(prefs.getTempleThemeId());

    return Scaffold(
      backgroundColor: templeTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: templeTheme.primaryColor,
          backgroundColor: Colors.white,
          onRefresh: () async {
            await songRepo.loadSongs();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // --- Clean, High-Performance Top Header Bar ---
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 700;
                    final isCompact = constraints.maxWidth < 420;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Show logo and title only on mobile when left sidebar is absent
                          if (!isDesktop) ...[
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: templeTheme.primaryColor.withOpacity(0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'images/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: templeTheme.primaryColor,
                                      child: Icon(Icons.wb_sunny, color: templeTheme.accentGold, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'BHAKTI',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: templeTheme.primaryColor,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const Spacer(),
                          ] else ...[
                            // Desktop: Spacious Clean Search Field
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: templeTheme.borderColor),
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
                                      Icon(Icons.search_rounded, color: templeTheme.primaryColor, size: 20),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Search sacred chants, sahasranamas, stotras...',
                                        style: TextStyle(color: Color(0xFF7A685D), fontSize: 13.5, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],

                          // Ask Bhakti AI High-Performance Glossy Pill
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const BhaktiAiScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: templeTheme.borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [
                                          Color(0xFFFF4070),
                                          Color(0xFFFFB300),
                                          Color(0xFF00E5FF),
                                          Color(0xFF7C4DFF),
                                          Color(0xFFFF4070),
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.auto_awesome, color: Colors.white, size: 11),
                                    ),
                                  ),
                                  if (!isCompact || isDesktop) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      'AI',
                                      style: TextStyle(
                                        color: templeTheme.primaryColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),

                          // Search Icon Button
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SearchScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: templeTheme.borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.search_rounded, color: templeTheme.primaryColor, size: 17),
                            ),
                          ),
                          const SizedBox(width: 5),

                          // Language Switcher Pill
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: templeTheme.borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.language_rounded, size: 14, color: templeTheme.primaryColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    currentLang.toUpperCase(),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: templeTheme.primaryColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),

                          // Sacred Temple Map & Yatra Button
                          Tooltip(
                            message: 'Sacred Temple Map & Yatra',
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SacredTempleMapScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFF8E7),
                                      Color(0xFFFFECD2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.goldPrimary.withOpacity(0.8), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.goldPrimary.withOpacity(0.12),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.public_rounded, size: 15, color: templeTheme.primaryColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      'MAP',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: templeTheme.primaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          if (isDesktop) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              icon: Icon(Icons.settings_outlined, color: templeTheme.primaryColor, size: 20),
                              tooltip: 'Settings',
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // --- Daily Vedic Panchanga & Festivals ---
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 2),
                  child: DailyPanchangaCard(),
                ),
              ),

              // --- Sacred Shloka of the Day ---
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: DailyShlokaCard(),
                ),
              ),

              // --- Featured Sahasranamas Carousel (Placed Above Sacred Sahasranamas) ---
              if (allSongs.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Featured Sahasranamas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 252,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: allSongs.length,
                            itemBuilder: (context, index) {
                              final song = allSongs[index];
                              final isCurrentPlaying = player.currentSong?.id == song.id && player.isPlaying;

                              return GestureDetector(
                                onTap: () {
                                  if (isCurrentPlaying) {
                                    player.pause();
                                  } else if (player.currentSong?.id == song.id) {
                                    player.resume();
                                  } else {
                                    player.playSong(song, newQueue: allSongs);
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: 180,
                                  margin: const EdgeInsets.only(right: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCurrentPlaying ? AppColors.goldPrimary : const Color(0xFFEADBCE),
                                      width: isCurrentPlaying ? 1.8 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isCurrentPlaying
                                            ? AppColors.goldPrimary.withOpacity(0.25)
                                            : Colors.black.withOpacity(0.04),
                                        blurRadius: isCurrentPlaying ? 14 : 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: SacredCornerFiligree(
                                    borderRadius: BorderRadius.circular(20),
                                    color: isCurrentPlaying
                                        ? const Color(0xFFD4AF37)
                                        : const Color(0x99D4AF37),
                                    cornerSize: 18,
                                    strokeWidth: 1.4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            // Album Cover Card
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: Stack(
                                                children: [
                                                  _buildSongImage(song.imageUrl, size: 156, radius: 16),
                                                  if (isCurrentPlaying)
                                                    Positioned(
                                                      top: 8,
                                                      left: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.7),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const DivineMusicVisualizer(
                                                          isPlaying: true,
                                                          height: 10,
                                                          width: 14,
                                                          barColor: AppColors.goldLight,
                                                        ),
                                                      ),
                                                    ),
                                                  Positioned(
                                                    bottom: 8,
                                                    right: 8,
                                                    child: Container(
                                                      width: 38,
                                                      height: 38,
                                                      decoration: BoxDecoration(
                                                        gradient: AppColors.heroMaroonGradient,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: AppColors.maroonPrimary.withOpacity(0.4),
                                                            blurRadius: 6,
                                                          ),
                                                        ],
                                                      ),
                                                      child: IconButton(
                                                        icon: Icon(
                                                          isCurrentPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                          color: Colors.white,
                                                          size: 22,
                                                        ),
                                                        padding: EdgeInsets.zero,
                                                        tooltip: isCurrentPlaying ? 'Pause' : 'Play',
                                                        onPressed: () {
                                                          if (isCurrentPlaying) {
                                                            player.pause();
                                                          } else if (player.currentSong?.id == song.id) {
                                                            player.resume();
                                                          } else {
                                                            player.playSong(song, newQueue: allSongs);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              song.getLocalizedTitle(currentLang),
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              song.getLocalizedDeity(currentLang),
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: Color(0xFF7A685D),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // --- Quick Picks Section Header ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sacred Sahasranamas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Continuous divine chanting with high audio clarity',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF7A685D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: allSongs.isEmpty
                            ? null
                            : () {
                                player.playAll(allSongs, shuffle: false);
                              },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Play all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: templeTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Sacred Sahasranama Track Cards ---
              if (songRepo.isLoading && displayedSongs.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ShimmerSongTile(),
                      childCount: 4,
                    ),
                  ),
                )
              else if (displayedSongs.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: templeTheme.borderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off_rounded, size: 48, color: templeTheme.primaryColor.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'No Songs Available Yet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Upload devotional songs from the Admin portal or pull down to refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = displayedSongs[index];
                      final isPlaying = player.currentSong?.id == song.id && player.isPlaying;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPlaying ? templeTheme.primaryColor : templeTheme.borderColor,
                            width: isPlaying ? 1.8 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isPlaying
                                  ? templeTheme.primaryColor.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.03),
                              blurRadius: isPlaying ? 14 : 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => SongDetailsScreen(song: song)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  // Album Artwork with active aura
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _buildSongImage(song.imageUrl, size: 58, radius: 13),
                                      if (isPlaying)
                                        Positioned(
                                          bottom: 3,
                                          right: 3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.65),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: DivineMusicVisualizer(
                                              isPlaying: true,
                                              height: 9,
                                              width: 12,
                                              barColor: templeTheme.accentGold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 13),

                                  // Title & Deity
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                song.getLocalizedTitle(currentLang),
                                                style: TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.22,
                                                  color: isPlaying ? templeTheme.primaryColor : AppColors.textDark,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isPlaying) ...[
                                              const SizedBox(width: 4),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: DivineMusicVisualizer(
                                                  isPlaying: true,
                                                  height: 13,
                                                  width: 16,
                                                  barColor: templeTheme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Builder(
                                          builder: (context) {
                                            final liveDuration = (isPlaying && player.totalDuration != null && player.totalDuration!.inSeconds > 0)
                                                ? '${player.totalDuration!.inMinutes}:${(player.totalDuration!.inSeconds % 60).toString().padLeft(2, '0')}'
                                                : song.formattedDuration;
                                            return Text(
                                              '${song.getLocalizedDeity(currentLang)} • $liveDuration',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: isPlaying ? templeTheme.primaryColor.withOpacity(0.85) : const Color(0xFF6B5B52),
                                                fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Favorite Heart Button
                                  IconButton(
                                    icon: Icon(
                                      prefs.isFavorite(song.id) ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                      color: prefs.isFavorite(song.id) ? templeTheme.primaryColor : const Color(0xFF8B776A),
                                      size: 22,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                    tooltip: 'Favorite',
                                    onPressed: () async {
                                      await prefs.toggleFavorite(song.id);
                                    },
                                  ),
                                  const SizedBox(width: 4),

                                  // Play/Pause Circular Action Button
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isPlaying ? templeTheme.primaryColor : const Color(0xFFF3EDE3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: isPlaying ? Colors.white : templeTheme.primaryColor,
                                        size: 24,
                                      ),
                                      padding: EdgeInsets.zero,
                                      tooltip: isPlaying ? 'Pause' : 'Play',
                                      onPressed: () {
                                        if (isPlaying) {
                                          player.pause();
                                        } else if (player.currentSong?.id == song.id) {
                                          player.resume();
                                        } else {
                                          player.playSong(song, newQueue: allSongs);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: displayedSongs.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 150)),
            ],
          ),
        ),
      ),
    );
  }

}

