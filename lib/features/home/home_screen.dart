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
import '../../widgets/deepam_loader.dart';
import 'widgets/daily_shloka_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedPill = 'All';

  final List<String> _pills = const [
    'All',
    'Sahasranamam',
    'Daily Chants',
    'Meditation',
    'Peaceful',
    'Kannada',
    'Sanskrit',
  ];

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
    var displayedSongs = allSongs;
    if (_selectedPill == 'Sahasranamam') {
      displayedSongs = allSongs.where((s) => s.categoryId == 'sahasranamam' || s.title.toLowerCase().contains('sahasranama')).toList();
    } else if (_selectedPill == 'Kannada') {
      displayedSongs = allSongs.where((s) => s.language == 'kn').toList();
    }

    return Scaffold(
      backgroundColor: AppColors.subtleBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.maroonPrimary,
          backgroundColor: Colors.white,
          onRefresh: () async {
            await songRepo.loadSongs();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // --- Clean Top Header Bar ---
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 700;
                    final isCompact = constraints.maxWidth < 500;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          // Show logo and title only on mobile when left sidebar is absent
                          if (!isDesktop) ...[
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.maroonPrimary.withOpacity(0.12),
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
                                      color: AppColors.maroonPrimary,
                                      child: const Icon(Icons.wb_sunny, color: AppColors.goldLight, size: 20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'BHAKTI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.maroonPrimary,
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
                                    border: Border.all(color: const Color(0xFFE2D7C7)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.search_rounded, color: AppColors.maroonPrimary, size: 20),
                                      SizedBox(width: 10),
                                      Text(
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

                          // Mobile Search Pill Button
                          if (!isDesktop) ...[
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 10 : 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2D7C7)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search_rounded, color: AppColors.maroonPrimary, size: 18),
                                    if (!isCompact) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Search...',
                                        style: TextStyle(color: Color(0xFF7A685D), fontSize: 12.5, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Language Switcher Pill
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2D7C7)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.language_rounded, size: 16, color: AppColors.maroonPrimary),
                                  const SizedBox(width: 5),
                                  Text(
                                    currentLang.toUpperCase(),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.maroonPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (!isDesktop) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined, color: AppColors.maroonPrimary, size: 22),
                              tooltip: 'Settings',
                              padding: const EdgeInsets.all(4),
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

              // --- Clean Filter Pills ---
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: _pills.map((pill) {
                      final isSelected = _selectedPill == pill;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPill = pill;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.maroonPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.maroonPrimary : const Color(0xFFE2D7C7),
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: AppColors.maroonPrimary.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                else
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                              ],
                            ),
                            child: Text(
                              pill,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // --- Bhakti AI Clean Interactive Assistant Bar ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: _buildAiHeroBanner(context),
                ),
              ),

              // --- Sacred Shloka of the Day ---
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: DailyShlokaCard(),
                ),
              ),


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
                          backgroundColor: AppColors.maroonPrimary,
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
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: DeepamLoader(
                      size: 90,
                      message: 'Loading Divine Melodies...',
                      subtitle: 'ॐ ಶಾಂತಿಃ',
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
                      border: Border.all(color: const Color(0xFFEADBCE)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off_rounded, size: 48, color: AppColors.maroonPrimary.withOpacity(0.5)),
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPlaying ? AppColors.maroonPrimary.withOpacity(0.5) : const Color(0xFFEADBCE),
                            width: isPlaying ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isPlaying
                                  ? AppColors.maroonPrimary.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Album Artwork
                              _buildSongImage(song.imageUrl, size: 64, radius: 14),
                              const SizedBox(width: 16),

                              // Title & Deity
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.getLocalizedTitle(currentLang),
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: isPlaying ? AppColors.maroonPrimary : AppColors.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${song.getLocalizedDeity(currentLang)} • ${song.formattedDuration}',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF6B5B52),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Play/Pause Circular Action Button
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isPlaying ? AppColors.maroonPrimary : const Color(0xFFF3EDE3),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: isPlaying ? Colors.white : AppColors.maroonPrimary,
                                    size: 26,
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
                              const SizedBox(width: 6),

                              // Favorite Heart
                              IconButton(
                                icon: Icon(
                                  prefs.isFavorite(song.id) ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                  color: prefs.isFavorite(song.id) ? AppColors.maroonPrimary : const Color(0xFF8B776A),
                                  size: 22,
                                ),
                                tooltip: 'Favorite',
                                onPressed: () async {
                                  await prefs.toggleFavorite(song.id);
                                },
                              ),

                              // Details Screen Arrow
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF8B776A), size: 16),
                                tooltip: 'Details',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => SongDetailsScreen(song: song)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: displayedSongs.length,
                  ),
                ),
              ),

              // --- Sacred Album Covers Carousel ---
              if (allSongs.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
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
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: allSongs.length,
                          itemBuilder: (context, index) {
                            final song = allSongs[index];
                            final isCurrentPlaying = player.currentSong?.id == song.id && player.isPlaying;

                            return Container(
                              width: 180,
                              margin: const EdgeInsets.only(right: 18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFEADBCE)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
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
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: AppColors.maroonPrimary,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
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
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiHeroBanner(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEADBCE),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.maroonPrimary.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BhaktiAiScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    // Glowing Sacred Sparkle Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroMaroonGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.maroonPrimary.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.goldLight, size: 22),
                    ),
                    const SizedBox(width: 14),

                    // Clean Text Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Bhakti AI Assistant',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.maroonPrimary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.mic, color: AppColors.maroonPrimary, size: 15),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isNarrow
                                ? 'Ask or chant in Kannada, Hindi, Tamil, ML, English'
                                : 'Ask questions, explore meanings, or listen in your sacred language',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF7A685D),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Clean Action Pill Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.maroonPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.maroonPrimary.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Ask AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

