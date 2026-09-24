import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../repositories/song_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/devotional_app_bar.dart';
import '../../widgets/devotional_card.dart';
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
            IconButton(
              icon: const Icon(Icons.play_circle_filled, color: AppColors.saffronPrimary, size: 28),
              tooltip: context.tr('playAll'),
              onPressed: () {
                player.playSong(favoriteSongs.first, newQueue: favoriteSongs);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                );
              },
            ),
        ],
      ),
      body: favoriteSongs.isEmpty
          ? EmptyStateView(
              title: context.tr('noFavoritesTitle'),
              subtitle: context.tr('noFavoritesSubtitle'),
              icon: Icons.favorite_border,
            )
          : ListView.builder(
              itemCount: favoriteSongs.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final song = favoriteSongs[index];
                return DevotionalCard(
                  song: song,
                  onTap: () {
                    player.playSong(song, newQueue: favoriteSongs);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                    );
                  },
                  onFavoriteToggled: () {
                    // Triggers rebuild
                  },
                );
              },
            ),
    );
  }
}
