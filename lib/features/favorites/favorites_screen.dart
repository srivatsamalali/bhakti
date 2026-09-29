import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../repositories/song_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/ambient_diya_particles.dart';
import '../../widgets/devotional_app_bar.dart';
import '../../widgets/devotional_card.dart';
import '../../widgets/divine_music_visualizer.dart';
import '../../widgets/empty_state_view.dart';
import '../player/full_player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<PreferencesService>();
    final songRepo = context.watch<SongRepository>();
    final player = context.watch<AudioPlayerService>();
    final favoriteSongs = songRepo.getFavoriteSongs();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: DevotionalAppBar(
        title: context.tr('navFavorites'),
        showLogo: false,
        actions: [
          if (favoriteSongs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.play_circle_filled, color: AppColors.saffronPrimary, size: 30),
                tooltip: context.tr('playAll'),
                onPressed: () {
                  player.playSong(favoriteSongs.first, newQueue: favoriteSongs);
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) => const FullPlayerScreen(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: AmbientDiyaParticles(
        particleCount: 16,
        child: favoriteSongs.isEmpty
            ? EmptyStateView(
                title: context.tr('noFavoritesTitle'),
                subtitle: context.tr('noFavoritesSubtitle'),
                icon: Icons.favorite_border,
              )
            : ListView.builder(
                itemCount: favoriteSongs.length + 1,
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 150),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Sacred Sanctum Header Banner
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF800020),
                            Color(0xFF5A0016),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.goldPrimary.withOpacity(0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.maroonPrimary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.goldPrimary.withOpacity(0.2),
                              border: Border.all(color: AppColors.goldLight, width: 1.5),
                            ),
                            child: const Icon(Icons.temple_hindu, color: AppColors.goldLight, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sacred Sanctum',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${favoriteSongs.length} Stotras & Sahasranama saved',
                                  style: TextStyle(
                                    color: AppColors.goldLight.withOpacity(0.9),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (player.isPlaying)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: DivineMusicVisualizer(
                                isPlaying: true,
                                barColor: AppColors.goldLight,
                                height: 18,
                                width: 18,
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  final song = favoriteSongs[index - 1];
                  return DevotionalCard(
                    song: song,
                    onTap: () {
                      player.playSong(song, newQueue: favoriteSongs);
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (_, __, ___) => const FullPlayerScreen(),
                        ),
                      );
                    },
                    onFavoriteToggled: () {
                      // Triggers rebuild via state
                    },
                  );
                },
              ),
      ),
    );
  }
}

