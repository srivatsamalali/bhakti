import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/preferences/preferences_service.dart';

class DailyShlokaCard extends StatelessWidget {
  const DailyShlokaCard({super.key});

  static const Map<String, Map<String, String>> _shlokaContent = {
    'kn': {
      'title': 'ದಿನದ ಪವಿತ್ರ ಶ್ಲೋಕ',
      'shloka': 'ಓಂ ಭೂರ್ಭುವಸ್ಸುವಃ । ತತ್ಸವಿತುರ್ವರೇಣ್ಯಂ ।\nಭರ್ಗೋ ದೇವಸ್ಯ ಧೀಮಹಿ । ಧಿಯೋ ಯೋ ನಃ ಪ್ರಚೋದಯಾತ್ ॥',
      'meaning': 'ಸಕಲ ಜಗತ್ತನ್ನು ಸೃಷ್ಟಿಸಿ ಪ್ರಕಾಶಿಸುವ ಆ ಪರಂಜ್ಯೋತಿಯನ್ನು ನಾವು ಧ್ಯಾನಿಸುತ್ತೇವೆ. ಆ ದೈವೀ ಪ್ರಕಾಶವು ನಮ್ಮ ಬುದ್ಧಿಯನ್ನು ಸನ್ಮಾರ್ಗದಲ್ಲಿ ಮುನ್ನಡೆಸಲಿ.',
      'deity': 'ಗಾಯತ್ರೀ ಮಹಾಮಂತ್ರ',
    },
    'en': {
      'title': 'Sacred Shloka of the Day',
      'shloka': 'Om Bhur Bhuvaḥ Swaḥ । Tat-Savitur Vareṇyaṃ ।\nBhargo Devasya Dhīmahi । Dhiyo Yo Naḥ Prachodayāt ॥',
      'meaning': 'We meditate on the supreme radiant light of the Divine Creator who illuminates the cosmos. May that divine light awaken and guide our intellect.',
      'deity': 'Gayatri Maha Mantra',
    },
    'hi': {
      'title': 'आज का दिव्य श्लोक',
      'shloka': 'ॐ भूर्भुवः स्वः । तत्सवितुर्वरेण्यं ।\nभर्गो देवस्य धीमहि । धियो यो नः प्रचोदयात् ॥',
      'meaning': 'हम उस प्राणस्वरूप, दुःखनाशक, सुखस्वरूप, श्रेष्ठ, तेजस्वी परमपिता परमात्मा के दिव्य तेज का ध्यान करते हैं जो हमारी बुद्धि को सन्मार्ग पर प्रेरित करे।',
      'deity': 'गायत्री महामंत्र',
    },
    'ta': {
      'title': 'இன்றைய புனித ஸ்லோகம்',
      'shloka': 'ஓம் பூர்புவஸ்ஸுவஹ । தத்ஸவிதுர்வரேண்யம் ।\nபர்கோ தேவஸ்ய தீமஹி । தியோ யோ நஹ் ப்ரசோதயாத் ॥',
      'meaning': 'அனைத்து உலகங்களையும் படைத்து ஒளிரச்செய்யும் அந்த பரம்பொருளை தியானிக்கிறோம். அந்த தெய்வீக ஒளி நமது புத்தியை நல்வழியில் செலுத்தட்டும்.',
      'deity': 'காயத்ரி மகா மந்திரம்',
    },
    'ml': {
      'title': 'ഇന്നത്തെ പവിത്ര ശ്ലോകം',
      'shloka': 'ഓം ഭൂർഭുവസ്സുവഃ । തത്സവിതുർവരേണ്യം ।\nഭർഗോ ദേവസ്യ ധീമഹി । ധിയോ യോ നഃ പ്രചോദയാത് ॥',
      'meaning': 'പ്രപഞ്ചത്തെ സൃഷ്ടിച്ചു പ്രകാശിപ്പിക്കുന്ന ആ പരമജ്യോതിയെ നാം ധ്യാനിക്കുന്നു. ആ ദൈവിക പ്രകാശം നമ്മുടെ ബുദ്ധിയെ സന്മാർഗ്ഗത്തിലേക്ക് നയിക്കട്ടെ.',
      'deity': 'ഗായത്രീ മഹാമന്ത്രം',
    },
  };

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final currentLang = prefs.getSelectedLanguage();
    final data = _shlokaContent[currentLang] ?? _shlokaContent['en']!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEADBCE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroonPrimary.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header badge
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.maroonPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.maroonPrimary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: AppColors.maroonPrimary),
                      const SizedBox(width: 6),
                      Text(
                        data['title']!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroonPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  data['deity']!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.maroonPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Sacred Shloka Verse
            Text(
              data['shloka']!,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 12),

            // Meaning Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECE4D6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.spa_rounded,
                      color: AppColors.maroonPrimary,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data['meaning']!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF5E5047),
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
