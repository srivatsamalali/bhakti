import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/audio/audio_player_service.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final activeTimer = player.activeSleepTimer;

    final options = [
      {'val': SleepTimerDuration.off, 'label': context.tr('timerOff')},
      {'val': SleepTimerDuration.min15, 'label': context.tr('min15')},
      {'val': SleepTimerDuration.min30, 'label': context.tr('min30')},
      {'val': SleepTimerDuration.min45, 'label': context.tr('min45')},
      {'val': SleepTimerDuration.min60, 'label': context.tr('min60')},
      {'val': SleepTimerDuration.endOfSong, 'label': context.tr('endOfSong')},
    ];

    return AlertDialog(
      backgroundColor: AppColors.creamCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.bedtime_outlined, color: AppColors.maroonPrimary, size: 26),
          const SizedBox(width: 10),
          Text(
            context.tr('sleepTimer'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.maroonPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final val = opt['val'] as SleepTimerDuration;
          final label = opt['label'] as String;
          final isSelected = activeTimer == val;

          return ListTile(
            title: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.maroonPrimary : AppColors.textDark,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.saffronPrimary)
                : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: () {
              player.setSleepTimer(val);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    val == SleepTimerDuration.off
                        ? context.tr('timerCancelled')
                        : '${context.tr('timerSetFor')} $label',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
