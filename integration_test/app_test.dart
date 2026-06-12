import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:experts/main.dart' as app;

import 'helpers/test_helpers.dart';

void main() {
  initBinding();

  group('Experts MVP e2e', () {
    testWidgets('fresh install shows Home and tab roots', (tester) async {
      setUpFreshInstall();
      app.main();
      await settle(tester);
      await waitForText(tester, 'Experts');

      expect(find.text('Market analysis from multiple AI perspectives.'), findsOneWidget);
      expect(find.text('Search stocks and ETFs'), findsOneWidget);
      expect(find.text('No saved assets yet'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);
      await screenshot('01_home_fresh_install');

      await tapTab(tester, 'Watchlist');
      expect(find.text('Saved Assets'), findsOneWidget);
      expect(find.text('No saved assets yet'), findsOneWidget);
      await screenshot('02_watchlist_empty');

      await tapTab(tester, 'Settings');
      expect(find.text('AI Privacy'), findsOneWidget);
      expect(find.text('Data Sources'), findsOneWidget);
      expect(find.text('Market Data'), findsOneWidget);
      await screenshot('03_settings');

      await tapTab(tester, 'Home');
      expect(find.text('Experts'), findsOneWidget);
    });

    testWidgets('AAPL details, screenshot, note, and watchlist flow', (
      tester,
    ) async {
      setUpFreshInstall();
      app.main();
      await settle(tester);
      await waitForText(tester, 'Experts');

      await tester.tap(find.text('AAPL').first);
      await settle(tester);
      await waitForText(tester, 'Apple Inc');
      await waitUntil(
        tester,
        () => find.text('Price unavailable').evaluate().isEmpty,
        reason: 'AAPL quote to load',
      );
      expect(find.text('AAPL'), findsWidgets);
      await screenshot('04_aapl_details_quote');

      await waitUntil(
        tester,
        () => find.byType(LineChart).evaluate().isNotEmpty,
        reason: 'AAPL chart to render from Twelve Data',
      );
      expect(find.text('Last'), findsOneWidget);
      expect(find.text('1M change'), findsOneWidget);
      expect(find.textContaining('Range'), findsOneWidget);
      expect(find.text('Chart: Twelve Data daily history'), findsOneWidget);
      await screenshot('05_chart_loaded');

      await scrollToText(tester, 'Chart Screenshot');
      await tester.tap(find.text('Add chart screenshot'));
      await settle(tester);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Library'), findsOneWidget);
      await screenshot('06_screenshot_picker_sheet');

      await tester.tap(find.text('Choose from Library'));
      await settle(tester);
      expect(find.text('Add chart screenshot'), findsNothing);
      await screenshot('07_screenshot_attached');

      await tester.tap(find.byIcon(CupertinoIcons.xmark).first);
      await settle(tester);
      expect(find.text('Add chart screenshot'), findsOneWidget);
      await tester.tap(find.text('Add chart screenshot'));
      await settle(tester);
      await tester.tap(find.text('Choose from Library'));
      await settle(tester);
      expect(find.text('Test screenshot attached'), findsOneWidget);
      await screenshot('07b_screenshot_reattached');

      await scrollToText(tester, 'Analysis Note');
      await tester.enterText(
        find.byType(CupertinoTextField).last,
        'Focus on the latest news and risk context.',
      );
      await tester.pump();
      await screenshot('08_note_entered');

      await tester.pageBack();
      await settle(tester);
      await waitForText(tester, 'Experts');
      await tester.tap(find.text('AAPL').first);
      await settle(tester);
      await waitForText(tester, 'Apple Inc');
      await tester.tap(find.byIcon(CupertinoIcons.heart).first);
      await settle(tester);
      expect(find.byIcon(CupertinoIcons.heart_fill), findsWidgets);

      await tester.pageBack();
      await settle(tester);
      await tapTab(tester, 'Watchlist');
      expect(find.text('Saved Assets'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);
      await screenshot('09_watchlist_aapl_saved');

      await tester.tap(find.byIcon(CupertinoIcons.xmark_circle).first);
      await settle(tester);
      expect(find.text('No saved assets yet'), findsOneWidget);
    });

    testWidgets('SPY is treated as ETF with useful metadata', (tester) async {
      setUpFreshInstall();
      app.main();
      await settle(tester);
      await waitForText(tester, 'Experts');

      await tester.enterText(find.byType(CupertinoTextField).first, 'SPY');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);
      await waitForText(tester, 'SPY');
      await waitUntil(
        tester,
        () => find.textContaining('ETF').evaluate().isNotEmpty,
        reason: 'SPY ETF metadata',
      );
      expect(find.textContaining('SPDR'), findsWidgets);
      expect(find.textContaining('ETF'), findsWidgets);
      await waitUntil(
        tester,
        () => find.byType(LineChart).evaluate().isNotEmpty,
        reason: 'SPY chart to render from Twelve Data',
      );
      expect(find.text('Last'), findsOneWidget);
      expect(find.text('1M change'), findsOneWidget);
      expect(find.textContaining('Range'), findsOneWidget);
      await screenshot('10_spy_etf_details');
    });

    testWidgets('AI consent decline blocks report and re-enable opens report', (
      tester,
    ) async {
      setUpFreshInstall();
      app.main();
      await settle(tester);
      await waitForText(tester, 'Experts');

      await tester.tap(find.text('AAPL').first);
      await settle(tester);
      await waitForText(tester, 'Apple Inc');
      await scrollToText(tester, 'Analyze');

      await tester.tap(find.text('Analyze'));
      await settle(tester);
      expect(find.text('AI Analysis Disclaimer'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await settle(tester);
      expect(find.text('AI Data Usage'), findsOneWidget);
      await screenshot('11_ai_consent_dialog');

      await tester.tap(find.text('Decline'));
      await settle(tester);
      expect(find.text('AI Data Usage'), findsNothing);
      expect(find.text('AI Report'), findsNothing);

      await tester.tap(find.text('Analyze'));
      await settle(tester);
      expect(find.text('AI Consent Required'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      await settle(tester);
      expect(find.text('Settings'), findsWidgets);

      await tester.tap(find.byType(CupertinoSwitch).first);
      await settle(tester);
      expect(find.text('AI Data Usage'), findsOneWidget);
      await tester.tap(find.text('I Agree'));
      await settle(tester);
      expect(find.text('You agreed to send analysis context to Gemini.'), findsOneWidget);
      await screenshot('12_ai_consent_enabled');
    });

    testWidgets('Analyze opens report with disclaimer after consent', (
      tester,
    ) async {
      setUpFreshInstall();
      app.main();
      await settle(tester);
      await waitForText(tester, 'Experts');

      await tester.tap(find.text('AAPL').first);
      await settle(tester);
      await waitForText(tester, 'Apple Inc');
      await scrollToText(tester, 'Analyze');

      await tester.tap(find.text('Analyze'));
      await settle(tester);
      if (find.text('AI Analysis Disclaimer').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await settle(tester);
      }
      if (find.text('AI Data Usage').evaluate().isNotEmpty) {
        await tester.tap(find.text('I Agree'));
        await settle(tester);
      }
      final reachedReport = await waitFor(
        tester,
        find.text('AI Report'),
        timeout: const Duration(seconds: 120),
      );
      expect(reachedReport, isTrue, reason: 'Expected AI Report to appear.');
      await waitForText(tester, 'Lead Analyst Conclusion');
      await scrollToText(tester, 'Educational disclaimer');
      expect(find.text('Educational disclaimer'), findsOneWidget);
      expect(
        find.textContaining('financial advice'),
        findsWidgets,
      );
      await screenshot('13_ai_report_disclaimer');
    });
  });
}
