import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late IntegrationTestWidgetsFlutterBinding binding;

void initBinding() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

Future<void> screenshot(String name) async {
  final bytes = await binding.takeScreenshot(name);
  try {
    await Directory('screenshots').create(recursive: true);
    await File('screenshots/$name.png').writeAsBytes(bytes);
  } on FileSystemException {
    // Device-side integration tests may run in a read-only sandbox.
  }
  debugPrint('[SCREENSHOT] $name');
}

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<bool> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

Future<void> waitForText(WidgetTester tester, String text) async {
  final found = await waitFor(tester, find.text(text));
  expect(found, isTrue, reason: 'Expected "$text" to appear.');
}

Future<void> waitUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 20),
  String reason = 'condition was not met',
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (predicate()) return;
  }
  fail('Timed out waiting for $reason.');
}

Future<void> tapTab(WidgetTester tester, String label) async {
  final key = ValueKey('tab_${label.toLowerCase()}');
  final keyedFinder = find.byKey(key);
  final finder = keyedFinder.evaluate().isNotEmpty
      ? keyedFinder
      : find.descendant(
          of: find.byType(CupertinoTabBar),
          matching: find.text(label),
        );
  expect(finder, findsOneWidget);
  await tester.tap(finder);
  await settle(tester);
}

Future<void> tapBack(WidgetTester tester) async {
  try {
    await tester.pageBack();
    await settle(tester);
    return;
  } catch (_) {
    for (final icon in [
      CupertinoIcons.back,
      CupertinoIcons.chevron_back,
    ]) {
      final finder = find.byIcon(icon);
      if (finder.evaluate().isNotEmpty) {
        await tester.tap(finder.first);
        await settle(tester);
        return;
      }
    }
  }
  fail('Back button was not available.');
}

void expectNotBlackScreen(String hint) {
  expect(
    find.byType(Text),
    findsWidgets,
    reason: 'Screen should not be black or empty after: $hint',
  );
}

Future<void> scrollToText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      350,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 30,
    );
  }
  await tester.ensureVisible(finder.first);
  await settle(tester);
}

void setUpFreshInstall() {
  SharedPreferences.setMockInitialValues({});
}

void setUpWithAiConsent({bool consent = true}) {
  SharedPreferences.setMockInitialValues({
    'experts.settings': jsonEncode({
      'aiConsentGiven': consent,
      'educationalDisclaimerAccepted': false,
      'dataSourceAttributionAccepted': false,
    }),
  });
}

void setUpWithWatchlist() {
  SharedPreferences.setMockInitialValues({
    'experts.watchlist': jsonEncode([
      {
        'symbol': 'AAPL',
        'name': 'Apple Inc.',
        'type': 'stock',
        'addedAt': DateTime.now().toIso8601String(),
        'lastPrice': 195.25,
        'changePercent': 0.8,
      },
    ]),
  });
}
