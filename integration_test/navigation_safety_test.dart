import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:experts/main.dart' as app;

import 'helpers/test_helpers.dart';

void main() {
  initBinding();

  group('Navigation safety', () {
    testWidgets('back from Asset Details returns to Home', (tester) async {
      setUpFreshInstall();
      app.main();
      await settle(tester);
      await waitForText(tester, 'Experts');

      await tester.tap(find.text('AAPL').first);
      await settle(tester);
      await waitForText(tester, 'Apple Inc');

      await tapBack(tester);
      expect(find.text('Experts'), findsOneWidget);
      expectNotBlackScreen('back from Asset Details');
      await screenshot('nav_back_asset_details');
    });

    testWidgets('tab roots have no pushed back button', (tester) async {
      setUpFreshInstall();
      app.main();
      await settle(tester);
      await waitForText(tester, 'Experts');

      for (final tab in ['Home', 'Watchlist', 'Settings']) {
        await tapTab(tester, tab);
        expect(find.byType(CupertinoNavigationBarBackButton), findsNothing);
        expectNotBlackScreen('$tab root');
      }
    });
  });
}
