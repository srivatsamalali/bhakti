import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/song_model.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../player/full_player_screen.dart';

class SongDetailsScreen extends StatefulWidget {
  final SongModel song;

  const SongDetailsScreen({super.key, required this.song});

  @override
  State<SongDetailsScreen> createState() => _SongDetailsScreenState();
}

class _SongDetailsScreenState extends State<SongDetailsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logSongViewed(widget.song.id, widget.song.title);
  }

  Widget _buildCover(String imageUrl) {
    if (imageUrl.startsWith('blob:')) {
      return Image.network(
        imageUrl,
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/lalitha_sahasranamam.jpg',
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.maroonDark),
        errorWidget: (_, __, ___) => Image.asset(
          'assets/images/lalitha_sahasranamam.jpg',
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb) {
      try {
        return Image.file(
          File(imageUrl),
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 240,
            color: AppColors.maroonDark,
            child: const Icon(Icons.music_note, color: AppColors.goldLight, size: 60),
          ),
        );
      } catch (_) {
        return Image.asset('assets/images/lalitha_sahasranamam.jpg', height: 240, width: double.infinity, fit: BoxFit.cover);
      }
    } else {
      return Image.asset('assets/images/lalitha_sahasranamam.jpg', height: 240, width: double.infinity, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();
    final isFav = prefs.isFavorite(widget.song.id);
    final isPlayingThis = player.currentSong?.id == widget.song.id && player.isPlaying;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: Text(widget.song.getLocalizedTitle(currentLang)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.error : AppColors.maroonPrimary,
            ),
            onPressed: () async {
              await prefs.toggleFavorite(widget.song.id);
              AnalyticsService.instance.logSongFavorited(widget.song.id, !isFav);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Share.share(
                'Listen to "${widget.song.getLocalizedTitle(currentLang)}" on Bhakti app. ${widget.song.description}',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Devotional Artwork
            Stack(
              children: [
                _buildCover(widget.song.imageUrl),
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.song.categoryName ?? widget.song.categoryId.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.maroonDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.song.getLocalizedTitle(currentLang),
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Play Now & Add to Queue Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            player.playSong(widget.song);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                            );
                          },
                          icon: Icon(isPlayingThis ? Icons.pause : Icons.play_arrow),
                          label: Text(
                            isPlayingThis ? context.tr('pause') : context.tr('play'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.maroonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          player.addToQueue(widget.song);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to Queue: ${widget.song.getLocalizedTitle(currentLang)}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: const Icon(Icons.queue_music, color: AppColors.maroonPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Metadata Cards (Deity, Duration, Artist)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.creamCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.goldPrimary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow(
                          context.tr('deity'),
                          widget.song.getLocalizedDeity(currentLang),
                          Icons.spa_outlined,
                        ),
                        const Divider(height: 16),
                        _buildMetaRow(
                          context.tr('duration'),
                          widget.song.formattedDuration,
                          Icons.timer_outlined,
                        ),
                        if (widget.song.artist != null && widget.song.artist!.isNotEmpty) ...[
                          const Divider(height: 16),
                          _buildMetaRow(
                            context.tr('artist'),
                            widget.song.artist!,
                            Icons.person_outline,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description / Significance
                  Text(
                    'Spiritual Significance',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroonPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.song.description,
                    style: AppTypography.bodyLarge.copyWith(
                      height: 1.6,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sacred Lyrics
                  if (widget.song.lyrics != null && widget.song.lyrics!.isNotEmpty) ...[
                    Text(
                      context.tr('lyrics'),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroonPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.creamSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.goldPrimary.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        widget.song.lyrics!,
                        style: AppTypography.sacredDevotionalText.copyWith(
                          fontSize: 16,
                          height: 1.8,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.maroonPrimary, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
