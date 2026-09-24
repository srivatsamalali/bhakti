import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/song_model.dart';
import '../../../repositories/song_repository.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../services/preferences/preferences_service.dart';
import '../../player/full_player_screen.dart';

class HeroSpiritualBanner extends StatelessWidget {
  final SongModel? featuredSong;

  const HeroSpiritualBanner({super.key, this.featuredSong});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();
    final player = context.watch<AudioPlayerService>();
    final songRepo = context.watch<SongRepository>();
    final allSongs = songRepo.allSongs;
    final isPlayingFeatured = featuredSong != null &&
        player.currentSong?.id == featuredSong!.id &&
        player.isPlaying;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.heroMaroonGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroonPrimary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.goldLight.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: AppColors.goldPrimary.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Background Ornate Motif Watermark
            Positioned(
              right: -24,
              top: -24,
              child: Icon(
                Icons.temple_hindu,
                size: 150,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
            Positioned(
              left: -15,
              bottom: -15,
              child: Icon(
                Icons.spa,
                size: 110,
                color: AppColors.goldLight.withOpacity(0.05),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Pill Tagline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.goldLight.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.goldLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('spiritualTagline').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppColors.goldLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.goldLight,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grand Headline
                  Text(
                    context.tr('heroSpiritualQuote'),
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Continuous Playlist Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: allSongs.isEmpty
                              ? null
                              : () {
                                  player.playAll(allSongs, shuffle: false);
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) => const FullPlayerScreen(),
                                      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldPrimary,
                            foregroundColor: AppColors.maroonDark,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.all_inclusive, size: 18),
                          label: const Text(
                            'Play All',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: allSongs.isEmpty
                              ? null
                              : () {
                                  player.playAll(allSongs, shuffle: true);
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) => const FullPlayerScreen(),
                                      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.18),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: BorderSide(color: AppColors.goldLight.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.shuffle, size: 16, color: AppColors.goldLight),
                          label: const Text(
                            'Shuffle',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Interactive Featured Devotional Bar
                  if (featuredSong != null)
                    InkWell(
                      onTap: () {
                        if (isPlayingFeatured) {
                          player.pause();
                        } else {
                          player.playSong(featuredSong!, newQueue: allSongs);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isPlayingFeatured
                              ? Colors.black.withOpacity(0.35)
                              : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPlayingFeatured
                                ? AppColors.goldLight
                                : AppColors.goldLight.withOpacity(0.3),
                            width: isPlayingFeatured ? 1.5 : 1,
                          ),
                          boxShadow: isPlayingFeatured
                              ? [
                                  BoxShadow(
                                    color: AppColors.goldLight.withOpacity(0.2),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.goldLight.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isPlayingFeatured ? Icons.pause : Icons.play_arrow,
                                color: AppColors.maroonDark,
                                size: 26,
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
                                        context.tr('popularDevotionals').toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.goldLight,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      if (isPlayingFeatured) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.graphic_eq,
                                          color: AppColors.goldLight,
                                          size: 14,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    featuredSong!.getLocalizedTitle(currentLang),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.goldLight,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
