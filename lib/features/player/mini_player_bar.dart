import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import 'full_player_screen.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildArtwork(String imageUrl) {
    Widget fallback = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.heroMaroonGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.wb_sunny, color: AppColors.goldLight, size: 24),
      ),
    );

    if (imageUrl.startsWith('blob:')) {
      return Image.network(
        imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => fallback,
      );
    } else if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/lalitha_sahasranamam.jpg',
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    } else if (!kIsWeb) {
      try {
        return Image.file(
          File(imageUrl),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    final prefs = context.watch<PreferencesService>();
    final isFav = prefs.isFavorite(song.id);
    final currentLang = prefs.getSelectedLanguage();

    void openFullPlayer() {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const FullPlayerScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Slim Progress Scrubbing Bar (Sacred Maroon Progress Line)
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final total = player.totalDuration ?? Duration(seconds: song.duration);
                final ratio = total.inMilliseconds > 0
                    ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0;

                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null && total.inMilliseconds > 0) {
                      final localX = details.localPosition.dx.clamp(0.0, box.size.width);
                      final seekRatio = localX / box.size.width;
                      player.seek(Duration(milliseconds: (total.inMilliseconds * seekRatio).toInt()));
                    }
                  },
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: const Color(0xFFEADFCF),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.maroonPrimary),
                    minHeight: 3.5,
                  ),
                );
              },
            ),

            // Main Subtle Player Bar
            Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: isDesktop
                  ? Row(
                      children: [
                        // --- LEFT: Controls & Time ---
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded, color: AppColors.maroonPrimary, size: 28),
                              tooltip: 'Previous Track',
                              onPressed: () => player.playPrevious(),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.maroonPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                tooltip: player.isPlaying ? 'Pause' : 'Play',
                                onPressed: () => player.togglePlayPause(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded, color: AppColors.maroonPrimary, size: 28),
                              tooltip: 'Next Track',
                              onPressed: () => player.playNext(),
                            ),
                            const SizedBox(width: 8),
                            StreamBuilder<Duration>(
                              stream: player.positionStream,
                              builder: (context, snapshot) {
                                final position = snapshot.data ?? Duration.zero;
                                final total = player.totalDuration ?? Duration(seconds: song.duration);
                                return Text(
                                  '${_formatDuration(position)} / ${_formatDuration(total)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7A685D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // --- CENTER: Artwork & Title & Details ---
                        Expanded(
                          child: InkWell(
                            onTap: openFullPlayer,
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildArtwork(song.imageUrl),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.getLocalizedTitle(currentLang),
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${song.getLocalizedDeity(currentLang)} • ${song.formattedDuration}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF7A685D),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                    color: isFav ? AppColors.maroonPrimary : const Color(0xFF8B776A),
                                    size: 24,
                                  ),
                                  tooltip: 'Favorite',
                                  onPressed: () async {
                                    await prefs.toggleFavorite(song.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // --- RIGHT: Repeat, Shuffle, Fullscreen ---
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                player.loopMode == LoopMode.all
                                    ? Icons.repeat_rounded
                                    : (player.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded),
                                color: player.loopMode != LoopMode.off ? AppColors.maroonPrimary : const Color(0xFF8B776A),
                                size: 22,
                              ),
                              tooltip: 'Repeat',
                              onPressed: () => player.toggleLoopMode(),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: player.isShuffleEnabled ? AppColors.maroonPrimary : const Color(0xFF8B776A),
                                size: 22,
                              ),
                              tooltip: 'Shuffle',
                              onPressed: () => player.toggleShuffle(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.maroonPrimary, size: 28),
                              tooltip: 'Expand Player',
                              onPressed: openFullPlayer,
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // Mobile Layout: [Artwork + Title/Artist in Expanded] + [Favorite] + [Play/Pause] + [Expand]
                        Expanded(
                          child: InkWell(
                            onTap: openFullPlayer,
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildArtwork(song.imageUrl),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
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
                                        '${song.getLocalizedDeity(currentLang)} • ${song.formattedDuration}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7A685D),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                            color: isFav ? AppColors.maroonPrimary : const Color(0xFF8B776A),
                            size: 22,
                          ),
                          tooltip: 'Favorite',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            await prefs.toggleFavorite(song.id);
                          },
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.maroonPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: player.isPlaying ? 'Pause' : 'Play',
                            onPressed: () => player.togglePlayPause(),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.maroonPrimary, size: 26),
                          tooltip: 'Expand Player',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: openFullPlayer,
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

