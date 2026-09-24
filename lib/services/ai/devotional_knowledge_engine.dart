import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'language_detector.dart';

/// Secure Devotional Knowledge and Natural Language Engine.
/// Provides offline-resilient authoritative answers across Kannada, English, Hindi, Tamil, and Malayalam,
/// with a secure Cloud Function / Backend proxy bridge for generative capabilities.
class DevotionalKnowledgeEngine {
  // Optional secure backend endpoint (e.g. Firebase Cloud Function)
  final String? backendEndpoint;
  final String? backendAuthToken;

  DevotionalKnowledgeEngine({
    this.backendEndpoint,
    this.backendAuthToken,
  });

  /// Explains a devotional work or answers a spiritual query in the requested language
  Future<String> answerQuery({
    required String query,
    required String languageCode,
    String? matchedSongId,
  }) async {
    // 1. Try secure backend first if configured
    if (backendEndpoint != null && backendEndpoint!.isNotEmpty) {
      try {
        final remoteResponse = await _callSecureBackend(query, languageCode);
        if (remoteResponse != null && remoteResponse.trim().isNotEmpty) {
          return remoteResponse;
        }
      } catch (e) {
        debugPrint('Secure AI backend call notice: $e. Falling back to authentic devotional knowledge base.');
      }
    }

    // 2. Authoritative curated spiritual knowledge base (Fast, 100% offline, zero-latency)
    return _generateCuratedResponse(query, languageCode, matchedSongId);
  }

  /// Calls the secure server-side AI proxy without bundling secret API keys in the mobile binary
  Future<String?> _callSecureBackend(String query, String languageCode) async {
    final uri = Uri.parse(backendEndpoint!);
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (backendAuthToken != null) 'Authorization': 'Bearer $backendAuthToken',
      },
      body: jsonEncode({
        'query': query,
        'language': languageCode,
        'maxTokens': 300,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] as String?;
    }
    return null;
  }

  /// Curated authentic knowledge base respecting spiritual traditions and safety rules
  String _generateCuratedResponse(String query, String langCode, String? songId) {
    final lower = query.toLowerCase();

    // 1. Lalitha Sahasranamam
    if (songId == 'lalitha_sahasranamam' || lower.contains('lalitha') || lower.contains('ಲಲಿತಾ') || lower.contains('ललिता') || lower.contains('லலிதா') || lower.contains('ലളിത')) {
      switch (langCode) {
        case AiLanguage.kannada:
          return 'ಶ್ರೀ ಲಲಿತಾ ಸಹಸ್ರನಾಮವು ಬ್ರಹ್ಮಾಂಡ ಪುರಾಣದ ಉತ್ತರಖಂಡದಲ್ಲಿ ಬರುವ ಅತ್ಯಂತ ಪವಿತ್ರವಾದ 1,000 ದಿವ್ಯ ನಾಮಗಳ ಸ್ತೋತ್ರ. ಹಯಗ್ರೀವ ಭಗವಂತನು ಅಗಸ್ತ್ಯ ಮಹರ್ಷಿಗಳಿಗೆ ಈ ರಹಸ್ಯ ನಾಮಾವಳಿಯನ್ನು ಉಪದೇಶಿಸಿದರು. ಪರಮೇಶ್ವರಿ ಲಲಿತಾ ತ್ರಿಪುರ ಸುಂದರಿಯ ಉಪಾಸನೆಯು ಮನಸ್ಸಿಗೆ ಪರಮ ಶಾಂತಿ, ಸಕಲ ಸಕಾರಾತ್ಮಕ ಶಕ್ತಿ ಮತ್ತು ಆಧ್ಯಾತ್ಮಿಕ ಮುಕ್ತಿಯನ್ನು ನೀಡುತ್ತದೆ ಎಂದು ಭಕ್ತರು ನಂಬುತ್ತಾರೆ.';
        case AiLanguage.hindi:
          return 'श्री ललिता सहस्रनाम ब्रह्मांड पुराण के उत्तरखंड में वर्णित देवी ललिता त्रिपुर सुंदरी के 1,000 पावन नामों का दिव्य स्तोत्र है। भगवान हयग्रीव ने महर्षि अगस्त्य को इसका उपदेश दिया था। पारंपरिक मान्यता के अनुसार, इसका नित्य पाठ जीवन में सुख, शांति, सुरक्षा और आध्यात्मिक उन्नति प्रदान करता है।';
        case AiLanguage.tamil:
          return 'ஸ்ரீ லலிதா சஹஸ்ரநாமம் பிரம்மாண்ட புராணத்தில் உள்ள மிகவும் புனிதமான 1,000 திருநாமங்களின் தொகுப்பாகும். ஹயக்ரீவர் அகஸ்திய முனிவருக்கு உபதேசித்த இந்த ஸ்தோத்திரம், அம்பிகையின் அருள், அமைதி மற்றும் ஆன்மீக மேன்மையை அருளக்கூடியது.';
        case AiLanguage.malayalam:
          return 'ബ്രഹ്മാണ്ഡ പുരാണത്തിലെ ലളിതോപാഖ്യാനത്തിൽ ഭഗവാൻ ഹയഗ്രീവൻ അഗസ്ത്യ മഹർഷിക്ക് ഉപദേശിച്ചു കൊടുത്ത 1,000 ദിവ്യ നാമങ്ങളാണ് ശ്രീ ലളിതാ സഹസ്രനാമം. ഇത് ജഗദംബികയുടെ അനുഗ്രഹം, ശാന്തി, ആത്മീയ ഉന്നതി എന്നിവ പ്രധാനം ചെയ്യുന്നു.';
        case AiLanguage.english:
        default:
          return 'Sri Lalitha Sahasranamam is a sacred hymn of 1,000 divine names of the Supreme Goddess Sri Lalitha Tripura Sundari, found in the Brahmanda Purana. Narrated by Lord Hayagriva to Sage Agastya, devotees traditionally chant it for peace, inner strength, spiritual upliftment, and divine grace.';
      }
    }

    // 2. Vishnu Sahasranamam
    if (songId == 'vishnu_sahasranamam' || lower.contains('vishnu') || lower.contains('ವಿಷ್ಣು') || lower.contains('विष्णु') || lower.contains('விஷ்ணு') || lower.contains('വിഷ്ണു')) {
      switch (langCode) {
        case AiLanguage.kannada:
          return 'ವಿಷ್ಣು ಸಹಸ್ರನಾಮವು ಮಹಾಭಾರತದ ಅನುಶಾಸನ ಪರ್ವದಲ್ಲಿ ಕಂಡುಬರುವ ಭಗವಾನ್ ಶ್ರೀ ಮಹಾವಿಷ್ಣುವಿನ 1,000 ನಾಮಗಳ ಮಹಾ ಸ್ತೋತ್ರ. ಕುರುಕ್ಷೇತ್ರ ಯುದ್ಧದ ನಂತರ ಭೀಷ್ಮ ಪಿತಾಮಹರು ಯುಧಿಷ್ಠಿರ ಮಹಾರಾಜನಿಗೆ ಈ ಪರಮ ಧರ್ಮದ ಉಪದೇಶವನ್ನು ನೀಡಿದರು. ಇದರ ಪಠಣದಿಂದ ಭಯ ನಿವಾರಣೆ ಮತ್ತು ಮನಶ್ಶಾಂತಿ ಲಭಿಸುತ್ತದೆ ಎಂಬುದು ಸಾಂಪ್ರದಾಯಿಕ ನಂಬಿಕೆ.';
        case AiLanguage.hindi:
          return 'विष्णु सहस्रनाम महाभारत के अनुशासन पर्व में वर्णित भगवान विष्णु के 1,000 नामों का महास्तोत्र है। शरशैया पर लेटे भीष्म पितामह ने युधिष्ठिर को यह दिव्य उपदेश दिया था। इसके श्रवण और पाठ से जीवन में स्थिरता, सकारात्मकता और शांति प्राप्त होती है।';
        case AiLanguage.tamil:
          return 'விஷ்ணு சஹஸ்ரநாமம் மகாபாரதத்தின் அனுசாசன பர்வத்தில் பீஷ்மர் யுதிஷ்டிரருக்கு உபதேசித்த மகாவிஷ்ணுவின் ஆயிரம் திருநாமங்கள் ஆகும். இது அனைத்து இன்னல்களையும் போக்கி மன அமைதியைத் தரும் என்று நம்பப்படுகிறது.';
        case AiLanguage.malayalam:
          return 'മഹാഭാരതത്തിലെ അനുശാസന പർവ്വത്തിൽ ഭീഷ്മ പിതാമഹൻ യുധിഷ്ഠിരന് ഉപദേശിച്ച മഹാവിഷ്ണുവിന്റെ 1,000 തിരുനാമങ്ങളാണ് വിഷ്ണു സഹസ്രനാമം. ഇത് മനസ്സിന് ശാന്തിയും ഭക്തിയും പ്രധാനം ചെയ്യുന്നു.';
        case AiLanguage.english:
        default:
          return 'Vishnu Sahasranamam is the thousand names of Lord Vishnu found in the Anushasana Parva of the Mahabharata. It was revealed by Bhishma Pitamaha to King Yudhishthira, and is revered across traditions for bestowing peace, courage, and spiritual clarity.';
      }
    }

    // 3. Hanuman Chalisa
    if (songId == 'hanuman_chalisa' || lower.contains('hanuman') || lower.contains('chalisa') || lower.contains('ಹನುಮಾನ್') || lower.contains('हनुमान') || lower.contains('அனுமன்') || lower.contains('ഹനുമാൻ')) {
      switch (langCode) {
        case AiLanguage.kannada:
          return 'ಶ್ರೀ ಹನುಮಾನ್ ಚಾಲೀಸಾವನ್ನು 16ನೇ ಶತಮಾನದಲ್ಲಿ ಭಕ್ತ ಸಂತ ಗೋಸ್ವಾಮಿ ತುಳಸೀದಾಸರು ಅವಧಿ ಭಾಷೆಯಲ್ಲಿ ರಚಿಸಿದರು. ಇದು ಭಗವಾನ್ ಹನುಮಂತನ ಅಪ್ರತಿಮ ಶಕ್ತಿ, ಭಕ್ತಿ, ನಿಷ್ಠೆ ಮತ್ತು ಕೃಪೆಯನ್ನು ವರ್ಣಿಸುವ 40 ಚೌಪಾಯಿಗಳ ಭಕ್ತಿ ಸ್ತೋತ್ರ. ಸಂಕಟಗಳ ನಿವಾರಣೆ ಮತ್ತು ಧೈರ್ಯಕ್ಕಾಗಿ ಇದನ್ನು ನಿತ್ಯವೂ ಪಠಿಸಲಾಗುತ್ತದೆ.';
        case AiLanguage.hindi:
          return 'श्री हनुमान चालीसा 16वीं शताब्दी में गोस्वामी तुलसीदास जी द्वारा अवधी में रचित 40 चौपाइयों का पावन स्तोत्र है। यह भगवान हनुमान की असीम शक्ति, बुद्धि और भक्ति का गुणगान करता है। भक्त इसे संकटमोचन और आत्मबल के लिए श्रद्धा से जपते हैं।';
        case AiLanguage.tamil:
          return 'ஸ்ரீ அனுமன் சாலிசா துளசிதாசரால் அருளப்பட்ட 40 பாடல்களைக் கொண்ட தெய்வீக பிரார்த்தனை. இது தைரியம், பலம் மற்றும் பக்தியை அருளக்கூடிய சக்திவாய்ந்த ஸ்தோத்திரம் ஆகும்.';
        case AiLanguage.malayalam:
          return 'ഭക്തകവി ഗോസ്വാമി തുളസീദാസ് രചിച്ച 40 ചൗപായികൾ അടങ്ങിയ ഭക്തിഗീതമാണ് ശ്രീ ഹനുമാൻ ചാലീസ. ഹനുമാൻ സ്വാമിയുടെ കൃപയും ശക്തിയും നേടാൻ ഭക്തർ ഇത് നിത്യവും ചൊല്ലുന്നു.';
        case AiLanguage.english:
        default:
          return 'The Hanuman Chalisa is a 40-verse hymn composed by Goswami Tulsidas in Awadhi praising Lord Hanuman’s valour, wisdom, and devotion. It is universally chanted for inner courage, protection, and peace of mind.';
      }
    }

    // 4. Shiva Panchakshari / Om Namah Shivaya
    if (songId == 'shiva_panchakshari' || lower.contains('shiva') || lower.contains('panchakshari') || lower.contains('ಶಿವ') || lower.contains('शिव') || lower.contains('சிவன்') || lower.contains('ശിവൻ')) {
      switch (langCode) {
        case AiLanguage.kannada:
          return 'ಶಿವ ಪಂಚಾಕ್ಷರ ಸ್ತೋತ್ರವನ್ನು ಜಗದ್ಗುರು ಶ್ರೀ ಆದಿ ಶಂಕರಾಚಾರ್ಯರು ರಚಿಸಿದ್ದಾರೆ. ಇದು ‘ನ-ಮ-ಶಿ-ವ-ಯ’ ಎಂಬ ಪಂಚ ಮಹಾಭೂತಗಳ ಪ್ರತೀಕವಾದ ಐದು ಪವಿತ್ರ ಅಕ್ಷರಗಳಲ್ಲಿ ನೆಲೆಸಿರುವ ಪರಮೇಶ್ವರನ ದಿವ್ಯ ಸ್ವರೂಪವನ್ನು ಆರಾಧಿಸುತ್ತದೆ.';
        case AiLanguage.hindi:
          return 'शिव पंचाक्षर स्तोत्र आदि शंकराचार्य जी द्वारा विरचित है। यह ‘नमः शिवाय’ के पांच अक्षरों में व्याप्त महादेव शिव के सर्वव्यापक और कल्याणकारी स्वरूप का वर्णन करता है।';
        case AiLanguage.tamil:
          return 'சிவ பஞ்சாட்சர ஸ்தோத்திரம் ஆதி சங்கரரால் அருளப்பட்டது. ‘ந-ம-சி-வா-ய’ என்ற பஞ்சாட்சர மந்திரத்தின் மகிமையையும் சிவபெருமானின் பெருமையையும் இது விளக்குகிறது.';
        case AiLanguage.malayalam:
          return 'ആദി ശങ്കരാചാര്യർ രചിച്ച ശിവ പഞ്ചാക്ഷര സ്തോത്രം ‘ന-മ-ശി-വ-യ’ എന്ന പഞ്ചാക്ഷരങ്ങളിലെ പരമേശ്വര തത്ത്വത്തെ മഹത്വപ്പെടുത്തുന്നു.';
        case AiLanguage.english:
        default:
          return 'The Shiva Panchakshari Stotra composed by Adi Shankaracharya venerates Lord Shiva through the five sacred syllables of ‘Na-Ma-Shi-Va-Ya’, symbolizing the fundamental elements and the eternal divine reality.';
      }
    }

    // 5. Gayatri Mantra
    if (lower.contains('gayatri') || lower.contains('ಗಾಯತ್ರಿ') || lower.contains('गायत्री') || lower.contains('காயத்ரி') || lower.contains('ഗായത്രി')) {
      switch (langCode) {
        case AiLanguage.kannada:
          return 'ಗಾಯತ್ರಿ ಮಂತ್ರವು ಋಗ್ವೇದದ ಪರಮ ಪವಿತ್ರವಾದ ಮಂತ್ರ. ಇದು ವಿಶ್ವದ ಪ್ರಕಾಶಕನಾದ ಸವಿತೃ ದೇವನನ್ನು ಪ್ರಾರ್ಥಿಸುತ್ತಾ, "ನಮ್ಮ ಬುದ್ಧಿಯನ್ನು ಸನ್ಮಾರ್ಗದಲ್ಲಿ ಪ್ರಚೋದಿಸು" ಎಂದು ಜ್ಞಾನ ಮತ್ತು ವಿವೇಕವನ್ನು ಕೋರುತ್ತದೆ.';
        case AiLanguage.hindi:
          return 'गायत्री मंत्र ऋग्वेद का अत्यंत पावन महामंत्र है जो सविता (सूर्य) देव की उपासना के माध्यम से सदबुद्धि, विवेक और ज्ञान की प्रार्थना करता है।';
        case AiLanguage.tamil:
          return 'காயத்ரி மந்திரம் ரிக் வேதத்தில் உள்ள மிக உன்னதமான மந்திரம் ஆகும். இது பேரொளியான இறைவனிடம் நற்புத்தியையும் ஞானத்தையும் அருளுமாறு வேண்டுகிறது.';
        case AiLanguage.malayalam:
          return 'ഋഗ്വേദത്തിലെ പവിത്രമായ ഗായത്രീ മന്ത്രം സൂര്യദേവനായ സവിതൃവിനോട് സദ്ബുദ്ധിയും ജ്ഞാനവും നൽകാൻ പ്രാർത്ഥിക്കുന്ന പ്രാർത്ഥനയാണ്.';
        case AiLanguage.english:
        default:
          return 'The Gayatri Mantra is a revered hymn from the Rigveda dedicated to Savitr (the divine sun/light), praying for illumination of the intellect and spiritual wisdom.';
      }
    }

    // 6. General Devotional / Spiritual concepts
    switch (langCode) {
      case AiLanguage.kannada:
        return 'ಭಕ್ತಿಯು ಮನಸ್ಸಿಗೆ ನೆಮ್ಮದಿ ಮತ್ತು ಭಗವಂತನೊಂದಿಗೆ ಆತ್ಮೀಕ ಅನುಸಂಧಾನವನ್ನು ತರುತ್ತದೆ. ಭಕ್ತಿ ಆ್ಯಪ್‌ನಲ್ಲಿರುವ ಸ್ತೋತ್ರಗಳು, ಸಹಸ್ರನಾಮಗಳು ಮತ್ತು ಚಾಲೀಸಾಗಳನ್ನು ಆಲಿಸಿ ಆನಂದಿಸಿ. ನೀವು ಯಾವುದೇ ಹಾಡನ್ನು ನುಡಿಯುವ ಮೂಲಕ ಅಥವಾ ಕೇಳುವ ಮೂಲಕ ಆಲಿಸಬಹುದು.';
      case AiLanguage.hindi:
        return 'भक्ति मार्ग आत्मा को शांति, समर्पण और दिव्यता से जोड़ता है। भक्ति ऐप पर उपलब्ध पावन स्तोत्रों, सहस्रनामों और चालीसा का आनंद लें। आप किसी भी भजन को बजाने या उसके बारे में जानने के लिए कह सकते हैं।';
      case AiLanguage.tamil:
        return 'பக்தி என்பது இறைவனுடன் ஆன்மாவை இணைக்கும் அமைதியான வழியாகும். பக்தி செயலியில் உள்ள ஸ்தோத்திரங்கள் மற்றும் சஹஸ்ரநாமங்களை கேட்டு மகிழுங்கள்.';
      case AiLanguage.malayalam:
        return 'ഭക്തി മനസ്സിന് ശാന്തിയും ആത്മീയ ഉണർവും നൽകുന്നു. ഭക്തി ആപ്പിലെ സ്തോത്രങ്ങളും നാമങ്ങളും കേട്ട് ഭക്തിസാന്ദ്രമായ അനുഭവം നേടൂ.';
      case AiLanguage.english:
      default:
        return 'Devotion (Bhakti) brings serenity, inner strength, and connection to the divine. You can listen to sacred Sahasranamas, Stotras, and Chalisas on Bhakti anytime by voice or text.';
    }
  }
}
