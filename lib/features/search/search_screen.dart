import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/song_model.dart';
import '../../repositories/song_repository.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/preferences/preferences_service.dart';
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
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();

    final results = _query.isEmpty
        ? <SongModel>[]
        : songRepo.searchSongs(_query, currentLang);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(fontSize: 16, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: context.tr('searchPlaceholder'),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            hintStyle: const TextStyle(color: AppColors.textMuted),
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
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                });
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular Searches',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroonPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: popularDevotionalKeywords.map((kw) {
                      return ActionChip(
                        label: Text(kw),
                        backgroundColor: AppColors.creamCard,
                        side: BorderSide(
                          color: AppColors.goldPrimary.withOpacity(0.3),
                        ),
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
                        context.read<SongRepository>();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
