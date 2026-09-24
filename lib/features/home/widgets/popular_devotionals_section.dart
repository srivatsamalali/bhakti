import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/song_model.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../widgets/devotional_card.dart';
import '../../player/full_player_screen.dart';

class PopularDevotionalsSection extends StatelessWidget {
  final List<SongModel> songs;
  final VoidCallback? onViewAll;

  const PopularDevotionalsSection({
    super.key,
    required this.songs,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();

    if (songs.isEmpty) return const SizedBox.shrink();

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
                  const Icon(Icons.star_rounded, color: AppColors.saffronPrimary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('popularDevotionals'),
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroonPrimary,
                    ),
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('viewAll'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.saffronPrimary,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.saffronPrimary),
                    ],
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: songs.length,
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
      ],
    );
  }
}
