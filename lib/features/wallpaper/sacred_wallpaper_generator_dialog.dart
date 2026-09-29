import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/temple_theme.dart';
import '../../models/song_model.dart';
import '../../services/preferences/preferences_service.dart';

enum WallpaperFormat {
  story('Story (9:16)', 9 / 16, Icons.stay_current_portrait_rounded),
  wallpaper('Wallpaper (9:19.5)', 9 / 19.5, Icons.phone_android_rounded),
  square('Square DP (1:1)', 1.0, Icons.crop_square_rounded);

  final String label;
  final double aspectRatio;
  final IconData icon;
  const WallpaperFormat(this.label, this.aspectRatio, this.icon);
}

enum WallpaperStyle {
  sanctumGold('Sanctum Gold Foil', [Color(0xFF6B0E1E), Color(0xFF380710), Color(0xFF140205)], Color(0xFFFFD700), '🪷'),
  cosmicStarlight('Cosmic Celestial', [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF020617)], Color(0xFFA5B4FC), '✨'),
  vrindavanPeacock('Vrindavan Mayura', [Color(0xFF064E3B), Color(0xFF022C22), Color(0xFF011A14)], Color(0xFF34D399), '🦚'),
  suryaSaffron('Surya Bhagwa', [Color(0xFFEA580C), Color(0xFF9A3412), Color(0xFF431407)], Color(0xFFFDE047), '☀️'),
  sandalwoodParchment('Sacred Sandalwood', [Color(0xFFFAF5EC), Color(0xFFF3E8D6), Color(0xFFE8D7BE)], Color(0xFF854D0E), '📜');

  final String label;
  final List<Color> gradientColors;
  final Color accentColor;
  final String icon;
  const WallpaperStyle(this.label, this.gradientColors, this.accentColor, this.icon);
}

class SacredWallpaperGeneratorDialog extends StatefulWidget {
  final String? shlokaTitle;
  final String? shlokaText;
  final String? shlokaMeaning;
  final String? deity;
  final SongModel? song;
  final String? panchangaSummary;

  const SacredWallpaperGeneratorDialog({
    super.key,
    this.shlokaTitle,
    this.shlokaText,
    this.shlokaMeaning,
    this.deity,
    this.song,
    this.panchangaSummary,
  });

  static Future<void> show(
    BuildContext context, {
    String? shlokaTitle,
    String? shlokaText,
    String? shlokaMeaning,
    String? deity,
    SongModel? song,
    String? panchangaSummary,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SacredWallpaperGeneratorDialog(
        shlokaTitle: shlokaTitle,
        shlokaText: shlokaText,
        shlokaMeaning: shlokaMeaning,
        deity: deity,
        song: song,
        panchangaSummary: panchangaSummary,
      ),
    );
  }

  @override
  State<SacredWallpaperGeneratorDialog> createState() => _SacredWallpaperGeneratorDialogState();
}

class _SacredWallpaperGeneratorDialogState extends State<SacredWallpaperGeneratorDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  WallpaperFormat _selectedFormat = WallpaperFormat.story;
  WallpaperStyle _selectedStyle = WallpaperStyle.sanctumGold;
  bool _isProcessing = false;

  String get _title {
    if (widget.song != null) return widget.song!.title;
    if (widget.shlokaTitle != null) return widget.shlokaTitle!;
    if (widget.panchangaSummary != null) return 'Daily Panchanga Blessings';
    return 'Sacred Shloka of the Day';
  }

  String get _deity {
    if (widget.song != null) return widget.song!.deity;
    if (widget.deity != null) return widget.deity!;
    return 'Universal Divine Prayer';
  }

  String get _mainContent {
    if (widget.song != null) {
      final lyrics = widget.song!.lyrics;
      if (lyrics != null && lyrics.trim().isNotEmpty) {
        final lines = lyrics.split('\n').where((l) => l.trim().isNotEmpty).toList();
        final selectedLines = lines.take(6).join('\n');
        return '॥ ${widget.song!.title} ॥\n\n$selectedLines';
      }
      return '॥ ${widget.song!.title} ॥\n\nSacred devotional chanting dedicated to $_deity.';
    }
    if (widget.shlokaText != null) return widget.shlokaText!;
    if (widget.panchangaSummary != null) return widget.panchangaSummary!;
    return 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं ।\nभर्गो देवಸ್ಯ धीमहि धियो यो नः प्रचोदयात् ॥';
  }

  String? get _subContent {
    if (widget.shlokaMeaning != null) return widget.shlokaMeaning!;
    if (widget.song != null && widget.song!.artist != null && widget.song!.artist!.isNotEmpty) {
      return 'Rendered with devotion by ${widget.song!.artist}';
    }
    return null;
  }

  Future<Uint8List?> _capturePngBytes() async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing wallpaper image: $e');
      return null;
    }
  }

  Future<void> _shareWallpaper(BuildContext shareContext) async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await _capturePngBytes();
      if (bytes == null) throw Exception('Failed to render wallpaper canvas');

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/bhakti_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      // Resolve origin Rect for iOS/iPad share popover anchor
      final size = MediaQuery.of(context).size;
      final box = shareContext.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? (box.localToGlobal(Offset.zero) & box.size)
          : Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🙏 Divine blessings from Bhakti App — $_title ($_deity)',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share wallpaper: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveWallpaper() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await _capturePngBytes();
      if (bytes == null) throw Exception('Failed to render wallpaper canvas');

      final filename = 'Bhakti_Wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';

      // Save directly to Device Photo Library (Photos / Camera Roll / Gallery)
      await Gal.putImageBytes(bytes, name: filename);

      if (mounted) {
        final prefs = context.read<PreferencesService>();
        final activeTheme = TempleTheme.fromId(prefs.getTempleThemeId());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.goldLight),
                SizedBox(width: 10),
                Expanded(child: Text('Sacred wallpaper saved to Photos! 🖼️')),
              ],
            ),
            backgroundColor: activeTheme.primaryColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photos access error: ${e.type.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save wallpaper: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final activeTheme = TempleTheme.fromId(prefs.getTempleThemeId());
    final screenHeight = MediaQuery.of(context).size.height;
    final maxCanvasHeight = (screenHeight * 0.42).clamp(260.0, 360.0);

    return Container(
      height: screenHeight * 0.90,
      decoration: BoxDecoration(
        color: activeTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: activeTheme.borderColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: activeTheme.heroGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1-Tap Sacred Story & Wallpaper',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: activeTheme.primaryColor,
                            ),
                          ),
                          Text(
                            'Share 4K Devotional Posters to Status & Stories',
                            style: TextStyle(fontSize: 11.5, color: activeTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Canvas Preview & Controls
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  // Canvas Card with Max Height Constraint
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxCanvasHeight),
                      child: AspectRatio(
                        aspectRatio: _selectedFormat.aspectRatio,
                        child: RepaintBoundary(
                          key: _boundaryKey,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: _selectedStyle.gradientColors,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: _buildWallpaperContent(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Format Selector (Story, Wallpaper, Square)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: WallpaperFormat.values.map((f) {
                        final isSelected = _selectedFormat == f;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            avatar: Icon(
                              f.icon,
                              size: 15,
                              color: isSelected ? Colors.white : activeTheme.primaryColor,
                            ),
                            label: Text(f.label),
                            selected: isSelected,
                            selectedColor: activeTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : activeTheme.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedFormat = f);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Style Presets
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: WallpaperStyle.values.map((style) {
                        final isSelected = _selectedStyle == style;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedStyle = style),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: style.gradientColors),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? style.accentColor : Colors.white24,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(style.icon, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 5),
                                  Text(
                                    style.label,
                                    style: TextStyle(
                                      color: style == WallpaperStyle.sandalwoodParchment
                                          ? const Color(0xFF451A03)
                                          : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 11.5,
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

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            decoration: BoxDecoration(
              color: activeTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Save Button
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _isProcessing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Save 4K', style: TextStyle(fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeTheme.primaryColor,
                      side: BorderSide(color: activeTheme.primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isProcessing ? null : _saveWallpaper,
                  ),
                ),
                const SizedBox(width: 10),

                // Share Button with Builder for anchor context
                Expanded(
                  flex: 2,
                  child: Builder(
                    builder: (btnContext) {
                      return ElevatedButton.icon(
                        icon: _isProcessing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share Status & Story', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: _isProcessing ? null : () => _shareWallpaper(btnContext),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperContent() {
    final isParchment = _selectedStyle == WallpaperStyle.sandalwoodParchment;
    final primaryTextColor = isParchment ? const Color(0xFF261102) : Colors.white;
    final secondaryTextColor = isParchment ? const Color(0xFF78350F) : _selectedStyle.accentColor;
    final mutedTextColor = isParchment ? const Color(0xFF573014) : Colors.white.withOpacity(0.85);

    return Stack(
      children: [
        // Decorative Sacred Inner Border Frame
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedStyle.accentColor.withOpacity(0.35),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),

        // Corner Sacred Diya Icons
        Positioned(
          top: 14,
          left: 14,
          child: Icon(Icons.spa_rounded, size: 13, color: _selectedStyle.accentColor.withOpacity(0.55)),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: Icon(Icons.spa_rounded, size: 13, color: _selectedStyle.accentColor.withOpacity(0.55)),
        ),
        Positioned(
          bottom: 14,
          left: 14,
          child: Icon(Icons.spa_rounded, size: 13, color: _selectedStyle.accentColor.withOpacity(0.55)),
        ),
        Positioned(
          bottom: 14,
          right: 14,
          child: Icon(Icons.spa_rounded, size: 13, color: _selectedStyle.accentColor.withOpacity(0.55)),
        ),

        // Main Typography Body
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Deity Emoji Icon & Aura
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedStyle.accentColor.withOpacity(0.18),
                    border: Border.all(color: _selectedStyle.accentColor.withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Text(_selectedStyle.icon, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 6),

                // Deity Title
                Text(
                  _deity.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: secondaryTextColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),

                // Main Title
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Divider line
                Container(
                  width: 44,
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _selectedStyle.accentColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Sacred Verse / Shloka Text
                Flexible(
                  child: Text(
                    _mainContent,
                    textAlign: TextAlign.center,
                    maxLines: 7,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                      height: 1.45,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // Meaning / Subcontent
                if (_subContent != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isParchment ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _selectedStyle.accentColor.withOpacity(0.25)),
                    ),
                    child: Text(
                      _subContent!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: mutedTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Footer App Branding Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedStyle.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wb_sunny_rounded, size: 10, color: secondaryTextColor),
                      const SizedBox(width: 4),
                      Text(
                        'Bhakti App • Divine Music & Stotras',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
