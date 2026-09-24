import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/song_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/devotional_app_bar.dart';
import '../../widgets/devotional_card.dart';
import '../../widgets/empty_state_view.dart';
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
    final currentLang = prefs.getSelectedLanguage();

    var filteredSongs = songRepo.allSongs;
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filteredSongs = filteredSongs.where((s) => s.categoryId == _selectedCategory).toList();
    }
    if (_selectedLanguage != null && _selectedLanguage!.isNotEmpty) {
      filteredSongs = filteredSongs.where((s) => s.language == _selectedLanguage).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: DevotionalAppBar(
        title: context.tr('navSongs'),
        showLogo: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: context.tr('navSearch'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          if (filteredSongs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_outline, color: AppColors.saffronPrimary),
              tooltip: context.tr('playAll'),
              onPressed: () {
                player.playSong(filteredSongs.first, newQueue: filteredSongs);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips (Categories)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(context.tr('allSongs')),
                  selected: _selectedCategory == null,
                  selectedColor: AppColors.maroonPrimary,
                  backgroundColor: AppColors.creamCard,
                  labelStyle: TextStyle(
                    color: _selectedCategory == null ? Colors.white : AppColors.textDark,
                    fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...catRepo.categories.map((cat) {
                  final isSel = _selectedCategory == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.getLocalizedName(currentLang)),
                      selected: isSel,
                      selectedColor: AppColors.maroonPrimary,
                      backgroundColor: AppColors.creamCard,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textDark,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = val ? cat.id : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Songs List
          Expanded(
            child: songRepo.isLoading
                ? const Center(
                    child: DeepamLoader(
                      size: 90,
                      message: 'Loading Divine Melodies...',
                      subtitle: 'ॐ ನಮೋ ನಾರಾಯಣಾಯ',
                    ),
                  )
                : filteredSongs.isEmpty
                    ? EmptyStateView(
                        title: context.tr('noSearchResults'),
                        subtitle: context.tr('noFavoritesSubtitle'),
                        icon: Icons.music_off_outlined,
                      )
                    : ListView.builder(
                        itemCount: filteredSongs.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
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
