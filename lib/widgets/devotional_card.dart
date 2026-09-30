import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../models/song_model.dart';
import '../services/audio/audio_player_service.dart';
import '../services/preferences/preferences_service.dart';

class DevotionalCard extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final bool showFavoriteButton;
  final VoidCallback? onFavoriteToggled;

  const DevotionalCard({
    super.key,
    required this.song,
    required this.onTap,
    this.showFavoriteButton = true,
    this.onFavoriteToggled,
  });

  Widget _buildImage(BuildContext context) {
    Widget fallback = Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: AppColors.heroMaroonGradient,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Center(
        child: Icon(Icons.wb_sunny, color: AppColors.goldLight, size: 22),
      ),
    );

    if (song.imageUrl.startsWith('data:image')) {
      try {
        final base64String = song.imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    } else if (song.imageUrl.startsWith('blob:')) {
      return Image.network(
        song.imageUrl,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (song.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: song.imageUrl,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 54,
          height: 54,
          color: AppColors.subtleSurface,
          child: const Center(
            child: Icon(Icons.music_note, color: AppColors.goldPrimary, size: 22),
          ),
        ),
        errorWidget: (context, url, error) => fallback,
      );
    } else if (song.imageUrl.startsWith('assets/')) {
      return Image.asset(
        song.imageUrl,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/lalitha_sahasranamam.jpg',
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    } else if (!kIsWeb) {
      try {
        return Image.file(
          File(song.imageUrl),
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    } else {
      return fallback;
    }
  }

  String _formatDuration(int duration) {
    final minutes = (duration / 60).floor();
    final seconds = duration % 60;
    if (minutes >= 60) {
      final hours = (minutes / 60).floor();
      final remMinutes = minutes % 60;
      return '${hours.toString().padLeft(2, '0')}:${remMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final player = context.watch<AudioPlayerService>();
    final isFav = prefs.isFavorite(song.id);
    final isCurrentPlaying = player.currentSong?.id == song.id && player.isPlaying;
    final currentLang = prefs.getSelectedLanguage();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlaying
              ? AppColors.maroonPrimary
              : const Color(0xFFEEDBCE),
          width: isCurrentPlaying ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentPlaying
                ? AppColors.maroonPrimary.withOpacity(0.14)
                : Colors.black.withOpacity(0.025),
            blurRadius: isCurrentPlaying ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Compact Thumbnail with Active Aura
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildImage(context),
                      if (isCurrentPlaying)
                        Container(
                          width: 54,
                          height: 54,
                          color: Colors.black.withOpacity(0.4),
                          child: const Center(
                            child: Icon(
                              Icons.graphic_eq_rounded,
                              color: AppColors.goldLight,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 11),

                // Title, Deity, Category & Duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.getLocalizedTitle(currentLang),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: isCurrentPlaying
                              ? AppColors.maroonPrimary
                              : AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              song.getLocalizedDeity(currentLang),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF7A685D),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.maroonPrimary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              song.categoryName ?? song.categoryId.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.maroonPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (player.currentSong?.id == song.id && (player.totalDuration?.inSeconds ?? 0) > 0)
                                ? _formatDuration(player.totalDuration!.inSeconds)
                                : song.formattedDuration,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8D7B70),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Favorite Button
                if (showFavoriteButton)
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      color: isFav ? AppColors.error : const Color(0xFF8D7B70),
                      size: 20,
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    tooltip: isFav ? context.tr('unfavorite') : context.tr('favorite'),
                    onPressed: () async {
                      await prefs.toggleFavorite(song.id);
                      onFavoriteToggled?.call();
                    },
                  ),

                // Play / Pause Compact Action Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCurrentPlaying
                        ? AppColors.maroonPrimary
                        : const Color(0xFFF3EDE3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isCurrentPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isCurrentPlaying ? Colors.white : AppColors.maroonPrimary,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: isCurrentPlaying ? context.tr('pause') : context.tr('play'),
                    onPressed: () {
                      if (isCurrentPlaying) {
                        player.pause();
                      } else if (player.currentSong?.id == song.id) {
                        player.resume();
                      } else {
                        player.playSong(song);
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
  }
}
