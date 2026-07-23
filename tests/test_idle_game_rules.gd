extends Node

const IdleGameRules = preload("res://IdleGameRules.gd")

var failures := 0


func _ready() -> void:
	var rules := IdleGameRules.new()
	_test_stage_loot_scales(rules)
	_test_team_slots_follow_academy_level(rules)
	_test_class_discount_reduces_rank_cost(rules)
	_test_locked_or_equipped_items_cannot_be_salvaged(rules)
	_test_every_facility_has_a_distinct_service(rules)
	_test_market_service_trades_supplies_for_gold(rules)
	_test_shrine_service_improves_with_level(rules)
	_test_every_resource_has_a_visual_definition(rules)
	_test_talent_tree_has_branch_depth(rules)
	_test_new_talents_change_rewards_and_stats(rules)
	_test_enemy_sprite_regions_match_the_sheet_grid(rules)
	_test_building_sprite_regions_match_the_sheet_grid(rules)
	_test_enemy_animation_cycle_uses_combat_frames(rules)
	_test_enemy_names_map_to_matching_visual_families(rules)
	_test_building_names_map_to_matching_art_columns(rules)
	_test_campaign_has_authored_late_game_regions(rules)
	_test_elites_and_bosses_have_distinct_rewards(rules)
	_test_region_gear_sets_and_drop_rules(rules)
	_test_equipment_sets_and_advancements_change_stats(rules)
	_test_achievement_catalog_and_completion(rules)
	_test_combat_xp_levels_and_caps_heroes(rules)
	_test_region_relics_are_unique_and_functional(rules)
	_test_expanded_buildings_change_progression(rules)
	if failures == 0:
		print("IDLE_RULES_TEST_PASS")
	else:
		push_error("Idle rules tests failed: %d" % [failures])
	get_tree().quit(0 if failures == 0 else 1)


func _test_stage_loot_scales(rules) -> void:
	var early: Dictionary = rules.get_stage(1)
	var late: Dictionary = rules.get_stage(21)
	_assert_true(int(late["item_min"]) > int(early["item_min"]), "later stages raise minimum item level")
	_assert_true(int(late["item_max"]) > int(early["item_max"]), "later stages raise maximum item level")
	var item: Dictionary = rules.generate_equipment(21, 4)
	_assert_true(int(item["level"]) >= int(late["item_min"]), "generated item respects stage minimum")
	_assert_true(int(item["level"]) <= int(late["item_max"]), "generated item respects stage maximum")


func _test_team_slots_follow_academy_level(rules) -> void:
	_assert_equal(rules.team_slots({"academy": 1}), 2, "academy level one starts with two heroes")
	_assert_equal(rules.team_slots({"academy": 2}), 3, "academy level two unlocks a third hero")
	_assert_equal(rules.team_slots({"academy": 5}), 5, "academy level five unlocks the full team")


func _test_class_discount_reduces_rank_cost(rules) -> void:
	var hero: Dictionary = rules.create_hero(rules.HEROES[0])
	var normal: Dictionary = rules.class_rank_cost(hero, false)
	var discounted: Dictionary = rules.class_rank_cost(hero, true)
	_assert_true(int(discounted["gold"]) < int(normal["gold"]), "class talent reduces rank gold cost")
	_assert_true(int(discounted["shards"]) < int(normal["shards"]), "class talent reduces rank shard cost")


func _test_locked_or_equipped_items_cannot_be_salvaged(rules) -> void:
	if not rules.has_method("can_salvage_item"):
		push_error("IdleGameRules is missing can_salvage_item")
		failures += 1
		return
	var item: Dictionary = rules.generate_equipment(1, 0)
	_assert_true(rules.can_salvage_item(item, false), "ordinary unequipped item can be salvaged")
	item["locked"] = true
	_assert_false(rules.can_salvage_item(item, false), "locked item cannot be salvaged")
	item["locked"] = false
	_assert_false(rules.can_salvage_item(item, true), "equipped item cannot be salvaged")


func _test_every_facility_has_a_distinct_service(rules) -> void:
	if not rules.has_method("facility_service"):
		_fail("IdleGameRules is missing facility_service")
		return
	var names: Array[String] = []
	for building_id in rules.get_building_order():
		var service: Dictionary = rules.facility_service(building_id, 1)
		_assert_false(service.is_empty(), "%s has a facility service" % [building_id])
		var service_name := String(service.get("name", ""))
		_assert_false(service_name.is_empty(), "%s service has a name" % [building_id])
		_assert_false(names.has(service_name), "%s service name is unique" % [building_id])
		names.append(service_name)


func _test_market_service_trades_supplies_for_gold(rules) -> void:
	if not rules.has_method("facility_service"):
		return
	var service: Dictionary = rules.facility_service("market", 3)
	_assert_true(int(service["cost"].get("wood", 0)) > 0, "market trade costs wood")
	_assert_true(int(service["cost"].get("ore", 0)) > 0, "market trade costs ore")
	_assert_true(int(service["reward"].get("gold", 0)) > 0, "market trade rewards gold")


func _test_shrine_service_improves_with_level(rules) -> void:
	if not rules.has_method("facility_service"):
		return
	var first: Dictionary = rules.facility_service("shrine", 1)
	var fifth: Dictionary = rules.facility_service("shrine", 5)
	_assert_true(int(fifth["reward"].get("essence", 0)) > int(first["reward"].get("essence", 0)), "higher shrine level distills more essence")


func _test_every_resource_has_a_visual_definition(rules) -> void:
	if not rules.has_method("resource_visual"):
		_fail("IdleGameRules is missing resource_visual")
		return
	var symbols: Array[String] = []
	for resource_name in rules.RESOURCE_ORDER:
		var visual: Dictionary = rules.resource_visual(resource_name)
		_assert_false(visual.is_empty(), "%s has a resource visual" % [resource_name])
		var symbol := String(visual.get("symbol", ""))
		_assert_false(symbol.is_empty(), "%s visual has a symbol" % [resource_name])
		_assert_false(symbols.has(symbol), "%s visual symbol is distinct" % [resource_name])
		_assert_true(visual.get("color", null) is Color, "%s visual has a color" % [resource_name])
		symbols.append(symbol)


func _test_talent_tree_has_branch_depth(rules) -> void:
	var branches := {}
	for talent in rules.TALENTS:
		var branch := String(talent["branch"])
		branches[branch] = int(branches.get(branch, 0)) + 1
	for branch_name in ["Combat", "Economy", "Loot", "Automation", "Class"]:
		_assert_true(int(branches.get(branch_name, 0)) >= 2, "%s branch has multiple talents" % [branch_name])


func _test_new_talents_change_rewards_and_stats(rules) -> void:
	var boss_wave: int = int(rules.get_stage(10)["wave_count"])
	var no_talents: Array[String] = []
	var essence_talents: Array[String] = ["essence_lure"]
	var salvage_talents: Array[String] = ["careful_salvage"]
	var medic_talents: Array[String] = ["field_medic"]
	var ordinary: Dictionary = rules.wave_rewards(10, boss_wave, {"market": 1}, no_talents)
	var lured: Dictionary = rules.wave_rewards(10, boss_wave, {"market": 1}, essence_talents)
	_assert_true(int(lured["essence"]) > int(ordinary["essence"]), "essence lure increases boss essence")
	var item: Dictionary = rules.generate_equipment(12, 4)
	var base_salvage: Dictionary = rules.salvage_value(item, no_talents)
	var careful_salvage: Dictionary = rules.salvage_value(item, salvage_talents)
	_assert_true(int(careful_salvage["ore"]) > int(base_salvage["ore"]), "careful salvage increases ore yield")
	var hero: Dictionary = rules.create_hero(rules.HEROES[0])
	var base_stats: Dictionary = rules.hero_stats(hero, [], {"infirmary": 1}, no_talents)
	var medic_stats: Dictionary = rules.hero_stats(hero, [], {"infirmary": 1}, medic_talents)
	_assert_true(int(medic_stats["hp"]) > int(base_stats["hp"]), "field medic increases hero HP")


func _test_enemy_sprite_regions_match_the_sheet_grid(rules) -> void:
	if not rules.has_method("enemy_sprite_region"):
		_fail("IdleGameRules is missing enemy_sprite_region")
		return
	_assert_equal(rules.enemy_sprite_region(1, 0), Rect2i(0, 0, 192, 192), "first enemy idle frame uses the first cell")
	_assert_equal(rules.enemy_sprite_region(2, 1), Rect2i(192, 192, 192, 192), "second enemy attack frame uses row two column two")
	_assert_equal(rules.enemy_sprite_region(6, 3), Rect2i(576, 0, 192, 192), "enemy families wrap while preserving animation state")


func _test_building_sprite_regions_match_the_sheet_grid(rules) -> void:
	if not rules.has_method("building_sprite_region"):
		_fail("IdleGameRules is missing building_sprite_region")
		return
	_assert_equal(rules.building_sprite_region(0, 0), Rect2i(0, 0, 256, 192), "forge base uses the first sheet cell")
	_assert_equal(rules.building_sprite_region(1, 1), Rect2i(256, 192, 256, 192), "workshop level one uses its column and first built row")
	_assert_equal(rules.building_art_level(3), 2, "middle building levels use the developed art tier")
	_assert_equal(rules.building_sprite_region(5, 5), Rect2i(1280, 576, 256, 192), "shrine max level uses its column and highest art row")


func _test_enemy_animation_cycle_uses_combat_frames(rules) -> void:
	if not rules.has_method("enemy_animation_state"):
		_fail("IdleGameRules is missing enemy_animation_state")
		return
	_assert_equal(rules.enemy_animation_state(0.05, false), 1, "opening animation phase uses attack frame")
	_assert_equal(rules.enemy_animation_state(0.48, false), 2, "middle animation phase uses hit frame")
	_assert_equal(rules.enemy_animation_state(0.84, true), 3, "boss late phase uses skill frame")
	_assert_equal(rules.enemy_animation_state(0.84, false), 0, "normal enemy late phase returns to idle")


func _test_enemy_names_map_to_matching_visual_families(rules) -> void:
	if not rules.has_method("enemy_visual_index"):
		_fail("IdleGameRules is missing enemy_visual_index")
		return
	_assert_equal(rules.enemy_visual_index("Slime", "Meadow Road"), 1, "slime uses slime art")
	_assert_equal(rules.enemy_visual_index("Wolf", "Meadow Road"), 2, "wolf uses wolf art")
	_assert_equal(rules.enemy_visual_index("Zombie", "Grave Ruins"), 3, "zombie uses undead art")
	_assert_equal(rules.enemy_visual_index("Dinosaur", "Ember Hollow"), 4, "dinosaur uses dinosaur art")
	_assert_equal(rules.enemy_visual_index("Bone Knight", "Fallen Keep"), 5, "bone knight uses armored enemy art")
	_assert_equal(rules.enemy_visual_index("Golem", "Iron Mine"), 5, "golem uses heavy enemy art")


func _test_building_names_map_to_matching_art_columns(rules) -> void:
	if not rules.has_method("building_visual_column"):
		_fail("IdleGameRules is missing building_visual_column")
		return
	_assert_equal(rules.building_visual_column("forge"), 0, "forge uses forge art")
	_assert_equal(rules.building_visual_column("infirmary"), 1, "infirmary uses medical art")
	_assert_equal(rules.building_visual_column("workshop"), 2, "workshop uses workshop art")
	_assert_equal(rules.building_visual_column("academy"), 3, "academy uses academy art")
	_assert_equal(rules.building_visual_column("shrine"), 4, "shrine uses shrine art")
	_assert_equal(rules.building_visual_column("market"), 5, "market uses market art")
	_assert_equal(rules.building_visual_column("barracks"), 6, "barracks uses expansion art")
	_assert_equal(rules.building_visual_column("observatory"), 7, "observatory uses expansion art")


func _test_campaign_has_authored_late_game_regions(rules) -> void:
	_assert_equal(rules.MAX_STAGE, 120, "campaign contains 120 stages")
	_assert_equal(rules.REGIONS.size(), 12, "campaign contains twelve authored regions")
	var final_stage: Dictionary = rules.get_stage(rules.MAX_STAGE)
	_assert_equal(final_stage["region"], "Starfall Spire", "final stages use the authored final region")
	_assert_true(bool(final_stage["is_final"]), "stage 120 is marked as the campaign finale")
	_assert_true(int(final_stage["power"]) > int(rules.get_stage(60)["power"]), "late-game power continues scaling")


func _test_elites_and_bosses_have_distinct_rewards(rules) -> void:
	var buildings := {"market": 1}
	var talents: Array[String] = []
	_assert_equal(rules.encounter_type(4, 10), "Normal", "ordinary wave is normal")
	_assert_equal(rules.encounter_type(5, 10), "Elite", "middle wave is elite")
	_assert_equal(rules.encounter_type(10, 10), "Boss", "final wave is boss")
	var normal: Dictionary = rules.wave_rewards(31, 4, buildings, talents)
	var elite: Dictionary = rules.wave_rewards(31, 5, buildings, talents)
	var boss: Dictionary = rules.wave_rewards(31, 10, buildings, talents)
	_assert_true(int(elite["gold"]) > int(normal["gold"]), "elite grants bonus gold")
	_assert_true(int(elite["dust"]) > int(normal["dust"]), "elite grants bonus dust")
	_assert_true(int(boss["essence"]) > int(normal["essence"]), "boss grants essence")


func _test_region_gear_sets_and_drop_rules(rules) -> void:
	var early: Dictionary = rules.generate_equipment(1, 2)
	var late: Dictionary = rules.generate_equipment(111, 2)
	_assert_equal(early["set"], "Wayfarer", "early gear belongs to the meadow set")
	_assert_equal(late["set"], "Ascendant", "final-region gear belongs to the ascendant set")
	_assert_true(String(early["name"]) != String(late["name"]), "regions have distinct item names")
	_assert_true(rules.should_drop_equipment(20, 10, 3), "bosses guarantee equipment")


func _test_equipment_sets_and_advancements_change_stats(rules) -> void:
	var hero: Dictionary = rules.create_hero(rules.HEROES[0])
	var no_talents: Array[String] = []
	var base: Dictionary = rules.hero_stats(hero, [], {"infirmary": 1}, no_talents)
	hero["advanced"] = "Blademaster"
	var advanced: Dictionary = rules.hero_stats(hero, [], {"infirmary": 1}, no_talents)
	_assert_true(int(advanced["atk"]) > int(base["atk"]), "aggressive advancement raises attack")
	var inventory: Array = []
	for roll in range(3):
		inventory.append(rules.generate_equipment(1, roll))
		hero["equipment"][rules.SLOTS[roll]] = roll
	var set_stats: Dictionary = rules.hero_stats(hero, inventory, {"infirmary": 1}, no_talents)
	_assert_true(float(set_stats["speed"]) > float(advanced["speed"]), "three-piece set raises speed")
	_assert_true(float(set_stats["crit"]) > float(advanced["crit"]), "three-piece set raises crit")


func _test_achievement_catalog_and_completion(rules) -> void:
	_assert_true(rules.ACHIEVEMENTS.size() >= 15, "achievement catalog has long-term depth")
	var ids: Array[String] = []
	for achievement in rules.ACHIEVEMENTS:
		var achievement_id := String(achievement["id"])
		_assert_false(ids.has(achievement_id), "achievement IDs are unique")
		_assert_false((achievement["reward"] as Dictionary).is_empty(), "%s has a reward" % [achievement_id])
		ids.append(achievement_id)
	var finale: Dictionary = rules.ACHIEVEMENTS[5]
	_assert_false(rules.achievement_complete(finale, {"best_stage": 119}), "finale remains locked before stage 120")
	_assert_true(rules.achievement_complete(finale, {"best_stage": 120}), "finale unlocks at stage 120")


func _test_combat_xp_levels_and_caps_heroes(rules) -> void:
	var hero: Dictionary = rules.create_hero(rules.HEROES[0])
	var needed: int = rules.hero_xp_to_next(1)
	_assert_equal(rules.grant_hero_xp(hero, needed - 1), 0, "partial XP does not level a hero")
	_assert_equal(rules.grant_hero_xp(hero, 1), 1, "reaching the XP threshold levels a hero")
	_assert_equal(hero["level"], 2, "XP level is applied to durable hero state")
	hero["level"] = rules.MAX_HERO_LEVEL
	hero["xp"] = 50
	_assert_equal(rules.grant_hero_xp(hero, 9999), 0, "max-level hero gains no extra levels")
	_assert_equal(hero["xp"], 0, "max-level hero does not retain useless XP")


func _test_region_relics_are_unique_and_functional(rules) -> void:
	_assert_equal(rules.RELICS.size(), rules.REGIONS.size(), "every region has one relic")
	var ids: Array[String] = []
	for relic in rules.RELICS:
		var relic_id := String(relic["id"])
		_assert_false(ids.has(relic_id), "relic IDs are unique")
		_assert_false((relic["effects"] as Dictionary).is_empty(), "%s has a gameplay effect" % [relic_id])
		ids.append(relic_id)
	_assert_true(rules.relic_for_stage(9).is_empty(), "ordinary stage does not award a region relic")
	_assert_equal(rules.relic_for_stage(10)["id"], "wayfarer_compass", "first capstone awards meadow relic")
	_assert_equal(rules.relic_for_stage(120)["id"], "star_crown", "final capstone awards final relic")
	var no_relics: Array[String] = []
	var attack_relics: Array[String] = ["emberheart"]
	var hero: Dictionary = rules.create_hero(rules.HEROES[0])
	var base: Dictionary = rules.hero_stats(hero, [], {"infirmary": 1}, no_relics, no_relics)
	var boosted: Dictionary = rules.hero_stats(hero, [], {"infirmary": 1}, no_relics, attack_relics)
	_assert_true(int(boosted["atk"]) > int(base["atk"]), "ember relic increases hero attack")
	var ordinary: Dictionary = rules.wave_rewards(10, 1, {"market": 1}, no_relics, no_relics)
	var compass_relics: Array[String] = ["wayfarer_compass"]
	var compass: Dictionary = rules.wave_rewards(10, 1, {"market": 1}, no_relics, compass_relics)
	_assert_true(int(compass["wood"]) > int(ordinary["wood"]), "compass increases region materials")


func _test_expanded_buildings_change_progression(rules) -> void:
	_assert_equal(rules.get_building_order().size(), 8, "camp has eight distinct facilities")
	var no_talents: Array[String] = []
	var no_relics: Array[String] = []
	var hero: Dictionary = rules.create_hero(rules.HEROES[0])
	var basic: Dictionary = rules.hero_stats(hero, [], {"infirmary": 1, "barracks": 1}, no_talents, no_relics)
	var trained: Dictionary = rules.hero_stats(hero, [], {"infirmary": 1, "barracks": 5}, no_talents, no_relics)
	_assert_true(int(trained["atk"]) > int(basic["atk"]), "higher barracks level increases hero attack")
	var basic_rarity: int = rules.equipment_rarity_bonus({"observatory": 1}, no_talents, no_relics)
	var scouted_rarity: int = rules.equipment_rarity_bonus({"observatory": 5}, no_talents, no_relics)
	_assert_true(scouted_rarity > basic_rarity, "higher observatory level improves equipment rarity")
	_assert_equal(rules.facility_service("barracks", 1)["id"], "drill", "barracks offers team drills")
	_assert_equal(rules.facility_service("observatory", 1)["id"], "scout", "observatory offers scout caches")


func _fail(message: String) -> void:
	push_error(message)
	failures += 1


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, expected, actual])
		failures += 1


func _assert_true(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1


func _assert_false(value: bool, message: String) -> void:
	if value:
		push_error(message)
		failures += 1
