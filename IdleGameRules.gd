extends RefCounted

const RESOURCE_ORDER: Array[String] = ["gold", "wood", "ore", "herbs", "ink", "dust", "essence", "shards", "fragments"]
const MAX_STAGE := 120
const INVENTORY_CAP := 120
const MAX_HERO_LEVEL := 100

const RESOURCE_VISUALS := {
	"gold": {"symbol": "coin", "color": Color(0.94, 0.72, 0.20)},
	"wood": {"symbol": "logs", "color": Color(0.58, 0.32, 0.16)},
	"ore": {"symbol": "ingot", "color": Color(0.56, 0.64, 0.72)},
	"herbs": {"symbol": "leaves", "color": Color(0.34, 0.70, 0.36)},
	"ink": {"symbol": "bottle", "color": Color(0.32, 0.34, 0.72)},
	"dust": {"symbol": "powder", "color": Color(0.78, 0.55, 0.30)},
	"essence": {"symbol": "flame", "color": Color(0.28, 0.76, 0.82)},
	"shards": {"symbol": "crystals", "color": Color(0.36, 0.58, 0.94)},
	"fragments": {"symbol": "relic", "color": Color(0.74, 0.38, 0.74)},
}

const CLASSES := {
	"warrior": {
		"name": "Warrior",
		"role": "Bruiser",
		"skill": "Shield Break",
		"advanced": ["Blademaster", "Warlord"],
		"stats": {"hp": 135, "atk": 15, "def": 9, "speed": 0.85, "crit": 0.05},
		"rank_unlocks": ["Shield Break", "+12% defense scaling", "Skill hits two enemies", "Team damage reduction", "Class advancement"],
	},
	"ranger": {
		"name": "Ranger",
		"role": "Damage",
		"skill": "Rapid Volley",
		"advanced": ["Sniper", "Beast Hunter"],
		"stats": {"hp": 95, "atk": 19, "def": 5, "speed": 1.18, "crit": 0.12},
		"rank_unlocks": ["Rapid Volley", "+10% attack speed", "Volley adds crit", "Boss mark", "Class advancement"],
	},
	"cleric": {
		"name": "Cleric",
		"role": "Support",
		"skill": "Radiant Mend",
		"advanced": ["Oracle", "Battle Saint"],
		"stats": {"hp": 110, "atk": 11, "def": 7, "speed": 0.92, "crit": 0.04},
		"rank_unlocks": ["Radiant Mend", "+10% healing", "Mend adds shield", "Team recovery", "Class advancement"],
	},
	"rogue": {
		"name": "Rogue",
		"role": "Loot",
		"skill": "Pilfer Strike",
		"advanced": ["Nightblade", "Treasure Seeker"],
		"stats": {"hp": 90, "atk": 17, "def": 5, "speed": 1.28, "crit": 0.18},
		"rank_unlocks": ["Pilfer Strike", "+5% drop chance", "Pilfer can crit twice", "+8% rare loot", "Class advancement"],
	},
	"mage": {
		"name": "Mage",
		"role": "Area",
		"skill": "Meteor Sigil",
		"advanced": ["Archmage", "Rune Caller"],
		"stats": {"hp": 84, "atk": 24, "def": 4, "speed": 0.76, "crit": 0.08},
		"rank_unlocks": ["Meteor Sigil", "+14% skill power", "Meteor hits all enemies", "Arcane income", "Class advancement"],
	},
	"paladin": {
		"name": "Paladin",
		"role": "Tank/Heal",
		"skill": "Oathlight Guard",
		"advanced": ["Templar", "Dawnkeeper"],
		"stats": {"hp": 150, "atk": 14, "def": 11, "speed": 0.78, "crit": 0.04},
		"rank_unlocks": ["Oathlight Guard", "+10% healing received", "Guard shields weakest ally", "Holy counter", "Class advancement"],
	},
	"druid": {
		"name": "Druid",
		"role": "Nature",
		"skill": "Briar Bloom",
		"advanced": ["Wildspeaker", "Grove Sage"],
		"stats": {"hp": 104, "atk": 15, "def": 6, "speed": 0.96, "crit": 0.07},
		"rank_unlocks": ["Briar Bloom", "+12% herb rewards", "Bloom adds regeneration", "Summon thornling", "Class advancement"],
	},
	"artificer": {
		"name": "Artificer",
		"role": "Utility",
		"skill": "Clockwork Charge",
		"advanced": ["Machinist", "Runewright"],
		"stats": {"hp": 100, "atk": 16, "def": 7, "speed": 1.02, "crit": 0.09},
		"rank_unlocks": ["Clockwork Charge", "+8% gear stats", "Charge boosts automation", "Turret assist", "Class advancement"],
	},
	"necromancer": {
		"name": "Necromancer",
		"role": "Minion",
		"skill": "Grave Pact",
		"advanced": ["Lichbinder", "Soul Shepherd"],
		"stats": {"hp": 88, "atk": 22, "def": 4, "speed": 0.82, "crit": 0.10},
		"rank_unlocks": ["Grave Pact", "+10% essence rewards", "Pact summons bone guard", "Soul drain", "Class advancement"],
	},
	"monk": {
		"name": "Monk",
		"role": "Stance",
		"skill": "Iron Palm",
		"advanced": ["Storm Fist", "Stillwater Master"],
		"stats": {"hp": 112, "atk": 18, "def": 7, "speed": 1.32, "crit": 0.14},
		"rank_unlocks": ["Iron Palm", "+12% dodge stance", "Palm chains after crit", "Focus burst", "Class advancement"],
	},
}

const HEROES := [
	{"id": "arlen", "name": "Arlen", "class_id": "warrior"},
	{"id": "mira", "name": "Mira", "class_id": "ranger"},
	{"id": "sol", "name": "Sol", "class_id": "cleric"},
	{"id": "vex", "name": "Vex", "class_id": "rogue"},
	{"id": "nora", "name": "Nora", "class_id": "mage"},
	{"id": "maelis", "name": "Maelis", "class_id": "paladin"},
	{"id": "rowan", "name": "Rowan", "class_id": "druid"},
	{"id": "cog", "name": "Cog", "class_id": "artificer"},
	{"id": "nyra", "name": "Nyra", "class_id": "necromancer"},
	{"id": "jin", "name": "Jin", "class_id": "monk"},
]

const BUILDINGS := {
	"forge": {
		"name": "Forge",
		"column": 0,
		"text": "Craft, upgrade, reroll, and salvage gear.",
		"unlocks": ["Craft gear", "Upgrade gear", "Affix reroll", "Targeted forge", "Rare crafting"],
		"costs": [
			{"wood": 20, "ore": 18, "gold": 120},
			{"wood": 42, "ore": 45, "dust": 12, "gold": 360},
			{"wood": 90, "ore": 96, "dust": 30, "gold": 900},
			{"wood": 160, "ore": 180, "fragments": 8, "gold": 1800},
		],
	},
	"workshop": {
		"name": "Workshop",
		"column": 3,
		"text": "Battle speed and automation systems.",
		"unlocks": ["Battle speed", "Auto-salvage", "Smart farm", "Repeat crafting", "Full automation"],
		"costs": [
			{"wood": 24, "ore": 10, "ink": 8, "gold": 110},
			{"wood": 56, "ore": 28, "ink": 18, "gold": 340},
			{"wood": 104, "ore": 62, "ink": 40, "gold": 860},
			{"wood": 180, "ore": 110, "ink": 80, "gold": 1720},
		],
	},
	"academy": {
		"name": "Academy",
		"column": 2,
		"text": "Team slots, hero cap, and class advancement.",
		"unlocks": ["Training", "3rd slot", "Class ranks", "4th slot", "Elite classes"],
		"costs": [
			{"wood": 18, "ink": 18, "gold": 140},
			{"wood": 40, "ink": 42, "shards": 5, "gold": 420},
			{"wood": 82, "ink": 86, "shards": 14, "gold": 980},
			{"wood": 150, "ink": 160, "shards": 30, "gold": 2100},
		],
	},
	"infirmary": {
		"name": "Infirmary",
		"column": 1,
		"text": "Team health, recovery, and survival.",
		"unlocks": ["Recovery", "HP aura", "Defeat safety", "Boss revive", "Blessed camp"],
		"costs": [
			{"wood": 16, "herbs": 20, "gold": 120},
			{"wood": 38, "herbs": 46, "gold": 360},
			{"wood": 80, "herbs": 96, "ink": 20, "gold": 880},
			{"wood": 140, "herbs": 180, "ink": 46, "gold": 1900},
		],
	},
	"market": {
		"name": "Market",
		"column": 5,
		"text": "Trades, contracts, and idle income.",
		"unlocks": ["Trade", "Contracts", "Income aura", "Rare offers", "Guild route"],
		"costs": [
			{"wood": 26, "ore": 8, "gold": 160},
			{"wood": 60, "ore": 24, "herbs": 20, "gold": 420},
			{"wood": 120, "ore": 52, "herbs": 44, "gold": 1040},
			{"wood": 220, "ore": 110, "fragments": 6, "gold": 2200},
		],
	},
	"shrine": {
		"name": "Shrine",
		"column": 4,
		"text": "Talent branches, essence, and rare drops.",
		"unlocks": ["Combat talents", "Loot branch", "Class branch", "Boss essence", "Advanced nodes"],
		"costs": [
			{"wood": 12, "herbs": 12, "ink": 20, "gold": 150},
			{"wood": 32, "herbs": 28, "ink": 50, "essence": 4, "gold": 430},
			{"wood": 72, "herbs": 70, "ink": 110, "essence": 10, "gold": 1000},
			{"wood": 132, "herbs": 136, "ink": 210, "essence": 24, "gold": 2300},
		],
	},
}

const TALENTS := [
	{"id": "battle_rhythm", "name": "Battle Rhythm", "branch": "Combat", "cost": {"essence": 3}, "text": "+8% attack speed.", "effect": "speed"},
	{"id": "shared_guard", "name": "Shared Guard", "branch": "Combat", "cost": {"essence": 5}, "text": "+10 team defense.", "effect": "def"},
	{"id": "boss_breaker", "name": "Boss Breaker", "branch": "Combat", "cost": {"essence": 7, "ore": 45}, "text": "+15% boss damage.", "effect": "boss_damage"},
	{"id": "merchant_routes", "name": "Merchant Routes", "branch": "Economy", "cost": {"essence": 4, "gold": 250}, "text": "+15% gold gain.", "effect": "gold"},
	{"id": "packed_supplies", "name": "Packed Supplies", "branch": "Economy", "cost": {"essence": 5, "wood": 30}, "text": "+12% material gain.", "effect": "materials"},
	{"id": "veteran_trainers", "name": "Veteran Trainers", "branch": "Economy", "cost": {"essence": 7, "ink": 42}, "text": "+15% combat XP.", "effect": "xp"},
	{"id": "rare_find", "name": "Rare Find", "branch": "Loot", "cost": {"essence": 6, "ink": 30}, "text": "+4% rare equipment chance.", "effect": "rarity"},
	{"id": "shard_scent", "name": "Shard Scent", "branch": "Loot", "cost": {"essence": 7, "shards": 4}, "text": "+3% class shard chance.", "effect": "shards"},
	{"id": "careful_salvage", "name": "Careful Salvage", "branch": "Loot", "cost": {"essence": 8, "dust": 25}, "text": "+15% salvage yield.", "effect": "salvage"},
	{"id": "essence_lure", "name": "Essence Lure", "branch": "Loot", "cost": {"essence": 9, "fragments": 2}, "text": "+1 boss essence.", "effect": "essence"},
	{"id": "filter_junk", "name": "Filter Junk", "branch": "Automation", "cost": {"essence": 5, "ore": 30}, "text": "Unlock auto-salvage filter.", "effect": "automation"},
	{"id": "smart_farm", "name": "Smart Farm", "branch": "Automation", "cost": {"essence": 8, "ink": 50}, "text": "Improves farm stage efficiency.", "effect": "farm"},
	{"id": "field_medic", "name": "Field Medic", "branch": "Automation", "cost": {"essence": 8, "herbs": 60}, "text": "+8% team HP.", "effect": "hp"},
	{"id": "class_drill", "name": "Class Drill", "branch": "Class", "cost": {"essence": 6, "shards": 8}, "text": "-10% class rank costs.", "effect": "class"},
	{"id": "elite_doctrine", "name": "Elite Doctrine", "branch": "Class", "cost": {"essence": 12, "shards": 18, "ink": 70}, "text": "+6% rank stat scaling.", "effect": "rank_stats"},
]

const ACHIEVEMENTS := [
	{"id": "first_push", "name": "Beyond the Gate", "text": "Clear stage 2.", "metric": "best_stage", "target": 2, "reward": {"gold": 120}},
	{"id": "road_veteran", "name": "Road Veteran", "text": "Clear stage 10.", "metric": "best_stage", "target": 10, "reward": {"shards": 4, "gold": 300}},
	{"id": "frontier_scout", "name": "Frontier Scout", "text": "Clear stage 25.", "metric": "best_stage", "target": 25, "reward": {"essence": 5, "ink": 40}},
	{"id": "halfway", "name": "Halfway to Heaven", "text": "Clear stage 60.", "metric": "best_stage", "target": 60, "reward": {"fragments": 8, "shards": 14}},
	{"id": "voidwalker", "name": "Voidwalker", "text": "Clear stage 110.", "metric": "best_stage", "target": 110, "reward": {"essence": 20, "fragments": 20}},
	{"id": "crown_of_stars", "name": "Crown of Stars", "text": "Complete stage 120.", "metric": "best_stage", "target": 120, "reward": {"gold": 12000, "essence": 40}},
	{"id": "well_equipped", "name": "Well Equipped", "text": "Own 25 pieces of equipment.", "metric": "inventory", "target": 25, "reward": {"ore": 120, "dust": 30}},
	{"id": "quartermaster", "name": "Quartermaster", "text": "Own 75 pieces of equipment.", "metric": "inventory", "target": 75, "reward": {"ore": 300, "fragments": 10}},
	{"id": "growing_camp", "name": "Growing Camp", "text": "Reach 12 total building levels.", "metric": "building_levels", "target": 12, "reward": {"wood": 160, "gold": 500}},
	{"id": "master_builder", "name": "Master Builder", "text": "Max every camp building.", "metric": "building_levels", "target": 30, "reward": {"fragments": 18, "essence": 12}},
	{"id": "student", "name": "Shrine Student", "text": "Unlock 5 talents.", "metric": "talents", "target": 5, "reward": {"essence": 8}},
	{"id": "sage", "name": "Shrine Sage", "text": "Unlock every talent.", "metric": "talents", "target": 15, "reward": {"shards": 24, "essence": 20}},
	{"id": "seasoned", "name": "Seasoned Hero", "text": "Raise a hero to level 20.", "metric": "hero_level", "target": 20, "reward": {"gold": 1600, "herbs": 120}},
	{"id": "advanced_class", "name": "A Higher Calling", "text": "Advance a hero at rank 5.", "metric": "advanced_heroes", "target": 1, "reward": {"shards": 20, "ink": 100}},
	{"id": "treasury", "name": "Full Treasury", "text": "Hold 10,000 gold.", "metric": "gold", "target": 10000, "reward": {"fragments": 6, "dust": 80}},
	{"id": "relic_keeper", "name": "Relic Keeper", "text": "Collect all 12 region relics.", "metric": "relics", "target": 12, "reward": {"gold": 8000, "essence": 30}},
]

const REGIONS := [
	{"name": "Meadow Road", "materials": ["wood", "herbs"], "enemies": ["Slime", "Wolf"], "boss": "Moss Alpha", "set": "Wayfarer", "gear": ["Trailblade", "Hidecoat", "Lucky Acorn"]},
	{"name": "Iron Mine", "materials": ["ore", "dust"], "enemies": ["Mole", "Golem"], "boss": "Orebreaker", "set": "Deepdelver", "gear": ["Iron Pick", "Riveted Plate", "Miner's Lamp"]},
	{"name": "Grave Ruins", "materials": ["ink", "essence"], "enemies": ["Zombie", "Specter"], "boss": "Crypt King", "set": "Gravebound", "gear": ["Grave Scythe", "Mourning Mail", "Pale Locket"]},
	{"name": "Ember Hollow", "materials": ["ore", "fragments"], "enemies": ["Dinosaur", "Drake"], "boss": "Emberjaw", "set": "Emberhide", "gear": ["Cinder Fang", "Scale Mantle", "Coal Heart"]},
	{"name": "Fallen Keep", "materials": ["shards", "fragments"], "enemies": ["Bone Knight", "Warden"], "boss": "Hollow Lord", "set": "Oathbroken", "gear": ["Keep Cleaver", "Warden Plate", "Broken Signet"]},
	{"name": "Frostmarch", "materials": ["herbs", "shards"], "enemies": ["Frostling", "Whitefang"], "boss": "Wintermaw", "set": "Rimeguard", "gear": ["Glacier Edge", "Rimecoat", "Frozen Tear"]},
	{"name": "Sunken Vault", "materials": ["ink", "fragments"], "enemies": ["Drowned", "Shellback"], "boss": "Tide Tyrant", "set": "Tidecaller", "gear": ["Coral Spear", "Pearl Carapace", "Siren Coin"]},
	{"name": "Verdant Maze", "materials": ["wood", "essence"], "enemies": ["Vinebeast", "Sporeling"], "boss": "Thorn Matron", "set": "Wildheart", "gear": ["Briar Hook", "Living Bark", "Bloom Seed"]},
	{"name": "Clockwork City", "materials": ["ore", "ink"], "enemies": ["Automaton", "Gearhound"], "boss": "Grand Engine", "set": "Mechanist", "gear": ["Arc Wrench", "Brass Shell", "Ticking Core"]},
	{"name": "Crystal Expanse", "materials": ["dust", "shards"], "enemies": ["Shardling", "Prism Drake"], "boss": "Glass Colossus", "set": "Prismatic", "gear": ["Prism Blade", "Mirror Guard", "Star Lens"]},
	{"name": "Void Frontier", "materials": ["essence", "fragments"], "enemies": ["Voidling", "Rift Stalker"], "boss": "The Unmoored", "set": "Riftwalker", "gear": ["Null Saber", "Riftweave", "Black Compass"]},
	{"name": "Starfall Spire", "materials": ["shards", "essence"], "enemies": ["Astral Guard", "Comet Beast"], "boss": "Crown of Stars", "set": "Ascendant", "gear": ["Starforged Edge", "Celestial Aegis", "Dawn Crown"]},
]

const RELICS := [
	{"id": "wayfarer_compass", "name": "Wayfarer Compass", "region": "Meadow Road", "text": "+8% material rewards.", "effects": {"materials_pct": 0.08}},
	{"id": "deepdelver_anvil", "name": "Deepdelver Anvil", "region": "Iron Mine", "text": "+6 defense to every hero.", "effects": {"def_flat": 6.0}},
	{"id": "grave_bell", "name": "Grave Bell", "region": "Grave Ruins", "text": "+10% skill power.", "effects": {"skill_pct": 0.10}},
	{"id": "emberheart", "name": "Emberheart", "region": "Ember Hollow", "text": "+8% hero attack.", "effects": {"atk_pct": 0.08}},
	{"id": "warden_sigil", "name": "Warden Sigil", "region": "Fallen Keep", "text": "+10% hero health.", "effects": {"hp_pct": 0.10}},
	{"id": "winter_fang", "name": "Winter Fang", "region": "Frostmarch", "text": "+3% critical chance.", "effects": {"crit_flat": 0.03}},
	{"id": "tide_crown", "name": "Tide Crown", "region": "Sunken Vault", "text": "+10% gold rewards.", "effects": {"gold_pct": 0.10}},
	{"id": "thorn_seed", "name": "Thorn Seed", "region": "Verdant Maze", "text": "+6% health and +4% attack.", "effects": {"hp_pct": 0.06, "atk_pct": 0.04}},
	{"id": "clockwork_heart", "name": "Clockwork Heart", "region": "Clockwork City", "text": "+8% attack speed.", "effects": {"speed_flat": 0.08}},
	{"id": "prism_eye", "name": "Prism Eye", "region": "Crystal Expanse", "text": "+8 equipment rarity score.", "effects": {"rarity_bonus": 8.0}},
	{"id": "void_lantern", "name": "Void Lantern", "region": "Void Frontier", "text": "+12% boss damage and +10% salvage.", "effects": {"boss_damage_pct": 0.12, "salvage_pct": 0.10}},
	{"id": "star_crown", "name": "Star Crown", "region": "Starfall Spire", "text": "+8% core stats and +10% combat XP.", "effects": {"hp_pct": 0.08, "atk_pct": 0.08, "skill_pct": 0.08, "xp_pct": 0.10}},
]

const RARITIES: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const SLOTS: Array[String] = ["weapon", "armor", "trinket"]


func starting_materials() -> Dictionary:
	return {"gold": 260, "wood": 45, "ore": 35, "herbs": 22, "ink": 18, "dust": 8, "essence": 6, "shards": 8, "fragments": 0}


func resource_visual(resource_name: String) -> Dictionary:
	return RESOURCE_VISUALS.get(resource_name, {}).duplicate(true)


func enemy_sprite_region(enemy_index: int, state: int) -> Rect2i:
	return Rect2i(posmod(state, 4) * 192, posmod(enemy_index - 1, 5) * 192, 192, 192)


func building_sprite_region(building_index: int, level: int) -> Rect2i:
	return Rect2i(clampi(building_index, 0, 5) * 256, clampi(level, 0, 3) * 192, 256, 192)


func building_visual_column(building_id: String) -> int:
	var columns := {"forge": 0, "infirmary": 1, "workshop": 2, "academy": 3, "shrine": 4, "market": 5}
	return int(columns.get(building_id, 0))


func enemy_animation_state(cycle: float, is_boss: bool) -> int:
	var phase := fposmod(cycle, 1.0)
	if phase < 0.12:
		return 1
	if phase >= 0.42 and phase < 0.55:
		return 2
	if is_boss and phase >= 0.78 and phase < 0.92:
		return 3
	return 0


func enemy_visual_index(enemy_name: String, region_name: String) -> int:
	var normalized := enemy_name.to_lower()
	if normalized.contains("slime") or normalized.contains("moss"):
		return 1
	if normalized.contains("wolf") or normalized.contains("mole"):
		return 2
	if normalized.contains("zombie") or normalized.contains("specter") or normalized.contains("crypt"):
		return 3
	if normalized.contains("dinosaur") or normalized.contains("drake") or normalized.contains("ember"):
		return 4
	if normalized.contains("golem") or normalized.contains("orebreaker") or normalized.contains("bone") or normalized.contains("warden") or normalized.contains("hollow"):
		return 5
	var region := region_name.to_lower()
	if region.contains("meadow"):
		return 1
	if region.contains("grave"):
		return 3
	if region.contains("ember"):
		return 4
	return 5


func create_hero(hero_def: Dictionary) -> Dictionary:
	return {
		"id": hero_def["id"],
		"name": hero_def["name"],
		"class_id": hero_def["class_id"],
		"level": 1,
		"skill_level": 1,
		"rank": 1,
		"advanced": "",
		"xp": 0,
		"equipment": {"weapon": -1, "armor": -1, "trinket": -1},
		"hp": 0.0,
		"max_hp": 0.0,
		"attack_timer": 0.0,
		"skill_timer": 0.0,
	}


func get_class_data(class_id: String) -> Dictionary:
	return CLASSES.get(class_id, {}).duplicate(true)


func get_building_order() -> Array[String]:
	return ["forge", "workshop", "academy", "infirmary", "market", "shrine"]


func get_building(building_id: String) -> Dictionary:
	return BUILDINGS.get(building_id, {}).duplicate(true)


func get_building_cost(building_id: String, current_level: int) -> Dictionary:
	var building: Dictionary = get_building(building_id)
	if current_level >= 5:
		return {}
	var costs: Array = building["costs"]
	return costs[max(current_level - 1, 0)].duplicate(true)


func facility_service(building_id: String, current_level: int) -> Dictionary:
	var level := clampi(current_level, 1, 5)
	match building_id:
		"forge":
			return {
				"id": "craft",
				"name": "Craft Gear",
				"description": "Forge equipment near the current stage level.",
				"cost": {"gold": 60 + level * 25, "ore": 10 + level * 4, "dust": 2 + level},
				"reward": {},
			}
		"workshop":
			return {
				"id": "salvage",
				"name": "Sort Junk",
				"description": "Salvage all unlocked, unequipped Common and Uncommon gear.",
				"cost": {},
				"reward": {},
			}
		"academy":
			return {
				"id": "train",
				"name": "Train Hero",
				"description": "Raise the selected hero by one level.",
				"cost": {"gold": 80 + level * 60, "ink": 2 + level},
				"reward": {},
			}
		"infirmary":
			return {
				"id": "restore",
				"name": "Restore Team",
				"description": "Fully restore every active hero.",
				"cost": {"herbs": 6 + level * 2},
				"reward": {},
			}
		"market":
			return {
				"id": "trade",
				"name": "Trade Supplies",
				"description": "Exchange wood and ore for a level-scaled gold payout.",
				"cost": {"wood": 10 + level * 2, "ore": 4 + level},
				"reward": {"gold": 80 + level * 45},
			}
		"shrine":
			return {
				"id": "distill",
				"name": "Distill Essence",
				"description": "Convert camp supplies into talent essence.",
				"cost": {"gold": 50 + level * 25, "herbs": 6 + level * 2, "ink": 5 + level * 2},
				"reward": {"essence": 1 + int((level - 1) / 2)},
			}
	return {}


func get_talent(talent_id: String) -> Dictionary:
	for talent in TALENTS:
		if talent["id"] == talent_id:
			return talent.duplicate(true)
	return {}


func get_relic(relic_id: String) -> Dictionary:
	for relic in RELICS:
		if String(relic["id"]) == relic_id:
			return relic.duplicate(true)
	return {}


func relic_for_stage(stage_index: int) -> Dictionary:
	if stage_index < 10 or stage_index > MAX_STAGE or stage_index % 10 != 0:
		return {}
	return RELICS[int(stage_index / 10) - 1].duplicate(true)


func relic_effect_total(effect_name: String, owned_relics: Array[String]) -> float:
	var total := 0.0
	for relic_id in owned_relics:
		var relic := get_relic(relic_id)
		if not relic.is_empty():
			total += float((relic["effects"] as Dictionary).get(effect_name, 0.0))
	return total


func achievement_value(achievement: Dictionary, progress: Dictionary) -> int:
	return maxi(0, int(progress.get(String(achievement.get("metric", "")), 0)))


func achievement_complete(achievement: Dictionary, progress: Dictionary) -> bool:
	return achievement_value(achievement, progress) >= int(achievement.get("target", 1))


func get_stage(stage_index: int) -> Dictionary:
	stage_index = clampi(stage_index, 1, MAX_STAGE)
	var region_index: int = int((stage_index - 1) / 10)
	var local_stage: int = ((stage_index - 1) % 10) + 1
	var region: Dictionary = REGIONS[region_index]
	var level_min: int = max(1, stage_index - 3)
	var level_max: int = stage_index + 2 + region_index * 2
	return {
		"index": stage_index,
		"name": "%s %d-%d" % [region["name"], region_index + 1, local_stage],
		"region": region["name"],
		"wave_count": 10,
		"enemy_hp": 70 + stage_index * 24 + region_index * region_index * 35,
		"enemy_atk": 7 + stage_index * 3 + region_index * 2,
		"power": 450 + stage_index * 180 + region_index * region_index * 120,
		"item_min": level_min,
		"item_max": level_max,
		"materials": region["materials"],
		"enemies": region["enemies"],
		"boss": region["boss"],
		"set": region["set"],
		"is_final": stage_index == MAX_STAGE,
	}


func hero_stats(hero: Dictionary, inventory: Array, buildings: Dictionary, unlocked_talents: Array[String], owned_relics: Array[String] = []) -> Dictionary:
	var class_data: Dictionary = get_class_data(String(hero["class_id"]))
	var base: Dictionary = class_data["stats"]
	var level: int = int(hero["level"])
	var rank: int = int(hero["rank"])
	var stats: Dictionary = {
		"hp": int(base["hp"] + level * 18 + rank * 35),
		"atk": int(base["atk"] + level * 4 + rank * 8),
		"def": int(base["def"] + level * 2 + rank * 5),
		"speed": float(base["speed"]) + rank * 0.03,
		"crit": float(base["crit"]) + rank * 0.01,
		"skill_power": 1.0 + float(hero["skill_level"]) * 0.08,
	}
	if unlocked_talents.has("battle_rhythm"):
		stats["speed"] += 0.08
	if unlocked_talents.has("shared_guard"):
		stats["def"] += 10
	if unlocked_talents.has("field_medic"):
		stats["hp"] = int(float(stats["hp"]) * 1.08)
	if unlocked_talents.has("elite_doctrine"):
		stats["atk"] = int(float(stats["atk"]) * 1.06)
		stats["def"] = int(float(stats["def"]) * 1.06)
	_apply_advancement_stats(stats, String(hero.get("advanced", "")))
	stats["hp"] = int(float(stats["hp"]) * (1.0 + relic_effect_total("hp_pct", owned_relics)))
	stats["atk"] = int(float(stats["atk"]) * (1.0 + relic_effect_total("atk_pct", owned_relics)))
	stats["def"] += int(relic_effect_total("def_flat", owned_relics))
	stats["speed"] = float(stats["speed"]) + relic_effect_total("speed_flat", owned_relics)
	stats["crit"] = float(stats["crit"]) + relic_effect_total("crit_flat", owned_relics)
	stats["skill_power"] = float(stats["skill_power"]) * (1.0 + relic_effect_total("skill_pct", owned_relics))
	var infirmary_level: int = int(buildings.get("infirmary", 1))
	stats["hp"] += infirmary_level * 18
	for slot in SLOTS:
		var item_index: int = int(hero["equipment"].get(slot, -1))
		if item_index >= 0 and item_index < inventory.size():
			_apply_item_stats(stats, inventory[item_index])
	_apply_set_bonuses(stats, hero, inventory)
	return stats


func team_power(heroes: Array, inventory: Array, buildings: Dictionary, unlocked_talents: Array[String], team_slots: int, owned_relics: Array[String] = []) -> int:
	var power: int = 0
	for index in range(min(team_slots, heroes.size())):
		var stats: Dictionary = hero_stats(heroes[index], inventory, buildings, unlocked_talents, owned_relics)
		power += int(stats["hp"] * 0.6 + stats["atk"] * 9 + stats["def"] * 5 + float(stats["speed"]) * 90 + float(stats["crit"]) * 300)
	return power


func team_slots(buildings: Dictionary) -> int:
	var academy_level: int = int(buildings.get("academy", 1))
	if academy_level >= 5:
		return 5
	if academy_level >= 4:
		return 4
	if academy_level >= 2:
		return 3
	return 2


func can_afford(cost: Dictionary, materials: Dictionary) -> bool:
	for key in cost:
		if int(materials.get(key, 0)) < int(cost[key]):
			return false
	return true


func spend(cost: Dictionary, materials: Dictionary) -> void:
	for key in cost:
		materials[key] = int(materials.get(key, 0)) - int(cost[key])


func can_salvage_item(item: Dictionary, equipped: bool) -> bool:
	return not equipped and not bool(item.get("locked", false))


func hero_level_cost(hero: Dictionary) -> Dictionary:
	var level: int = int(hero["level"])
	if level >= MAX_HERO_LEVEL:
		return {}
	return {"gold": 50 + level * 32, "herbs": 2 + int(level / 4)}


func hero_xp_to_next(level: int) -> int:
	return 60 + clampi(level, 1, MAX_HERO_LEVEL) * 30


func grant_hero_xp(hero: Dictionary, amount: int) -> int:
	if int(hero.get("level", 1)) >= MAX_HERO_LEVEL:
		hero["xp"] = 0
		return 0
	hero["xp"] = int(hero.get("xp", 0)) + maxi(0, amount)
	var levels_gained := 0
	while int(hero["level"]) < MAX_HERO_LEVEL:
		var needed := hero_xp_to_next(int(hero["level"]))
		if int(hero["xp"]) < needed:
			break
		hero["xp"] = int(hero["xp"]) - needed
		hero["level"] = int(hero["level"]) + 1
		levels_gained += 1
	if int(hero["level"]) >= MAX_HERO_LEVEL:
		hero["xp"] = 0
	return levels_gained


func skill_cost(hero: Dictionary) -> Dictionary:
	var level: int = int(hero["skill_level"])
	return {"gold": 80 + level * 45, "ink": 4 + level * 2}


func class_rank_cost(hero: Dictionary, class_discount: bool) -> Dictionary:
	var rank: int = int(hero["rank"])
	var multiplier: float = 0.9 if class_discount else 1.0
	return {
		"gold": int((220 + rank * 180) * multiplier),
		"shards": int((6 + rank * 4) * multiplier),
		"ink": int((8 + rank * 3) * multiplier),
	}


func equipment_upgrade_cost(item: Dictionary) -> Dictionary:
	var level: int = int(item["level"])
	return {"ore": 8 + level * 3, "dust": 2 + int(level / 2), "gold": 35 + level * 18}


func generate_equipment(stage_index: int, roll_index: int, rarity_bonus: int = 0) -> Dictionary:
	var stage: Dictionary = get_stage(stage_index)
	var region_index: int = int((int(stage["index"]) - 1) / 10)
	var region: Dictionary = REGIONS[region_index]
	var slot: String = SLOTS[(stage_index + roll_index) % SLOTS.size()]
	var rarity_score: int = (stage_index + roll_index * 3 + rarity_bonus) % 100
	var rarity: String = "Common"
	if rarity_score > 94:
		rarity = "Legendary"
	elif rarity_score > 82:
		rarity = "Epic"
	elif rarity_score > 62:
		rarity = "Rare"
	elif rarity_score > 34:
		rarity = "Uncommon"
	var item_level: int = int(stage["item_min"]) + ((stage_index + roll_index) % max(1, int(stage["item_max"]) - int(stage["item_min"]) + 1))
	var req_level: int = max(1, item_level - (1 if rarity == "Legendary" else 0))
	var main_stat: Dictionary = _item_main_stat(slot, item_level, rarity)
	return {
		"id": "item_%d_%d" % [stage_index, roll_index],
		"name": "%s %s" % [rarity, String(region["gear"][SLOTS.find(slot)])],
		"slot": slot,
		"rarity": rarity,
		"level": item_level,
		"required_level": req_level,
		"main": main_stat,
		"affix": _item_affix(stage_index, roll_index, rarity),
		"set": String(region["set"]),
		"source_region": String(stage["region"]),
		"locked": false,
	}


func encounter_type(wave: int, wave_count: int) -> String:
	if wave >= wave_count:
		return "Boss"
	if wave % 5 == 0:
		return "Elite"
	return "Normal"


func should_drop_equipment(stage_index: int, wave: int, roll_index: int) -> bool:
	var stage: Dictionary = get_stage(stage_index)
	var encounter := encounter_type(wave, int(stage["wave_count"]))
	if encounter == "Boss":
		return true
	if encounter == "Elite":
		return (stage_index + roll_index) % 100 < 72
	return (stage_index * 7 + wave * 13 + roll_index * 17) % 100 < 24


func wave_rewards(stage_index: int, wave: int, buildings: Dictionary, talents: Array[String], owned_relics: Array[String] = []) -> Dictionary:
	var stage: Dictionary = get_stage(stage_index)
	var market_level: int = int(buildings.get("market", 1))
	var material_bonus: float = 1.0 + market_level * 0.05 + (0.12 if talents.has("packed_supplies") else 0.0) + relic_effect_total("materials_pct", owned_relics)
	var gold_bonus: float = 1.0 + market_level * 0.07 + (0.15 if talents.has("merchant_routes") else 0.0) + relic_effect_total("gold_pct", owned_relics)
	var rewards: Dictionary = {
		"gold": int((18 + stage_index * 5) * gold_bonus),
		"wood": 0,
		"ore": 0,
		"herbs": 0,
		"ink": 0,
		"dust": 0,
		"essence": 0,
		"shards": 0,
		"fragments": 0,
	}
	for material in stage["materials"]:
		rewards[material] = int((3 + stage_index) * material_bonus)
	var encounter := encounter_type(wave, int(stage["wave_count"]))
	if encounter == "Elite":
		rewards["gold"] += int((12 + stage_index * 3) * gold_bonus)
		rewards["dust"] += 3 + int(stage_index / 3)
		rewards["fragments"] += int(stage_index / 30)
	if encounter == "Boss":
		rewards["essence"] += 1 + int(stage_index / 10)
		if talents.has("essence_lure"):
			rewards["essence"] += 1
		rewards["shards"] += 1 + (1 if talents.has("shard_scent") else 0)
		if stage_index >= 10:
			rewards["fragments"] += 1
	return rewards


func salvage_value(item: Dictionary, talents: Array[String], owned_relics: Array[String] = []) -> Dictionary:
	var bonus: float = (1.15 if talents.has("careful_salvage") else 1.0) + relic_effect_total("salvage_pct", owned_relics)
	return {
		"ore": int((5 + int(item["level"]) * 2) * bonus),
		"dust": int((1 + _rarity_index(item["rarity"])) * bonus),
		"fragments": 1 if _rarity_index(item["rarity"]) >= 3 else 0,
	}


func _apply_item_stats(stats: Dictionary, item: Dictionary) -> void:
	for key in item["main"]:
		stats[key] = stats.get(key, 0) + item["main"][key]
	var affix: Dictionary = item["affix"]
	stats[affix["stat"]] = stats.get(affix["stat"], 0) + affix["value"]


func _item_main_stat(slot: String, level: int, rarity: String) -> Dictionary:
	var multiplier: float = 1.0 + _rarity_index(rarity) * 0.28
	if slot == "weapon":
		return {"atk": int((12 + level * 4) * multiplier)}
	if slot == "armor":
		return {"hp": int((80 + level * 18) * multiplier), "def": int((4 + level * 1.2) * multiplier)}
	return {"speed": 0.03 + level * 0.002 * multiplier, "crit": 0.01 + level * 0.001 * multiplier}


func _item_affix(stage_index: int, roll_index: int, rarity: String) -> Dictionary:
	var affixes: Array = [
		{"stat": "atk", "label": "Attack", "base": 5},
		{"stat": "hp", "label": "HP", "base": 35},
		{"stat": "def", "label": "Defense", "base": 3},
		{"stat": "crit", "label": "Crit", "base": 0.015},
		{"stat": "speed", "label": "Speed", "base": 0.025},
		{"stat": "skill_power", "label": "Skill Power", "base": 0.04},
		{"stat": "atk", "label": "Ferocity", "base": 8},
		{"stat": "hp", "label": "Vitality", "base": 55},
	]
	var affix: Dictionary = affixes[(stage_index + roll_index) % affixes.size()]
	var value = affix["base"]
	if typeof(value) == TYPE_FLOAT:
		value = float(value) + _rarity_index(rarity) * 0.006
	else:
		value = int(value) + stage_index * (1 + _rarity_index(rarity))
	return {"stat": affix["stat"], "label": affix["label"], "value": value}


func _apply_set_bonuses(stats: Dictionary, hero: Dictionary, inventory: Array) -> void:
	var counts: Dictionary = {}
	for slot in SLOTS:
		var item_index := int(hero.get("equipment", {}).get(slot, -1))
		if item_index >= 0 and item_index < inventory.size():
			var set_name := String(inventory[item_index].get("set", ""))
			if not set_name.is_empty():
				counts[set_name] = int(counts.get(set_name, 0)) + 1
	for set_name in counts:
		var count := int(counts[set_name])
		if count >= 2:
			stats["atk"] = int(float(stats["atk"]) * 1.08)
			stats["hp"] = int(float(stats["hp"]) * 1.08)
		if count >= 3:
			stats["speed"] = float(stats["speed"]) + 0.08
			stats["crit"] = float(stats["crit"]) + 0.04


func _apply_advancement_stats(stats: Dictionary, advancement: String) -> void:
	if advancement.is_empty():
		return
	var aggressive := ["Blademaster", "Sniper", "Battle Saint", "Nightblade", "Archmage", "Templar", "Wildspeaker", "Machinist", "Lichbinder", "Storm Fist"]
	if aggressive.has(advancement):
		stats["atk"] = int(float(stats["atk"]) * 1.18)
		stats["crit"] = float(stats["crit"]) + 0.04
	else:
		stats["hp"] = int(float(stats["hp"]) * 1.18)
		stats["def"] = int(float(stats["def"]) * 1.15)


func _slot_name(slot: String) -> String:
	if slot == "weapon":
		return "Weapon"
	if slot == "armor":
		return "Armor"
	return "Trinket"


func _rarity_index(rarity: String) -> int:
	return max(RARITIES.find(rarity), 0)
