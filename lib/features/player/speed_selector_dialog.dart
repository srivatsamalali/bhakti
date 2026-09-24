import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/audio/audio_player_service.dart';

class SpeedSelectorDialog extends StatelessWidget {
  const SpeedSelectorDialog({super.key});

  static const List<double> speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final currentSpeed = player.playbackSpeed;

    return AlertDialog(
      backgroundColor: AppColors.creamCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.speed, color: AppColors.maroonPrimary, size: 26),
          const SizedBox(width: 10),
          Text(
            context.tr('speed'),
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
        children: speeds.map((speed) {
          final isSelected = (currentSpeed - speed).abs() < 0.01;
          return ListTile(
            title: Text(
              '${speed}x',
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
              player.setPlaybackSpeed(speed);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}
