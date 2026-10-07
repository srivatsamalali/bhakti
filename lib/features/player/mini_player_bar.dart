import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/song_model.dart';
import '../../repositories/song_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/divine_music_visualizer.dart';
import '../../widgets/adaptive_button.dart';
import '../../widgets/liquid_glass/glass_style.dart';
import '../../widgets/liquid_glass/liquid_glass.dart';
import '../../widgets/favorite_sparkle_burst.dart';
import 'full_player_screen.dart';

class MiniPlayerBar extends StatefulWidget {
  const MiniPlayerBar({super.key});

  @override
  State<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends State<MiniPlayerBar> with SingleTickerProviderStateMixin {
  double _dragOffsetY = 0.0;
  bool _isNavigating = false;
  bool _isDismissing = false;

  late AnimationController _animController;
  Animation<double>? _snapAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animController.addListener(() {
      if (_snapAnimation != null) {
        setState(() {
          _dragOffsetY = _snapAnimation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openFullPlayer() {
    if (_isNavigating || _isDismissing || !mounted) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => const FullPlayerScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  void _animateSnapBack() {
    if (!mounted) return;
    _snapAnimation = Tween<double>(
      begin: _dragOffsetY,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward(from: 0.0);
  }

  void _animateDismiss(AudioPlayerService player, PreferencesService prefs) {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    HapticFeedback.mediumImpact();

    _snapAnimation = Tween<double>(
      begin: _dragOffsetY,
      end: 120.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInCubic));

    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        prefs.clearLastPlayedSession();
        if (player.currentSong != null) {
          player.stop();
        }
        setState(() {
          _dragOffsetY = 0.0;
          _isDismissing = false;
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildArtwork(String imageUrl, {bool isPlaying = false, double progress = 0.0}) {
    Widget fallback = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: AppColors.heroMaroonGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.wb_sunny, color: AppColors.goldLight, size: 22),
      ),
    );

    Widget imageWidget;
    if (imageUrl.startsWith('blob:')) {
      imageWidget = Image.network(
        imageUrl,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (imageUrl.startsWith('http')) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => fallback,
      );
    } else if (imageUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        imageUrl,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/lalitha_sahasranamam.jpg',
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    } else if (!kIsWeb) {
      try {
        imageWidget = Image.file(
          File(imageUrl),
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        imageWidget = fallback;
      }
    } else {
      imageWidget = fallback;
    }

    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing Circular Gold Progress Ring
          if (progress > 0)
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.2,
                backgroundColor: AppColors.goldPrimary.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
              ),
            ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                if (isPlaying)
                  BoxShadow(
                    color: AppColors.goldPrimary.withOpacity(0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: imageWidget,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePlayTap(SongModel song, bool isLiveAudio, int savedPositionMs, AudioPlayerService player) {
    HapticFeedback.lightImpact();
    if (isLiveAudio) {
      player.togglePlayPause();
    } else {
      player.playSong(song, initialPosition: Duration(milliseconds: savedPositionMs));
    }
  }

  void _handleMiniPlayerTap(SongModel song, bool isLiveAudio, int savedPositionMs, AudioPlayerService player) {
    if (_isDismissing) return;
    if (!isLiveAudio) {
      player.playSong(song, initialPosition: Duration(milliseconds: savedPositionMs));
    }
    _openFullPlayer();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final songRepo = context.watch<SongRepository>();
    final prefs = context.watch<PreferencesService>();

    final isLiveAudio = player.currentSong != null;
    SongModel? song = player.currentSong;
    int savedPositionMs = 0;

    if (song == null) {
      final lastSongId = prefs.getLastPlayedSongId();
      if (lastSongId != null && lastSongId.isNotEmpty) {
        song = songRepo.getSongById(lastSongId);
        savedPositionMs = prefs.getLastPlayedPositionMs();
      }
    }

    if (song == null) return const SizedBox.shrink();

    final activeSong = song;
    final isPlaying = isLiveAudio && player.isPlaying;
    final isFav = prefs.isFavorite(activeSong.id);
    final currentLang = prefs.getSelectedLanguage();

    final double opacity = _isDismissing
        ? (1.0 - (_dragOffsetY / 120.0)).clamp(0.0, 1.0)
        : (1.0 - (_dragOffsetY / 250.0)).clamp(0.4, 1.0);
    final double scale = (1.0 - (_dragOffsetY / 1000.0)).clamp(0.92, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;

        return Transform.translate(
          offset: Offset(0, _dragOffsetY.clamp(0.0, 160.0)),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleMiniPlayerTap(activeSong, isLiveAudio, savedPositionMs, player),
                onVerticalDragStart: (_) {
                  if (_isDismissing) return;
                  _animController.stop();
                },
                onVerticalDragUpdate: (details) {
                  if (_isDismissing) return;
                  final dy = details.primaryDelta ?? 0;
                  setState(() {
                    if (_dragOffsetY + dy > 0) {
                      _dragOffsetY += dy * 0.85;
                    } else {
                      _dragOffsetY += dy * 0.35;
                    }
                  });
                },
                onVerticalDragEnd: (details) {
                  if (_isDismissing) return;
                  final velocity = details.primaryVelocity ?? 0;

                  // Swiped up fast -> Open Full Player
                  if (velocity < -300 || _dragOffsetY < -25) {
                    _animateSnapBack();
                    _handleMiniPlayerTap(activeSong, isLiveAudio, savedPositionMs, player);
                    return;
                  }

                  // Pulled down past threshold OR flicked down -> Dismiss & stop music
                  if (_dragOffsetY > 38 || velocity > 320) {
                    _animateDismiss(player, prefs);
                  } else {
                    // Pulled back or threshold not crossed -> Snap smoothly back into place!
                    _animateSnapBack();
                  }
                },
                onVerticalDragCancel: () {
                  if (!_isDismissing) {
                    _animateSnapBack();
                  }
                },
                child: LiquidGlass(
                  style: isDesktop ? GlassStyle.toolbar : GlassStyle.sheet,
                  tint: AppColors.goldPrimary,
                  cornerRadius: isDesktop ? 0 : 18,
                  margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Slim Progress Scrubbing Bar (Sacred Maroon / Gold Progress Line)
                      if (isLiveAudio)
                        StreamBuilder<Duration>(
                          stream: player.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final total = player.totalDuration ?? Duration(seconds: activeSong.duration > 0 ? activeSong.duration : 1);
                            final ratio = total.inMilliseconds > 0
                                ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                                : 0.0;

                            return GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                final box = context.findRenderObject() as RenderBox?;
                                if (box != null && total.inMilliseconds > 0) {
                                  final localX = details.localPosition.dx.clamp(0.0, box.size.width);
                                  final seekRatio = localX / box.size.width;
                                  player.seek(Duration(milliseconds: (total.inMilliseconds * seekRatio).toInt()));
                                }
                              },
                              child: LinearProgressIndicator(
                                value: ratio,
                                backgroundColor: AppColors.goldPrimary.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.maroonPrimary),
                                minHeight: 3.0,
                              ),
                            );
                          },
                        )
                      else
                        LinearProgressIndicator(
                          value: (activeSong.duration > 0 ? (savedPositionMs / 1000) / activeSong.duration : 0.0).clamp(0.0, 1.0),
                          backgroundColor: AppColors.goldPrimary.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.maroonPrimary),
                          minHeight: 3.0,
                        ),

                      // Main Liquid Glass Player Body
                      Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: isDesktop
                            ? Row(
                                children: [
                                  // --- LEFT: Controls & Time ---
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.skip_previous_rounded, color: AppColors.maroonPrimary, size: 28),
                                        tooltip: 'Previous Track',
                                        onPressed: isLiveAudio ? () => player.playPrevious() : null,
                                      ),
                                      AdaptiveIconButton(
                                        size: 44,
                                        isPrimary: true,
                                        backgroundColor: AppColors.maroonPrimary,
                                        icon: Icon(
                                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          size: 28,
                                        ),
                                        tooltip: isPlaying ? 'Pause' : 'Play',
                                        onPressed: () => _handlePlayTap(activeSong, isLiveAudio, savedPositionMs, player),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.skip_next_rounded, color: AppColors.maroonPrimary, size: 28),
                                        tooltip: 'Next Track',
                                        onPressed: isLiveAudio ? () => player.playNext() : null,
                                      ),
                                      const SizedBox(width: 8),
                                      if (isLiveAudio)
                                        StreamBuilder<Duration>(
                                          stream: player.positionStream,
                                          builder: (context, snapshot) {
                                            final position = snapshot.data ?? Duration.zero;
                                            final total = player.totalDuration ?? Duration(seconds: activeSong.duration > 0 ? activeSong.duration : 1);
                                            return Text(
                                              '${_formatDuration(position)} / ${_formatDuration(total)}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF7A685D),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                        )
                                      else
                                        Text(
                                          '${_formatDuration(Duration(milliseconds: savedPositionMs))} / ${_formatDuration(Duration(seconds: activeSong.duration))}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF7A685D),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(width: 16),

                                  // --- CENTER: Artwork & Title & Details ---
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _handleMiniPlayerTap(activeSong, isLiveAudio, savedPositionMs, player),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Row(
                                        children: [
                                          if (isLiveAudio)
                                            StreamBuilder<Duration>(
                                              stream: player.positionStream,
                                              builder: (context, snapshot) {
                                                final position = snapshot.data ?? Duration.zero;
                                                final total = player.totalDuration ?? Duration(seconds: activeSong.duration > 0 ? activeSong.duration : 1);
                                                final ratio = total.inMilliseconds > 0
                                                    ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                                                    : 0.0;
                                                return _buildArtwork(
                                                  activeSong.imageUrl,
                                                  isPlaying: isPlaying,
                                                  progress: ratio,
                                                );
                                              },
                                            )
                                          else
                                            _buildArtwork(
                                              activeSong.imageUrl,
                                              isPlaying: false,
                                              progress: (activeSong.duration > 0 ? (savedPositionMs / 1000) / activeSong.duration : 0.0).clamp(0.0, 1.0),
                                            ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    if (isPlaying) ...[
                                                      const DivineMusicVisualizer(
                                                        isPlaying: true,
                                                        height: 14,
                                                        width: 16,
                                                        barColor: AppColors.maroonPrimary,
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    Flexible(
                                                      child: Text(
                                                        activeSong.getLocalizedTitle(currentLang),
                                                        style: const TextStyle(
                                                          fontSize: 15.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.textDark,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${activeSong.getLocalizedDeity(currentLang)} • ${activeSong.formattedDuration}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF7A685D),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          FavoriteSparkleBurst(
                                            key: ValueKey('mini_d_fav_${activeSong.id}'),
                                            isFavorited: isFav,
                                            size: 22,
                                            activeColor: AppColors.error,
                                            inactiveColor: const Color(0xFF8B776A),
                                            onTap: () async {
                                              await prefs.toggleFavorite(activeSong.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // --- RIGHT: Controls & Expand Button ---
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isLiveAudio) ...[
                                        IconButton(
                                          icon: Icon(
                                            player.loopMode == LoopMode.all
                                                ? Icons.repeat_rounded
                                                : (player.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded),
                                            color: player.loopMode != LoopMode.off ? AppColors.maroonPrimary : const Color(0xFF8B776A),
                                            size: 22,
                                          ),
                                          tooltip: 'Repeat',
                                          onPressed: () => player.toggleLoopMode(),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.shuffle_rounded,
                                            color: player.isShuffleEnabled ? AppColors.maroonPrimary : const Color(0xFF8B776A),
                                            size: 22,
                                          ),
                                          tooltip: 'Shuffle',
                                          onPressed: () => player.toggleShuffle(),
                                        ),
                                      ],
                                      IconButton(
                                        icon: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.maroonPrimary, size: 28),
                                        tooltip: 'Expand Player',
                                        onPressed: () => _handleMiniPlayerTap(activeSong, isLiveAudio, savedPositionMs, player),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  // Mobile Layout: [Artwork + Title/Artist + Last Played Minutes] + [Favorite] + [Play/Pause] + [Expand]
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _handleMiniPlayerTap(activeSong, isLiveAudio, savedPositionMs, player),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Row(
                                        children: [
                                          if (isLiveAudio)
                                            StreamBuilder<Duration>(
                                              stream: player.positionStream,
                                              builder: (context, snapshot) {
                                                final position = snapshot.data ?? Duration.zero;
                                                final total = player.totalDuration ?? Duration(seconds: activeSong.duration > 0 ? activeSong.duration : 1);
                                                final ratio = total.inMilliseconds > 0
                                                    ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                                                    : 0.0;
                                                return _buildArtwork(
                                                  activeSong.imageUrl,
                                                  isPlaying: isPlaying,
                                                  progress: ratio,
                                                );
                                              },
                                            )
                                          else
                                            _buildArtwork(
                                              activeSong.imageUrl,
                                              isPlaying: false,
                                              progress: (activeSong.duration > 0 ? (savedPositionMs / 1000) / activeSong.duration : 0.0).clamp(0.0, 1.0),
                                            ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    if (isPlaying) ...[
                                                      const DivineMusicVisualizer(
                                                        isPlaying: true,
                                                        height: 12,
                                                        width: 14,
                                                        barColor: AppColors.maroonPrimary,
                                                      ),
                                                      const SizedBox(width: 6),
                                                    ],
                                                    Flexible(
                                                      child: Text(
                                                        activeSong.getLocalizedTitle(currentLang),
                                                        style: const TextStyle(
                                                          fontSize: 14.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.textDark,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                if (isLiveAudio)
                                                  StreamBuilder<Duration>(
                                                    stream: player.positionStream,
                                                    builder: (context, snapshot) {
                                                      final position = snapshot.data ?? Duration.zero;
                                                      final total = player.totalDuration ?? Duration(seconds: activeSong.duration > 0 ? activeSong.duration : 1);
                                                      return Text(
                                                        '${activeSong.getLocalizedDeity(currentLang)} • ${_formatDuration(position)} / ${_formatDuration(total)}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(0xFF7A685D),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      );
                                                    },
                                                  )
                                                else
                                                  Text(
                                                    '${activeSong.getLocalizedDeity(currentLang)} • ${_formatDuration(Duration(milliseconds: savedPositionMs))} / ${_formatDuration(Duration(seconds: activeSong.duration))}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF7A685D),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  FavoriteSparkleBurst(
                                    key: ValueKey('mini_fav_${activeSong.id}'),
                                    isFavorited: isFav,
                                    size: 22,
                                    activeColor: AppColors.error,
                                    inactiveColor: const Color(0xFF8B776A),
                                    onTap: () async {
                                      await prefs.toggleFavorite(activeSong.id);
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  AdaptiveIconButton(
                                    size: 40,
                                    isPrimary: true,
                                    backgroundColor: AppColors.maroonPrimary,
                                    icon: Icon(
                                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      size: 24,
                                    ),
                                    tooltip: isPlaying ? 'Pause' : 'Play',
                                    onPressed: () => _handlePlayTap(activeSong, isLiveAudio, savedPositionMs, player),
                                  ),
                                  const SizedBox(width: 2),
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.maroonPrimary, size: 26),
                                    tooltip: 'Expand Player',
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _handleMiniPlayerTap(activeSong, isLiveAudio, savedPositionMs, player),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
