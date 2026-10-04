import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/temple_theme.dart';
import '../../services/firebase/song_request_service.dart';
import '../../services/preferences/preferences_service.dart';

class SongRequestDialog extends StatefulWidget {
  const SongRequestDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SongRequestDialog(),
    );
  }

  @override
  State<SongRequestDialog> createState() => _SongRequestDialogState();
}

class _SongRequestDialogState extends State<SongRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _deityController = TextEditingController();
  final _singerController = TextEditingController();
  final _referenceUrlController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedLanguage = AppConstants.langKannada;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final lang = context.read<PreferencesService>().getSelectedLanguage();
    _selectedLanguage = lang;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _deityController.dispose();
    _singerController.dispose();
    _referenceUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final requestService = context.read<SongRequestService>();

    final success = await requestService.submitRequest(
      songTitle: _titleController.text,
      deity: _deityController.text,
      language: _selectedLanguage,
      singerOrComposer: _singerController.text,
      referenceUrl: _referenceUrlController.text,
      notes: _notesController.text,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.stars_rounded, color: AppColors.goldLight),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Song request submitted! +5 Seva Tokens awarded 🙏🪙'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final templeTheme = TempleTheme.fromId(prefs.getTempleThemeId());

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDF9), Color(0xFFFAF5EC)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: templeTheme.heroGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: templeTheme.primaryColor.withOpacity(0.24),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request a Devotional Song',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: templeTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Earn +5 Seva Tokens for your request',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC77800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8D6E63)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),

            // Form Fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Token Incentive Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFD54F)),
                        ),
                        child: const Row(
                          children: [
                            Text('🪙', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your request helps us expand the sacred collection. You will receive +5 Seva Tokens automatically!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6D4C41),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Song / Stotram Title (Required)
                      Text(
                        'Song / Stotram / Bhajan Title *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: templeTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Jagadodharana, Venkatesha Suprabhatam',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: templeTheme.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: templeTheme.borderColor),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter song title' : null,
                      ),
                      const SizedBox(height: 14),

                      // Deity / God (Optional)
                      Text(
                        'Deity / Presiding God',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: templeTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _deityController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Lord Shiva, Krishna, Devi Durga',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: templeTheme.borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Language Selection
                      Text(
                        'Language',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: templeTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: templeTheme.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: AppConstants.langKannada, child: Text('ಕನ್ನಡ (Kannada)')),
                              DropdownMenuItem(value: 'sa', child: Text('संस्कृतम् (Sanskrit)')),
                              DropdownMenuItem(value: AppConstants.langHindi, child: Text('हिन्दी (Hindi)')),
                              DropdownMenuItem(value: AppConstants.langTamil, child: Text('தமிழ் (Tamil)')),
                              DropdownMenuItem(value: AppConstants.langMalayalam, child: Text('മലയാളം (Malayalam)')),
                              DropdownMenuItem(value: 'te', child: Text('తెలుగు (Telugu)')),
                              DropdownMenuItem(value: AppConstants.langEnglish, child: Text('English (Global)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedLanguage = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Singer / Composer
                      Text(
                        'Singer / Composer (Optional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: templeTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _singerController,
                        decoration: InputDecoration(
                          hintText: 'e.g. M.S. Subbulakshmi, Vidyabhushana, Purandara Dasa',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: templeTheme.borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Reference / YouTube Link
                      Text(
                        'Reference / YouTube Link (Optional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: templeTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _referenceUrlController,
                        decoration: InputDecoration(
                          hintText: 'https://youtube.com/...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: templeTheme.borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: templeTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Submit Song Request',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
