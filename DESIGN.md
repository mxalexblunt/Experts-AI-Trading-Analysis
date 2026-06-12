# Experts Design System

Version: redesign v2
Primary references:
- `design_reference/card_reference.png`
- `design_reference/image.png`
- `design_reference_v2.png`

## Direction

Experts uses a light premium fintech interface: calm like a native iOS tool,
tactile like a product card system, and precise enough for repeated market
analysis work.

The app should feel:
- warm, bright, and trustworthy
- rounded and physical, with depth from shadow rather than borders
- finance-focused, not decorative or marketing-led
- modern enough to show logos, chart surfaces, circular actions, and floating
  navigation without depending on stock photography

All user-facing UI copy must be English only. MVP remains light theme only.

## Visual Mechanics

- Canvas: warm off-white.
- Surfaces: elevated white cards, soft inset fields, and occasional warm hero
  panels.
- Shape: large tactile cards at 24-36px radius; pills for search, segmented
  controls, chips, CTAs, and tab selection.
- Depth: soft external shadows with negative spread; borders are used only for
  inset or quiet utility surfaces.
- Asset imagery: use Finnhub company logos when available. Use a dark monogram
  or chart-line fallback for ETFs and missing logos.
- Navigation: rounded circular action buttons and a floating capsule bottom bar.
- CTAs: black primary for major analysis actions; yellow accent for selected
  states and high-attention actions.
- Typography: bundled Manrope, zero letter spacing, tabular figures for numbers.

## Tokens

Core colors:
- `canvas`: `#FAF8F3`
- `surface`: `#FFFFFF`
- `surfaceSoft`: `#F4F1EA`
- `surfaceInset`: `#F7F4ED`
- `surfaceWash`: `#FFFCF5`
- `textPrimary`: `#101421`
- `textSecondary`: `#4F5665`
- `textTertiary`: `#8A909B`
- `primary`: `#F8DC3D`
- `actionDark`: `#111318`
- `tradingUp`: `#16A56F`
- `tradingDown`: `#E04F5F`

Shape:
- small controls: 12-18
- normal cards: 24-30
- hero panels: 36
- pills/circular buttons: 999

Shadows:
- `subtle`: quiet inset/control lift
- `card`: standard elevated surfaces
- `floating`: bottom nav and hero surfaces
- `control`: circular buttons and CTAs

## Component Rules

- Prefer `AppCard` variants over raw `Container` surfaces.
- Prefer `AssetLogoTile` for asset identity; never rely on decorative photos.
- Use pill search fields and rounded text areas.
- Avoid nested cards; repeated asset rows should be separate tactile cards or a
  single intentional list group.
- Keep charts readable and data-dense; do not over-decorate financial content.
- Settings and status cards should be quieter than analysis cards but still use
  rounded, elevated surfaces.

## Anti-Patterns

- Thin outlined rectangles as the main card language.
- Small 8px app cards or square logo tiles.
- Full-width default tab bar chrome.
- Random market photos in core workflows.
- Purple/blue gradients, dark theme, or brand-copying from the references.
- Russian UI text.
