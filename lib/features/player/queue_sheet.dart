import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/divine_music_visualizer.dart';

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
      decoration: BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppColors.goldPrimary.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroonPrimary.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 10),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withOpacity(0.4),
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.maroonPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.queue_music, color: AppColors.maroonPrimary, size: 22),
                    ),
                    const SizedBox(width: 10),
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
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.goldPrimary.withOpacity(0.4)),
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
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 18, color: AppColors.error),
                    onPressed: () {
                      player.clearQueue();
                      Navigator.pop(context);
                    },
                    label: Text(
                      context.tr('clearQueue'),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.goldPrimary.withOpacity(0.2)),

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
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    onReorder: (oldIndex, newIndex) {
                      player.reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = queue[index];
                      final isCurrent = index == currentIndex;

                      return Container(
                        key: ValueKey(song.id + index.toString()),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.maroonPrimary.withOpacity(0.08)
                              : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.goldPrimary
                                : AppColors.goldPrimary.withOpacity(0.15),
                            width: isCurrent ? 1.5 : 1,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.goldPrimary.withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: isCurrent
                                      ? const LinearGradient(
                                          colors: [AppColors.maroonPrimary, AppColors.maroonDark],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isCurrent ? null : AppColors.creamSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isCurrent ? AppColors.goldLight : AppColors.goldPrimary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: isCurrent && player.isPlaying
                                    ? const Center(
                                        child: DivineMusicVisualizer(
                                          isPlaying: true,
                                          barColor: AppColors.goldLight,
                                          height: 16,
                                          width: 16,
                                        ),
                                      )
                                    : Icon(
                                        isCurrent ? Icons.play_arrow : Icons.music_note,
                                        color: isCurrent ? AppColors.goldLight : AppColors.maroonPrimary,
                                        size: 20,
                                      ),
                              ),
                            ],
                          ),
                          title: Text(
                            song.getLocalizedTitle(currentLang),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
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
                                icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                                onPressed: () {
                                  player.removeFromQueue(index);
                                },
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle, color: AppColors.textMuted, size: 20),
                              ),
                            ],
                          ),
                          onTap: () {
                            player.playSong(song);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

