import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/sacred_back_button.dart';
import '../home/widgets/sacred_temple_map_widget.dart';

/// Full-Page Sacred Temple Map & Aerial Yatra Screen
class SacredTempleMapScreen extends StatelessWidget {
  const SacredTempleMapScreen({super.key});

  String _getTitle(String lang) {
    switch (lang) {
      case 'kn': return 'ಪುಣ್ಯಕ್ಷೇತ್ರ ದರ್ಶನ';
      case 'hi': return 'पवित्र तीर्थ दर्शन';
      case 'te': return 'పుణ్యక్షేత్ర దర్శనం';
      case 'ta': return 'புண்ணிய ஸ்தல தரிசனம்';
      case 'ml': return 'പുണ്യക്ഷേത്ര ദർശനം';
      case 'en':
      default: return 'Sacred Temple Yatra';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<PreferencesService>().getSelectedLanguage();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0503),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0904),
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: const SacredBackButton(
          color: AppColors.goldLight,
          backgroundColor: Color(0xFF2A1007),
          borderColor: Color(0x60D4AF37),
        ),
        title: Row(
          children: [
            const Icon(Icons.public_rounded, color: AppColors.goldLight, size: 20),
            const SizedBox(width: 8),
            Text(
              _getTitle(lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.goldLight,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0x44C8A050),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SacredTempleMapWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
