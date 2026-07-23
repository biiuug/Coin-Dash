extends Node

const MainGame = preload("res://Main.gd")
const IdleGameRules = preload("res://IdleGameRules.gd")
const SAVE_PATH := "user://idle_hero_camp_save.json"
const TEST_SAVE_PATH := "res://.test-output/idle_hero_camp_save.json"

var failures := 0


func _ready() -> void:
	OS.set_environment("IDLE_HERO_CAMP_SAVE_PATH", _save_file_path())
	_write_fixture()
	var game = MainGame.new()
	add_child(game)
	_test_automatic_load(game)
	game.materials["gold"] = 99999
	game.heroes[0]["level"] = 12
	game.current_wave = 5
	game.enemy_hp = 3.0
	game.queue_free()
	await get_tree().process_frame
	_test_exit_save()
	DirAccess.remove_absolute(_save_file_path())
	DirAccess.remove_absolute(_save_file_path() + ".bak")
	DirAccess.remove_absolute(_save_file_path() + ".tmp")
	if failures == 0:
		print("SAVE_LIFECYCLE_TEST_PASS")
	else:
		push_error("Save lifecycle tests failed: %d" % failures)
	OS.unset_environment("IDLE_HERO_CAMP_SAVE_PATH")
	get_tree().quit(0 if failures == 0 else 1)


func _write_fixture() -> void:
	var save_path := _save_file_path()
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	var rules := IdleGameRules.new()
	var hero: Dictionary = rules.create_hero(rules.HEROES[0])
	hero["level"] = 11
	hero["rank"] = 4
	hero["xp"] = 4321
	hero["hp"] = 1.0
	hero["attack_timer"] = 0.9
	var fixture := {
		"version": 2,
		"materials": {"gold": 54321, "wood": 20, "ore": 30, "herbs": 40, "ink": 50, "shards": 60, "dust": 70, "essence": 80},
		"heroes": [hero],
		"inventory": [rules.generate_equipment(7, 2)],
		"buildings": {"forge": 4, "academy": 3},
		"unlocked_talents": ["class_drill"],
		"unlocked_achievements": ["first_push"],
		"owned_relics": ["wayfarer_compass"],
		"selected_tab": "Heroes",
		"selected_hero": 0,
		"selected_item": 0,
		"equipment_filter": "all",
		"auto_salvage_junk": false,
		"selected_building": "forge",
		"selected_talent": "class_drill",
		"stage_index": 7,
		"best_stage": 8,
		"battle_paused": true,
		"speed_index": 2,
		"item_roll_counter": 19,
		"saved_at": Time.get_unix_time_from_system(),
	}
	var encoded := JSON.stringify(fixture)
	var backup_file := FileAccess.open(save_path + ".bak", FileAccess.WRITE)
	if backup_file == null:
		_assert_equal(FileAccess.get_open_error(), OK, "fixture save file opens")
		return
	backup_file.store_string(encoded)
	backup_file = null
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		_assert_equal(FileAccess.get_open_error(), OK, "corrupt primary fixture opens")
		return
	file.store_string("{damaged primary")


func _test_automatic_load(game) -> void:
	_assert_equal(game.materials["gold"], 54321, "resources auto-load")
	_assert_equal(game.heroes[0]["level"], 11, "hero level auto-loads")
	_assert_equal(game.heroes[0]["rank"], 4, "hero rank auto-loads")
	_assert_equal(game.heroes[0]["xp"], 4321, "hero XP auto-loads")
	_assert_equal(game.inventory.size(), 1, "complete inventory auto-loads")
	_assert_equal(game.buildings["forge"], 4, "building level auto-loads")
	_assert_equal(game.best_stage, 8, "stage progress auto-loads")
	_assert_equal(game.stage_index, 7, "selected stage auto-loads")
	_assert_equal(game.unlocked_achievements, ["first_push"], "claimed achievements auto-load")
	_assert_equal(game.owned_relics, ["wayfarer_compass"], "collected relics auto-load")
	_assert_equal(game.current_wave, 1, "wave progress resets on load")
	_assert_equal(game.heroes[0]["hp"], game.heroes[0]["max_hp"], "hero starts at full health")
	_assert_equal(game.battle_log.has("Recovered backup save."), true, "corrupt primary recovers from backup")


func _test_exit_save() -> void:
	var file := FileAccess.open(_save_file_path(), FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	_assert_equal(data["materials"]["gold"], 100499, "exit save includes newly earned achievement reward")
	_assert_equal(data["heroes"][0]["level"], 12, "exit saves changed hero level")
	_assert_false(data.has("current_wave"), "exit save omits current wave")
	_assert_false(data.has("enemy_hp"), "exit save omits enemy health")
	_assert_false(data["heroes"][0].has("hp"), "exit save omits hero health")
	_assert_equal(data["unlocked_achievements"].has("growing_camp"), true, "migration claims newly satisfied camp achievement")


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, expected, actual])
		failures += 1


func _assert_false(value: bool, message: String) -> void:
	if value:
		push_error(message)
		failures += 1


func _save_file_path() -> String:
	return ProjectSettings.globalize_path(TEST_SAVE_PATH)
