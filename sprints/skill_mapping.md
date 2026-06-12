# Skill Mapping

Implementation should consult these local skills when the matching sprint begins.

| Skill | Use During | Notes |
| --- | --- | --- |
| `skill-ai-integration` | Sprints 12-13 | Gemini through direct HTTP, no AI SDK packages. |
| `skill-ai-consent` | Sprints 11, 14 | First-use consent gate, settings toggle, AI call blocking. |
| `skill-image-picker` | Sprint 10 | Single chart screenshot, iOS permissions, image quality limits. |
| `skill-nano-banana` | Sprint 12 | Reuse local Gemini key setup only; never expose real keys. |
| `skill-design-extractor` | Sprints 2, 15 | Apply `DESIGN.md` and `design_reference/image.png` direction. |

## Standing Constraints

- Cupertino only.
- English UI only.
- No Material widgets.
- No hardcoded colors or text styles in feature widgets.
- No formatter/build/test commands unless explicitly requested.

