import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../repositories/song_repository.dart';
import '../services/audio/audio_player_service.dart';
import 'admin/admin_login_screen.dart';
import 'ai/bhakti_ai_screen.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'player/mini_player_bar.dart';
import 'settings/settings_screen.dart';
import 'songs/song_library_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SongLibraryScreen(),
    BhaktiAiScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];


  Widget _buildDesktopSidebar(BuildContext context, AudioPlayerService player, SongRepository songRepo) {
    final allSongs = songRepo.allSongs;

    return Material(
      color: const Color(0xFFF3ECE0),
      child: Container(
        width: 250,
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Color(0xFFE2D7C7), width: 1),
          ),
        ),
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
                        color: AppColors.maroonPrimary.withOpacity(0.15),
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
            onTap: () => setState(() => _currentIndex = 0),
          ),
          _buildSidebarNavItem(
            icon: Icons.library_music_rounded,
            label: 'Explore Chants',
            isSelected: _currentIndex == 1,
            onTap: () => setState(() => _currentIndex = 1),
          ),
          _buildSidebarNavItem(
            icon: Icons.auto_awesome_rounded,
            label: 'Bhakti AI',
            isSelected: _currentIndex == 2,
            onTap: () => setState(() => _currentIndex = 2),
          ),
          _buildSidebarNavItem(
            icon: Icons.favorite_rounded,
            label: 'Favorites',
            isSelected: _currentIndex == 3,
            onTap: () => setState(() => _currentIndex = 3),
          ),
          _buildSidebarNavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            isSelected: _currentIndex == 4,
            onTap: () => setState(() => _currentIndex = 4),
          ),


          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE2D7C7), height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 12),

          // Admin Portal Nav Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDECFC0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'SACRED SAHASRANAMAS',
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
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isCurrentPlaying ? AppColors.maroonPrimary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Icon(
                          isCurrentPlaying ? Icons.graphic_eq : Icons.play_circle_fill,
                          color: isCurrentPlaying ? AppColors.maroonPrimary : AppColors.goldPrimary,
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
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      leading: const Icon(Icons.favorite, color: AppColors.maroonPrimary, size: 20),
                      title: const Text(
                        'Liked Devotionals',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                      onTap: () {
                        setState(() => _currentIndex = 2);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        color: isSelected ? AppColors.maroonPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textDark,
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
    final hasActiveTrack = player.currentSong != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 750;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.subtleBackground,
            body: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Desktop Left Navigation Sidebar
                      _buildDesktopSidebar(context, player, songRepo),

                      // Desktop Main Screen Content
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _screens,
                        ),
                      ),
                    ],
                  ),
                ),

                // Persistent YouTube Music Bottom Player Bar
                if (hasActiveTrack) const MiniPlayerBar(),
              ],
            ),
          );
        }

        // Mobile Layout
        return Scaffold(
          backgroundColor: AppColors.subtleBackground,
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Persistent Mini Player above bottom navigation
              if (hasActiveTrack) const MiniPlayerBar(),

              // Subtle Divine Bottom Navigation
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.subtleBorder, width: 1),
                  ),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.white,
                  selectedItemColor: AppColors.maroonPrimary,
                  unselectedItemColor: AppColors.textMuted,
                  currentIndex: _currentIndex,
                  type: BottomNavigationBarType.fixed,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_outlined),
                      activeIcon: const Icon(Icons.home_rounded),
                      label: context.tr('navHome'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.library_music_outlined),
                      activeIcon: const Icon(Icons.library_music_rounded),
                      label: context.tr('navSongs'),
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.saffronPrimary.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.saffronPrimary, size: 20),
                      ),
                      activeIcon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.maroonPrimary,
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      label: 'Bhakti AI',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.favorite_outline_rounded),
                      activeIcon: const Icon(Icons.favorite_rounded),
                      label: context.tr('navFavorites'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.settings_outlined),
                      activeIcon: const Icon(Icons.settings_rounded),
                      label: context.tr('navSettings'),
                    ),

                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

