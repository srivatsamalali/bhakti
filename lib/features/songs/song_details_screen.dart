import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/deity_theme_helper.dart';
import '../../models/song_model.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/ambient_diya_particles.dart';
import '../../widgets/divine_music_visualizer.dart';
import '../player/full_player_screen.dart';

class SongDetailsScreen extends StatefulWidget {
  final SongModel song;

  const SongDetailsScreen({super.key, required this.song});

  @override
  State<SongDetailsScreen> createState() => _SongDetailsScreenState();
}

class _SongDetailsScreenState extends State<SongDetailsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logSongViewed(widget.song.id, widget.song.title);
  }

  Widget _buildCover(String imageUrl) {
    if (imageUrl.startsWith('blob:')) {
      return Image.network(
        imageUrl,
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/lalitha_sahasranamam.jpg',
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.maroonDark),
        errorWidget: (_, __, ___) => Image.asset(
          'assets/images/lalitha_sahasranamam.jpg',
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb) {
      try {
        return Image.file(
          File(imageUrl),
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 240,
            color: AppColors.maroonDark,
            child: const Icon(Icons.music_note, color: AppColors.goldLight, size: 60),
          ),
        );
      } catch (_) {
        return Image.asset('assets/images/lalitha_sahasranamam.jpg', height: 240, width: double.infinity, fit: BoxFit.cover);
      }
    } else {
      return Image.asset('assets/images/lalitha_sahasranamam.jpg', height: 240, width: double.infinity, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();
    final isFav = prefs.isFavorite(widget.song.id);
    final isPlayingThis = player.currentSong?.id == widget.song.id && player.isPlaying;

    final deityTheme = DeityThemeHelper.getThemeForDeity(widget.song.deity);

    return Scaffold(
      backgroundColor: AppColors.subtleBackground,
      appBar: AppBar(
        title: Text(
          widget.song.getLocalizedTitle(currentLang),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.error : AppColors.maroonPrimary,
            ),
            onPressed: () async {
              await prefs.toggleFavorite(widget.song.id);
              AnalyticsService.instance.logSongFavorited(widget.song.id, !isFav);
            },
          ),
          Builder(
            builder: (btnContext) {
              return IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.maroonPrimary),
                onPressed: () {
                  final size = MediaQuery.of(context).size;
                  final box = btnContext.findRenderObject() as RenderBox?;
                  final origin = box != null && box.hasSize
                      ? (box.localToGlobal(Offset.zero) & box.size)
                      : Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2);

                  Share.share(
                    'Listen to "${widget.song.getLocalizedTitle(currentLang)}" on Bhakti app. ${widget.song.description}',
                    sharePositionOrigin: origin,
                  );
                },
              );
            },
          ),
        ],
      ),
      body: AmbientDiyaParticles(
        particleColor: deityTheme.primaryGlow,
        particleCount: 14,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Divine Hero Deity Banner
              Stack(
                children: [
                  _buildCover(widget.song.imageUrl),
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.song.categoryName ?? widget.song.categoryId.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.maroonDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.song.getLocalizedTitle(currentLang),
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.song.getLocalizedDeity(currentLang),
                          style: TextStyle(
                            color: deityTheme.accentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hero Floating Play Button
                  Positioned(
                    bottom: 16,
                    right: 20,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            if (isPlayingThis) {
                              player.pause();
                            } else if (player.currentSong?.id == widget.song.id) {
                              player.resume();
                            } else {
                              player.playSong(widget.song);
                            }
                          },
                          child: Center(
                            child: Icon(
                              isPlayingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: AppColors.maroonDark,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grand Devotional Playback Action Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFDF9), Color(0xFFFFF8EE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.maroonPrimary.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Main Primary Play/Pause Button
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.heroMaroonGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.maroonPrimary.withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        if (isPlayingThis) {
                                          player.pause();
                                        } else if (player.currentSong?.id == widget.song.id) {
                                          player.resume();
                                        } else {
                                          player.playSong(widget.song);
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isPlayingThis ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                            color: AppColors.goldLight,
                                            size: 26,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isPlayingThis
                                                ? (currentLang == 'kn' ? 'ವಿರಾಮ (Pause)' : 'Pause Chanting')
                                                : (currentLang == 'kn' ? 'ಈಗ ಆಲಿಸಿ (Play Now)' : 'Listen Now'),
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Full Player Screen Launcher Button
                              Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2D7C7)),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.open_in_full_rounded, color: AppColors.maroonPrimary, size: 20),
                                  tooltip: 'Open Full Player',
                                  onPressed: () {
                                    if (!isPlayingThis && player.currentSong?.id != widget.song.id) {
                                      player.playSong(widget.song);
                                    }
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Add to Queue Button
                              Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2D7C7)),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.queue_music_rounded, color: AppColors.maroonPrimary, size: 22),
                                  tooltip: 'Add to Queue',
                                  onPressed: () {
                                    player.addToQueue(widget.song);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Added to Queue: ${widget.song.getLocalizedTitle(currentLang)}'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: AppColors.maroonPrimary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          // Live playback status if current track is playing
                          if (player.currentSong?.id == widget.song.id) ...[
                            const SizedBox(height: 12),
                            Divider(color: const Color(0xFFEADBCE).withOpacity(0.6), height: 1),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                DivineMusicVisualizer(
                                  isPlaying: isPlayingThis,
                                  height: 12,
                                  width: 16,
                                  barColor: AppColors.maroonPrimary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: StreamBuilder<Duration>(
                                    stream: player.positionStream,
                                    builder: (context, snapshot) {
                                      final position = snapshot.data ?? Duration.zero;
                                      final total = player.totalDuration ?? Duration.zero;
                                      final posText = '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}';
                                      final totalText = '${total.inMinutes}:${(total.inSeconds % 60).toString().padLeft(2, '0')}';
                                      final progress = total.inMilliseconds > 0 ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0) : 0.0;

                                      return Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(posText, style: const TextStyle(fontSize: 11, color: Color(0xFF7A685D), fontWeight: FontWeight.w600)),
                                              Text(totalText, style: const TextStyle(fontSize: 11, color: Color(0xFF7A685D), fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 4,
                                              backgroundColor: const Color(0xFFEDE3D5),
                                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.maroonPrimary),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metadata Cards (Deity, Duration, Artist)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEADBCE),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMetaRow(
                            context.tr('deity'),
                            widget.song.getLocalizedDeity(currentLang),
                            Icons.spa_outlined,
                          ),
                          const Divider(height: 16, color: Color(0xFFF0E8DD)),
                          _buildMetaRow(
                            context.tr('duration'),
                            widget.song.formattedDuration,
                            Icons.timer_outlined,
                          ),
                          if (widget.song.artist != null && widget.song.artist!.isNotEmpty) ...[
                            const Divider(height: 16, color: Color(0xFFF0E8DD)),
                            _buildMetaRow(
                              context.tr('artist'),
                              widget.song.artist!,
                              Icons.person_outline,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description / Significance
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEADBCE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spiritual Significance',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.maroonPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.song.description,
                            style: AppTypography.bodyLarge.copyWith(
                              height: 1.6,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                  // Sacred Lyrics
                  if (widget.song.lyrics != null && widget.song.lyrics!.isNotEmpty) ...[
                    Text(
                      context.tr('lyrics'),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroonPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.creamSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.goldPrimary.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        widget.song.lyrics!,
                        style: AppTypography.sacredDevotionalText.copyWith(
                          fontSize: 16,
                          height: 1.8,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMetaRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.maroonPrimary, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
