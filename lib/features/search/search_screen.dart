import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/song_model.dart';
import '../../repositories/song_repository.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/ambient_diya_particles.dart';
import '../../widgets/devotional_card.dart';
import '../../widgets/empty_state_view.dart';
import '../player/full_player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<Map<String, String>> deityFilters = [
    {'name': 'Ganesha', 'icon': '🪔', 'label': 'Ganesha'},
    {'name': 'Shiva', 'icon': '🔱', 'label': 'Shiva'},
    {'name': 'Krishna', 'icon': '🦚', 'label': 'Krishna'},
    {'name': 'Vishnu', 'icon': '🐚', 'label': 'Vishnu'},
    {'name': 'Devi', 'icon': '🌺', 'label': 'Devi / Durga'},
    {'name': 'Hanuman', 'icon': '🚩', 'label': 'Hanuman'},
    {'name': 'Surya', 'icon': '☀️', 'label': 'Surya'},
  ];

  static const List<String> popularDevotionalKeywords = [
    'Lalitha Sahasranamam',
    'Hanuman Chalisa',
    'Vishnu Sahasranamam',
    'Shiva Panchakshari',
    'Durga Saptashati',
    'Ganesh Stotram',
    'ಸಹಸ್ರನಾಮ',
    'ललिता',
    'शिव',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songRepo = context.watch<SongRepository>();
    final player = context.watch<AudioPlayerService>();
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();

    final results = _query.isEmpty
        ? <SongModel>[]
        : songRepo.searchSongs(_query, currentLang);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.goldPrimary.withOpacity(0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldPrimary.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppColors.saffronPrimary, size: 22),
              hintText: context.tr('searchPlaceholder'),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            onChanged: (val) {
              setState(() {
                _query = val;
              });
              if (val.length >= 3) {
                AnalyticsService.instance.logSearchUsed(val);
              }
            },
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textMuted),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                });
              },
            ),
        ],
      ),
      body: AmbientDiyaParticles(
        particleCount: 14,
        child: _query.isEmpty
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deity quick explore
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: AppColors.saffronPrimary),
                        const SizedBox(width: 6),
                        const Text(
                          'Explore by Sacred Deity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.maroonPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: deityFilters.map((df) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _searchController.text = df['name']!;
                              setState(() {
                                _query = df['name']!;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.creamCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.goldPrimary.withOpacity(0.35),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.goldPrimary.withOpacity(0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(df['icon']!, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    df['label']!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Popular keywords
                    Row(
                      children: [
                        const Icon(Icons.trending_up, size: 16, color: AppColors.maroonPrimary),
                        const SizedBox(width: 6),
                        const Text(
                          'Popular Stotras & Sahasranama',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.maroonPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: popularDevotionalKeywords.map((kw) {
                        return ActionChip(
                          label: Text(kw),
                          labelStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                          backgroundColor: AppColors.creamCard,
                          side: BorderSide(
                            color: AppColors.goldPrimary.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onPressed: () {
                            _searchController.text = kw;
                            setState(() {
                              _query = kw;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
            : results.isEmpty
                ? EmptyStateView(
                    title: context.tr('noSearchResults'),
                    subtitle: 'Try searching with another deity, stotra, or language keyword.',
                    icon: Icons.search_off_outlined,
                  )
                : ListView.builder(
                    itemCount: results.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final song = results[index];
                      return DevotionalCard(
                        song: song,
                        onTap: () {
                          player.playSong(song, newQueue: results);
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              opaque: false,
                              pageBuilder: (_, __, ___) => const FullPlayerScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

