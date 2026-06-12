# Experts PRD

## Summary

Experts is a free iOS Flutter app that helps users understand US stocks and ETFs through multiple AI-generated market-analysis perspectives. The product promise is:

> Look at an asset through the eyes of multiple experts in a few seconds.

Experts is educational. It must not present itself as a trading signal app, financial advisor, price target engine, or buy/sell recommendation tool.

## MVP Goals

- Help beginner traders and investors compare bullish, bearish, risk, and consensus narratives.
- Support ticker-based analysis for US stocks and ETFs.
- Support one chart screenshot upload for visual chart interpretation.
- Show lightweight market data, chart context, and recent news before analysis.
- Keep the MVP free with no subscriptions, ads, accounts, brokerage connection, or sync.
- Keep App Store positioning clearly educational.

## Non-Goals

- No crypto coverage in the MVP.
- No trading execution or brokerage integration.
- No personalized financial advice.
- No guaranteed predictions, direct buy/sell language, or price targets.
- No social/community features.
- No dark theme in the MVP.

## Platform

- Flutter iOS app.
- Riverpod for state management.
- SharedPreferences for MVP persistence where local storage is enough.
- Cupertino-only interface. Do not use Material widgets, Material themes, or Material app scaffolding.
- UI copy must be English only.

## Design Direction

Visual source: [DESIGN.md](/Users/infoas/new_projects/experts/DESIGN.md).

Experts uses a light-only fintech style inspired by Exness without cloning its brand:

- warm white/off-white canvas
- deep navy typography
- yellow primary CTAs
- clean financial cards
- soft gray dividers and surfaces
- native iOS interaction patterns
- medium density for analysis and scanning

Implementation must use centralized tokens for colors, typography, spacing, radii, and shadows. Do not hardcode colors or text styles in feature widgets.

## Core User Flow

1. User opens Experts.
2. User searches for a ticker or selects a saved asset.
3. App opens Asset Details.
4. User reviews price, chart, and news context.
5. User may attach one chart screenshot.
6. User may add an optional analysis note.
7. User taps Analyze.
8. App gates the first AI action behind AI data consent.
9. App generates Bull, Bear, Risk, Consensus, and final report sections.
10. Every AI report includes an educational disclaimer.

## Core Screens

### Home

- App title: "Experts"
- Value line: "Market analysis from multiple AI perspectives."
- Search field for ticker/name.
- Watchlist shortcuts.
- Recent searches.
- Empty, loading, and error states.

### Asset Details

- Symbol and company name.
- Asset type.
- Current price.
- Price change and percentage change.
- Simple chart with 1D, 1W, 1M, 6M, and 1Y timeframes.
- Watchlist icon button.
- Screenshot attachment entry point.
- Optional analysis note.
- Analyze action.
- News list.

### AI Report

- Asset summary.
- Consensus summary first.
- Bull Analyst card.
- Bear Analyst card.
- Risk Analyst card.
- Final educational disclaimer.

### Settings

- AI Privacy section.
- AI Data Consent toggle.
- Data source attribution.
- Educational disclaimer/legal notes.

## AI Requirements

- Use Google Gemini through direct HTTP requests, not AI SDK packages.
- Use `dart:io` `HttpClient`, `dart:convert`, and UTF-8 request encoding.
- Use structured JSON responses for report generation.
- Never log or commit real API keys.
- Reuse local `GOOGLE_API_KEY` setup only during implementation; public docs must not contain the secret.

## Multi-Analyst Flow

The MVP should use separate AI calls:

1. Bull Analyst receives asset data, chart context, news context, screenshot observations when available, and optional user note.
2. Bear Analyst receives the same context and focuses on downside arguments.
3. Risk Analyst receives the same context and focuses on uncertainty and risk.
4. Consensus Analyst receives the first three analyst outputs.
5. Final Report formats all sections for the UI.

Prompts must:

- Ask for educational analysis only.
- Ban direct buy/sell/short/enter/exit commands.
- Avoid price targets and guarantees.
- Include uncertainty when data is incomplete.
- Return valid JSON when structured responses are requested.

## AI Consent

Before any AI call:

- If `aiConsentGiven == null`, show the AI consent dialog.
- If the user agrees, persist `true` and continue.
- If the user declines, persist `false` and stop the action.
- If `aiConsentGiven == false`, block the AI action and direct the user to Settings.

Consent copy must explain that Experts uses Google Gemini and may send ticker, market data, news summaries, optional notes, and uploaded chart images for analysis. Do not claim any retention policy unless verified later.

## Data Sources

- Market data candidate: Finnhub.
- News candidate: Finnhub company/news endpoints.
- Finnhub key is configured for the MVP; runtime overrides should still use `FINNHUB_API_KEY` when needed.
- Confirm free-tier rate limits, ETF coverage, attribution requirements, and endpoint availability during implementation.

## Chart Screenshot Upload

- Single image only for MVP.
- Use `image_picker`.
- Use `maxWidth: 1200`, `maxHeight: 1200`, `imageQuality: 85`.
- Provide camera and photo library options.
- Required iOS permission copy:
  - Camera: "Experts needs camera access to take chart screenshots for AI market analysis."
  - Photo Library: "Experts needs photo library access to choose chart screenshots for AI market analysis."

## Watchlist

- Add/remove assets.
- Show saved tickers on Home.
- Persist locally.
- No account or sync.

## Required Disclaimer

> Experts does not provide financial advice, trading recommendations, or guarantees of future performance.

The disclaimer must appear in every AI report and in Settings/legal notes.
