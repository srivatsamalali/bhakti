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
      {'val': SleepTimerDuration.off, 'label': context.tr('timerOff'), 'desc': 'Turn off timer'},
      {'val': SleepTimerDuration.min15, 'label': context.tr('min15'), 'desc': '15 minutes'},
      {'val': SleepTimerDuration.min30, 'label': context.tr('min30'), 'desc': '30 minutes'},
      {'val': SleepTimerDuration.min45, 'label': context.tr('min45'), 'desc': '45 minutes'},
      {'val': SleepTimerDuration.min60, 'label': context.tr('min60'), 'desc': '60 minutes'},
      {'val': SleepTimerDuration.endOfSong, 'label': context.tr('endOfSong'), 'desc': 'When track finishes'},
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.creamCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.goldPrimary.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.maroonPrimary.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.maroonPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bedtime_rounded, color: AppColors.maroonPrimary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('sleepTimer'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroonPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final val = opt['val'] as SleepTimerDuration;
              final label = opt['label'] as String;
              final isSelected = activeTimer == val;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.maroonPrimary.withOpacity(0.08)
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.goldPrimary
                              : AppColors.goldPrimary.withOpacity(0.15),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.maroonPrimary : AppColors.textDark,
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.saffronPrimary, size: 20)
                          else
                            Icon(Icons.radio_button_unchecked, color: AppColors.goldDark.withOpacity(0.35), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

