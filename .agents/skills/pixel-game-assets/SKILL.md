---
name: pixel-game-assets
description: Use when generating or editing any image, sprite, animation, icon, character, enemy, building, card, relic, resource, equipment, background, or other visual asset for Idle Hero Camp.
---

# Pixel Game Assets

## Core Rule

Every generated visual for this game must be crisp pixel art. Use hard pixel edges, a controlled palette, readable silhouettes, nearest-neighbor scaling, no antialiasing, no painterly detail, and no smooth vector rendering.

Use assets/knight-style-reference.gif as the primary style reference: compact heroic proportions, dark outlines, clustered highlights, and strong material readability.

## Asset Contract

Asset categories include characters, enemies, buildings, cards, resources, relics, equipment, backgrounds, and UI icons.

| Asset | Logical size |
|---|---:|
| Character frame | 64 by 96 |
| Enemy frame | 96 by 96 |
| Building level | 256 by 192 |
| Card illustration | 192 by 108 |
| Resource/equipment icon | 64 by 64 |
| Talent/stage icon | 48 by 48 |

Animation sheets use equal cells, a stable baseline, identical identity and scale, and explicit frame order. Character samples use idle, walk, attack, hit.

## Workflow

1. Inspect existing game assets and this skill's reference before prompting.
2. Generate one subject or one animation sheet at a time with the built-in image tool. Request a flat chroma-key background, no shadows, no text, and no borders.
3. Keep a versioned keyed source. Never overwrite a live asset unless explicitly requested.
4. Run scripts/finalize_pixel_sheet.py for sheets. It removes the key, fits each subject to its cell, quantizes without dithering, and writes transparent RGBA.
5. Validate exact dimensions, binary alpha, transparent corners, nonempty cells, limited palette, and visual consistency.
6. Save final project assets under assets/ and configure Godot textures for nearest-neighbor filtering.

## Common Mistakes

- Pixel-styled high-resolution painting is not pixel art: finalize and inspect at 1x.
- Do not mix frame sizes, baselines, palettes, light direction, or character proportions.
- Do not leave chroma color, soft alpha fringes, labels, borders, scenery, or unrelated objects.
- Do not stretch generated art to fit. Crop, fit proportionally, and center it.
