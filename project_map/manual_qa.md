# Manual QA Checklist

Run these after opening the app on an iOS simulator/device. The current Finnhub key supports search, quotes, and news; charts require a Twelve Data key.

## Automated E2E Pass

Last checked: 2026-06-09 on iPhone 17 Pro simulator.

- `flutter test integration_test/app_test.dart -d 85C86B16-B8A4-4282-8B0F-8524F80E0D6A --dart-define=EXPERTS_E2E_FAKE_PICKER=true --dart-define=EXPERTS_E2E_FAKE_AI=true --reporter expanded`
- `flutter test integration_test/navigation_safety_test.dart -d 85C86B16-B8A4-4282-8B0F-8524F80E0D6A --dart-define=EXPERTS_E2E_FAKE_PICKER=true --dart-define=EXPERTS_E2E_FAKE_AI=true --reporter expanded`
- `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d 85C86B16-B8A4-4282-8B0F-8524F80E0D6A --dart-define=EXPERTS_E2E_FAKE_PICKER=true --dart-define=EXPERTS_E2E_FAKE_AI=true`
- `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/navigation_safety_test.dart -d 85C86B16-B8A4-4282-8B0F-8524F80E0D6A --dart-define=EXPERTS_E2E_FAKE_PICKER=true --dart-define=EXPERTS_E2E_FAKE_AI=true`

Screenshots saved in `screenshots/`; visual contact sheet reviewed at `screenshots/contact_sheet.png`.

Notes:
- Screenshot upload uses `EXPERTS_E2E_FAKE_PICKER=true` to avoid native Photos/Camera automation.
- AI report uses `EXPERTS_E2E_FAKE_AI=true` to avoid Gemini network hangs in automated tests.
- Finnhub market data is live for search, quotes, and news.
- Twelve Data chart history is live when `TWELVE_DATA_API_KEY` is configured.

## Recommended Commands

- `flutter analyze`
- `flutter run -d <ios-simulator-id>`

Do not run builds, tests, or formatters unless explicitly requested by the user.

## Core Flow

- [X] Open the app and confirm the first screen is Home, not a marketing page.
- [X] Search or enter `AAPL`, then open Asset Details.
- [X] Confirm quote and news data load for `AAPL`.
- [X] Confirm AAPL chart history renders when `TWELVE_DATA_API_KEY` is configured.
- [X] Confirm SPY chart history renders when `TWELVE_DATA_API_KEY` is configured.
- [ ] Confirm chart unavailable state clearly explains a missing chart key.
- [X] Search or enter `SPY`, then confirm it is treated as an ETF with a useful name.
- [X] Add a chart screenshot from the library path. E2E uses fake picker bytes after tapping `Choose from Library`.
- [X] Remove the screenshot and add it again.
- [X] Enter an analysis note shorter than 240 characters.
- [X] Tap Analyze and confirm the AI consent dialog appears before the first AI call.
- [X] Decline consent and confirm the report is not generated.
- [X] Re-enable consent in Settings.
- [X] Run Analyze again and confirm the AI Report screen opens.
- [X] Confirm every report includes the educational disclaimer.
- [X] Add the asset to Watchlist, return to Watchlist, and confirm it appears.
- [X] Remove the asset from Watchlist.

## Visual Review

- [X] Confirm the app is light-only.
- [X] Confirm no UI copy is Russian.
- [X] Confirm CTAs use yellow and ordinary surfaces stay white/off-white.
- [X] Confirm no crypto motifs or dark-mode surfaces appear.
