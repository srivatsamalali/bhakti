import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/song_model.dart';
import '../../services/ai/bhakti_ai_service.dart';
import '../../services/ai/language_detector.dart';
import '../../services/ai/voice_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/preferences/preferences_service.dart';
import '../player/full_player_screen.dart';
import '../../widgets/deepam_loader.dart';


class BhaktiAiScreen extends StatefulWidget {
  const BhaktiAiScreen({super.key});

  @override
  State<BhaktiAiScreen> createState() => _BhaktiAiScreenState();
}

class _BhaktiAiScreenState extends State<BhaktiAiScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  bool _isListeningOverlayVisible = false;
  String _liveSpeechText = '';

  final List<String> _quickSuggestions = [
    'What is Lalitha Sahasranamam?',
    'Play Lalitha Sahasranamam',
    'ಲಲಿತಾ ಸಹಸ್ರನಾಮದ ಸಾಹಿತ್ಯ ಕೊಡಿ',
    'हनुमान चालीसा बजाओ',
    'Explain Shiva Panchakshari',
    'Show my favorite songs',
    'ಕನ್ನಡದಲ್ಲಿ ಯಾವ ಹಾಡುಗಳು ಇವೆ?',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final aiService = context.read<BhaktiAiService>();
    await aiService.processQuery(text);
    _scrollToBottom();
  }

  Future<void> _handleVoiceMicTap() async {
    final voiceService = context.read<VoiceService>();
    final aiService = context.read<BhaktiAiService>();
    final prefs = context.read<PreferencesService>();

    if (!prefs.isAiVoiceInputEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice input is disabled in AI settings.')),
      );
      return;
    }

    setState(() {
      _isListeningOverlayVisible = true;
      _liveSpeechText = '';
    });

    final currentAppLang = prefs.getSelectedLanguage();
    final speechLocale = AiLanguage.getSpeechLocale(currentAppLang);

    await voiceService.startListening(
      languageLocale: speechLocale,
      onResult: (spokenText) async {
        setState(() {
          _liveSpeechText = spokenText;
          _isListeningOverlayVisible = false;
        });
        if (spokenText.trim().isNotEmpty) {
          await aiService.processQuery(spokenText, isVoice: true);
          _scrollToBottom();
        }
      },
    );
  }

  void _cancelVoiceListening() {
    final voiceService = context.read<VoiceService>();
    voiceService.stopListening();
    setState(() {
      _isListeningOverlayVisible = false;
    });
  }

  void _showLyricsDialog(SongModel song, String? preloadedLyrics, String currentLang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String activeLang = currentLang;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final lyrics = song.getLocalizedLyrics(activeLang) ?? preloadedLyrics ?? song.lyrics ?? 'Lyrics not available.';
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFFFDFBF7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Top Handle
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDECFC0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.getLocalizedTitle(activeLang),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.maroonPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.getLocalizedDeity(activeLang),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF7A685D)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textDark),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Language Switcher Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        _buildLangChip('kn', 'ಕನ್ನಡ', activeLang, (l) => setModalState(() => activeLang = l)),
                        _buildLangChip('hi', 'हिन्दी', activeLang, (l) => setModalState(() => activeLang = l)),
                        _buildLangChip('ta', 'தமிழ்', activeLang, (l) => setModalState(() => activeLang = l)),
                        _buildLangChip('ml', 'മലയാളം', activeLang, (l) => setModalState(() => activeLang = l)),
                        _buildLangChip('en', 'English', activeLang, (l) => setModalState(() => activeLang = l)),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFFEADBCE), height: 1),

                  // Scrollable Lyrics Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SelectableText(
                            lyrics,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3ECE0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2D7C7)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_outlined, size: 18, color: AppColors.maroonPrimary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    song.licenseInfo ?? 'Public Domain / Authorized Devotional Text',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B584E)),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLangChip(String code, String label, String activeLang, Function(String) onSelect) {
    final isSelected = activeLang == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.maroonPrimary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12.5,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isSelected ? AppColors.maroonPrimary : const Color(0xFFDECFC0)),
        ),
        onSelected: (_) => onSelect(code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiService = context.watch<BhaktiAiService>();
    final prefs = context.watch<PreferencesService>();
    final player = context.watch<AudioPlayerService>();
    final isVoiceOutputOn = prefs.isAiVoiceOutputEnabled();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE88A1A), Color(0xFF800020)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.saffronPrimary.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bhakti AI',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.maroonPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Your Devotional Companion',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8B776A),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Voice output TTS toggle button
          IconButton(
            tooltip: isVoiceOutputOn ? 'AI Voice Response ON' : 'AI Voice Response OFF',
            icon: Icon(
              isVoiceOutputOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: isVoiceOutputOn ? AppColors.maroonPrimary : AppColors.textMuted,
            ),
            onPressed: () {
              prefs.setAiVoiceOutputEnabled(!isVoiceOutputOn);
            },
          ),
          // Clear conversation
          IconButton(
            tooltip: 'Clear conversation',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            onPressed: () {
              aiService.clearConversation();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Top Quick Suggestions Bar
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _quickSuggestions[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(suggestion),
                        labelStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.maroonPrimary,
                        ),
                        backgroundColor: Colors.white,
                        elevation: 1,
                        shadowColor: Colors.black.withOpacity(0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFEADBCE)),
                        ),
                        onPressed: () {
                          aiService.processQuery(suggestion);
                          _scrollToBottom();
                        },
                      ),
                    );
                  },
                ),
              ),

              const Divider(color: Color(0xFFEADBCE), height: 1),

              // Chat Messages Stream
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: aiService.messages.length + (aiService.isProcessing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == aiService.messages.length && aiService.isProcessing) {
                      return _buildThinkingBubble();
                    }
                    final message = aiService.messages[index];
                    return _buildMessageItem(context, message, player);
                  },
                ),
              ),

              // Bottom Input Bar
              _buildBottomInputBar(context, aiService),
            ],
          ),

          // Animated Voice Listening Overlay
          if (_isListeningOverlayVisible) _buildListeningOverlay(),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEADBCE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DeepamLoader.compact(
              size: 26,
            ),
            const SizedBox(width: 12),
            Text(
              'Bhakti AI is contemplating...',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.maroonPrimary.withOpacity(0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, AiMessage message, AudioPlayerService player) {
    final isUser = message.sender == AiSender.user;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B1E2F), Color(0xFF6E0D1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.maroonPrimary.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.isVoice)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, size: 14, color: Color(0xFFFFD59E)),
                      SizedBox(width: 4),
                      Text(
                        'Voice Request',
                        style: TextStyle(fontSize: 10, color: Color(0xFFFFD59E), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              Text(
                message.text,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // AI Response Bubble
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: const Color(0xFFEADBCE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                message.text,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textDark,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Embedded Interactive Song Card (If AI played or matched a song)
            if (message.song != null) ...[
              const SizedBox(height: 8),
              _buildInlineSongActionCard(context, message.song!, player, message.detectedLanguage),
            ],

            // Embedded Multiple Song Carousel (If AI retrieved favorites / category list)
            if (message.songList != null && message.songList!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInlineSongList(context, message.songList!, player, message.detectedLanguage),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInlineSongActionCard(
    BuildContext context,
    SongModel song,
    AudioPlayerService player,
    String langCode,
  ) {
    final isCurrentPlaying = player.currentSong?.id == song.id && player.isPlaying;
    final localizedTitle = song.getLocalizedTitle(langCode);
    final localizedDeity = song.getLocalizedDeity(langCode);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5D5C2)),
      ),
      child: Row(
        children: [
          // Play / Pause Circle
          InkWell(
            onTap: () {
              if (isCurrentPlaying) {
                player.pause();
              } else {
                player.playSong(song);
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.saffronPrimary, AppColors.maroonPrimary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.maroonPrimary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isCurrentPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Deity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.maroonPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$localizedDeity • ${song.formattedDuration}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7A685D)),
                ),
              ],
            ),
          ),

          // Lyrics button
          IconButton(
            tooltip: 'View Lyrics',
            icon: const Icon(Icons.menu_book_rounded, color: AppColors.maroonPrimary, size: 22),
            onPressed: () {
              _showLyricsDialog(song, null, langCode);
            },
          ),

          // Open Full Player
          IconButton(
            tooltip: 'Open Player',
            icon: const Icon(Icons.open_in_full_rounded, color: Color(0xFF7A685D), size: 20),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
              );
            },
          ),

        ],
      ),
    );
  }

  Widget _buildInlineSongList(
    BuildContext context,
    List<SongModel> songs,
    AudioPlayerService player,
    String langCode,
  ) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5D5C2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const Divider(color: Color(0xFFEADBCE), height: 1),
        itemBuilder: (context, idx) {
          final s = songs[idx];
          final isPlaying = player.currentSong?.id == s.id && player.isPlaying;
          return ListTile(
            dense: true,
            leading: Icon(
              isPlaying ? Icons.graphic_eq : Icons.play_circle_fill,
              color: isPlaying ? AppColors.maroonPrimary : AppColors.goldPrimary,
              size: 22,
            ),
            title: Text(
              s.getLocalizedTitle(langCode),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                color: isPlaying ? AppColors.maroonPrimary : AppColors.textDark,
              ),
              maxLines: 1,
            ),
            subtitle: Text(
              s.getLocalizedDeity(langCode),
              style: const TextStyle(fontSize: 11, color: Color(0xFF7A685D)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.menu_book_rounded, size: 18, color: AppColors.maroonPrimary),
              onPressed: () => _showLyricsDialog(s, null, langCode),
            ),
            onTap: () {
              player.playSong(s, newQueue: songs);
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomInputBar(BuildContext context, BhaktiAiService aiService) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEADBCE), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Microphone Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE88A1A), Color(0xFF800020)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.maroonPrimary.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleVoiceMicTap,
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.mic, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Text Input Field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F0E7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2D5C4)),
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendText(),
                decoration: const InputDecoration(
                  hintText: 'Ask Bhakti anything...',
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9E8E84)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send Button
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.maroonPrimary,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
              onPressed: _handleSendText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sacred Pulsing Diya / Mic Glow
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.15);
                  final opacity = 0.4 - (_pulseController.value * 0.2);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80 * scale,
                        height: 80 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.saffronPrimary.withOpacity(opacity),
                        ),
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFE88A1A), Color(0xFF800020)],
                          ),
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 32),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Listening...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.maroonPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Speak in Kannada, Hindi, Tamil, Malayalam or English',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF7A685D)),
              ),
              const SizedBox(height: 16),

              if (_liveSpeechText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECE0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '"$_liveSpeechText"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.maroonPrimary,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              TextButton.icon(
                onPressed: _cancelVoiceListening,
                icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.textMuted),
                label: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
