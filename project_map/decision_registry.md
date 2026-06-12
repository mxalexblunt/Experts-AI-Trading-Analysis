# Decision Registry

## Product Decisions

- Experts is educational market context, not financial advice.
- MVP covers US stocks and ETFs only.
- Crypto is deferred.
- No monetization in the MVP.
- No account or sync in the MVP.
- Consensus appears before individual analyst cards.

## Engineering Decisions

- Flutter iOS MVP.
- Cupertino-only UI.
- Riverpod state management.
- SharedPreferences for simple local persistence.
- Gemini via direct HTTP requests.
- Structured JSON for AI report responses.
- Finnhub is the initial market data/news candidate.
- `fl_chart` is the initial chart package candidate.
- `image_picker` is the screenshot upload package.

## Design Decisions

- Light-only fintech interface.
- Centralized design tokens required.
- Yellow is reserved for primary actions and selected emphasis.
- Standard cards use 8px radius.
- Use small semantic accents for Bull/Bear/Risk/Consensus instead of full-color cards.
- UI text is English only.

