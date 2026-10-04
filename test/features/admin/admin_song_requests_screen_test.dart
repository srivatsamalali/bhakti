import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhakti/features/admin/admin_song_requests_screen.dart';
import 'package:bhakti/services/preferences/preferences_service.dart';
import 'package:bhakti/services/rewards/seva_token_service.dart';
import 'package:bhakti/services/firebase/song_request_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AdminSongRequestsScreen renders devotee song requests and status filters', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesService.create();
    final sevaService = SevaTokenService(prefs);
    final requestService = SongRequestService(sevaService);

    // Submit a sample request
    await requestService.submitRequest(
      songTitle: 'Kandar Anubhuti',
      deity: 'Lord Murugan',
      language: 'ta',
      singerOrComposer: 'Arunagirinathar',
      notes: 'Please add with authentic Tamil lyrics',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PreferencesService>.value(value: prefs),
          ChangeNotifierProvider<SevaTokenService>.value(value: sevaService),
          ChangeNotifierProvider<SongRequestService>.value(value: requestService),
        ],
        child: const MaterialApp(
          home: AdminSongRequestsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Devotee Song Requests 📜'), findsOneWidget);
    expect(find.text('Kandar Anubhuti'), findsOneWidget);
    expect(find.text('🛕 Lord Murugan'), findsOneWidget);
    expect(find.text('Singer/Composer: Arunagirinathar'), findsOneWidget);
    expect(find.text('Add to Catalog'), findsOneWidget);
  });
}
