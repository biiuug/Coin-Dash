# Idle Hero Camp

A compact Godot 4 desktop idle auto-fighter prototype. The game runs around a small camp interface: heroes fight automatically, earn resources and equipment, then spend those gains on hero growth, gear, buildings, and talents.

## Current Prototype

- Auto-battle stage loop with waves, boss clears, run rewards, and equipment drops.
- Battle dashboard with animated enemy attack, hit, and boss-skill frames, team health, gear counts, stage loot ranges, pause, and speed controls.
- Guide tab with visual shortcuts for the core loop and each progression system.
- Ten hero classes with levels, skill levels, class rank-ups, advancement choices, and rank unlock previews.
- Equipment with rarity, item level, hero level requirements, upgrading, equipping, and salvaging.
- Equipment filters and one-click auto-equip for the selected hero.
- Scrollable equipment inventory with lock protection for valuable drops.
- Bulk junk salvage for unlocked, unequipped Common and Uncommon equipment.
- Optional auto-junk conversion for newly dropped Common and Uncommon gear.
- Distinct pixel-art visuals for all nine resources, buildings, enemy families, hero portraits, equipment slots, talents, stage regions, and current card actions.
- Six camp buildings: Forge, Workshop, Academy, Infirmary, Market, and Shrine.
- Six distinct camp services for crafting, junk sorting, hero training, team recovery, supply trading, and essence distilling.
- Camp screen with visible resource-icon service and upgrade costs plus an affordable upgrade-all action.
- Expanded talent branches for combat, economy, loot, automation, and class growth, including boss damage, salvage yield, essence gain, and team sustain bonuses.
- Stage list showing material sources and item level ranges so higher fights drop better loot.
- Scrollable stage selection so every unlocked region remains reachable in the compact window.
- Manual save/load/new game controls plus periodic autosave.
- New-game confirmation before the current autosave is replaced.
- Offline resource progress after loading a save, capped to keep returns controlled.

## Run

Open this folder in Godot 4.6 or newer, then press Run. The main scene is `res://Main.tscn`.

## Controls

Use the mouse to switch tabs, follow the Guide shortcuts, farm or push stages, pause combat, change battle speed, level heroes, filter, auto-equip, or bulk-salvage gear, upgrade buildings, unlock talents, and save or load progress.
