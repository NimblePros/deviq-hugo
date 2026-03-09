# Plan: Add Icons to Home Page Category Cards

## Context

The DevIQ home page displays 11 category cards in a 4-column grid using the Hextra theme's `feature-card` shortcode. Currently the cards show only a title and "Explore ... →" subtitle text with alternating indigo background colors. Adding monochromatic icons improves visual identity and scannability.

## Approach

Override the Hextra `feature-card` shortcode locally to render the icon **above** the title at a larger size (3rem / 48px). This is better than the default behavior (1.5rem inline with title text).

Icons use **Heroicons v2 outline** style — SVG-based, stroke-only, no fills. They render with `currentColor` so they naturally adapt to light and dark mode on the indigo card backgrounds.

## Files Modified

| File | Change |
|------|--------|
| `layouts/_shortcodes/hextra/feature-card.html` | Local override — moves icon above title, increases to 3rem |
| `content/_index.md` | Adds `icon="..."` parameter to each feature-card |
| `assets/css/custom.css` | Adds opacity styling for card icons |

## Icon Assignments (Heroicons v2 outline)

| Category | Icon Name | Rationale |
|----------|-----------|-----------|
| Design Patterns | `puzzle-piece` | Patterns as interlocking puzzle pieces |
| Practices | `clipboard-document-check` | Repeatable checklists and routines |
| Principles | `light-bulb` | Guiding ideas / illumination |
| Values | `heart` | Core values |
| Antipatterns | `no-symbol` | Warning / prohibition |
| Domain Driven Design | `globe-alt` | Modeling a domain / world |
| Tools | `wrench-screwdriver` | Developer tooling |
| Terms | `book-open` | Glossary / reference |
| Testing | `beaker` | Lab testing (exact semantic match) |
| Laws of Software Development | `scale` | Laws / balance / judgment |
| Architecture | `building-office-2` | Structure / building |
| Code Smells | `exclamation-circle` | Warning / something is wrong |

## Icon Rendering

Icons are rendered via Hextra's `utils/icon.html` partial, which outputs inline SVG with `currentColor` for stroke. This means:

- **Light mode** (light indigo backgrounds): icons render in the page's default text color
- **Dark mode** (deep indigo backgrounds): icons render in white

CSS adds 80% opacity to soften the icons slightly against the card backgrounds.

## Verification

1. Run `hugo serve` and open `http://localhost:1313/`
2. Confirm each card shows the correct icon above the title
3. Toggle dark mode — icons should remain clearly visible
4. Check responsive layout at mobile widths
