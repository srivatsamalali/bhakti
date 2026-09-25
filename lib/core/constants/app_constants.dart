/// Core application constants for Bhakti app
class AppConstants {
  AppConstants._();

  static const String appName = 'Bhakti';
  static const String appTagline = 'Divine Music for a Better Life';
  static const String appSpiritualTagline = 'Spirituality for Everyone, Everywhere';
  static const String appUniversalPrayer = '॥ लोकाः समस्ताः सुखिनೋ ಭವಂತು ॥';
  static const String appVersion = '1.0.1';

  // Supported language codes
  static const String langKannada = 'kn';
  static const String langEnglish = 'en';
  static const String langHindi = 'hi';
  static const String langTamil = 'ta';
  static const String langMalayalam = 'ml';

  static const List<String> supportedLanguages = [
    langKannada,
    langEnglish,
    langHindi,
    langTamil,
    langMalayalam,
  ];

  // Storage Keys
  static const String keySelectedLanguage = 'bhakti_selected_language';
  static const String keyIsFirstLaunch = 'bhakti_is_first_launch';
  static const String keyFavorites = 'bhakti_favorite_song_ids';
  static const String keyRecentlyPlayed = 'bhakti_recently_played_ids';
  static const String keyAdminHashedPass = 'bhakti_admin_security_hash';
  static const String keyPlaybackSpeed = 'bhakti_playback_speed';

  // AI Assistant Preferences Keys
  static const String keyAiEnabled = 'bhakti_ai_enabled';
  static const String keyAiVoiceInputEnabled = 'bhakti_ai_voice_input_enabled';
  static const String keyAiVoiceOutputEnabled = 'bhakti_ai_voice_output_enabled';
  static const String keyAiPreferredLanguage = 'bhakti_ai_pref_language';
  static const String keyAdminAiDailyLimit = 'bhakti_admin_ai_daily_limit';
  static const String keyAdminAiMaxTokens = 'bhakti_admin_ai_max_tokens';
  static const String keyAdminAiGlobalEnabled = 'bhakti_admin_ai_global_enabled';


  // Default Admin Credentials (Development)
  static const String defaultAdminUser = 'sri';
  static const String defaultAdminPass = 'sri';

  // Firestore Collections
  static const String colSongs = 'songs';
  static const String colCategories = 'categories';
  static const String colAdmins = 'admins';
  static const String colAppConfig = 'app_config';

  // AdMob Production Unit IDs (Android)
  static const String prodAndroidBannerId = 'ca-app-pub-4673754881851008/7036485474';
  static const String prodAndroidInterstitialId = 'ca-app-pub-4673754881851008/5559666555';

  // AdMob Test Unit IDs (For safe debug/development)
  static const String testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testAndroidNativeId = 'ca-app-pub-3940256099942544/2247696110';

  static const String testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String testIosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';
  static const String testIosNativeId = 'ca-app-pub-3940256099942544/3986624511';

  // Max bounds
  static const int maxRecentHistoryCount = 25;
  static const int maxUploadImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxUploadAudioSizeBytes = 50 * 1024 * 1024; // 50MB
}
