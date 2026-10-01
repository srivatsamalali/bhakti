import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../home/widgets/sacred_temple_map_widget.dart';

/// Full-Page Sacred Temple Map & Aerial Yatra Screen
class SacredTempleMapScreen extends StatelessWidget {
  const SacredTempleMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0503),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0904),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.4),
              border: Border.all(color: AppColors.goldPrimary.withOpacity(0.4)),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.goldLight, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.public_rounded, color: AppColors.goldLight, size: 20),
            SizedBox(width: 8),
            Text(
              'ಪುಣ್ಯಕ್ಷೇತ್ರ ದರ್ಶನ • SACRED MAP',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
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
