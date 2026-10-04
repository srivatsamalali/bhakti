import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bhakti/features/rewards/seva_wallet_screen.dart';
import 'package:bhakti/services/preferences/preferences_service.dart';
import 'package:bhakti/services/rewards/seva_token_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SevaWalletScreen renders without layout overflow or collapse', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesService.create();
    final sevaService = SevaTokenService(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PreferencesService>.value(value: prefs),
          ChangeNotifierProvider<SevaTokenService>.value(value: sevaService),
        ],
        child: const MaterialApp(
          home: SevaWalletScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Seva Karma & Rewards 🪙'), findsOneWidget);
    expect(find.text('Your Sacred Devotee Passkey'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('1-Day Ad-Free Sacred Listening'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('1-Day Ad-Free Sacred Listening'), findsOneWidget);

    final perkText = tester.renderObject(find.text('1-Day Ad-Free Sacred Listening')) as RenderBox;
    expect(perkText.size.width, greaterThan(100));
  });
}
