# Experts Agent Instructions

## Scope

These instructions apply to work in `/Users/infoas/new_projects/experts`.

## Product Guardrails

- Build a Flutter iOS MVP for educational market analysis.
- UI copy must be English only.
- Experts must never present outputs as financial advice, trading recommendations, guaranteed predictions, price targets, or buy/sell signals.
- Use the PRD and design system as source documents:
  - [PRD.md](/Users/infoas/new_projects/experts/PRD.md)
  - [DESIGN.md](/Users/infoas/new_projects/experts/DESIGN.md)

## Flutter UI Rules

- Cupertino only.
- Do not use `MaterialApp`, `Scaffold`, Material widgets, Material themes, or Material icons.
- Prefer `CupertinoApp`, `CupertinoPageScaffold`, `CupertinoNavigationBar`, `CupertinoSliverNavigationBar`, `CupertinoButton`, `CupertinoTextField`, `CupertinoSwitch`, and `CupertinoIcons`.
- Do not hardcode colors in feature widgets. Use centralized app color tokens.
- Do not hardcode text styles in feature widgets. Use centralized typography tokens.
- Keep the MVP light-only. Do not add dark mode.
- Use system SF Pro by default. Do not add runtime font fetching.
- Letter spacing must be `0`.

## Architecture Rules

- Use Riverpod for state management.
- SharedPreferences is acceptable for MVP local settings, watchlist, and recent-search persistence.
- Use direct HTTP for Gemini integration. Do not add AI SDK packages.
- Keep API keys out of docs, logs, commits, final responses, and screenshots.
- Gate all AI calls behind AI data consent.

## Design Rules

- Follow the light fintech direction in `DESIGN.md`.
- Primary CTAs use the yellow token only through the shared design system.
- Standard app cards use 8px radius unless the design system defines a specific exception.
- Do not create marketing-only hero pages; the first screen should be useful app UI.
- Do not use purple/blue gradients, dark surfaces, decorative orb backgrounds, or crypto motifs.

## Workflow Rules

- Do not use git commands in this project unless the user explicitly asks.
- Do not run tests, builds, formatters, `flutter pub get`, or commands that rewrite files unless the user explicitly asks.
- `flutter analyze` may be run when useful.
- Do not revert or overwrite unrelated edits. Multiple agents may work in this codebase at the same time.
- Keep edits scoped to the task and the requested ownership area.

