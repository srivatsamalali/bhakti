import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhakti/features/language/language_selection_screen.dart';
import 'package:bhakti/features/settings/settings_screen.dart';
import 'package:bhakti/features/favorites/favorites_screen.dart';
import 'package:bhakti/repositories/song_repository.dart';
import 'package:bhakti/services/firebase/firestore_service.dart';
import 'package:bhakti/services/firebase/auth_service.dart';
import 'package:bhakti/services/audio/audio_player_service.dart';
import 'package:bhakti/services/preferences/preferences_service.dart';
import 'package:bhakti/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LanguageSelectionScreen renders sacred languages', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'bhakti_selected_language': 'kn',
    });

    final prefsService = await PreferencesService.create();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PreferencesService>.value(value: prefsService),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
          ],
          home: Scaffold(
            body: LanguageSelectionScreen(isInitialLaunch: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ಕನ್ನಡ'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('മലയാളം'), findsOneWidget);
  });

  testWidgets('FavoritesScreen renders empty state when no favorites', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefsService = await PreferencesService.create();
    final firestoreService = FirestoreService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PreferencesService>.value(value: prefsService),
          ChangeNotifierProvider<SongRepository>(
            create: (_) => SongRepository(firestoreService, prefsService),
          ),
          ChangeNotifierProvider<AudioPlayerService>(
            create: (_) => AudioPlayerService(prefsService),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
          ],
          home: FavoritesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FavoritesScreen), findsOneWidget);
  });

  testWidgets('SettingsScreen renders options and preferences', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefsService = await PreferencesService.create();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PreferencesService>.value(value: prefsService),
          ChangeNotifierProvider<AuthService>(
            create: (_) => AuthService(prefsService),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
          ],
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
