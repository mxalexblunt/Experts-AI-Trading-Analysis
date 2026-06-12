# Experts PRD

## Product Summary

Experts is a free market-analysis app that helps users understand a financial asset from several AI-generated perspectives.

The core promise:

> Look at an asset through the eyes of multiple experts in a few seconds.

Users can search for a US stock ticker or upload a chart screenshot. The app then creates a structured educational analysis from four roles:

- Bull Analyst
- Bear Analyst
- Risk Analyst
- Consensus Analyst

Experts must not present itself as a trading signal app. It provides educational market context, not financial advice, price targets, guarantees, or direct buy/sell recommendations.

---

## Product Status

This document is the working PRD for the MVP.

Visual direction is defined in [DESIGN.md](/Users/infoas/new_projects/experts/DESIGN.md): Exness-inspired, light-only fintech style.

---

## Skill References

Implementation should follow these local Codex skills:

- [skill-ai-integration](/Users/infoas/.codex/skills/skill-ai-integration/SKILL.md)
  - Use Google Gemini through direct HTTP requests.
  - Do not use AI SDK packages.
  - Use `dart:io` `HttpClient`, `dart:convert`, and UTF-8 request encoding.
  - Use JSON response mode when structured output is required.

- [skill-ai-consent](/Users/infoas/.codex/skills/skill-ai-consent/SKILL.md)
  - Show AI consent only on first AI feature use, not at app launch.
  - Persist `AppSettings.aiConsentGiven` as `bool?`.
  - Add an AI Privacy settings toggle.
  - Block AI calls when consent is missing or revoked.
  - Never send the user's real name to AI; use `$USERNAME` placeholder replacement if the app ever supports user names.

- [skill-image-picker](/Users/infoas/.codex/skills/skill-image-picker/SKILL.md)
  - Use `image_picker` for chart screenshot upload.
  - Add iOS camera and photo library permission descriptions with Experts-specific purpose text.
  - Use a single-image attachment flow for MVP chart analysis.
  - Use `maxWidth: 1200`, `maxHeight: 1200`, and `imageQuality: 85`.

- [skill-nano-banana](/Users/infoas/.codex/skills/skill-nano-banana/SKILL.md)
  - Gemini API key source can reuse the existing `GOOGLE_API_KEY` environment setup from this skill.
  - Do not print or commit the real key.
  - If a runtime app key must be embedded during MVP implementation, keep the PRD and public docs free of the actual secret value.

- [skill-design-extractor](/Users/infoas/.codex/skills/skill-design-extractor/SKILL.md)
  - Use `design_reference/image.png` as the primary visual reference.
  - Build an Exness-inspired light fintech design system, not a direct clone.
  - Keep the MVP light-only.
  - Use `DESIGN.md` as the implementation source for colors, typography, spacing, components, and screen patterns.

---

## Visual Direction

Experts should use an Exness-inspired light fintech style:

- warm white/off-white canvas
- deep navy typography
- yellow primary CTAs
- clean financial cards
- soft gray dividers and surfaces
- mobile-first premium product feel
- no dark theme in the MVP

Full design tokens and component rules live in [DESIGN.md](/Users/infoas/new_projects/experts/DESIGN.md).

---

## Target Users

- Beginner traders who want quick context before deeper research.
- Investors who want to compare bullish and bearish narratives.
- TradingView users who already look at charts and want a second opinion.
- Users who want a fast explanation of what may be happening with a ticker.

---

## Core Value

Most market apps show charts, prices, and news.

Experts adds a structured thinking layer:

- Why the asset might go up.
- Why the asset might go down.
- What risks matter right now.
- Which scenario appears most balanced based on available context.

The value is not "the AI knows the future." The value is "the AI helps the user consider multiple angles before forming their own view."

---

## Product Goals

- Make market analysis easier to understand for non-professional users.
- Present opposing views side by side instead of one overconfident answer.
- Support both US stock ticker-based analysis and chart screenshot analysis.
- Keep the app free with no paid tiers.
- Keep App Store positioning clearly educational.

---

## Non-Goals

- No monetization or premium tier in the MVP.
- No brokerage integration.
- No trading execution.
- No personalized financial advice.
- No guaranteed signals, predictions, or "buy/sell now" language.
- No social/community features in the MVP.
- No crypto coverage in the first MVP.

---

## Platform & Interface Requirements

- Initial target: iOS Flutter app.
- State management: Riverpod.
- Persistence: SharedPreferences is acceptable for MVP settings/watchlist storage.
- Application UI text must be English only.
- PRD and internal planning can be in Russian/English, but user-facing labels, buttons, placeholders, errors, dialogs, onboarding, and settings must be English.

---

## MVP Functional Scope

### 1. Home / Search

User can search for an asset by ticker or name.

Supported asset types for MVP:

- Stocks
- ETFs

Deferred until after MVP:

- Crypto

Example queries:

- AAPL
- TSLA
- NVDA
- SPY
- QQQ

Expected UI:

- Search field.
- Recent searches.
- Watchlist shortcut.
- Empty state for first launch.
- Loading and error states.

### 2. Asset Details

The asset details screen should show enough context before AI analysis.

Required content:

- Asset name.
- Ticker.
- Asset type.
- Current price.
- Price change and percentage change.
- Simple chart.
- Timeframe selector.
- Watchlist button.

Recommended MVP timeframes:

- 1D
- 1W
- 1M
- 6M
- 1Y

### 3. AI Multi-Analyst Report

The main product surface is a structured AI report.

Required sections:

#### Bull Case

Explains why the asset could rise.

Should consider:

- Price trend.
- Positive market context.
- Recent news.
- Momentum.
- Technical signals if chart data or screenshot is available.

#### Bear Case

Explains why the asset could fall.

Should consider:

- Overbought conditions.
- Negative news.
- Weak momentum.
- Valuation or macro pressure when relevant.
- Chart risks if chart data or screenshot is available.

#### Risk Analysis

Explains important risks without choosing a direction.

Should consider:

- Volatility.
- Upcoming events.
- News uncertainty.
- Liquidity risk for smaller or thinly traded assets.
- Broader market risk.

#### Consensus

Creates a balanced summary from the other analysts.

Should include:

- Most likely scenario phrased cautiously.
- Key supporting reasons.
- Key invalidation risks.
- Clear educational disclaimer.

The report should avoid direct commands such as "buy", "sell", "short", "enter now", or "exit now."

### 4. Chart Screenshot Upload

User can upload a financial chart screenshot for AI interpretation.

Supported inputs:

- TradingView screenshot.
- Any clear financial chart screenshot.

AI should identify, when visible:

- Trend direction.
- Support/resistance zones.
- Momentum impression.
- Volatility.
- Possible chart pattern.
- Limits of confidence if the image is unclear.

Important:

- Screenshot analysis should be framed as visual interpretation, not a trading recommendation.
- If the chart lacks ticker/timeframe context, the app should ask the user to provide it or proceed with lower confidence.
- MVP upload uses a single-image picker, not multi-image upload.
- The picker should offer camera and photo library options.
- iOS permission copy must be purpose-specific:
  - Camera: "Experts needs camera access to take chart screenshots for AI market analysis."
  - Photo Library: "Experts needs photo library access to choose chart screenshots for AI market analysis."

### 5. Market News

The app should show recent news related to the selected asset.

MVP behavior:

- Display a small list of recent headlines.
- Include source and publish date when available.
- Pass headline summaries/context into AI analysis when available.
- Handle "no news found" gracefully.

### 6. User Analysis Note

Before running AI analysis, the user can optionally add a short note.

Examples:

- "I am watching this before earnings."
- "I want to understand recent weakness."
- "Focus on the next few weeks."

MVP behavior:

- The note is optional.
- The note is sent to AI only after AI data consent is granted.
- The note should not ask for personal financial advice.
- UI copy should make it clear that the note helps focus the educational analysis.

### 7. Watchlist

User can save favorite assets.

MVP behavior:

- Add/remove asset from Watchlist.
- Show saved tickers on Home.
- Persist locally.
- No account required.
- No sync in the MVP.

### 8. Settings

Required MVP settings:

- AI Privacy section.
- AI Data Consent toggle.
- Educational disclaimer / legal notes.
- Data source attribution.

The AI Privacy section must follow `skill-ai-consent`.

---

## AI Architecture

### Core AI Provider

Use Gemini through direct HTTP requests according to `skill-ai-integration`.

MVP recommendation:

- Core service: `GeminiService`.
- Specialized service: `MarketAnalysisAiService`.
- Four analyst text/image methods:
  - `generateBullCase`
  - `generateBearCase`
  - `generateRiskAnalysis`
  - `generateConsensus`
- One final synthesis method:
  - `generateFinalReport`

API key:

- Gemini key: use the existing `GOOGLE_API_KEY` value from the local Nano Banana setup when implementation starts.
- Do not expose the real Gemini key in PRD, README, logs, or final responses.
- Finnhub key: use `YOUR_FINNHUB_API_KEY` placeholder until the user provides a real key.
- For production, a backend proxy or Firebase Function is preferred, but direct HTTP is acceptable for the current skill-based MVP.

### Multi-Agent Analysis Flow

The MVP should use separate AI calls rather than a single prompt that simulates all analysts:

1. Bull Analyst receives asset data, chart context, and news context.
2. Bear Analyst receives the same context and focuses on downside arguments.
3. Risk Analyst receives the same context and focuses on uncertainty and risk.
4. Consensus Analyst receives the three analyst outputs and creates a balanced consensus.
5. Final Report prompt receives all four outputs and formats the user-facing report.

This costs more requests than a single prompt, but creates clearer separation between perspectives and makes the product concept stronger.

### AI Response Format

For the multi-analyst report, request structured JSON.

Suggested fields:

```json
{
  "bullCase": {
    "summary": "string",
    "points": ["string"],
    "confidence": 0
  },
  "bearCase": {
    "summary": "string",
    "points": ["string"],
    "confidence": 0
  },
  "riskAnalysis": {
    "summary": "string",
    "points": ["string"],
    "riskLevel": "low | medium | high"
  },
  "consensus": {
    "summary": "string",
    "scenario": "bullish | neutral | bearish | mixed",
    "keyRisks": ["string"],
    "disclaimer": "string"
  }
}
```

### AI Prompt Requirements

Prompts must:

- Ask for educational analysis only.
- Instruct the model not to provide financial advice.
- Instruct the model not to give direct buy/sell commands.
- Include available market data, news context, and chart/screenshot observations.
- Ask the model to admit uncertainty when data is incomplete.
- Require valid JSON only when structured responses are needed.

### AI Consent Requirements

Before any AI call:

- If `aiConsentGiven == null`, show the AI consent dialog.
- If the user agrees, persist `true` and continue.
- If the user declines, persist `false` and stop the AI action.
- If `aiConsentGiven == false`, block the AI action and let the user re-enable consent in Settings.

Consent dialog must explain:

- The app uses Google Gemini to generate market analysis.
- Data sent may include ticker, market data, news summaries, user-entered notes, and uploaded chart images.
- The user's name is not sent.
- Data is processed by Google Gemini.
- Consent can be revoked in Settings.

Do not claim that Google does not store or retain data unless verified in policy/legal copy later.

---

## Data Sources

### Market Data

Primary candidate:

- Finnhub

Need to confirm:

- Does Finnhub cover all required US stocks and ETFs for MVP?
- Which endpoints are available on the selected plan?
- Whether free-tier API limits are acceptable.

### News

Primary candidate:

- Finnhub company/news endpoints if sufficient.

Need to confirm:

- Source attribution requirements.
- Rate limits.

### Charts

Candidate Flutter package:

- `fl_chart`

Need to add dependency when implementation starts.

---

## Monetization

There will be no monetization in the MVP.

No premium plan, no subscriptions, no paid unlocks, no ads.

No daily AI analysis limits in the first MVP.

If API cost or rate limits become a real issue later, fair-use limits can be reconsidered, but they are out of scope for the initial build.

---

## App Store Positioning

Suggested positioning:

> Experts is an AI-powered market analysis app that provides educational insights from multiple perspectives.

Required disclaimer:

> Experts does not provide financial advice, trading recommendations, or guarantees of future performance.

Recommended places for disclaimer:

- Every AI report.
- Settings / Legal section.
- App Store description.

---

## MVP User Flow

1. User opens Experts.
2. User searches for a ticker or selects one from Watchlist.
3. App opens Asset Details.
4. User can optionally upload a chart screenshot.
5. User can optionally add a short analysis note.
6. User taps Analyze.
7. If AI consent has not been answered yet, app shows consent dialog.
8. App generates Bull, Bear, Risk, Consensus, and final report analysis.
9. The AI report shows the educational disclaimer.
10. User can read news, inspect chart context, or save the asset to Watchlist.

---

## Empty, Loading, and Error States

Home:

- No watchlist yet.
- No recent searches yet.
- Search failed.

Asset Details:

- Market data unavailable.
- Chart unavailable.
- News unavailable.

AI Analysis:

- AI consent declined.
- AI service unavailable.
- API limit reached.
- Uploaded image is unclear.
- Analysis could not be parsed.

All user-facing copy must be in English.

---

## MVP Acceptance Criteria

- User can search for an asset.
- User can open asset details.
- User can add/remove asset from Watchlist.
- User can generate a structured multi-analyst AI report.
- User can add an optional short analysis note before generating the report.
- User can upload a chart screenshot for AI interpretation.
- User can see recent news when available.
- AI consent appears before the first AI request.
- AI consent can be revoked and re-granted in Settings.
- AI calls are blocked when consent is missing or revoked.
- The app never frames AI output as financial advice.
- No monetization or Premium UI is present.
- User-facing UI is English only.

---

## Product Decisions

- MVP market scope: US stocks and ETFs.
- Crypto is intentionally deferred.
- Gemini API key source: existing local `GOOGLE_API_KEY` from Nano Banana setup.
- Finnhub API key: placeholder until the user provides the real key.
- Screenshot upload is included in MVP through `skill-image-picker`.
- AI architecture uses four analyst prompts plus separate consensus/final-report prompts.
- Optional user note is included before analysis.
- Educational disclaimer appears on every AI report.
- Watchlist is local-only in the MVP.
- Real market data waits for the Finnhub key; no mock market-data implementation is planned as a substitute.
- No monetization and no usage limits in the first MVP.

---

## Open Questions

1. Do you want a pure Cupertino iOS app style, or should we keep the structure portable for Android later?
2. Should the optional analysis note have a short character limit, for example 240 characters?
3. Do we need a first-run educational disclaimer before any report, in addition to the disclaimer on every AI report?

---

## Suggested First Implementation Sprint

1. Replace Flutter starter screen with Experts shell.
2. Add Home, Asset Details, AI Report, Watchlist, and Settings screens.
3. Add local settings/watchlist persistence.
4. Add AI consent model, dialog, gate, and Settings toggle.
5. Add image picker dependency, iOS permissions, and single chart screenshot attachment flow.
6. Add Gemini core service using the existing local Gemini key source during implementation.
7. Add `MarketAnalysisAiService` with four analyst prompts, consensus prompt, final-report prompt, and structured JSON parsing.
8. Add optional user note input before analysis.
9. Add real Finnhub market data integration after the key is provided.
