import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/language_model.dart';
import '../../models/song_model.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/song_repository.dart';
import '../../services/audio/audio_compression_service.dart';
import '../../services/firebase/firestore_service.dart';
import '../../services/firebase/storage_service.dart';
import '../../services/storage/media_blob_helper.dart';

class AdminAddEditSongScreen extends StatefulWidget {
  final SongModel? existingSong;

  const AdminAddEditSongScreen({super.key, this.existingSong});

  @override
  State<AdminAddEditSongScreen> createState() => _AdminAddEditSongScreenState();
}

class _AdminAddEditSongScreenState extends State<AdminAddEditSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  late TextEditingController _titleController;
  late TextEditingController _deityController;
  late TextEditingController _descriptionController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _lyricsController;

  String _selectedLanguage = 'kn';
  String _selectedCategoryId = 'stotras';

  Uint8List? _pickedImageBytes;
  File? _pickedImageFile;
  String? _imageFileName;

  Uint8List? _pickedAudioBytes;
  File? _pickedAudioFile;
  String? _audioFileName;
  int _detectedDuration = 0;

  @override
  void initState() {
    super.initState();
    final song = widget.existingSong;
    _titleController = TextEditingController(text: song?.title ?? '');
    _deityController = TextEditingController(text: song?.deity ?? '');
    _descriptionController = TextEditingController(text: song?.description ?? '');
    _artistController = TextEditingController(text: song?.artist ?? '');
    _albumController = TextEditingController(text: song?.album ?? '');
    _lyricsController = TextEditingController(text: song?.lyrics ?? '');

    if (song != null) {
      _selectedLanguage = song.language;
      _selectedCategoryId = song.categoryId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _deityController.dispose();
    _descriptionController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _imageFileName = picked.name;
        if (!kIsWeb) {
          _pickedImageFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        Uint8List? audioBytes = file.bytes;
        final fileName = file.name;
        String? compressionInfo;

        if (audioBytes != null && AudioCompressionService.exceedsThreshold(audioBytes.lengthInBytes)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Compressing large audio (${AudioCompressionService.formatBytes(audioBytes.lengthInBytes)}) to below 50 MB...'),
                duration: const Duration(seconds: 2),
              ),
            );
          }

          final compressionResult = await AudioCompressionService.compressIfNeeded(
            originalBytes: audioBytes,
            fileName: fileName,
          );
          audioBytes = compressionResult.bytes;
          compressionInfo = compressionResult.summary;
        }

        int detectedDuration = 0;
        final directPath = (!kIsWeb && file.path != null && file.path!.isNotEmpty) ? file.path : null;

        if (directPath != null) {
          try {
            final tempPlayer = AudioPlayer();
            final source = AudioSource.file(
              directPath,
              tag: MediaItem(id: 'temp_probe', title: 'Duration Probe'),
            );
            final d = await tempPlayer.setAudioSource(source).timeout(const Duration(seconds: 8));
            if (d != null && d.inSeconds > 0) {
              detectedDuration = d.inSeconds;
            }
            await tempPlayer.dispose();
          } catch (e) {
            debugPrint('Direct file path duration detection notice: $e');
          }
        }

        if (detectedDuration == 0 && audioBytes != null) {
          try {
            final tempPlayer = AudioPlayer();
            final tempUrl = await saveLocalMedia('temp_detect_${DateTime.now().millisecondsSinceEpoch}', audioBytes, 'mp3', 'audio/mpeg');
            if (tempUrl.isNotEmpty) {
              final source = (!kIsWeb && tempUrl.startsWith('/'))
                  ? AudioSource.file(tempUrl, tag: MediaItem(id: 'temp_probe', title: 'Duration Probe'))
                  : AudioSource.uri(Uri.parse(tempUrl), tag: MediaItem(id: 'temp_probe', title: 'Duration Probe'));
              final d = await tempPlayer.setAudioSource(source).timeout(const Duration(seconds: 8));
              if (d != null && d.inSeconds > 0) {
                detectedDuration = d.inSeconds;
              }
            }
            await tempPlayer.dispose();
          } catch (e) {
            debugPrint('Temp audio duration detection notice: $e');
          }
        }

        setState(() {
          _pickedAudioBytes = audioBytes;
          _detectedDuration = detectedDuration;
          final durationLabel = detectedDuration > 0
              ? ' • ${detectedDuration ~/ 60}:${(detectedDuration % 60).toString().padLeft(2, '0')}'
              : '';
          _audioFileName = compressionInfo != null
              ? '$fileName ($compressionInfo$durationLabel)'
              : '$fileName (${AudioCompressionService.formatBytes(audioBytes?.lengthInBytes ?? file.size)}$durationLabel)';
          if (!kIsWeb && file.path != null) {
            _pickedAudioFile = File(file.path!);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file picker: $e')),
      );
    }
  }

  Future<void> _saveSong({required bool publishImmediately}) async {
    if (!_formKey.currentState!.validate()) return;

    final hasAudio = widget.existingSong != null ||
        _pickedAudioBytes != null ||
        _pickedAudioFile != null;

    if (!hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an MP3/M4A audio file.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String currentStep = 'Validating metadata...';
    double progressValue = 0.1;
    StateSetter? modalSetState;

    // Open dedicated, centered Publishing Progress Modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            modalSetState = setModalState;
            final percent = (progressValue * 100).clamp(0, 100).toInt();

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.creamCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.goldPrimary.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.maroonDark.withOpacity(0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.goldLight.withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.maroonDark,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        publishImmediately ? 'Publishing Devotional Song' : 'Saving Draft Stotra',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroonPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentStep,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 8,
                          backgroundColor: AppColors.creamSurface,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroonDark,
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

    try {
      final songId = widget.existingSong?.id ?? const Uuid().v4();
      String imageUrl = widget.existingSong?.imageUrl ?? 'assets/images/lalitha_sahasranamam.jpg';
      String audioUrl = widget.existingSong?.audioUrl ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

      // Stage 1: Upload Cover Image
      if (_pickedImageBytes != null || _pickedImageFile != null) {
        modalSetState?.call(() {
          currentStep = 'Uploading devotional artwork...';
          progressValue = 0.25;
        });

        if (_pickedImageBytes != null) {
          imageUrl = await _storageService.uploadSongCoverImageBytes(
            songId: songId,
            bytes: _pickedImageBytes!,
            fileName: _imageFileName ?? 'cover.jpg',
          );
        } else if (_pickedImageFile != null) {
          imageUrl = await _storageService.uploadSongCoverImage(
            songId: songId,
            file: _pickedImageFile!,
          );
        }
      }

      // Stage 2: Upload Audio
      if (_pickedAudioBytes != null || _pickedAudioFile != null) {
        modalSetState?.call(() {
          currentStep = 'Uploading sacred audio track...';
          progressValue = 0.45;
        });

        if (_pickedAudioBytes != null) {
          audioUrl = await _storageService.uploadSongAudioBytes(
            songId: songId,
            bytes: _pickedAudioBytes!,
            fileName: _audioFileName ?? 'audio.mp3',
            onProgress: (p) {
              modalSetState?.call(() {
                progressValue = 0.45 + (p * 0.45);
                currentStep = 'Uploading audio (${(p * 100).toInt()}%)...';
              });
            },
          );
        } else if (_pickedAudioFile != null) {
          audioUrl = await _storageService.uploadSongAudio(
            songId: songId,
            file: _pickedAudioFile!,
            onProgress: (p) {
              modalSetState?.call(() {
                progressValue = 0.45 + (p * 0.45);
                currentStep = 'Uploading audio (${(p * 100).toInt()}%)...';
              });
            },
          );
        }
      }

      if (audioUrl.isEmpty || (!audioUrl.startsWith('http') && !audioUrl.startsWith('assets/'))) {
        throw Exception('Audio track must be uploaded to Cloud Storage. Please check internet connection.');
      }

      modalSetState?.call(() {
        currentStep = 'Syncing with cloud catalog...';
        progressValue = 0.92;
      });

      final effectiveDuration = _detectedDuration > 0
          ? _detectedDuration
          : (widget.existingSong?.duration ?? 1740);

      final songModel = SongModel(
        id: songId,
        title: _titleController.text.trim(),
        language: _selectedLanguage,
        categoryId: _selectedCategoryId,
        deity: _deityController.text.trim(),
        description: _descriptionController.text.trim(),
        artist: _artistController.text.trim().isNotEmpty ? _artistController.text.trim() : null,
        album: _albumController.text.trim().isNotEmpty ? _albumController.text.trim() : null,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        duration: effectiveDuration,
        lyrics: _lyricsController.text.trim().isNotEmpty ? _lyricsController.text.trim() : null,
        published: publishImmediately,
        createdAt: widget.existingSong?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingSong == null) {
        await _firestoreService.createSong(songModel);
      } else {
        await _firestoreService.updateSong(songModel);
      }

      modalSetState?.call(() {
        currentStep = 'Complete!';
        progressValue = 1.0;
      });

      if (mounted) {
        await context.read<SongRepository>().loadSongs();
      }

      // Close publishing modal
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            publishImmediately
                ? 'Devotional song published globally to all users!'
                : 'Song saved as draft.',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Admin song save error: $e');
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving song: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catRepo = context.watch<CategoryRepository>();
    final isEditing = widget.existingSong != null;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: Text(isEditing ? context.tr('editSong') : context.tr('addSong')),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Media Upload Section (Image & Audio)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Media Attachments',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.maroonPrimary),
                          ),
                          const SizedBox(height: 16),

                          // Image Selection
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _pickedImageBytes != null
                                    ? Image.memory(_pickedImageBytes!, width: 72, height: 72, fit: BoxFit.cover)
                                    : (!kIsWeb && _pickedImageFile != null
                                        ? Image.file(_pickedImageFile!, width: 72, height: 72, fit: BoxFit.cover)
                                        : Image.asset('assets/images/lalitha_sahasranamam.jpg', width: 72, height: 72, fit: BoxFit.cover)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.image_outlined),
                                  label: Text(_imageFileName != null || _pickedImageFile != null ? 'Change Artwork' : 'Upload Artwork'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Audio Selection
                          OutlinedButton.icon(
                            onPressed: _pickAudio,
                            icon: Icon(
                              _audioFileName != null ? Icons.check_circle : Icons.audio_file_outlined,
                              color: _audioFileName != null ? AppColors.success : null,
                            ),
                            label: Text(
                              _audioFileName != null
                                  ? 'Selected: $_audioFileName'
                                  : (isEditing ? 'Change Audio File' : 'Upload Audio (MP3/M4A)'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: context.tr('songTitle'),
                      hintText: 'e.g., Lalitha Sahasranamam',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Deity
                  TextFormField(
                    controller: _deityController,
                    decoration: InputDecoration(
                      labelText: context.tr('deityField'),
                      hintText: 'e.g., Goddess Lalitha Tripura Sundari',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Deity name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Language & Category Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          decoration: InputDecoration(labelText: context.tr('selectLanguageField')),
                          items: LanguageModel.supported.map((lang) {
                            return DropdownMenuItem(
                              value: lang.code,
                              child: Text('${lang.nativeName} (${lang.englishName})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLanguage = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: catRepo.categories.any((c) => c.id == _selectedCategoryId)
                              ? _selectedCategoryId
                              : (catRepo.categories.isNotEmpty ? catRepo.categories.first.id : 'stotras'),
                          decoration: InputDecoration(labelText: context.tr('selectCategoryField')),
                          items: catRepo.categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.getLocalizedName('en')),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategoryId = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.tr('descriptionField'),
                      hintText: 'Spiritual significance and background of this stotra...',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Artist & Album
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _artistController,
                          decoration: InputDecoration(
                            labelText: context.tr('artistField'),
                            hintText: 'e.g., Vedic Chants',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _albumController,
                          decoration: InputDecoration(
                            labelText: context.tr('albumField'),
                            hintText: 'e.g., Sacred Hymns',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Sacred Lyrics
                  TextFormField(
                    controller: _lyricsController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: context.tr('lyricsField'),
                      hintText: 'Paste full Sanskrit or Indic lyrics here...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons: Save Draft & Publish
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _saveSong(publishImmediately: false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(context.tr('saveDraft'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveSong(publishImmediately: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.maroonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            context.tr('publish'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
