import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/song_model.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/song_repository.dart';
import '../../services/firebase/auth_service.dart';
import '../../services/firebase/firestore_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/deepam_loader.dart';
import 'admin_add_edit_song_screen.dart';
import 'admin_categories_screen.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<SongModel> _adminSongs = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, published, drafts

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final songs = await _firestoreService.getAllSongsForAdmin();
    if (mounted) {
      setState(() {
        _adminSongs = songs;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePublish(SongModel song) async {
    await _firestoreService.setPublishedStatus(song.id, !song.published);
    await _loadAdminData();
    if (mounted) {
      context.read<SongRepository>().loadSongs();
    }
  }

  Future<void> _deleteSong(SongModel song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.creamCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('deleteSong'),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete "${song.title}"? This will permanently remove the stotra from the global catalog.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          context.tr('cancel'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          context.tr('confirm'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _firestoreService.deleteSong(song.id);
      await _loadAdminData();
      if (mounted) {
        context.read<SongRepository>().loadSongs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song deleted successfully.')),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.creamCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.goldPrimary.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.maroonPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppColors.maroonPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Admin Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.maroonPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: oldPassController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    filled: true,
                    fillColor: AppColors.creamSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    filled: true,
                    fillColor: AppColors.creamSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final auth = context.read<AuthService>();
                          final ok = await auth.changeAdminPassword(oldPassController.text, newPassController.text);
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? 'Admin password updated!' : 'Incorrect current password.'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.maroonPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
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
    final auth = context.watch<AuthService>();
    final catRepo = context.watch<CategoryRepository>();

    final totalSongs = _adminSongs.length;
    final publishedSongs = _adminSongs.where((s) => s.published).length;
    final draftSongs = _adminSongs.where((s) => !s.published).length;

    var displayedSongs = _adminSongs;
    if (_filter == 'published') {
      displayedSongs = _adminSongs.where((s) => s.published).toList();
    } else if (_filter == 'drafts') {
      displayedSongs = _adminSongs.where((s) => !s.published).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: Text(context.tr('adminDashboard')),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'categories') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
                );
              } else if (val == 'password') {
                _showChangePasswordDialog();
              } else if (val == 'seed') {
                await _firestoreService.seedInitialContent();
                await _loadAdminData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sample content synced to Firestore!')),
                  );
                }
              } else if (val == 'logout') {
                await auth.logoutAdmin();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'categories',
                child: Text(context.tr('manageCategories')),
              ),
              const PopupMenuItem(
                value: 'seed',
                child: Text('Seed / Sync Content to Cloud'),
              ),
              const PopupMenuItem(
                value: 'password',
                child: Text('Change Admin Password'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text(context.tr('logout'), style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.maroonPrimary,
        icon: const Icon(Icons.add, color: AppColors.goldLight),
        label: Text(
          context.tr('addSong'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdminAddEditSongScreen()),
          );
          if (result == true && mounted) {
            _loadAdminData();
            context.read<SongRepository>().loadSongs();
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadAdminData,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Grid Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context.tr('totalSongs'),
                          '$totalSongs',
                          Icons.music_note,
                          AppColors.maroonPrimary,
                        ),
                      ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      context.tr('publishedSongs'),
                      '$publishedSongs',
                      Icons.check_circle_outline,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context.tr('draftSongs'),
                      '$draftSongs',
                      Icons.edit_note,
                      AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      context.tr('categories'),
                      '${catRepo.categories.length}',
                      Icons.category_outlined,
                      AppColors.goldDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // AI Companion Management Card
              _buildAiAdminCard(context.watch<PreferencesService>()),

              const SizedBox(height: 20),

              // Filter Chips

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Song Catalog (${displayedSongs.length})',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroonPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _filter == 'all',
                        onSelected: (_) => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Live'),
                        selected: _filter == 'published',
                        onSelected: (_) => setState(() => _filter = 'published'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Drafts'),
                        selected: _filter == 'drafts',
                        onSelected: (_) => setState(() => _filter = 'drafts'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Admin Song Items
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: DeepamLoader(
                      size: 80,
                      message: 'Updating Repository...',
                      subtitle: 'ॐ ಶಾಂತಿಃ',
                    ),
                  ),
                )
              else if (displayedSongs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No songs found in this view.'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedSongs.length,
                  itemBuilder: (context, index) {
                    final song = displayedSongs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: song.published
                              ? AppColors.goldPrimary.withOpacity(0.25)
                              : AppColors.warning.withOpacity(0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/images/lalitha_sahasranamam.jpg',
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${song.deity} • ${song.language.toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: song.published
                                        ? AppColors.success.withOpacity(0.12)
                                        : AppColors.warning.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    song.published ? 'LIVE' : 'DRAFT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: song.published ? AppColors.success : AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),

                            // Actions: Edit, Publish/Unpublish, Delete
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: Icon(
                                    song.published ? Icons.visibility_off : Icons.publish,
                                    size: 16,
                                  ),
                                  label: Text(song.published ? 'Unpublish' : 'Publish'),
                                  onPressed: () => _togglePublish(song),
                                ),
                                const SizedBox(width: 6),
                                TextButton.icon(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit'),
                                  onPressed: () async {
                                    final res = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => AdminAddEditSongScreen(existingSong: song),
                                      ),
                                    );
                                    if (res == true && mounted) {
                                      _loadAdminData();
                                      context.read<SongRepository>().loadSongs();
                                    }
                                  },
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                  onPressed: () => _deleteSong(song),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAdminCard(PreferencesService prefs) {
    final isAiEnabled = prefs.isAdminAiGlobalEnabled();
    final dailyLimit = prefs.getAdminAiDailyLimit();
    final maxTokens = prefs.getAdminAiMaxTokens();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDECFC0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.maroonPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.maroonPrimary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Bhakti AI Engine Controls',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroonPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isAiEnabled,
                activeColor: AppColors.maroonPrimary,
                onChanged: (val) => prefs.setAdminAiGlobalEnabled(val),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Status: ${isAiEnabled ? "Active & Serving" : "Paused"} • Limit: $dailyLimit req/day • Max: $maxTokens tokens',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A685D)),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.tune, size: 16, color: AppColors.maroonPrimary),
                label: const Text('Configure', style: TextStyle(color: AppColors.maroonPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => _showAiConfigDialog(prefs),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAiConfigDialog(PreferencesService prefs) {
    int currentLimit = prefs.getAdminAiDailyLimit();
    int currentTokens = prefs.getAdminAiMaxTokens();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.maroonPrimary),
            SizedBox(width: 8),
            Text('Configure Bhakti AI', style: TextStyle(color: AppColors.maroonPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Request Limit per user:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: currentLimit,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 20, child: Text('20 requests / day')),
                DropdownMenuItem(value: 50, child: Text('50 requests / day (Recommended)')),
                DropdownMenuItem(value: 100, child: Text('100 requests / day')),
                DropdownMenuItem(value: 500, child: Text('500 requests / day')),
              ],
              onChanged: (v) {
                if (v != null) currentLimit = v;
              },
            ),
            const SizedBox(height: 16),
            const Text('Max AI Response Length (Tokens):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: currentTokens,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 150, child: Text('150 tokens (Concise)')),
                DropdownMenuItem(value: 300, child: Text('300 tokens (Standard)')),
                DropdownMenuItem(value: 600, child: Text('600 tokens (Detailed)')),
              ],
              onChanged: (v) {
                if (v != null) currentTokens = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await prefs.setAdminAiDailyLimit(currentLimit);
              await prefs.setAdminAiMaxTokens(currentTokens);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI configuration updated!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.maroonPrimary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

