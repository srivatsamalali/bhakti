import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/deity_theme_helper.dart';
import '../../models/song_model.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/audio/offline_download_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/ambient_diya_particles.dart';
import '../../widgets/adaptive_button.dart';
import '../../widgets/divine_music_visualizer.dart';
import '../../widgets/devotional_waveform_bar.dart';
import '../../widgets/sacred_mandala_aura.dart';
import 'ab_looper_sheet.dart';
import 'queue_sheet.dart';
import 'sleep_timer_dialog.dart';
import 'speed_selector_dialog.dart';
import 'temple_acoustic_dialog.dart';
import '../wallpaper/sacred_wallpaper_generator_dialog.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> with TickerProviderStateMixin {
  bool _showLyricsSheet = false;
  String? _selectedLyricsLang;
  bool _isDisliked = false;
  double _verticalDragOffset = 0;
  bool _dragActionTriggered = false;
  late final AnimationController _mandalaController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _mandalaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mandalaController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildArtworkImage(SongModel song) {
    Widget fallback = Container(
      color: AppColors.maroonDark,
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: AppColors.goldLight, size: 72),
      ),
    );

    if (song.imageUrl.startsWith('blob:')) {
      return Image.network(
        song.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (song.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: song.imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    } else if (song.imageUrl.startsWith('assets/')) {
      return Image.asset(
        song.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (!kIsWeb) {
      try {
        return Image.file(
          File(song.imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  void _showMoreOptions(BuildContext context, AudioPlayerService player, SongModel song) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1410).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.temple_hindu_rounded, color: AppColors.goldLight),
                title: const Text('Temple Acoustic Ambiance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  player.acousticMode == TempleAcousticMode.pureStudio
                      ? 'Studio Sound'
                      : 'Active: ${player.acousticMode.name}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const TempleAcousticDialog());
                },
              ),
              ListTile(
                leading: const Icon(Icons.repeat_on_rounded, color: AppColors.goldLight),
                title: const Text('A-B Stanza Memorization Looper', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AbLooperSheet(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed_rounded, color: AppColors.goldLight),
                title: const Text('Playback Speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                trailing: Text('${player.playbackSpeed}x', style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const SpeedSelectorDialog());
                },
              ),
              ListTile(
                leading: const Icon(Icons.bedtime_outlined, color: AppColors.goldLight),
                title: const Text('Sleep Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const SleepTimerDialog());
                },
              ),
              ListTile(
                leading: const Icon(Icons.wallpaper_rounded, color: AppColors.goldLight),
                title: const Text('Make Sacred Story & Poster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Generate 4K wallpaper for Status & Stories', style: TextStyle(color: Colors.white60, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  SacredWallpaperGeneratorDialog.show(
                    context,
                    song: song,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded, color: AppColors.goldLight),
                title: const Text('Up Next / Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const QueueSheet(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSaveToPlaylistDialog(BuildContext context, PreferencesService prefs, SongModel song, String currentLang) {
    HapticFeedback.lightImpact();
    final playlists = prefs.getPlaylistNames();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFDF9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFECD7B8), width: 1.5),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.maroonPrimary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.playlist_add_rounded, color: AppColors.maroonPrimary, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Save to Playlist',
                    style: TextStyle(color: AppColors.maroonPrimary, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New playlist text field
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: 'New playlist name (e.g. Daily Chants)...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8D7B6F)),
                        prefixIcon: const Icon(Icons.create_new_folder_outlined, color: AppColors.maroonPrimary, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF6EFE6),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final name = textController.text.trim();
                        if (name.isNotEmpty) {
                          await prefs.createPlaylist(name);
                          await prefs.addSongToPlaylist(name, song.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Saved "${song.getLocalizedTitle(currentLang)}" to playlist "$name"! 📿'),
                                backgroundColor: AppColors.maroonPrimary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Create & Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.maroonPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    if (playlists.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Existing Playlists:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B584C)),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: playlists.length,
                          itemBuilder: (_, index) {
                            final pName = playlists[index];
                            final containsSong = prefs.getCustomPlaylists()[pName]?.contains(song.id) ?? false;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: Icon(
                                containsSong ? Icons.check_circle_rounded : Icons.folder_outlined,
                                color: containsSong ? Colors.green : AppColors.maroonPrimary,
                                size: 20,
                              ),
                              title: Text(pName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                              trailing: containsSong
                                  ? const Text('Added', style: TextStyle(color: Colors.green, fontSize: 11.5, fontWeight: FontWeight.bold))
                                  : TextButton(
                                      onPressed: () async {
                                        await prefs.addSongToPlaylist(pName, song.id);
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Added "${song.getLocalizedTitle(currentLang)}" to "$pName"! 📿'),
                                              backgroundColor: AppColors.maroonPrimary,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroonPrimary)),
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF7A685D))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _shareCurrentSong(BuildContext context, SongModel song, String currentLang) async {
    HapticFeedback.lightImpact();
    final size = MediaQuery.of(context).size;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? (box.localToGlobal(Offset.zero) & box.size)
        : Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2);

    final title = song.getLocalizedTitle(currentLang);
    final deity = song.getLocalizedDeity(currentLang);

    await Share.share(
      '🕉️ Listening to divine chant "$title" ($deity) on Bhakti Devotional App. May peace, health, and divine blessings reach you! 🙏\n\nExperience high-quality spiritual stotras on Bhakti.',
      subject: title,
      sharePositionOrigin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final song = player.currentSong;
    final prefs = context.watch<PreferencesService>();
    final downloadService = context.watch<OfflineDownloadService>();
    final currentLang = prefs.getSelectedLanguage();

    if (song == null) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9),
        body: const Center(
          child: Text('No song playing', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final isFav = prefs.isFavorite(song.id);
    final isDownloaded = downloadService.isDownloaded(song.id);
    final isDownloading = downloadService.isDownloading(song.id);
    final deityTheme = DeityThemeHelper.getThemeForDeity(song.deity);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Frosted Glass Blur Background with transparent ambient gradients
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF101924).withOpacity(0.92),
                      const Color(0xFF18202A).withOpacity(0.94),
                      const Color(0xFF0D141C).withOpacity(0.97),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Subtle Calming Ambient Glow
          Positioned.fill(
            child: AmbientDiyaParticles(
              particleColor: deityTheme.accentColor,
              particleCount: 5,
              child: const SizedBox.expand(),
            ),
          ),

          // Main YouTube Music-style Player Screen with Vertical Gestures (Swipe down to minimize, Swipe up for Up Next)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (_) {
              _verticalDragOffset = 0;
              _dragActionTriggered = false;
            },
            onVerticalDragUpdate: (details) {
              if (_dragActionTriggered) return;
              _verticalDragOffset += details.primaryDelta ?? 0;

              // Swipe DOWN: minimize / close full player
              if (_verticalDragOffset > 35) {
                _dragActionTriggered = true;
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              }
              // Swipe UP: open Up Next queue sheet
              else if (_verticalDragOffset < -35) {
                _dragActionTriggered = true;
                HapticFeedback.lightImpact();
                _showUpNextQueueSheet(context, player, currentLang);
              }
            },
            onVerticalDragEnd: (details) {
              if (_dragActionTriggered) return;
              final velocity = details.primaryVelocity ?? 0;

              if (velocity > 100 || _verticalDragOffset > 20) {
                _dragActionTriggered = true;
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              } else if (velocity < -100 || _verticalDragOffset < -20) {
                _dragActionTriggered = true;
                HapticFeedback.lightImpact();
                _showUpNextQueueSheet(context, player, currentLang);
              }
              _verticalDragOffset = 0;
            },
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final isDesktop = constraints.maxWidth >= 700;
                  final maxArtSize = (availableHeight * 0.38).clamp(150.0, 330.0);

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 480 : double.infinity,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // --- TOP BAR: [Chevron Down] + [Spacer] + [Cast & More] ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Minimize Chevron Down
                                IconButton(
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 34, color: Colors.white),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                  },
                                ),

                                const Spacer(),

                                // Cast & Overflow 3-dots Menu
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.cast_rounded, size: 22, color: Colors.white),
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Searching for Google Cast & AirPlay speakers... 📡'),
                                            backgroundColor: const Color(0xFF1E2630),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert_rounded, size: 24, color: Colors.white),
                                      padding: const EdgeInsets.only(left: 6),
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _showMoreOptions(context, player, song),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const Spacer(flex: 1),

                            // --- MAIN ALBUM ARTWORK WITH SACRED MANDALA AURA ---
                            Flexible(
                              flex: 12,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: maxArtSize,
                                    maxWidth: maxArtSize,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Rotating Sacred Chakra Mandala Aura
                                        SacredMandalaAura(
                                          isPlaying: player.isPlaying,
                                          rotationAnimation: _mandalaController,
                                          glowAnimation: _glowController,
                                          auraColor: deityTheme.accentColor,
                                        ),

                                        // Main Artwork Card with dynamic aura shadow
                                        Container(
                                          margin: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.5),
                                                blurRadius: 24,
                                                offset: const Offset(0, 10),
                                              ),
                                              BoxShadow(
                                                color: deityTheme.accentColor.withOpacity(player.isPlaying ? 0.35 : 0.15),
                                                blurRadius: 20,
                                                spreadRadius: player.isPlaying ? 3 : 1,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(18),
                                            child: _buildArtworkImage(song),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(flex: 1),

                            // --- SONG TITLE, DEITY & LIVE AUDIO WAVEFORM ROW ---
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() => _showLyricsSheet = true);
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                song.getLocalizedTitle(currentLang),
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 24),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${song.getLocalizedDeity(currentLang)}${song.categoryName != null ? ' • ${song.categoryName}' : ''}',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.65),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Dynamic Audio Waveform Spectrum Bar
                                DevotionalWaveformBar(
                                  isPlaying: player.isPlaying,
                                  barCount: 16,
                                  height: 22,
                                  primaryColor: deityTheme.accentColor,
                                  secondaryColor: AppColors.goldPrimary,
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // --- HORIZONTAL ACTION PILLS CAROUSEL ---
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  // 1. Like & Dislike Compound Pill
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                                          onTap: () async {
                                            HapticFeedback.selectionClick();
                                            await prefs.toggleFavorite(song.id);
                                            setState(() => _isDisliked = false);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isFav ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                                  size: 18,
                                                  color: isFav ? AppColors.goldLight : Colors.white,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '22k',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: isFav ? AppColors.goldLight : Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, height: 18, color: Colors.white24),
                                        InkWell(
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(22)),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() => _isDisliked = !_isDisliked);
                                            if (isFav) prefs.toggleFavorite(song.id);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Icon(
                                              _isDisliked ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                                              size: 18,
                                              color: _isDisliked ? Colors.redAccent : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // 2. Lyrics Pill
                                  _buildActionPill(
                                    icon: Icons.format_quote_rounded,
                                    label: 'Lyrics',
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() => _showLyricsSheet = true);
                                    },
                                  ),

                                  const SizedBox(width: 10),

                                  // 3. Save to Playlist Pill
                                  _buildActionPill(
                                    icon: Icons.playlist_add_rounded,
                                    label: 'Save',
                                    onTap: () => _showSaveToPlaylistDialog(context, prefs, song, currentLang),
                                  ),

                                  const SizedBox(width: 10),

                                  // 4. Share Pill
                                  Builder(
                                    builder: (btnCtx) {
                                      return _buildActionPill(
                                        icon: Icons.share_outlined,
                                        label: 'Share',
                                        onTap: () => _shareCurrentSong(btnCtx, song, currentLang),
                                      );
                                    },
                                  ),

                                  const SizedBox(width: 10),

                                  // 5. Download Pill
                                  _buildActionPill(
                                    icon: isDownloaded
                                        ? Icons.check_circle_rounded
                                        : (isDownloading ? Icons.hourglass_top_rounded : Icons.download_rounded),
                                    label: isDownloaded ? 'Downloaded' : (isDownloading ? 'Downloading...' : 'Download'),
                                    iconColor: isDownloaded ? Colors.greenAccent : Colors.white,
                                    onTap: () async {
                                      HapticFeedback.selectionClick();
                                      if (isDownloaded) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Track is available offline! 📿'),
                                            backgroundColor: const Color(0xFF1E2630),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      } else {
                                        await downloadService.downloadSong(song);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // --- SLIM PROGRESS BAR & TIMESTAMPS ---
                            StreamBuilder<Duration>(
                              stream: player.positionStream,
                              builder: (context, snapshot) {
                                final position = snapshot.data ?? Duration.zero;
                                final total = player.totalDuration ?? Duration(seconds: song.duration);
                                final maxSec = total.inSeconds > 0 ? total.inSeconds.toDouble() : 1.0;
                                final currentSec = position.inSeconds.toDouble().clamp(0.0, maxSec);

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3.2,
                                        trackShape: const RectangularSliderTrackShape(),
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor: Colors.white.withOpacity(0.22),
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.white.withOpacity(0.2),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(position),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.65),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(total),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.65),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 6),

                            // --- PRIMARY PLAYBACK CONTROLS (Shuffle, Prev, Solid White Play, Next, Repeat) ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Shuffle
                                IconButton(
                                  icon: Icon(
                                    Icons.shuffle_rounded,
                                    color: player.isShuffleEnabled ? AppColors.goldLight : Colors.white70,
                                    size: 26,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    player.toggleShuffle();
                                  },
                                ),

                                // Previous Track
                                IconButton(
                                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    player.playPrevious();
                                  },
                                ),

                                // Adaptive Central Play/Pause Button
                                AdaptiveIconButton(
                                  size: 68,
                                  isPrimary: true,
                                  backgroundColor: Colors.white,
                                  iconColor: const Color(0xFF161E28),
                                  borderColor: Colors.white.withOpacity(0.8),
                                  icon: Icon(
                                    player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    size: 40,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    player.togglePlayPause();
                                  },
                                ),

                                // Next Track
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    player.playNext();
                                  },
                                ),

                                // Repeat Mode
                                IconButton(
                                  icon: Icon(
                                    player.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                                    color: player.loopMode != LoopMode.off ? AppColors.goldLight : Colors.white70,
                                    size: 26,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    player.toggleLoopMode();
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // --- BOTTOM "YOUR QUEUE" PEEK BAR (Swipe Up or Tap to View Queue) ---
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _showUpNextQueueSheet(context, player, currentLang);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.38),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your queue',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.75),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // --- FULL-SCREEN LYRICS SHEET (SCREEN 2 FROM SCREENSHOT) ---
          if (_showLyricsSheet)
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 240),
                opacity: _showLyricsSheet ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121B24).withOpacity(0.97),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Drag Indicator
                            Center(
                              child: Container(
                                width: 44,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: Colors.white38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Mini Album Artwork + Title + Close Button Row
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildArtworkImage(song),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.getLocalizedTitle(currentLang),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        song.getLocalizedDeity(currentLang),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white60,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Close Lyrics Pill Button
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _showLyricsSheet = false);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Multi-Language Lyrics Selector Bar
                            Builder(
                              builder: (ctx) {
                                final activeLyricsLang = _selectedLyricsLang ?? currentLang;
                                const lyricsLanguages = [
                                  {'code': 'kn', 'label': 'Kannada', 'native': 'ಕನ್ನಡ', 'icon': '🌸'},
                                  {'code': 'en', 'label': 'English', 'native': 'English', 'icon': '🌐'},
                                  {'code': 'hi', 'label': 'Hindi', 'native': 'हिन्दी', 'icon': '🕉️'},
                                  {'code': 'ta', 'label': 'Tamil', 'native': 'தமிழ்', 'icon': '🪷'},
                                  {'code': 'ml', 'label': 'Malayalam', 'native': 'മലയാളം', 'icon': '🚩'},
                                ];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.translate_rounded, color: AppColors.goldLight, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Lyrics Script / Language (Defaulted to App Language)',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.white.withOpacity(0.6),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 38,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: lyricsLanguages.length,
                                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                                        itemBuilder: (context, index) {
                                          final lang = lyricsLanguages[index];
                                          final code = lang['code']!;
                                          final isSelected = activeLyricsLang == code;
                                          final hasLyricsInLang = (song.lyricsLocalized != null &&
                                                  (song.lyricsLocalized![code]?.trim().isNotEmpty ?? false)) ||
                                              (song.language == code && song.lyrics != null && song.lyrics!.trim().isNotEmpty);

                                          return GestureDetector(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setState(() => _selectedLyricsLang = code);
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                              decoration: BoxDecoration(
                                                gradient: isSelected
                                                    ? AppColors.goldGradient
                                                    : null,
                                                color: isSelected ? null : Colors.white.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.goldPrimary
                                                      : (hasLyricsInLang
                                                          ? AppColors.goldPrimary.withOpacity(0.4)
                                                          : Colors.white.withOpacity(0.12)),
                                                  width: isSelected ? 1.6 : 1.0,
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: AppColors.goldPrimary.withOpacity(0.35),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(lang['icon']!, style: const TextStyle(fontSize: 12)),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    '${lang['native']} (${lang['label']})',
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                      color: isSelected ? AppColors.maroonDark : Colors.white.withOpacity(0.9),
                                                    ),
                                                  ),
                                                  if (hasLyricsInLang) ...[
                                                    const SizedBox(width: 5),
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: isSelected ? AppColors.maroonDark : AppColors.goldLight,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // Large Devotional Lyrics with High-Clarity Typography
                            Builder(
                              builder: (ctx) {
                                final activeLyricsLang = _selectedLyricsLang ?? currentLang;
                                final localizedText = song.getLocalizedLyrics(activeLyricsLang);
                                final hasText = localizedText != null && localizedText.trim().isNotEmpty;

                                return Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      child: hasText
                                          ? Text(
                                              localizedText,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                height: 1.85,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.1,
                                              ),
                                            )
                                          : Container(
                                              padding: const EdgeInsets.all(24),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.06),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.translate_outlined, size: 44, color: AppColors.goldLight),
                                                  const SizedBox(height: 14),
                                                  Text(
                                                    'No lyrics available in selected language yet.',
                                                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'You can choose another script tab above or add lyrics in all 5 languages via Admin.',
                                                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.65), height: 1.4),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  if (song.lyrics != null && song.lyrics!.isNotEmpty) ...[
                                                    const SizedBox(height: 18),
                                                    OutlinedButton.icon(
                                                      onPressed: () {
                                                        setState(() => _selectedLyricsLang = song.language);
                                                      },
                                                      icon: const Icon(Icons.menu_book_rounded, color: AppColors.goldLight),
                                                      label: Text(
                                                        'View Default Lyrics (${song.language.toUpperCase()})',
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(color: AppColors.goldPrimary),
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpNextQueueSheet(BuildContext context, AudioPlayerService player, String currentLang) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final queue = player.queue;
            final currentIndex = player.currentIndex;

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.65,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B24).withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.2),
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldPrimary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.queue_music_rounded, color: AppColors.goldLight, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Up Next',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${queue.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.goldLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (queue.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      player.clearQueue();
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text(
                                      'Clear',
                                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.white.withOpacity(0.12)),

                      // Queue List
                      Expanded(
                        child: queue.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.queue_music_rounded, color: Colors.white.withOpacity(0.3), size: 48),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Queue is empty',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )
                            : ReorderableListView.builder(
                                itemCount: queue.length,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                                onReorder: (oldIndex, newIndex) {
                                  player.reorderQueue(oldIndex, newIndex);
                                  setModalState(() {});
                                },
                                itemBuilder: (context, index) {
                                  final qSong = queue[index];
                                  final isCurrent = index == currentIndex;

                                  return Container(
                                    key: ValueKey(qSong.id + index.toString()),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? AppColors.goldPrimary.withOpacity(0.15)
                                          : Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppColors.goldPrimary.withOpacity(0.6)
                                            : Colors.white.withOpacity(0.08),
                                        width: isCurrent ? 1.2 : 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              _buildArtworkImage(qSong),
                                              if (isCurrent && player.isPlaying)
                                                Container(
                                                  color: Colors.black.withOpacity(0.55),
                                                  child: const Center(
                                                    child: DivineMusicVisualizer(
                                                      isPlaying: true,
                                                      barColor: AppColors.goldLight,
                                                      height: 16,
                                                      width: 18,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        qSong.getLocalizedTitle(currentLang),
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                          color: isCurrent ? AppColors.goldLight : Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        qSong.getLocalizedDeity(currentLang),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                                            onPressed: () {
                                              player.removeFromQueue(index);
                                              setModalState(() {});
                                            },
                                          ),
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: const Icon(Icons.drag_handle_rounded, color: Colors.white54, size: 20),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        player.playSong(qSong);
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
