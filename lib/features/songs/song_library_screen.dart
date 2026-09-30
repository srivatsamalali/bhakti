import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/temple_theme.dart';
import '../../models/song_model.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/song_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/audio/offline_download_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/devotional_app_bar.dart';
import '../../widgets/devotional_card.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/adaptive_button.dart';
import '../../widgets/deepam_loader.dart';
import '../player/full_player_screen.dart';
import '../search/search_screen.dart';
import 'song_details_screen.dart';

class SongLibraryScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialLanguage;

  const SongLibraryScreen({
    super.key,
    this.initialCategory,
    this.initialLanguage,
  });

  @override
  State<SongLibraryScreen> createState() => _SongLibraryScreenState();
}

class _SongLibraryScreenState extends State<SongLibraryScreen> {
  String? _selectedCategory;
  String? _selectedLanguage;
  bool _isDownloadsTab = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedLanguage = widget.initialLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final songRepo = context.watch<SongRepository>();
    final catRepo = context.watch<CategoryRepository>();
    final player = context.watch<AudioPlayerService>();
    final prefs = context.watch<PreferencesService>();
    final downloadService = context.watch<OfflineDownloadService>();
    final currentLang = prefs.getSelectedLanguage();
    final templeTheme = TempleTheme.fromId(prefs.getTempleThemeId());

    final downloadedSongsList = downloadService.downloadedSongs.values.toList();

    List<SongModel> displayedSongs;
    if (_isDownloadsTab) {
      displayedSongs = downloadedSongsList;
      if (_selectedLanguage != null && _selectedLanguage!.isNotEmpty) {
        displayedSongs = displayedSongs.where((s) => s.language == _selectedLanguage).toList();
      }
    } else {
      displayedSongs = songRepo.allSongs;
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        final selLower = _selectedCategory!.toLowerCase();
        if (selLower == 'sahasranamam') {
          displayedSongs = displayedSongs.where((s) =>
            s.categoryId == 'sahasranamam' ||
            s.categoryId == 'sahasranama' ||
            s.title.toLowerCase().contains('sahasranama') ||
            s.title.toLowerCase().contains('sahasranamam')
          ).toList();
        } else if (selLower == 'daily chants' || selLower == 'daily-chants' || selLower == 'daily') {
          displayedSongs = displayedSongs.where((s) =>
            s.categoryId == 'daily-chants' ||
            s.categoryId == 'daily' ||
            s.title.toLowerCase().contains('gayatri') ||
            s.title.toLowerCase().contains('suprabhatam') ||
            s.title.toLowerCase().contains('daily')
          ).toList();
        } else if (selLower == 'meditation') {
          displayedSongs = displayedSongs.where((s) =>
            s.categoryId == 'meditation' ||
            s.title.toLowerCase().contains('meditation') ||
            s.title.toLowerCase().contains('dhyana') ||
            s.title.toLowerCase().contains('peace')
          ).toList();
        } else if (selLower == 'stotras') {
          displayedSongs = displayedSongs.where((s) =>
            s.categoryId == 'stotras' ||
            s.categoryId == 'stotra' ||
            s.title.toLowerCase().contains('stotra') ||
            s.title.toLowerCase().contains('stotram') ||
            s.title.toLowerCase().contains('ashtakam')
          ).toList();
        } else {
          displayedSongs = displayedSongs.where((s) => s.categoryId == _selectedCategory).toList();
        }
      }
      if (_selectedLanguage != null && _selectedLanguage!.isNotEmpty) {
        displayedSongs = displayedSongs.where((s) => s.language == _selectedLanguage).toList();
      }
    }

    final playAllLabel = (currentLang == 'kn') ? 'ಎಲ್ಲವನ್ನೂ ಪ್ಲೇ ಮಾಡಿ' : 'Play All';
    final shuffleLabel = (currentLang == 'kn') ? 'ಷಫಲ್' : 'Shuffle';
    final downloadsLabel = (currentLang == 'kn') ? 'ಡೌನ್‌ಲೋಡ್‌ಗಳು' : 'Downloads';
    final allSongsLabel = (currentLang == 'kn') ? 'ಎಲ್ಲಾ ಸ್ತೋತ್ರಗಳು' : 'All';

    final categoryPills = <Map<String, dynamic>>[
      {'id': null, 'name': allSongsLabel, 'isDownload': false},
      {'id': 'Sahasranamam', 'name': currentLang == 'kn' ? 'ಸಹಸ್ರನಾಮ' : 'Sahasranamam', 'isDownload': false},
      {'id': 'Daily Chants', 'name': currentLang == 'kn' ? 'ದೈನಂದಿನ ಮಂತ್ರ' : 'Daily Chants', 'isDownload': false},
      {'id': 'Meditation', 'name': currentLang == 'kn' ? 'ಧ್ಯಾನ' : 'Meditation', 'isDownload': false},
      {'id': 'Stotras', 'name': currentLang == 'kn' ? 'ಸ್ತೋತ್ರಗಳು' : 'Stotras', 'isDownload': false},
      {'id': 'downloads', 'name': downloadedSongsList.isNotEmpty ? '$downloadsLabel (${downloadedSongsList.length})' : downloadsLabel, 'isDownload': true},
      ...catRepo.categories
          .where((c) => !['sahasranamam', 'daily-chants', 'meditation', 'stotras'].contains(c.id.toLowerCase()))
          .map((c) => {'id': c.id, 'name': c.getLocalizedName(currentLang), 'isDownload': false}),
    ];

    return Scaffold(
      backgroundColor: templeTheme.backgroundColor,
      appBar: DevotionalAppBar(
        title: _isDownloadsTab ? downloadsLabel : context.tr('navSongs'),
        showLogo: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: context.tr('navSearch'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          if (displayedSongs.isNotEmpty)
            IconButton(
              icon: Icon(Icons.play_circle_fill_rounded, color: templeTheme.accentGold, size: 28),
              tooltip: playAllLabel,
              onPressed: () {
                player.playAll(displayedSongs, shuffle: false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: categoryPills.map((pill) {
                final isDownload = pill['isDownload'] as bool;
                final pillId = pill['id'] as String?;
                final pillName = pill['name'] as String;

                final isSelected = isDownload
                    ? _isDownloadsTab
                    : (!_isDownloadsTab && _selectedCategory == pillId);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isDownload) {
                          _isDownloadsTab = true;
                          _selectedCategory = null;
                        } else {
                          _isDownloadsTab = false;
                          _selectedCategory = pillId;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? templeTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? templeTheme.primaryColor : templeTheme.borderColor,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: templeTheme.primaryColor.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDownload) ...[
                            Icon(
                              Icons.cloud_download_rounded,
                              size: 15,
                              color: isSelected ? Colors.white : templeTheme.primaryColor,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            pillName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Prominent Play All & Shuffle Action Bar
          if (displayedSongs.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    templeTheme.primaryColor.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: templeTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Track Count Icon & Info
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: templeTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        _isDownloadsTab ? Icons.download_done_rounded : Icons.library_music_rounded,
                        color: templeTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDownloadsTab
                              ? ((currentLang == 'kn') ? 'ಆಫ್‌ಲೈನ್ ಗೀತೆಗಳು' : 'Offline Library')
                              : ((currentLang == 'kn') ? 'ದಿವ್ಯ ಸ್ತೋತ್ರ ಸಂಗ್ರಹ' : 'Divine Chants Library'),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: templeTheme.primaryColor,
                          ),
                        ),
                        Text(
                          '${displayedSongs.length} ${(currentLang == 'kn') ? 'ಹಾಡುಗಳು' : 'tracks available'}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A685D), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Adaptive Shuffle Button (Liquid Glass on iOS, M3 Tonal on Android)
                  AdaptiveButton.icon(
                    onPressed: () {
                      player.playAll(displayedSongs, shuffle: true);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                      );
                    },
                    icon: const Icon(Icons.shuffle_rounded, size: 16),
                    label: Text(shuffleLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    variant: AdaptiveButtonVariant.secondary,
                    color: templeTheme.primaryColor,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 6),

                  // Adaptive Play All Button (Liquid Glass Primary on iOS, M3 Filled on Android)
                  AdaptiveButton.icon(
                    onPressed: () {
                      player.playAll(displayedSongs, shuffle: false);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(playAllLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    variant: AdaptiveButtonVariant.primary,
                    color: templeTheme.primaryColor,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
            ),

          Divider(height: 1, color: templeTheme.borderColor),

          // Songs List or Downloads Empty State
          Expanded(
            child: songRepo.isLoading
                ? const Center(
                    child: DeepamLoader(
                      size: 90,
                      message: 'Loading Divine Melodies...',
                      subtitle: 'ॐ ನಮೋ ನಾರಾಯಣಾಯ',
                    ),
                  )
                : displayedSongs.isEmpty
                    ? (_isDownloadsTab
                        ? EmptyStateView(
                            title: (currentLang == 'kn') ? 'ಯಾವುದೇ ಡೌನ್‌ಲೋಡ್ ಇಲ್ಲ' : 'No Downloads Yet',
                            subtitle: (currentLang == 'kn')
                                ? 'ಇಂಟರ್ನೆಟ್ ಇಲ್ಲದೆ ಕೇಳಲು ನಿಮ್ಮ ನೆಚ್ಚಿನ ಸ್ತೋತ್ರಗಳನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ.'
                                : 'Download your favorite devotional chants and sahasranamas to listen offline anytime.',
                            icon: Icons.cloud_download_outlined,
                          )
                        : EmptyStateView(
                            title: context.tr('noSearchResults'),
                            subtitle: context.tr('noFavoritesSubtitle'),
                            icon: Icons.music_off_outlined,
                          ))
                    : ListView.builder(
                        itemCount: displayedSongs.length,
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 150),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final song = displayedSongs[index];
                          return DevotionalCard(
                            song: song,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SongDetailsScreen(song: song),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
