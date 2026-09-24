import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../repositories/song_repository.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../services/preferences/preferences_service.dart';
import '../../../widgets/devotional_card.dart';
import '../../player/full_player_screen.dart';

class RecentlyPlayedSection extends StatelessWidget {
  const RecentlyPlayedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final songRepo = context.watch<SongRepository>();
    final player = context.watch<AudioPlayerService>();
    final recentSongs = songRepo.getRecentlyPlayedSongs();

    if (recentSongs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: AppColors.maroonPrimary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('recentlyPlayed'),
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroonPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.read<PreferencesService>().clearRecentlyPlayed();
                },
                child: Text(
                  context.tr('clearAll'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentSongs.take(3).length,
          itemBuilder: (context, index) {
            final song = recentSongs[index];
            return DevotionalCard(
              song: song,
              onTap: () {
                player.playSong(song, newQueue: recentSongs);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
