import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../models/song_model.dart';
import '../repositories/song_repository.dart';
import '../services/audio/audio_player_service.dart';
import '../services/notifications/devotional_reminder_service.dart';
import '../services/preferences/preferences_service.dart';
import '../widgets/divine_music_visualizer.dart';
import '../widgets/liquid_glass/glass_style.dart';
import '../widgets/liquid_glass/glass_tab_bar.dart';
import '../widgets/liquid_glass/liquid_glass.dart';
import 'admin/admin_login_screen.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'player/mini_player_bar.dart';
import 'pooja/sacred_temple_map_screen.dart';
import 'pooja/virtual_pooja_room_screen.dart';
import 'settings/settings_screen.dart';
import 'songs/song_library_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  late final PageController _pageController;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  final List<Widget> _screens = const [
    HomeScreen(),
    SongLibraryScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _initHomeWidgetNavigation();
    _triggerWelcomeNotificationIfNeeded();
  }

  void _triggerWelcomeNotificationIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final lang = context.read<PreferencesService>().getSelectedLanguage();
        context.read<DevotionalReminderService>().sendWelcomeInstallationNotification(lang);
      } catch (e) {
        debugPrint('Welcome notification trigger notice: $e');
      }
    });
  }

  void _initHomeWidgetNavigation() {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
    try {
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
      _widgetClickSubscription = HomeWidget.widgetClicked.listen(_handleWidgetUri);
    } catch (e) {
      debugPrint('HomeWidget navigation init notice: $e');
    }
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || !mounted) return;
    final uriString = uri.toString().toLowerCase();
    debugPrint('Navigating from widget URI: $uriString (params: ${uri.queryParameters})');

    final player = context.read<AudioPlayerService>();
    final songRepo = context.read<SongRepository>();

    final songId = uri.queryParameters['id'] ?? '';
    final songTitle = uri.queryParameters['title'] ?? '';

    SongModel? song;
    if (songId.isNotEmpty) {
      song = songRepo.getSongById(songId);
      if (song == null) {
        try {
          song = songRepo.allSongs.firstWhere(
            (s) => s.id.toLowerCase().contains(songId.toLowerCase()) || songId.toLowerCase().contains(s.id.toLowerCase()),
          );
        } catch (_) {}
      }
    }

    if (song == null && songTitle.isNotEmpty) {
      final matches = songRepo.searchSongs(songTitle, 'en');
      if (matches.isNotEmpty) {
        song = matches.first;
      }
    }

    if (song != null) {
      player.playSong(song, newQueue: songRepo.allSongs);
      return;
    }

    if (uriString.contains('toggle')) {
      player.togglePlayPause();
    } else if (uriString.contains('next')) {
      player.skipToNext();
    } else if (uriString.contains('prev')) {
      player.skipToPrevious();
    } else if (uriString.contains('play') || uriString.contains('player')) {
      if (player.currentSong != null) {
        if (!player.isPlaying) player.resume();
      } else if (songRepo.allSongs.isNotEmpty) {
        player.playSong(songRepo.allSongs.first, newQueue: songRepo.allSongs);
      }
    } else if (uriString.contains('library') || uriString.contains('song')) {
      _navigateToTab(1);
    } else if (uriString.contains('favorite') || uriString.contains('liked')) {
      _navigateToTab(2);
    } else if (uriString.contains('pooja') || uriString.contains('sanctum')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VirtualPoojaRoomScreen()),
      );
    }
  }

  void _navigateToTab(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildDesktopSidebar(BuildContext context, AudioPlayerService player, SongRepository songRepo) {
    final allSongs = songRepo.allSongs;

    return LiquidGlass(
      style: GlassStyle.sidebar,
      tint: AppColors.goldPrimary,
      cornerRadius: 0,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      customBorder: const Border(
        right: BorderSide(color: Color(0x33C8A050), width: 1.2),
      ),
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Authentic Bhakti Diya Sacred Logo Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.maroonPrimary.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.maroonPrimary,
                            child: const Icon(Icons.wb_sunny, color: AppColors.goldLight, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BHAKTI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.maroonPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Divine Chants & Stotras',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7A685D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Primary Navigation Items
            _buildSidebarNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: _currentIndex == 0,
              onTap: () => _navigateToTab(0),
            ),
            _buildSidebarNavItem(
              icon: Icons.library_music_rounded,
              label: 'Explore Chants',
              isSelected: _currentIndex == 1,
              onTap: () => _navigateToTab(1),
            ),
            _buildSidebarNavItem(
              icon: Icons.public_rounded,
              label: 'Sacred Map Yatra',
              isSelected: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SacredTempleMapScreen()),
                );
              },
            ),
            _buildSidebarNavItem(
              icon: Icons.favorite_rounded,
              label: 'Favorites',
              isSelected: _currentIndex == 2,
              onTap: () => _navigateToTab(2),
            ),
            _buildSidebarNavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              isSelected: _currentIndex == 3,
              onTap: () => _navigateToTab(3),
            ),

            const SizedBox(height: 12),
            Divider(color: AppColors.goldPrimary.withOpacity(0.25), height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 12),

            // Admin Portal Nav Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LiquidGlass(
                style: GlassStyle.button,
                tint: AppColors.saffronPrimary,
                cornerRadius: 20,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  );
                },
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 18, color: AppColors.maroonPrimary),
                    SizedBox(width: 8),
                    Text(
                      'Admin Portal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroonPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (allSongs.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'SACRED STOTRAMS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B776A),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Quick Playlists list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    ...allSongs.map((song) {
                      final isCurrentPlaying = player.currentSong?.id == song.id && player.isPlaying;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isCurrentPlaying ? Colors.white.withOpacity(0.9) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: isCurrentPlaying
                              ? Border.all(color: AppColors.goldPrimary.withOpacity(0.6), width: 1.2)
                              : null,
                          boxShadow: isCurrentPlaying
                              ? [
                                  BoxShadow(
                                    color: AppColors.goldPrimary.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            leading: isCurrentPlaying
                                ? const DivineMusicVisualizer(
                                    isPlaying: true,
                                    height: 12,
                                    width: 16,
                                    barColor: AppColors.maroonPrimary,
                                  )
                                : const Icon(
                                    Icons.play_circle_fill,
                                    color: AppColors.goldPrimary,
                                    size: 22,
                                  ),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.w600,
                                color: isCurrentPlaying ? AppColors.maroonPrimary : AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.deity,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A685D)),
                              maxLines: 1,
                            ),
                            onTap: () {
                              player.playSong(song, newQueue: allSongs);
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.heroMaroonGradient : null,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: AppColors.goldPrimary.withOpacity(0.5), width: 1)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.maroonPrimary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.goldLight : AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textDark,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final songRepo = context.watch<SongRepository>();
    final prefs = context.watch<PreferencesService>();
    final lastPlayedId = prefs.getLastPlayedSongId();
    final hasActiveTrack = player.currentSong != null || (lastPlayedId != null && songRepo.getSongById(lastPlayedId) != null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 750;

        final favCount = songRepo.getFavoriteSongs().length;

        final Widget mainShell = isDesktop
            ? Scaffold(
                backgroundColor: AppColors.subtleBackground,
                body: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Desktop Left Navigation Sidebar with Liquid Glass
                          _buildDesktopSidebar(context, player, songRepo),

                          // Desktop Main Screen Content
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const BouncingScrollPhysics(),
                              onPageChanged: (index) {
                                setState(() {
                                  _currentIndex = index;
                                });
                              },
                              children: _screens,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Persistent Liquid Glass Bottom Player Bar
                    if (hasActiveTrack) const MiniPlayerBar(),
                  ],
                ),
              )
            : Scaffold(
                extendBody: true,
                backgroundColor: AppColors.subtleBackground,
                body: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: _screens,
                ),
                bottomNavigationBar: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Persistent Liquid Glass Mini Player above navigation bar
                    if (hasActiveTrack) const MiniPlayerBar(),

                    // Floating Liquid Glass Tab Bar matching WhatsApp / iOS 26 Liquid Glass
                    GlassTabBar(
                      currentIndex: _currentIndex,
                      pageController: _pageController,
                      tint: AppColors.goldPrimary,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                        if (_pageController.hasClients) {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      items: [
                        GlassTabItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: context.tr('navHome'),
                        ),
                        GlassTabItem(
                          icon: Icons.library_music_outlined,
                          activeIcon: Icons.library_music_rounded,
                          label: context.tr('navSongs'),
                        ),
                        GlassTabItem(
                          icon: Icons.favorite_outline_rounded,
                          activeIcon: Icons.favorite_rounded,
                          label: context.tr('navFavorites'),
                          badgeText: favCount > 0 ? '$favCount' : null,
                        ),
                        GlassTabItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings_rounded,
                          label: context.tr('navSettings'),
                        ),
                      ],
                    ),
                  ],
                ),
              );

        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.mediaPlayPause): () => player.togglePlayPause(),
            const SingleActivator(LogicalKeyboardKey.mediaPlay): () => player.resume(),
            const SingleActivator(LogicalKeyboardKey.mediaPause): () => player.pause(),
            const SingleActivator(LogicalKeyboardKey.mediaTrackNext): () => player.skipToNext(),
            const SingleActivator(LogicalKeyboardKey.mediaTrackPrevious): () => player.skipToPrevious(),
          },
          child: Focus(
            autofocus: true,
            child: mainShell,
          ),
        );
      },
    );
  }
}


