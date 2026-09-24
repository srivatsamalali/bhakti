import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/song_model.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import 'queue_sheet.dart';
import 'sleep_timer_dialog.dart';
import 'speed_selector_dialog.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  bool _showLyrics = false;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildArtwork(SongModel song) {
    Widget imageWidget;
    if (song.imageUrl.startsWith('blob:')) {
      imageWidget = Image.network(
        song.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/lalitha_sahasranamam.jpg',
          fit: BoxFit.cover,
        ),
      );
    } else if (song.imageUrl.startsWith('http')) {
      imageWidget = CachedNetworkImage(
        imageUrl: song.imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: AppColors.maroonDark,
          child: const Center(
            child: Icon(Icons.music_note, color: AppColors.goldLight, size: 64),
          ),
        ),
        errorWidget: (_, __, ___) => Image.asset(
          'assets/images/lalitha_sahasranamam.jpg',
          fit: BoxFit.cover,
        ),
      );
    } else if (song.imageUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        song.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.maroonDark,
          child: const Icon(Icons.music_note, color: AppColors.goldLight, size: 64),
        ),
      );
    } else if (!kIsWeb) {
      try {
        imageWidget = Image.file(
          File(song.imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.maroonDark,
            child: const Icon(Icons.music_note, color: AppColors.goldLight, size: 64),
          ),
        );
      } catch (_) {
        imageWidget = Image.asset('assets/images/lalitha_sahasranamam.jpg', fit: BoxFit.cover);
      }
    } else {
      imageWidget = Image.asset('assets/images/lalitha_sahasranamam.jpg', fit: BoxFit.cover);
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 340),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldLight.withOpacity(0.22),
            blurRadius: 28,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: AppColors.goldPrimary.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: imageWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final song = player.currentSong;
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();

    if (song == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 32, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            context.tr('noSongsAvailable'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final isFav = prefs.isFavorite(song.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          // Swipe down to dismiss player
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
        onHorizontalDragEnd: (details) {
          // Swipe left -> Next chant, Swipe right -> Previous chant
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -250) {
              player.playNext();
            } else if (details.primaryVelocity! > 250) {
              player.playPrevious();
            }
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.playerBackgroundGradient,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SafeArea(
                child: Column(
                  children: [
                    // Top Bar with Minimize, Title, and Share
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down, size: 36, color: Colors.white),
                            tooltip: 'Swipe down or tap to minimize',
                            onPressed: () => Navigator.pop(context),
                          ),
                          Column(
                            children: [
                              Text(
                                context.tr('nowPlaying').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2.0,
                                  color: AppColors.goldLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.categoryName ?? song.categoryId.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 24),
                            onPressed: () {
                              Share.share(
                                'Listening to divine devotional hymn "${song.getLocalizedTitle(currentLang)}" on Bhakti app. May it bring peace and blessings!',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Main Body: Artwork or Lyrics View
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _showLyrics
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.darkSurface.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.goldPrimary.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          context.tr('lyrics'),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.goldLight,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white70),
                                          onPressed: () {
                                            setState(() {
                                              _showLyrics = false;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const Divider(color: Colors.white24),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Text(
                                          song.lyrics ?? context.tr('noLyricsAvailable'),
                                          style: AppTypography.sacredDevotionalText.copyWith(
                                            color: AppColors.textLight,
                                            fontSize: 16,
                                            height: 1.9,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildArtwork(song),
                                    const SizedBox(height: 18),

                                    // Song Title & Deity
                                    Text(
                                      song.getLocalizedTitle(currentLang),
                                      style: AppTypography.titleLarge.copyWith(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      song.getLocalizedDeity(currentLang),
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontSize: 15,
                                        color: AppColors.goldLight,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (song.artist != null && song.artist!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        song.artist!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white60,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                      ),
                    ),

              const SizedBox(height: 12),

              // Progress Bar & Durations
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final total = player.totalDuration ?? Duration(seconds: song.duration);
                    final maxSec = total.inSeconds > 0 ? total.inSeconds.toDouble() : 1.0;
                    final currentSec = position.inSeconds.toDouble().clamp(0.0, maxSec);

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                            activeTrackColor: AppColors.goldLight,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            overlayColor: AppColors.goldLight.withOpacity(0.3),
                          ),
                          child: Slider(
                            value: currentSec,
                            max: maxSec,
                            onChanged: (val) {
                              player.seek(Duration(seconds: val.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                _formatDuration(total),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Primary Playback Controls: Prev, Seek -15, Play/Pause, Seek +15, Next
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36, color: Colors.white),
                      onPressed: () => player.playPrevious(),
                    ),

                    // Seek Backward 15s
                    IconButton(
                      icon: const Icon(Icons.rotate_left, size: 32, color: Colors.white),
                      tooltip: context.tr('seekBackward15'),
                      onPressed: () => player.seekBackward15(),
                    ),

                    // Play / Pause (Sacred Radiant Diya Style)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldLight.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: const EdgeInsets.all(16),
                        iconSize: 42,
                        icon: Icon(
                          player.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppColors.maroonDark,
                        ),
                        onPressed: () => player.togglePlayPause(),
                      ),
                    ),

                    // Seek Forward 15s
                    IconButton(
                      icon: const Icon(Icons.rotate_right, size: 32, color: Colors.white),
                      tooltip: context.tr('seekForward15'),
                      onPressed: () => player.seekForward15(),
                    ),

                    // Next
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 36, color: Colors.white),
                      onPressed: () => player.playNext(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Secondary Controls: Shuffle, Repeat, Speed, Sleep Timer, Lyrics, Queue, Favorite
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: player.isShuffleEnabled ? AppColors.goldLight : Colors.white60,
                        size: 22,
                      ),
                      tooltip: context.tr('shuffle'),
                      onPressed: () => player.toggleShuffle(),
                    ),

                    // Repeat
                    IconButton(
                      icon: Icon(
                        player.loopMode == LoopMode.one
                            ? Icons.repeat_one
                            : (player.loopMode == LoopMode.all ? Icons.repeat : Icons.repeat),
                        color: player.loopMode != LoopMode.off
                            ? AppColors.goldLight
                            : Colors.white60,
                        size: 22,
                      ),
                      onPressed: () => player.toggleLoopMode(),
                    ),

                    // Playback Speed
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const SpeedSelectorDialog(),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: player.playbackSpeed != 1.0
                                ? AppColors.goldLight
                                : Colors.white38,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${player.playbackSpeed}x',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: player.playbackSpeed != 1.0
                                ? AppColors.goldLight
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),

                    // Sleep Timer
                    IconButton(
                      icon: Icon(
                        Icons.bedtime_outlined,
                        color: player.activeSleepTimer != SleepTimerDuration.off
                            ? AppColors.goldLight
                            : Colors.white60,
                        size: 22,
                      ),
                      tooltip: context.tr('sleepTimer'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const SleepTimerDialog(),
                        );
                      },
                    ),

                    // Lyrics Toggle
                    IconButton(
                      icon: Icon(
                        Icons.menu_book_outlined,
                        color: _showLyrics ? AppColors.goldLight : Colors.white60,
                        size: 22,
                      ),
                      tooltip: context.tr('lyrics'),
                      onPressed: () {
                        setState(() {
                          _showLyrics = !_showLyrics;
                        });
                      },
                    ),

                    // Queue
                    IconButton(
                      icon: const Icon(Icons.queue_music, color: Colors.white70, size: 24),
                      tooltip: context.tr('queue'),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const QueueSheet(),
                        );
                      },
                    ),

                    // Favorite
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppColors.error : Colors.white70,
                        size: 24,
                      ),
                      onPressed: () async {
                        await prefs.toggleFavorite(song.id);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    ),
    ),
    ),
    );
  }
}
