# Remaining Pixel Assets Design

## Goal

Create first-version pixel art assets for the remaining Idle Hero Camp visual categories and expand the class roster with matching character sheets.

## Asset Scope

- Resource icons: gold, wood, ore, herbs, ink, dust, essence, shards, fragments.
- Equipment icons: weapon, armor, and trinket across five rarity tiers.
- Talent icons: Combat, Economy, Loot, Automation, Class.
- Stage icons: Meadow Road, Iron Mine, Grave Ruins, Ember Hollow, Fallen Keep.
- Class sheets: current classes plus five new classes, each with idle, walk, attack, and hit frames.

## Class Expansion

Add these classes as first-version playable class designs:

- Paladin: tank and healing hybrid.
- Druid: nature support and summon flavor.
- Artificer: gear-scaling utility and machinery flavor.
- Necromancer: minion and dark magic flavor.
- Monk: fast stance fighter.

## Technical Targets

- All generated assets follow the project-local `pixel-game-assets` skill.
- Resource and equipment icons use 64 by 64 cells.
- Talent and stage icons use 48 by 48 cells.
- Character frames use 64 by 96 cells.
- Sources use a flat `#ff00ff` key where practical; final files use transparent RGBA.
- Existing live files remain untouched unless a follow-up explicitly asks to switch the game to the new atlases.
