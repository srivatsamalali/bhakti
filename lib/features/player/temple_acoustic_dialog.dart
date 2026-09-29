import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/audio/audio_player_service.dart';

class TempleAcousticDialog extends StatelessWidget {
  const TempleAcousticDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();

    final presets = [
      (
        TempleAcousticMode.pureStudio,
        'Pure Studio (Standard)',
        'Crystal clear original studio recording',
        Icons.music_note_rounded,
      ),
      (
        TempleAcousticMode.garbhagrihaEcho,
        'Garbhagriha Sanctum Echo',
        'Deep sacred stone sanctum resonance & gentle reverb',
        Icons.temple_hindu_rounded,
      ),
      (
        TempleAcousticMode.templeHall,
        'Temple Mandapa Hall',
        'Spacious open courtyard acoustics with ambient warmth',
        Icons.surround_sound_rounded,
      ),
      (
        TempleAcousticMode.vedicResonance,
        'Vedic Deep Resonance',
        'Traditional measured cadence with warm bass vibrations',
        Icons.wb_sunny_rounded,
      ),
      (
        TempleAcousticMode.soothingMeditation,
        'Soothing Dhyana Meditation',
        'Slow, deeply peaceful pacing for deep focus & sleep',
        Icons.spa_rounded,
      ),
    ];

    return AlertDialog(
      backgroundColor: const Color(0xFF1E070A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x44D4AF37), width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.surround_sound_rounded, color: AppColors.goldLight, size: 22),
          SizedBox(width: 10),
          Text(
            'Temple Acoustic Ambiance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: presets.map((preset) {
            final isSelected = player.acousticMode == preset.$1;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.goldPrimary.withOpacity(0.18) : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.goldLight : Colors.white12,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(preset.$4, color: isSelected ? AppColors.goldLight : Colors.white60),
                title: Text(
                  preset.$2,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? AppColors.goldLight : Colors.white,
                  ),
                ),
                subtitle: Text(
                  preset.$3,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.goldLight, size: 20)
                    : null,
                onTap: () {
                  player.setTempleAcousticMode(preset.$1);
                  Navigator.of(context).pop();
                },
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: AppColors.goldLight)),
        ),
      ],
    );
  }
}
