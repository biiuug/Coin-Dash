# Idle Auto-Fighter Redesign

## Goal

Rework the current card-combat prototype into a compact desktop idle game. The game should fit in a small desktop window, run mostly by itself, and focus on long-term growth through auto battles, material drops, equipment, classes, buildings, and a deeper talent tree.

## Core Loop

1. A team of up to 5 heroes auto-fights waves in the active level.
2. Fights generate materials, gold, equipment, class shards, and talent essence.
3. The player upgrades heroes, skills, equipment, buildings, and talents.
4. Stronger teams push higher levels for better idle income and rarer drops.
5. Buildings process resources between runs: forge, upgrade, salvage, train, research, market, and academy.

The player can leave the game running as a desktop companion. Progress continues through idle ticks while the game is open, with optional offline progress later.

## First Version Scope

The first playable version should remove card combat entirely and replace it with:

- Auto battle with 5 hero slots and 1 enemy lane.
- Level selector with stages, waves, enemy power, and drop tables.
- Idle loot meter and recent drop log.
- Hero roster with classes, stats, level, skill level, and equipment slots.
- Equipment inventory with equip, upgrade, and salvage actions.
- Six camp buildings with distinct functions.
- Talent tree with combat, economy, drop, automation, and class branches.

## Combat

Combat is fully automatic. Each hero has attack speed, attack damage, HP, defense, crit, and a special skill timer. Enemies spawn in waves. A level is cleared when enough waves are defeated, and farming continues on the best cleared wave until the player pushes again.

Team size starts at 2 and grows to 5 through Academy and talent unlocks.

Stages are split into regions and levels, for example `Meadow 1-1` through `Meadow 1-10`, then `Mines 2-1`, `Ruins 3-1`, and so on. Each region has a material theme, enemy family, boss, and loot table. Higher stages increase enemy stats, idle income, equipment level requirements, and the maximum item tier that can drop.

Combat rewards:

- Common: wood, ore, herbs, gold.
- Uncommon: equipment, skill manuals, forge dust.
- Rare: class shards, talent essence, relic fragments.
- Boss/elite: higher equipment tier, building plans, rare essence.

Stage reward scaling:

- Stage level raises base gold and material income.
- Every 5 stages raises the minimum equipment level that can drop.
- Every 10 stages unlocks a new equipment tier band and a boss chest.
- Elite waves have increased class shard and talent essence chance.
- Boss waves guarantee at least one equipment item and have a chance for building plans.

Example regions:

- Meadow Road: wood, herbs, cloth armor, slime and wolf enemies.
- Iron Mine: ore, forge dust, weapons, mole and golem enemies.
- Grave Ruins: bone fragments, talent essence, trinkets, zombie and specter enemies.
- Ember Hollow: rare ore, fire crystals, high-attack gear, dinosaur and drake enemies.
- Fallen Keep: class shards, relic fragments, epic gear, knight and boss enemies.

Drop rate model:

- Common material drop chance starts at 100%.
- Equipment drop chance starts around 6% per wave and increases with stage, loot talents, Rogue passives, and Market upgrades.
- Rarity roll happens after an item drops. Higher stage, Shrine level, and Loot talents improve rarity weights.
- Class shard drops start from elites and bosses, then become low-probability idle drops in later regions.
- Talent essence drops from bosses, first-clear milestones, elite waves, and Shrine bonuses.

## Classes

Each hero class has a role and special skill.

- Warrior: front-line bruiser. Skill: Shield Break, reduces enemy defense.
- Ranger: fast single-target damage. Skill: Rapid Volley, burst attacks.
- Cleric: healing and protection. Skill: Radiant Mend, heals lowest HP ally.
- Mage: area damage. Skill: Meteor Sigil, damages all enemies.
- Rogue: crit and loot. Skill: Pilfer Strike, increases drop chance on kill.
- Guardian: tank. Skill: Stone Guard, grants team armor.

Classes can rank up and later advance into elite classes. Rank-up uses class shards, gold, and manuals. Advancement uses rare class seals from bosses and Academy research.

Class ranks:

- Rank I: base class and first special skill.
- Rank II: stat passive unlock, such as Warrior defense scaling or Ranger attack speed.
- Rank III: skill modifier unlock, such as Shield Break hitting two enemies or Radiant Mend adding a shield.
- Rank IV: role passive unlock, such as Rogue increasing team drop chance or Guardian reducing all incoming damage.
- Rank V: class advancement quest unlock.

Elite class examples:

- Warrior advances to Blademaster or Warlord.
- Ranger advances to Sniper or Beast Hunter.
- Cleric advances to Oracle or Battle Saint.
- Mage advances to Archmage or Rune Caller.
- Rogue advances to Nightblade or Treasure Seeker.
- Guardian advances to Paladin or Iron Sentinel.

Elite classes should not only add stats. They should change team-building decisions through passives, skill behavior, or economy effects. For example Treasure Seeker is weaker in boss damage but strongly increases rare equipment and shard drops while farming.

## Hero Progression

Heroes have:

- Level: raised with gold and training manuals.
- Skill level: raised with manuals and class shards.
- Star rank: raised with duplicate shards.
- Equipment: weapon, armor, trinket.
- Class passive: unique scaling bonus.
- Class rank: unlocks new passives, skill modifiers, and elite class advancement.

The first version can include 5 initial heroes, one per slot, and unlock extra classes through drops later.

Hero level and class rank should gate long-term growth differently. Hero level gives broad stats. Skill level improves active skill values. Star rank improves base scaling. Class rank unlocks new behavior. Equipment increases power quickly but is limited by level requirements.

## Equipment

Equipment has rarity, item level, level requirement, slot, main stat, and one or more affixes. Higher level equipment is always stronger than lower level equipment at the same rarity, and later stages drop higher item levels.

Rarities:

- Common
- Uncommon
- Rare
- Epic
- Legendary

Slots:

- Weapon: attack, skill power, crit, class-specific damage.
- Armor: HP, defense, damage reduction, recovery.
- Trinket: speed, drop rate, gold income, essence gain, special effects.

Equipment level rules:

- Each item has an item level and a required hero level.
- A hero cannot equip gear above their current level requirement.
- Required level usually equals item level, with some rare items requiring slightly less or more.
- Higher item level increases main stat and affix stat ranges.
- Rarity multiplies stat quality and adds affix count.
- Stage drop tables control item level range, so higher stage fights naturally drop better loot.

Example item level bands:

- Stages 1-5: item level 1-5, Common to Uncommon.
- Stages 6-10: item level 5-10, Common to Rare.
- Region 2: item level 10-20, Uncommon to Rare.
- Region 3: item level 20-35, Rare with early Epic chance.
- Region 4+: item level 35+, Epic and Legendary chances begin to matter.

Equipment affixes:

- Combat: attack, HP, defense, crit, attack speed, skill charge rate.
- Economy: gold gain, material gain, salvage yield.
- Loot: equipment drop chance, rarity chance, class shard chance.
- Class: bonus to a specific class or elite class.

Equipment actions:

- Equip to matching slot.
- Upgrade with ore and forge dust.
- Salvage into ore, dust, and rare fragments.
- Forge a random item using building resources.
- Compare with currently equipped item.
- Lock an item to prevent accidental salvage.
- Auto-salvage low rarity or low item level gear after Workshop automation unlocks.

Equipment upgrade rules:

- Upgrading increases item level within a limited range.
- Upgrade cap depends on Forge level and item rarity.
- Higher rarity gear costs more dust and rare fragments to upgrade.
- Salvaging upgraded items returns part of the invested materials, improved by talents and Forge level.

## Buildings

Buildings stay as the base/camp layer, but their functions change to support idle progression.

- Forge: craft gear, upgrade gear, reroll affixes at higher levels.
- Workshop: automates farming controls, unlocks auto-salvage filters and faster battle speed.
- Academy: unlocks team slots, class training, hero level cap.
- Infirmary: increases team HP, recovery, and idle survival.
- Market: improves gold/material income, lets the player trade excess resources.
- Shrine: unlocks talent tree branches, improves essence and rare drop rates.

Each building has 5 levels in the redesign. Higher levels unlock new actions rather than only bigger numbers.

Building unlock examples:

- Forge Lv 2 unlocks gear upgrade. Lv 3 unlocks affix reroll. Lv 4 unlocks targeted slot crafting. Lv 5 unlocks rare fragment crafting.
- Workshop Lv 2 unlocks battle speed. Lv 3 unlocks auto-salvage filters. Lv 4 unlocks auto-farm best cleared stage. Lv 5 unlocks repeat crafting.
- Academy Lv 2 unlocks third team slot. Lv 3 unlocks class rank training. Lv 4 unlocks fourth team slot. Lv 5 unlocks fifth team slot and elite class advancement.
- Infirmary Lv 2 improves recovery. Lv 3 grants team HP aura. Lv 4 reduces defeat penalty. Lv 5 unlocks revive once per boss fight.
- Market Lv 2 unlocks trades. Lv 3 unlocks contracts. Lv 4 improves idle income. Lv 5 unlocks rare rotating offers.
- Shrine Lv 2 unlocks Loot branch. Lv 3 unlocks Class branch. Lv 4 improves boss essence. Lv 5 unlocks advanced talent nodes.

## Talent Tree

Talent currency is Talent Essence from bosses, elites, and idle milestones.

Branches:

- Combat: attack, HP, defense, crit, skill speed, boss damage.
- Economy: gold gain, material gain, offline gain, building speed.
- Loot: equipment drop rate, rarity chance, class shard chance, salvage bonus.
- Automation: auto-advance, auto-salvage, auto-equip suggestions, repeat crafting.
- Class: specialized bonuses for Warrior, Ranger, Cleric, Mage, Rogue, Guardian.

The tree should feel wide enough for choices, not just a straight upgrade list.

Talent node types:

- Small nodes: flat stats or small percentage bonuses.
- Major nodes: unlock mechanics such as auto-advance, rare drop pity, or extra skill charge.
- Gate nodes: require a building level, stage clear, or class rank.
- Choice nodes: pick one of two bonuses until reset, such as boss damage vs idle income.

Example talents:

- Combat: `Battle Rhythm` increases attack speed; `Boss Breaker` increases boss damage; `Shared Guard` gives team defense.
- Economy: `Packed Supplies` increases material income; `Merchant Routes` increases gold income; `Workshop Hands` reduces building upgrade cost.
- Loot: `Rare Find` increases equipment rarity; `Shard Scent` increases class shard drop; `Careful Salvage` increases salvage yield.
- Automation: `Push Protocol` auto-advances until defeat; `Filter Junk` auto-salvages low rarity; `Smart Farm` returns to best stage per minute.
- Class: `Warrior Drill`, `Ranger Focus`, `Cleric Hymn`, `Mage Sigils`, `Rogue Luck`, `Guardian Oath`.

Talent unlocks should create medium-term goals. A player might farm bosses for essence, upgrade Shrine to access Loot nodes, or push Academy to enable class advancement nodes.

## Items And Materials

Materials should have clear uses so drops stay meaningful:

- Gold: hero leveling, market trades, basic forging.
- Wood: building upgrades, workshop automation.
- Ore: equipment upgrades and forge recipes.
- Herbs: healing/recovery systems and Infirmary upgrades.
- Ink: talent research, Academy training, class manuals.
- Forge Dust: equipment upgrade and affix reroll.
- Class Shards: class rank-up and elite advancement.
- Talent Essence: talent tree unlocks.
- Relic Fragments: rare equipment crafting and legendary upgrades.

Consumable items:

- Training Manual: hero XP or skill XP.
- Boss Chest: roll equipment and rare materials.
- Class Seal: required for elite class advancement.
- Reroll Stone: changes one equipment affix.
- Expedition Contract: temporary idle income or drop-rate boost.

Item sources should be distributed across stages and buildings so no single mode gives everything.

## Stage And Loot Progression

Stages are the main source of better loot. Higher stages should not merely add more resources; they should unlock new drop categories.

Stage structure:

- Each region has 10 normal stages and 1 boss stage.
- Every normal stage has 10 waves.
- Every 3rd wave has an elite chance after region 2.
- The boss stage gives first-clear rewards and repeat farming rewards.

First-clear rewards:

- Talent essence.
- Building plan chance.
- Class shard bundle.
- Guaranteed equipment above current farming average.

Repeat rewards:

- Materials based on region.
- Equipment with item level range tied to stage.
- Rare drops based on loot table and talents.

Loot quality should be visible in the UI through a stage info panel showing:

- Material per minute.
- Equipment level range.
- Rarity odds.
- Special drops.
- Best known team power requirement.

## Compact Desktop Layout

The first version should use a small fixed game area, roughly `960x540` or `1100x620`, not the current large `1800x1000` layout.

Main screen zones:

- Top: stage, team power, idle income, and key resources.
- Center: auto battle lane with heroes on the left, enemies on the right, HP bars and skill timers.
- Right: current level drops, battle log, and push/farm controls.
- Bottom: tabs for Heroes, Equipment, Buildings, Talents, and Levels.

## Screens For First Version

The first design pass includes four core screens:

- Battle Dashboard: live auto fight, team slots, enemy wave, income, drops.
- Hero & Equipment: character details, equipment slots, inventory, upgrade/salvage.
- Buildings: camp facilities with action buttons and upgrade summaries.
- Talent Tree: branch nodes for combat, economy, loot, automation, and classes.

## Implementation Direction After Approval

After approval, implementation should remove the deck/card systems from `Main.gd` and replace them with a new idle data model:

- `IdleGameRules.gd`: definitions for heroes, classes, enemies, equipment, buildings, talents, loot tables.
- `Main.gd`: UI/controller for compact idle game.
- Optional future split: separate UI components once the prototype stabilizes.

The first implementation should prioritize playable systems over final art polish.
