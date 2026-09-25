import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'repositories/category_repository.dart';
import 'repositories/song_repository.dart';
import 'services/ads/ad_service.dart';
import 'services/analytics/analytics_service.dart';
import 'services/audio/audio_player_service.dart';
import 'services/ai/ai_tools_service.dart';
import 'services/ai/bhakti_ai_service.dart';
import 'services/ai/voice_service.dart';
import 'services/firebase/auth_service.dart';
import 'services/firebase/firestore_service.dart';
import 'services/preferences/preferences_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize JustAudioBackground before runApp (required for iOS background audio lifecycle)
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.bhakti.devotional.audio',
      androidNotificationChannelName: 'Bhakti Devotional Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
  } catch (e) {
    debugPrint('JustAudioBackground init notice: $e');
  }

  // 2. Initialize SharedPreferences local persistence
  final prefsService = await PreferencesService.create();

  // 3. Initialize Firebase (safely wrapped)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // 4. Launch Flutter Application UI
  runApp(BhaktiApp(prefsService: prefsService));

  // 5. Initialize AdMob & Analytics asynchronously after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      AdService.instance.initialize().catchError((e) {
        debugPrint('AdMob initialization notice: $e');
      });
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }

    try {
      AnalyticsService.instance.initialize();
    } catch (e) {
      debugPrint('Analytics initialization notice: $e');
    }
  });
}

class BhaktiApp extends StatefulWidget {
  final PreferencesService prefsService;

  const BhaktiApp({super.key, required this.prefsService});

  @override
  State<BhaktiApp> createState() => _BhaktiAppState();
}

class _BhaktiAppState extends State<BhaktiApp> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PreferencesService>.value(value: widget.prefsService),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(widget.prefsService),
        ),
        ChangeNotifierProvider<CategoryRepository>(
          create: (_) => CategoryRepository(firestoreService),
        ),
        ChangeNotifierProvider<SongRepository>(
          create: (_) => SongRepository(firestoreService, widget.prefsService),
        ),
        ChangeNotifierProxyProvider<SongRepository, AudioPlayerService>(
          create: (ctx) => AudioPlayerService(widget.prefsService)..setDependencies(null, firestoreService),
          update: (ctx, songRepo, player) {
            final p = player ?? AudioPlayerService(widget.prefsService);
            p.setDependencies(songRepo, firestoreService);
            return p;
          },
        ),
        ChangeNotifierProvider<VoiceService>(
          create: (_) => VoiceService(),
        ),
        ProxyProvider3<SongRepository, AudioPlayerService, CategoryRepository, AiToolsService>(
          create: (ctx) => AiToolsService(
            songRepository: ctx.read<SongRepository>(),
            audioPlayerService: ctx.read<AudioPlayerService>(),
            categoryRepository: ctx.read<CategoryRepository>(),
          ),
          update: (ctx, songRepo, player, catRepo, prev) =>
              AiToolsService(songRepository: songRepo, audioPlayerService: player, categoryRepository: catRepo),
        ),

        ChangeNotifierProxyProvider3<PreferencesService, AiToolsService, VoiceService, BhaktiAiService>(
          create: (ctx) => BhaktiAiService(
            preferencesService: ctx.read<PreferencesService>(),
            toolsService: ctx.read<AiToolsService>(),
            voiceService: ctx.read<VoiceService>(),
          ),
          update: (ctx, prefs, tools, voice, prev) =>
              prev ?? BhaktiAiService(preferencesService: prefs, toolsService: tools, voiceService: voice),
        ),
      ],

      child: Consumer<PreferencesService>(
        builder: (context, prefs, _) {
          final currentLangCode = prefs.getSelectedLanguage();

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.lightTheme,
            themeMode: ThemeMode.light,
            locale: Locale(currentLangCode),
            supportedLocales: const [
              Locale(AppConstants.langKannada),
              Locale(AppConstants.langEnglish),
              Locale(AppConstants.langHindi),
              Locale(AppConstants.langTamil),
              Locale(AppConstants.langMalayalam),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
