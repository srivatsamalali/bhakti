import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/temple_theme.dart';
import '../../../repositories/song_repository.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../services/preferences/preferences_service.dart';
import '../../../services/wisdom/special_day_intelligence_service.dart';
import '../../../widgets/sacred_filigree_border.dart';

/// Breathtaking Golden Sanctum Modal for Auspicious Special Days & Festivals
class SpecialDayModalDialog extends StatelessWidget {
  final SpecialDayInfo info;

  const SpecialDayModalDialog({
    super.key,
    required this.info,
  });

  static Future<void> show(BuildContext context, SpecialDayInfo info) {
    HapticFeedback.mediumImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => SpecialDayModalDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final templeTheme = TempleTheme.fromId(prefs.getTempleThemeId());
    final songRepo = context.watch<SongRepository>();
    final player = context.watch<AudioPlayerService>();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFDF9),
              Color(0xFFFAF3E5),
            ],
          ),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB8860B).withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SacredCornerFiligree(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFFD4AF37),
          cornerSize: 24,
          strokeWidth: 1.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header Ribbon ---
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFE8D7B8).withOpacity(0.8),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B1E1E), Color(0xFF5E1010)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B1E1E).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFDF7A), size: 14),
                          const SizedBox(width: 5),
                          Text(
                            info.badgeText,
                            style: const TextStyle(
                              color: Color(0xFFFFF9EE),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Close 'X' Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1E1E).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B4533)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Scrollable Body ---
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Festival Main Title
                      Text(
                        info.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4A1A12),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A654C),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Presiding Deity Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4DC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2C482), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.temple_hindu_rounded, size: 18, color: Color(0xFF8B1E1E)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                info.deity,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5A1E14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Significance Card
                      const Text(
                        'ಪಾವಿತ್ರ್ಯತೆ & ಮಹತ್ವ • Significance',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        info.significance,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Color(0xFF33241C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rituals & Seva
                      const Text(
                        'ಇಂದಿನ ಪವಿತ್ರ ಆಚರಣೆಗಳು • Auspicious Rituals',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...info.rituals.map(
                        (ritual) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4, right: 8),
                                child: Icon(Icons.brightness_7_rounded, size: 12, color: Color(0xFFD4AF37)),
                              ),
                              Expanded(
                                child: Text(
                                  ritual,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF422D22),
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Sacred Mantra Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF1DF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF8B1E1E)),
                                const SizedBox(width: 6),
                                const Text(
                                  'ದಿನದ ಪವಿತ್ರ ಜಪ ಮಂತ್ರ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B1E1E),
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: info.mantra));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('ಮಂತ್ರ ನಕಲಿಸಲಾಗಿದೆ (Copied to clipboard)'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF7A5844)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              info.mantra,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C1810),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Recommended Stotram 1-Tap Play
                      if (info.recommendedStotram != null) ...[
                        const SizedBox(height: 14),
                        Builder(
                          builder: (context) {
                            final targetSong = songRepo.allSongs.firstWhere(
                              (s) =>
                                  s.title.toLowerCase().contains(info.recommendedStotram!.toLowerCase()) ||
                                  info.recommendedStotram!.toLowerCase().contains(s.title.toLowerCase()),
                              orElse: () => songRepo.allSongs.first,
                            );

                            return InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                player.playSong(targetSong);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: templeTheme.heroGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: templeTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'ಇಂದಿನ ಪವಿತ್ರ ಸ್ತೋತ್ರ ಆಲಿಸಿ',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFFFE8D6),
                                            ),
                                          ),
                                          Text(
                                            targetSong.title,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // --- Bottom Action Button ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B1D1D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'ದರ್ಶನ ಸ್ವೀಕರಿಸಿ • ಶುಭ ದಿನ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
