import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();
    final queue = player.queue;
    final currentIndex = player.currentIndex;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.queue_music, color: AppColors.maroonPrimary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('queue'),
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroonPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${queue.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroonPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (queue.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      player.clearQueue();
                      Navigator.pop(context);
                    },
                    child: Text(
                      context.tr('clearQueue'),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Reorderable List
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Text(
                      context.tr('queueEmpty'),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: queue.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onReorder: (oldIndex, newIndex) {
                      player.reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = queue[index];
                      final isCurrent = index == currentIndex;

                      return ListTile(
                        key: ValueKey(song.id + index.toString()),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.maroonPrimary
                                : AppColors.creamSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isCurrent ? Icons.volume_up : Icons.music_note,
                            color: isCurrent ? AppColors.goldLight : AppColors.maroonPrimary,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          song.getLocalizedTitle(currentLang),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent ? AppColors.maroonPrimary : AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.getLocalizedDeity(currentLang),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                              onPressed: () {
                                player.removeFromQueue(index);
                              },
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        onTap: () {
                          player.playSong(song);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
