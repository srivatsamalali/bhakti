import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
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
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: AppColors.heroMaroonGradient,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Center(
        child: Icon(Icons.wb_sunny, color: AppColors.goldLight, size: 28),
      ),
    );

    if (song.imageUrl.startsWith('data:image')) {
      try {
        final base64String = song.imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    } else if (song.imageUrl.startsWith('blob:')) {
      return Image.network(
        song.imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (song.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: song.imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 72,
          height: 72,
          color: AppColors.subtleSurface,
          child: const Center(
            child: Icon(Icons.music_note, color: AppColors.goldPrimary, size: 28),
          ),
        ),
        errorWidget: (context, url, error) => fallback,
      );
    } else if (song.imageUrl.startsWith('assets/')) {
      return Image.asset(
        song.imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/lalitha_sahasranamam.jpg',
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    } else if (!kIsWeb) {
      // Local file
      try {
        return Image.file(
          File(song.imageUrl),
          width: 72,
          height: 72,
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

    return Dismissible(
      key: Key('devotional_card_${song.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right: Add to Queue
          player.addToQueue(song);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.playlist_add_check, color: AppColors.goldLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Added "${song.getLocalizedTitle(currentLang)}" to Divine Queue'),
                  ),
                ],
              ),
              backgroundColor: AppColors.maroonPrimary,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (direction == DismissDirection.endToStart) {
          // Swipe Left: Toggle Favorite
          await prefs.toggleFavorite(song.id);
          onFavoriteToggled?.call();
          final updatedFav = prefs.isFavorite(song.id);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(updatedFav ? Icons.favorite : Icons.favorite_border, color: AppColors.goldLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      updatedFav
                          ? 'Saved "${song.getLocalizedTitle(currentLang)}" to Favorites'
                          : 'Removed from Favorites',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.maroonDark,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return false; // Do not dismiss card from list
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.goldDark,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.playlist_add, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('Add to Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.maroonPrimary,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(isFav ? 'Remove Favorite' : 'Add Favorite', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(isFav ? Icons.favorite_border : Icons.favorite, color: AppColors.goldLight, size: 28),
          ],
        ),
      ),
      child: Card(
        elevation: isCurrentPlaying ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isCurrentPlaying
                ? AppColors.goldLight
                : AppColors.goldPrimary.withOpacity(0.25),
            width: isCurrentPlaying ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isCurrentPlaying
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.maroonPrimary.withOpacity(0.08),
                      AppColors.saffronPrimary.withOpacity(0.05),
                      Colors.white,
                    ],
                  )
                : null,
            boxShadow: isCurrentPlaying
                ? [
                    BoxShadow(
                      color: AppColors.goldPrimary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail Artwork with Gold Border
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrentPlaying
                            ? AppColors.goldLight
                            : AppColors.goldPrimary.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildImage(context),
                          if (isCurrentPlaying)
                            Container(
                              width: 72,
                              height: 72,
                              color: Colors.black.withOpacity(0.45),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.graphic_eq,
                                    color: AppColors.goldLight,
                                    size: 28,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'PLAYING',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.goldLight,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title, Deity, and Language Tag
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.getLocalizedTitle(currentLang),
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isCurrentPlaying
                                ? AppColors.maroonPrimary
                                : AppColors.textDark,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.spa,
                              color: AppColors.goldDark,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                song.getLocalizedDeity(currentLang),
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                song.categoryName ?? song.categoryId.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.maroonDark,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (player.currentSong?.id == song.id && (player.totalDuration?.inSeconds ?? 0) > 0)
                                  ? _formatDuration(player.totalDuration!.inSeconds)
                                  : song.formattedDuration,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Favorite & Play Actions
                  if (showFavoriteButton)
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppColors.error : AppColors.textMuted,
                        size: 22,
                      ),
                      tooltip: isFav
                          ? context.tr('unfavorite')
                          : context.tr('favorite'),
                      onPressed: () async {
                        await prefs.toggleFavorite(song.id);
                        onFavoriteToggled?.call();
                      },
                    ),

                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: isCurrentPlaying
                            ? AppColors.heroMaroonGradient
                            : AppColors.goldGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isCurrentPlaying
                                ? AppColors.maroonPrimary.withOpacity(0.4)
                                : AppColors.goldPrimary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isCurrentPlaying ? Icons.pause : Icons.play_arrow,
                        color: isCurrentPlaying ? Colors.white : AppColors.maroonDark,
                        size: 20,
                      ),
                    ),
                    tooltip: isCurrentPlaying ? context.tr('pause') : context.tr('play'),
                    onPressed: () {
                      if (isCurrentPlaying) {
                        player.pause();
                      } else {
                        if (player.currentSong?.id == song.id) {
                          player.resume();
                        } else {
                          player.playSong(song);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
