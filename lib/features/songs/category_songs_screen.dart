import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/category_model.dart';
import '../../repositories/song_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/devotional_app_bar.dart';
import '../../widgets/devotional_card.dart';
import '../../widgets/empty_state_view.dart';
import '../player/full_player_screen.dart';

class CategorySongsScreen extends StatelessWidget {
  final CategoryModel category;

  const CategorySongsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final songRepo = context.watch<SongRepository>();
    final player = context.watch<AudioPlayerService>();
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();

    final songs = songRepo.getSongsByCategory(category.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: DevotionalAppBar(
        title: category.getLocalizedName(currentLang),
        showLogo: false,
        showBackButton: true,
        actions: [
          if (songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_filled, color: AppColors.saffronPrimary, size: 28),
              tooltip: context.tr('playAll'),
              onPressed: () {
                player.playSong(songs.first, newQueue: songs);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                );
              },
            ),
        ],
      ),
      body: songs.isEmpty
          ? EmptyStateView(
              title: '${category.getLocalizedName(currentLang)} ${context.tr('songs')}',
              subtitle: context.tr('noSearchResults'),
            )
          : ListView.builder(
              itemCount: songs.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final song = songs[index];
                return DevotionalCard(
                  song: song,
                  onTap: () {
                    player.playSong(song, newQueue: songs);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                    );
                  },
                );
              },
            ),
    );
  }
}
