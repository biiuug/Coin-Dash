# Idle Hero Camp - Release Design

## Game Loop

Idle Hero Camp is a desktop auto-battler about building a five-hero company and a camp that supports it. Battles run automatically. The player chooses where to farm, develops heroes, equips loot, upgrades camp facilities, unlocks talents, and pushes a 120-stage campaign. An atomic local save, eight-second autosave, backup recovery, and offline rewards make short and long sessions equally useful.

## Campaign And Combat

- Twelve authored regions contain ten stages each, ending at the Crown of Stars on stage 120.
- Normal, elite, boss, and final encounters use regional enemies and scaling power.
- Higher stages award more resources and higher-level equipment.
- Each region has distinct materials, an equipment set, a boss, and a guaranteed first-clear relic.
- A completed campaign remains playable for farming, collection, hero development, and record completion.

## Heroes And Classes

Ten classes support tank, damage, healing, control, and economy-focused teams. Heroes gain experience in combat and advance to level 100. Gold raises level directly, class shards raise rank, and rank five opens one of two elite advancement paths. Rank, skill level, advancement, equipment, talents, buildings, and relics all contribute to combat power.

## Equipment And Relics

Equipment has a slot, item level, required hero level, rarity, upgrade level, and generated stats. The weapon, armor, and trinket slots provide different stat profiles. Five rarities and twelve regional item sets support a long loot curve. Players can compare, equip, lock, upgrade, salvage, auto-equip, and automatically salvage low-rarity drops. Inventory is capped at 120 items; overflow is converted into salvage resources.

Each regional boss awards one of twelve permanent relics. Relics modify combat, rewards, experience, equipment rarity, building costs, or offline progression and are displayed in a dedicated collection.

## Camp

Eight facilities have five levels and a distinct repeatable service:

- Forge crafts equipment and improves equipment progression.
- Workshop improves automation and battle speed.
- Academy expands the team and supports class development.
- Infirmary improves health and recovery.
- Market increases income and trades materials.
- Shrine improves essence, rarity, and talent progression.
- Barracks runs team drills for hero experience.
- Observatory scouts ahead for caches and expands offline reward time.

Buildings require themed resources, visually progress through construction levels, and feed directly back into combat and collection systems.

## Resources And Talents

Nine resources have dedicated icons and uses: gold, wood, ore, herbs, ink, forge dust, class shards, talent essence, and relic fragments. Combat, stages, achievements, offline rewards, buildings, equipment salvage, and facility services provide complementary sources.

The talent tree spans Combat, Economy, Loot, Automation, and Class branches. Talents improve battle stats, reward yield, rarity, salvage, building efficiency, experience, and team behavior.

## Completion And Persistence

Sixteen campaign records track stage progress, collecting, building, hero development, and wealth, each with a one-time reward. Stage 120 displays a permanent campaign-complete state. Save version 4 stores all progression locally, writes through a temporary file, preserves a validated backup, recovers from a damaged primary save, and grants bounded offline rewards on return.
