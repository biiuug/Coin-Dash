extends Node

const SaveGameRules = preload("res://SaveGameRules.gd")

var failures := 0


func _ready() -> void:
	var rules := SaveGameRules.new()
	_test_snapshot_keeps_durable_progress(rules)
	_test_snapshot_omits_current_battle_progress(rules)
	_test_snapshot_does_not_alias_live_state(rules)
	if failures == 0:
		print("SAVE_GAME_RULES_TEST_PASS")
	else:
		push_error("Save game rules tests failed: %d" % failures)
	get_tree().quit(0 if failures == 0 else 1)


func _sample_state() -> Dictionary:
	return {
		"materials": {"gold": 321, "ore": 17},
		"heroes": [{
			"id": "warden",
			"level": 9,
			"skill_level": 4,
			"rank": 3,
			"advanced": "Sentinel",
			"xp": 876,
			"equipment": {"weapon": 0, "armor": -1, "trinket": 1},
			"future_mastery": 12,
			"hp": 4.0,
			"max_hp": 240.0,
			"attack_timer": 0.75,
			"skill_timer": 2.25,
		}],
		"inventory": [{"id": "blade", "level": 8, "required_level": 7, "locked": true}],
		"buildings": {"forge": 4, "academy": 3},
		"unlocked_talents": ["class_drill"],
		"unlocked_achievements": ["road_veteran"],
		"owned_relics": ["wayfarer_compass"],
		"selected_tab": "Equipment",
		"selected_hero": 0,
		"selected_item": 0,
		"equipment_filter": "weapon",
		"auto_salvage_junk": true,
		"selected_building": "forge",
		"selected_talent": "class_drill",
		"stage_index": 7,
		"best_stage": 9,
		"battle_paused": true,
		"speed_index": 2,
		"item_roll_counter": 41,
		"current_wave": 4,
		"enemy_name": "Boss",
		"enemy_hp": 12.0,
		"enemy_max_hp": 500.0,
		"battle_log": ["Killed three enemies"],
	}


func _test_snapshot_keeps_durable_progress(rules) -> void:
	var snapshot: Dictionary = rules.build_snapshot(_sample_state(), 12345.0)
	_assert_equal(snapshot.get("version"), 4, "save format version")
	_assert_equal(snapshot.get("materials"), {"gold": 321, "ore": 17}, "resources")
	_assert_equal(snapshot.get("inventory"), [{"id": "blade", "level": 8, "required_level": 7, "locked": true}], "all inventory data")
	_assert_equal(snapshot.get("buildings"), {"forge": 4, "academy": 3}, "building levels")
	_assert_equal(snapshot.get("stage_index"), 7, "selected stage")
	_assert_equal(snapshot.get("best_stage"), 9, "stage push progress")
	_assert_equal(snapshot.get("unlocked_achievements"), ["road_veteran"], "claimed achievements")
	_assert_equal(snapshot.get("owned_relics"), ["wayfarer_compass"], "collected relics")
	var hero: Dictionary = snapshot["heroes"][0]
	_assert_equal(hero.get("level"), 9, "hero level")
	_assert_equal(hero.get("rank"), 3, "hero class rank")
	_assert_equal(hero.get("advanced"), "Sentinel", "hero advancement")
	_assert_equal(hero.get("xp"), 876, "hero experience")
	_assert_equal(hero.get("equipment"), {"weapon": 0, "armor": -1, "trinket": 1}, "equipped inventory")
	_assert_equal(hero.get("future_mastery"), 12, "future durable hero progress")


func _test_snapshot_omits_current_battle_progress(rules) -> void:
	var snapshot: Dictionary = rules.build_snapshot(_sample_state(), 12345.0)
	for key in ["current_wave", "enemy_name", "enemy_hp", "enemy_max_hp", "battle_log"]:
		_assert_false(snapshot.has(key), "snapshot omits %s" % key)
	var hero: Dictionary = snapshot["heroes"][0]
	for key in ["hp", "max_hp", "attack_timer", "skill_timer"]:
		_assert_false(hero.has(key), "hero snapshot omits %s" % key)


func _test_snapshot_does_not_alias_live_state(rules) -> void:
	var state := _sample_state()
	var snapshot: Dictionary = rules.build_snapshot(state, 12345.0)
	snapshot["materials"]["gold"] = 0
	snapshot["heroes"][0]["level"] = 1
	_assert_equal(state["materials"]["gold"], 321, "snapshot resources are copied")
	_assert_equal(state["heroes"][0]["level"], 9, "snapshot heroes are copied")


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, expected, actual])
		failures += 1


func _assert_false(value: bool, message: String) -> void:
	if value:
		push_error(message)
		failures += 1
