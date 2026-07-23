extends Node2D

const IdleRules := preload("res://IdleGameRules.gd")
const SaveRules := preload("res://SaveGameRules.gd")

const VIEW_SIZE := Vector2(1100, 620)
const CARD_BG := Color(0.12, 0.14, 0.17)
const CARD_BG_ALT := Color(0.16, 0.18, 0.21)
const PANEL_BORDER := Color(0.34, 0.38, 0.44)
const TEXT_MAIN := Color(0.90, 0.88, 0.80)
const TEXT_MUTED := Color(0.58, 0.63, 0.67)
const ACCENT := Color(0.78, 0.63, 0.32)
const GOOD := Color(0.32, 0.78, 0.42)
const BAD := Color(0.82, 0.24, 0.24)
const BLUE := Color(0.32, 0.55, 0.92)
const TAB_NAMES: Array[String] = ["Guide", "Battle", "Heroes", "Equipment", "Buildings", "Talents", "Stages"]
const CLASS_ATLAS_ORDER: Array[String] = ["warrior", "ranger", "cleric", "rogue", "mage", "paladin", "druid", "artificer", "necromancer", "monk"]
const EQUIPMENT_ATLAS_SLOTS: Array[String] = ["weapon", "armor", "trinket"]
const EQUIPMENT_ATLAS_RARITIES: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const TALENT_ATLAS_BRANCHES: Array[String] = ["Combat", "Economy", "Loot", "Automation", "Class"]
const STAGE_ATLAS_REGIONS: Array[String] = ["Meadow Road", "Iron Mine", "Grave Ruins", "Ember Hollow", "Fallen Keep"]
const SAVE_PATH := "user://idle_hero_camp_save.json"
const AUTOSAVE_INTERVAL := 8.0
const OFFLINE_REWARD_CAP_SECONDS := 7200

var rules = IdleRules.new()
var save_rules = SaveRules.new()
var materials: Dictionary = {}
var heroes: Array = []
var inventory: Array = []
var buildings: Dictionary = {}
var unlocked_talents: Array[String] = []
var battle_log: Array[String] = []

var selected_tab: String = "Battle"
var selected_hero: int = 0
var selected_item: int = -1
var equipment_filter: String = "all"
var auto_salvage_junk: bool = false
var selected_building: String = "forge"
var selected_talent: String = "battle_rhythm"
var stage_index: int = 1
var best_stage: int = 1
var current_wave: int = 1
var battle_paused: bool = false
var speed_index: int = 1
var enemy_name: String = ""
var enemy_hp: float = 1.0
var enemy_max_hp: float = 1.0
var item_roll_counter: int = 0
var autosave_timer: float = 0.0
var save_notice_timer: float = 0.0
var flash_timer: float = 0.0
var enemy_flash: float = 0.0
var hero_flash: float = 0.0
var combat_visual_clock: float = 0.0
var enemy_visual_state: int = 0
var exit_save_completed: bool = false

var root: Control
var content: Control
var resource_row: HBoxContainer
var floating_layer: Control
var enemy_bar: ProgressBar
var wave_label: Label
var power_label: Label
var save_status_label: Label
var new_game_dialog: ConfirmationDialog
var enemy_sprite_rect: TextureRect
var hero_sprite_rects: Array[TextureRect] = []
var floating_messages: Array = []
var resource_icon_cache: Dictionary = {}
var equipment_icon_cache: Dictionary = {}
var hero_icon_cache: Dictionary = {}
var talent_icon_cache: Dictionary = {}
var stage_icon_cache: Dictionary = {}

var hero_texture: Texture2D
var enemy_texture: Texture2D
var building_texture: Texture2D
var class_sheet_texture: Texture2D
var resource_texture: Texture2D
var equipment_texture: Texture2D
var talent_texture: Texture2D
var stage_texture: Texture2D


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(int(VIEW_SIZE.x), int(VIEW_SIZE.y)))
	_load_assets()
	_initialize_state()
	var loaded: bool = _load_game()
	_build_shell()
	if not loaded:
		_set_enemy_for_wave()
	_refresh_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_before_exit()
		get_tree().quit()


func _exit_tree() -> void:
	_save_before_exit()


func _process(delta: float) -> void:
	_tick_battle(delta)
	autosave_timer += delta
	if autosave_timer >= AUTOSAVE_INTERVAL:
		_save_game(true)
	if save_notice_timer > 0.0:
		save_notice_timer = max(0.0, save_notice_timer - delta)
		if save_status_label != null:
			save_status_label.text = "Saved" if save_notice_timer > 0.0 else "Auto"
	_update_floating_messages(delta)
	if flash_timer > 0.0:
		flash_timer = max(0.0, flash_timer - delta)
	if enemy_flash > 0.0:
		enemy_flash = max(0.0, enemy_flash - delta)
		if is_instance_valid(enemy_sprite_rect):
			enemy_sprite_rect.modulate = Color(1.0, 0.45, 0.45) if enemy_flash > 0.0 else Color.WHITE
	if hero_flash > 0.0:
		hero_flash = max(0.0, hero_flash - delta)
		for rect in hero_sprite_rects:
			if is_instance_valid(rect):
				rect.modulate = Color(0.55, 0.75, 1.0) if hero_flash > 0.0 else Color.WHITE


func _load_assets() -> void:
	hero_texture = _load_png_texture("res://assets/characters/warden-sprite-sheet.png")
	enemy_texture = _load_png_texture("res://assets/enemies/enemy-sprites.png")
	building_texture = _load_png_texture("res://assets/buildings/camp-buildings-v4.png")
	class_sheet_texture = _load_png_texture("res://assets/characters/class-sheets-v1.png")
	resource_texture = _load_png_texture("res://assets/resources/resource-icons-v2.png")
	equipment_texture = _load_png_texture("res://assets/equipment/equipment-icons-v1.png")
	talent_texture = _load_png_texture("res://assets/ui/talent-icons-v1.png")
	stage_texture = _load_png_texture("res://assets/ui/stage-icons-v1.png")


func _load_png_texture(path: String) -> Texture2D:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _initialize_state() -> void:
	materials = rules.starting_materials()
	for hero_def in rules.HEROES:
		heroes.append(rules.create_hero(hero_def))
	var order: Array[String] = rules.get_building_order()
	for building_id in order:
		buildings[building_id] = 1
	for index in range(7):
		inventory.append(rules.generate_equipment(1 + int(index / 2), index))
	_refresh_hero_health(true)
	battle_log = ["Camp founded.", "Auto battle started at stage 1."]


func _build_shell() -> void:
	root = Control.new()
	root.name = "IdleAutoFighterUI"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var background := ColorRect.new()
	background.color = Color(0.075, 0.085, 0.10)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var header := HBoxContainer.new()
	header.position = Vector2(14, 10)
	header.size = Vector2(1072, 44)
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)

	var title := _make_label("Idle Hero Camp", 23, ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	title.custom_minimum_size = Vector2(178, 38)
	header.add_child(title)

	resource_row = HBoxContainer.new()
	resource_row.custom_minimum_size = Vector2(726, 38)
	resource_row.add_theme_constant_override("separation", 8)
	header.add_child(resource_row)

	var menu := HBoxContainer.new()
	menu.custom_minimum_size = Vector2(148, 38)
	menu.add_theme_constant_override("separation", 6)
	header.add_child(menu)
	var reset_button := _make_button("New", Vector2(48, 30), false, BAD)
	reset_button.tooltip_text = "Start a fresh save file."
	reset_button.pressed.connect(_on_new_game_requested)
	menu.add_child(reset_button)
	save_status_label = _make_label("Auto", 12, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	save_status_label.custom_minimum_size = Vector2(64, 30)
	save_status_label.tooltip_text = "Progress autosaves every 8 seconds, after major actions, and when exiting."
	menu.add_child(save_status_label)

	content = Control.new()
	content.position = Vector2(14, 62)
	content.size = Vector2(1072, 500)
	root.add_child(content)

	var tab_bar := HBoxContainer.new()
	tab_bar.position = Vector2(14, 570)
	tab_bar.size = Vector2(820, 40)
	tab_bar.add_theme_constant_override("separation", 8)
	root.add_child(tab_bar)
	for tab_name in TAB_NAMES:
		var button := _make_button(tab_name, Vector2(114, 34), selected_tab == tab_name)
		button.pressed.connect(_on_tab_pressed.bind(tab_name))
		tab_bar.add_child(button)

	floating_layer = Control.new()
	floating_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(floating_layer)

	new_game_dialog = ConfirmationDialog.new()
	new_game_dialog.title = "Start a new game?"
	new_game_dialog.dialog_text = "This replaces the current autosave and resets all progress."
	new_game_dialog.ok_button_text = "Start New Game"
	new_game_dialog.confirmed.connect(_on_new_game)
	root.add_child(new_game_dialog)


func _refresh_ui() -> void:
	_refresh_resources()
	_clear(content)
	hero_sprite_rects.clear()
	if selected_tab == "Guide":
		_build_guide_tab()
	elif selected_tab == "Battle":
		_build_battle_tab()
	elif selected_tab == "Heroes":
		_build_heroes_tab()
	elif selected_tab == "Equipment":
		_build_equipment_tab()
	elif selected_tab == "Buildings":
		_build_buildings_tab()
	elif selected_tab == "Talents":
		_build_talents_tab()
	else:
		_build_stages_tab()


func _refresh_resources() -> void:
	if resource_row == null:
		return
	_clear(resource_row)
	for resource_name in rules.RESOURCE_ORDER:
		var chip := HBoxContainer.new()
		chip.custom_minimum_size = Vector2(60, 30)
		chip.add_theme_constant_override("separation", 4)
		chip.tooltip_text = "%s: %d" % [String(resource_name).capitalize(), int(materials.get(resource_name, 0))]
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _resource_atlas(resource_name)
		chip.add_child(icon)
		chip.add_child(_make_label(_compact_number(int(materials.get(resource_name, 0))), 14, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT))
		resource_row.add_child(chip)


func _build_guide_tab() -> void:
	var overview := _panel(Vector2(0, 0), Vector2(1072, 108))
	content.add_child(overview)
	var title := _make_label("Idle Hero Camp", 26, ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(18, 14)
	title.size = Vector2(330, 34)
	overview.add_child(title)
	var subtitle := _make_label("Auto battle for loot, then invest in heroes, gear, buildings, talents, and harder stages.", 15, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	subtitle.position = Vector2(20, 52)
	subtitle.size = Vector2(760, 26)
	overview.add_child(subtitle)
	var save_line := _make_label("Autosave every %d seconds. Offline rewards are capped at %d hours." % [int(AUTOSAVE_INTERVAL), int(OFFLINE_REWARD_CAP_SECONDS / 3600)], 13, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	save_line.position = Vector2(20, 78)
	save_line.size = Vector2(760, 22)
	overview.add_child(save_line)
	var start_btn := _make_button("Go Battle", Vector2(130, 36), false, GOOD)
	start_btn.position = Vector2(895, 28)
	start_btn.tooltip_text = "Open the idle battle dashboard."
	start_btn.pressed.connect(_on_guide_open_tab.bind("Battle"))
	overview.add_child(start_btn)

	var guide_entries := [
		{"title": "Battle", "body": "Farm or push stages. Pause, change speed, and watch team HP on the dashboard.", "tab": "Battle", "kind": "stage"},
		{"title": "Heroes", "body": "Level heroes, train skills, rank classes, and auto-equip best gear.", "tab": "Heroes", "kind": "hero"},
		{"title": "Equipment", "body": "Filter gear, auto-equip upgrades, bulk salvage junk, or enable automatic junk conversion.", "tab": "Equipment", "kind": "item"},
		{"title": "Buildings", "body": "Use each facility service, then upgrade the camp for stronger crafting, training, recovery, trade, and research.", "tab": "Buildings", "kind": "building"},
		{"title": "Talents", "body": "Spend essence and materials on combat, loot, economy, automation, and class branches.", "tab": "Talents", "kind": "talent"},
		{"title": "Stages", "body": "Choose farm targets and inspect item-level ranges and material sources.", "tab": "Stages", "kind": "stage"},
	]
	for index in range(guide_entries.size()):
		var info: Dictionary = guide_entries[index]
		var col := index % 3
		var row := int(index / 3)
		_draw_guide_block(info, Vector2(col * 356, 130 + row * 152))


func _draw_guide_block(info: Dictionary, pos: Vector2) -> void:
	var guide_panel := _panel(pos, Vector2(340, 132))
	content.add_child(guide_panel)
	var icon := TextureRect.new()
	icon.position = Vector2(16, 18)
	icon.size = Vector2(52, 52)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _guide_icon_texture(String(info["kind"]))
	guide_panel.add_child(icon)
	var title := _make_label(String(info["title"]), 20, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(82, 14)
	title.size = Vector2(230, 26)
	guide_panel.add_child(title)
	var body := _make_label(String(info["body"]), 13, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.position = Vector2(82, 42)
	body.size = Vector2(240, 52)
	guide_panel.add_child(body)
	var button := _make_button("Open", Vector2(92, 28), false, BLUE)
	button.position = Vector2(222, 96)
	button.pressed.connect(_on_guide_open_tab.bind(String(info["tab"])))
	guide_panel.add_child(button)


func _build_battle_tab() -> void:
	var left := _panel(Vector2(0, 0), Vector2(710, 500))
	content.add_child(left)
	var right := _panel(Vector2(724, 0), Vector2(348, 500))
	content.add_child(right)

	var stage: Dictionary = rules.get_stage(stage_index)
	var stage_title := _make_label("%s  |  Wave %d/%d" % [String(stage["name"]), current_wave, int(stage["wave_count"])], 20, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	stage_title.position = Vector2(18, 14)
	stage_title.size = Vector2(500, 28)
	left.add_child(stage_title)
	wave_label = stage_title

	power_label = _make_label("Team Power %d / Stage %d" % [_team_power(), int(stage["power"])], 15, TEXT_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	power_label.position = Vector2(455, 17)
	power_label.size = Vector2(230, 24)
	left.add_child(power_label)

	var ground := ColorRect.new()
	ground.color = Color(0.40, 0.34, 0.23)
	ground.position = Vector2(44, 280)
	ground.size = Vector2(620, 4)
	left.add_child(ground)

	_draw_team_on_battlefield(left)
	_draw_enemy_on_battlefield(left)

	var controls := HBoxContainer.new()
	controls.position = Vector2(18, 430)
	controls.size = Vector2(676, 48)
	controls.add_theme_constant_override("separation", 10)
	left.add_child(controls)
	var farm_btn := _make_button("Farm Best", Vector2(132, 36), false, BLUE)
	farm_btn.tooltip_text = "Farm your highest cleared stage."
	farm_btn.pressed.connect(_on_farm_best)
	controls.add_child(farm_btn)
	var push_btn := _make_button("Push Stage", Vector2(132, 36), true, GOOD)
	push_btn.tooltip_text = "Fight the highest available stage."
	push_btn.pressed.connect(_on_push_stage)
	controls.add_child(push_btn)
	var heal_btn := _make_button("Camp Heal", Vector2(132, 36), false, ACCENT)
	heal_btn.tooltip_text = "Spend herbs to refill the active team."
	heal_btn.pressed.connect(_on_camp_heal)
	controls.add_child(heal_btn)
	var pause_btn := _make_button("Pause" if not battle_paused else "Resume", Vector2(104, 36), battle_paused, BAD if battle_paused else ACCENT)
	pause_btn.tooltip_text = "Pause or resume idle combat."
	pause_btn.pressed.connect(_on_toggle_pause)
	controls.add_child(pause_btn)
	var speed_btn := _make_button("Speed x%d" % [_battle_speed()], Vector2(104, 36), false, BLUE)
	speed_btn.tooltip_text = "Cycle battle speed between x1, x2, and x3."
	speed_btn.pressed.connect(_on_cycle_speed)
	controls.add_child(speed_btn)

	var summary := _make_label("Drops improve by stage. Boss waves add essence, shards, and better item levels.", 14, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	summary.position = Vector2(18, 390)
	summary.size = Vector2(670, 26)
	left.add_child(summary)

	var log_title := _make_label("Run Drops", 20, ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	log_title.position = Vector2(16, 12)
	log_title.size = Vector2(250, 26)
	right.add_child(log_title)
	var stage_summary := _make_label("Stage %d  Item Lv.%d-%d  %s" % [
		stage_index,
		int(stage["item_min"]),
		int(stage["item_max"]),
		", ".join(PackedStringArray(stage["materials"]))
	], 13, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	stage_summary.position = Vector2(16, 40)
	stage_summary.size = Vector2(314, 24)
	right.add_child(stage_summary)
	_draw_team_status_panel(right, Vector2(16, 74))
	var log_y := 250
	for entry in battle_log:
		var label := _make_label(entry, 14, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.position = Vector2(16, log_y)
		label.size = Vector2(314, 30)
		right.add_child(label)
		log_y += 32
		if log_y > 470:
			break


func _draw_team_on_battlefield(parent: Control) -> void:
	var slots: int = rules.team_slots(buildings)
	for index in range(slots):
		if index >= heroes.size():
			continue
		var hero: Dictionary = heroes[index]
		var x_pos := 78 + index * 86
		var stats: Dictionary = rules.hero_stats(hero, inventory, buildings, unlocked_talents)
		var max_hp := float(hero.get("max_hp", stats["hp"]))
		var hp := float(hero.get("hp", max_hp))
		var name_label := _make_label(String(hero["name"]), 13, TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
		name_label.position = Vector2(x_pos - 20, 142)
		name_label.size = Vector2(72, 20)
		name_label.tooltip_text = _hero_tooltip(hero, stats)
		parent.add_child(name_label)
		var bar := _make_bar(Vector2(x_pos - 20, 166), Vector2(72, 10), hp, max_hp, GOOD)
		parent.add_child(bar)
		var sprite := TextureRect.new()
		sprite.position = Vector2(x_pos - 18, 190)
		sprite.size = Vector2(68, 84)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.texture = _hero_portrait_texture(hero)
		sprite.tooltip_text = _hero_tooltip(hero, stats)
		parent.add_child(sprite)
		hero_sprite_rects.append(sprite)


func _draw_enemy_on_battlefield(parent: Control) -> void:
	var stage: Dictionary = rules.get_stage(stage_index)
	var visual_index: int = rules.enemy_visual_index(enemy_name, String(stage["region"]))
	var label := _make_label(enemy_name, 17, TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(480, 124)
	label.size = Vector2(170, 26)
	parent.add_child(label)
	enemy_bar = _make_bar(Vector2(502, 154), Vector2(126, 12), enemy_hp, enemy_max_hp, BAD)
	parent.add_child(enemy_bar)
	enemy_sprite_rect = TextureRect.new()
	enemy_sprite_rect.position = Vector2(500, 182)
	enemy_sprite_rect.size = Vector2(132, 96)
	enemy_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_sprite_rect.texture = _enemy_atlas(visual_index)
	parent.add_child(enemy_sprite_rect)


func _draw_team_status_panel(parent: Control, origin: Vector2) -> void:
	var title := _make_label("Team Status", 16, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	title.position = origin
	title.size = Vector2(180, 22)
	parent.add_child(title)
	var slots: int = rules.team_slots(buildings)
	var y := origin.y + 28
	for index in range(min(slots, heroes.size())):
		var hero: Dictionary = heroes[index]
		var stats: Dictionary = rules.hero_stats(hero, inventory, buildings, unlocked_talents)
		var max_hp := float(hero.get("max_hp", stats["hp"]))
		var hp := float(hero.get("hp", max_hp))
		var portrait := TextureRect.new()
		portrait.position = Vector2(origin.x, y)
		portrait.size = Vector2(28, 32)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = _hero_portrait_texture(hero)
		portrait.tooltip_text = _hero_tooltip(hero, stats)
		parent.add_child(portrait)
		var label := _make_label("%s  Lv.%d  Gear %d/3" % [String(hero["name"]), int(hero["level"]), _equipped_count(hero)], 13, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
		label.position = Vector2(origin.x + 36, y)
		label.size = Vector2(230, 18)
		label.tooltip_text = _hero_tooltip(hero, stats)
		parent.add_child(label)
		var bar := _make_bar(Vector2(origin.x + 36, y + 22), Vector2(230, 8), hp, max_hp, GOOD)
		parent.add_child(bar)
		y += 42


func _build_heroes_tab() -> void:
	var list := _panel(Vector2(0, 0), Vector2(260, 500))
	content.add_child(list)
	var details := _panel(Vector2(274, 0), Vector2(798, 500))
	content.add_child(details)

	var y := 16
	for index in range(heroes.size()):
		var hero: Dictionary = heroes[index]
		var portrait := TextureRect.new()
		portrait.position = Vector2(16, y + 2)
		portrait.size = Vector2(34, 34)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = _hero_portrait_texture(hero)
		portrait.tooltip_text = _hero_tooltip(hero, rules.hero_stats(hero, inventory, buildings, unlocked_talents))
		list.add_child(portrait)
		var button := _make_button("%s  Lv.%d" % [String(hero["name"]), int(hero["level"])], Vector2(188, 36), selected_hero == index)
		button.position = Vector2(56, y)
		button.pressed.connect(_on_hero_selected.bind(index))
		list.add_child(button)
		y += 44

	var selected: Dictionary = heroes[selected_hero]
	var class_data: Dictionary = rules.get_class_data(String(selected["class_id"]))
	var stats: Dictionary = rules.hero_stats(selected, inventory, buildings, unlocked_talents)
	var title := _make_label("%s  |  %s Rank %d" % [String(selected["name"]), String(class_data["name"]), int(selected["rank"])], 24, ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(104, 18)
	title.size = Vector2(500, 34)
	details.add_child(title)
	var selected_portrait := TextureRect.new()
	selected_portrait.position = Vector2(22, 18)
	selected_portrait.size = Vector2(66, 76)
	selected_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selected_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	selected_portrait.texture = _hero_portrait_texture(selected)
	selected_portrait.tooltip_text = _hero_tooltip(selected, stats)
	details.add_child(selected_portrait)
	var subtitle := _make_label("Advanced path: %s" % [String(class_data["advanced"][min(max(int(selected["rank"]) - 4, 0), 1)]) if int(selected["rank"]) >= 5 else "Not advanced"], 14, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	subtitle.position = Vector2(104, 54)
	subtitle.size = Vector2(500, 24)
	details.add_child(subtitle)

	var stat_text := "HP %d   ATK %d   DEF %d   SPD %.2f   CRIT %.1f%%   Skill x%.2f" % [
		int(stats["hp"]), int(stats["atk"]), int(stats["def"]), float(stats["speed"]), float(stats["crit"]) * 100.0, float(stats["skill_power"])
	]
	var stat_label := _make_label(stat_text, 16, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	stat_label.position = Vector2(22, 92)
	stat_label.size = Vector2(720, 26)
	details.add_child(stat_label)

	_add_cost_button(details, "Level Up", Vector2(22, 142), rules.hero_level_cost(selected), _on_level_hero)
	_add_cost_button(details, "Skill +", Vector2(174, 142), rules.skill_cost(selected), _on_skill_hero)
	_add_cost_button(details, "Rank Up", Vector2(326, 142), rules.class_rank_cost(selected, unlocked_talents.has("class_drill")), _on_rank_hero)
	var auto_equip := _make_button("Auto Equip", Vector2(140, 36), false, BLUE)
	auto_equip.position = Vector2(478, 142)
	auto_equip.tooltip_text = "Equip the best available valid gear for this hero."
	auto_equip.pressed.connect(_on_auto_equip_selected_hero)
	details.add_child(auto_equip)

	var unlocks: Array = class_data["rank_unlocks"]
	var unlock_title := _make_label("Rank unlocks", 18, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	unlock_title.position = Vector2(22, 202)
	unlock_title.size = Vector2(240, 26)
	details.add_child(unlock_title)
	for index in range(unlocks.size()):
		var color := GOOD if index < int(selected["rank"]) else TEXT_MUTED
		var label := _make_label("R%d  %s" % [index + 1, String(unlocks[index])], 14, color, HORIZONTAL_ALIGNMENT_LEFT)
		label.position = Vector2(22, 236 + index * 28)
		label.size = Vector2(360, 24)
		details.add_child(label)

	var eq_title := _make_label("Equipment", 18, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	eq_title.position = Vector2(430, 202)
	eq_title.size = Vector2(230, 26)
	details.add_child(eq_title)
	var eq_y := 236
	for slot in rules.SLOTS:
		var item_index := int(selected["equipment"].get(slot, -1))
		var text := "%s: Empty" % [String(slot).capitalize()]
		if item_index >= 0 and item_index < inventory.size():
			var item: Dictionary = inventory[item_index]
			text = "%s: %s Lv.%d" % [String(slot).capitalize(), String(item["name"]), int(item["level"])]
			var eq_icon := TextureRect.new()
			eq_icon.position = Vector2(430, eq_y + 2)
			eq_icon.size = Vector2(24, 24)
			eq_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			eq_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			eq_icon.texture = _item_icon_texture(item)
			eq_icon.tooltip_text = _item_tooltip(item)
			details.add_child(eq_icon)
		var label := _make_label(text, 14, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
		label.position = Vector2(462, eq_y)
		label.size = Vector2(298, 24)
		details.add_child(label)
		eq_y += 32


func _build_equipment_tab() -> void:
	var list := _panel(Vector2(0, 0), Vector2(610, 500))
	content.add_child(list)
	var details := _panel(Vector2(624, 0), Vector2(448, 500))
	content.add_child(details)

	var title := _make_label("Inventory", 22, ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(16, 12)
	title.size = Vector2(220, 30)
	list.add_child(title)
	var auto_junk := _make_button("Auto Junk: %s" % ["On" if auto_salvage_junk else "Off"], Vector2(148, 30), auto_salvage_junk, GOOD if auto_salvage_junk else BAD)
	auto_junk.position = Vector2(442, 10)
	auto_junk.tooltip_text = "Automatically salvage new Common and Uncommon gear drops."
	auto_junk.pressed.connect(_on_toggle_auto_salvage)
	list.add_child(auto_junk)
	var filters := HBoxContainer.new()
	filters.position = Vector2(18, 48)
	filters.size = Vector2(570, 32)
	filters.add_theme_constant_override("separation", 6)
	list.add_child(filters)
	for filter_name in ["all", "weapon", "armor", "trinket"]:
		var filter_button := _make_button(filter_name.capitalize(), Vector2(92, 28), equipment_filter == filter_name, BLUE)
		filter_button.tooltip_text = "Show %s equipment." % [filter_name]
		filter_button.pressed.connect(_on_equipment_filter_pressed.bind(filter_name))
		filters.add_child(filter_button)
	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.position = Vector2(12, 84)
	inventory_scroll.size = Vector2(586, 404)
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list.add_child(inventory_scroll)
	var inventory_content := Control.new()
	inventory_content.custom_minimum_size = Vector2(568, 404)
	inventory_scroll.add_child(inventory_content)
	var y := 0
	for index in range(inventory.size()):
		var item: Dictionary = inventory[index]
		if not _item_matches_filter(item):
			continue
		var icon := TextureRect.new()
		icon.position = Vector2(6, y + 1)
		icon.size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _item_icon_texture(item)
		icon.tooltip_text = _item_tooltip(item)
		inventory_content.add_child(icon)
		var lock_mark := "[L] " if bool(item.get("locked", false)) else ""
		var button_text := "%s%s  Lv.%d  Req.%d  %s" % [lock_mark, String(item["name"]), int(item["level"]), int(item["required_level"]), String(item["slot"]).capitalize()]
		var button := _make_button(button_text, Vector2(512, 32), selected_item == index, _rarity_color(String(item["rarity"])))
		button.position = Vector2(44, y)
		button.tooltip_text = _item_tooltip(item)
		button.pressed.connect(_on_item_selected.bind(index))
		inventory_content.add_child(button)
		y += 38
	inventory_content.custom_minimum_size.y = max(404.0, float(y))

	var selected: Dictionary = _selected_item_dict()
	if selected.is_empty():
		var empty := _make_label("Select equipment to inspect, equip, upgrade, or salvage.", 16, TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty.position = Vector2(24, 200)
		empty.size = Vector2(400, 60)
		details.add_child(empty)
		return

	var name_label := _make_label(String(selected["name"]), 24, _rarity_color(String(selected["rarity"])), HORIZONTAL_ALIGNMENT_LEFT)
	name_label.position = Vector2(92, 16)
	name_label.size = Vector2(316, 32)
	details.add_child(name_label)
	var big_icon := TextureRect.new()
	big_icon.position = Vector2(20, 18)
	big_icon.size = Vector2(54, 54)
	big_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	big_icon.texture = _item_icon_texture(selected)
	big_icon.tooltip_text = _item_tooltip(selected)
	details.add_child(big_icon)
	var desc := _make_label(_item_tooltip(selected), 15, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(92, 56)
	desc.size = Vector2(326, 140)
	details.add_child(desc)
	var hero: Dictionary = heroes[selected_hero]
	var level_ok := int(hero["level"]) >= int(selected["required_level"])
	var equip := _make_button("Equip to %s" % [String(hero["name"])], Vector2(180, 36), false, GOOD if level_ok else BAD)
	equip.position = Vector2(20, 220)
	equip.disabled = not level_ok
	equip.tooltip_text = "Requires hero level %d. Selected hero is level %d." % [int(selected["required_level"]), int(hero["level"])]
	equip.pressed.connect(_on_equip_selected_item)
	details.add_child(equip)
	_add_cost_button(details, "Upgrade", Vector2(210, 220), rules.equipment_upgrade_cost(selected), _on_upgrade_item)
	var can_salvage: bool = rules.can_salvage_item(selected, _is_item_equipped(selected_item))
	var salvage := _make_button("Salvage", Vector2(180, 36), false, BAD)
	salvage.position = Vector2(20, 270)
	salvage.disabled = not can_salvage
	salvage.tooltip_text = _format_cost(rules.salvage_value(selected, unlocked_talents), true) if can_salvage else "Unlock and unequip this item before salvaging it."
	salvage.pressed.connect(_on_salvage_item)
	details.add_child(salvage)
	var bulk_salvage := _make_button("Salvage Junk", Vector2(180, 36), false, BAD)
	bulk_salvage.position = Vector2(210, 270)
	bulk_salvage.tooltip_text = "Salvage all unequipped Common and Uncommon equipment."
	bulk_salvage.pressed.connect(_on_salvage_junk)
	details.add_child(bulk_salvage)
	var lock_button := _make_button("Unlock Item" if bool(selected.get("locked", false)) else "Lock Item", Vector2(180, 36), bool(selected.get("locked", false)), BLUE)
	lock_button.position = Vector2(20, 320)
	lock_button.tooltip_text = "Locked equipment is protected from manual and bulk salvage."
	lock_button.pressed.connect(_on_toggle_item_lock)
	details.add_child(lock_button)


func _build_buildings_tab() -> void:
	var order: Array[String] = rules.get_building_order()
	var header := _make_label("Camp Facilities", 24, ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	header.position = Vector2(6, 0)
	header.size = Vector2(260, 32)
	content.add_child(header)
	var upgrade_all := _make_button("Upgrade All Affordable", Vector2(190, 32), false, GOOD)
	upgrade_all.position = Vector2(872, 0)
	upgrade_all.tooltip_text = "Upgrade every facility that currently has enough resources."
	upgrade_all.pressed.connect(_on_upgrade_all_buildings)
	content.add_child(upgrade_all)
	for index in range(order.size()):
		var building_id := order[index]
		var col := index % 3
		var row := int(index / 3)
		var building_panel := _panel(Vector2(col * 356, 42 + row * 228), Vector2(340, 220))
		content.add_child(building_panel)
		var building: Dictionary = rules.get_building(building_id)
		var level: int = int(buildings.get(building_id, 1))
		var title := _make_label("%s  Lv.%d" % [String(building["name"]), level], 18, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
		title.position = Vector2(14, 8)
		title.size = Vector2(220, 26)
		title.tooltip_text = _building_tooltip(building_id)
		building_panel.add_child(title)
		var cost: Dictionary = rules.get_building_cost(building_id, level)
		var button := _make_button("^", Vector2(42, 30), false, GOOD if rules.can_afford(cost, materials) else BAD)
		button.position = Vector2(280, 6)
		button.disabled = cost.is_empty()
		button.tooltip_text = _upgrade_tooltip(building_id)
		button.pressed.connect(_on_upgrade_building.bind(building_id))
		building_panel.add_child(button)
		if not cost.is_empty():
			_add_resource_cost_row(building_panel, cost, Vector2(14, 36), 4)
		var art := TextureRect.new()
		art.position = Vector2(54, 60)
		art.size = Vector2(232, 90)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture = _building_atlas(rules.building_visual_column(building_id), level)
		art.tooltip_text = _building_tooltip(building_id)
		building_panel.add_child(art)
		var service: Dictionary = rules.facility_service(building_id, level)
		var service_cost: Dictionary = service["cost"]
		var service_reward: Dictionary = service["reward"]
		var service_tooltip := "%s\nCost: %s" % [String(service["description"]), _format_cost(service_cost, false)]
		if not service_reward.is_empty():
			service_tooltip += "\nReward: %s" % [_format_cost(service_reward, true)]
		var service_button := _make_button(String(service["name"]), Vector2(136, 30), false, GOOD if rules.can_afford(service_cost, materials) else BAD)
		service_button.position = Vector2(14, 158)
		service_button.tooltip_text = service_tooltip
		service_button.pressed.connect(_on_facility_service.bind(building_id))
		building_panel.add_child(service_button)
		var info := _make_label(String(service["description"]), 12, TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.position = Vector2(158, 154)
		info.size = Vector2(166, 38)
		info.tooltip_text = service_tooltip
		building_panel.add_child(info)
		if service_cost.is_empty():
			var free_label := _make_label("No cost", 12, GOOD, HORIZONTAL_ALIGNMENT_LEFT)
			free_label.position = Vector2(16, 194)
			free_label.size = Vector2(100, 20)
			building_panel.add_child(free_label)
		else:
			_add_resource_cost_row(building_panel, service_cost, Vector2(14, 194), 4)


func _build_talents_tab() -> void:
	var details := _panel(Vector2(682, 0), Vector2(390, 500))
	content.add_child(details)
	var branch_x: Dictionary = {"Combat": 0, "Economy": 170, "Loot": 340, "Automation": 0, "Class": 170}
	var branch_y: Dictionary = {"Combat": 0, "Economy": 0, "Loot": 0, "Automation": 220, "Class": 220}
	var counts: Dictionary = {}
	for talent in rules.TALENTS:
		var branch := String(talent["branch"])
		var local_index := int(counts.get(branch, 0))
		counts[branch] = local_index + 1
		var position := Vector2(int(branch_x[branch]) + local_index * 18, int(branch_y[branch]) + local_index * 52)
		var unlocked := unlocked_talents.has(String(talent["id"]))
		var icon := TextureRect.new()
		icon.position = position + Vector2(4, 5)
		icon.size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _talent_icon_texture(talent)
		icon.tooltip_text = String(talent["text"])
		content.add_child(icon)
		var node := _make_button(String(talent["name"]), Vector2(112, 40), selected_talent == String(talent["id"]), GOOD if unlocked else BLUE)
		node.position = position + Vector2(38, 0)
		node.tooltip_text = String(talent["text"])
		node.pressed.connect(_on_talent_selected.bind(String(talent["id"])))
		content.add_child(node)

	var talent: Dictionary = rules.get_talent(selected_talent)
	if talent.is_empty():
		return
	var title := _make_label(String(talent["name"]), 22, ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(72, 18)
	title.size = Vector2(286, 30)
	details.add_child(title)
	var detail_icon := TextureRect.new()
	detail_icon.position = Vector2(18, 16)
	detail_icon.size = Vector2(42, 42)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_icon.texture = _talent_icon_texture(talent)
	details.add_child(detail_icon)
	var body := _make_label("%s\n\nBranch: %s\nCost: %s" % [String(talent["text"]), String(talent["branch"]), _format_cost(talent["cost"], false)], 15, TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.position = Vector2(18, 64)
	body.size = Vector2(350, 150)
	details.add_child(body)
	var button := _make_button("Unlock", Vector2(150, 36), false, GOOD if rules.can_afford(talent["cost"], materials) else BAD)
	button.position = Vector2(18, 236)
	button.disabled = unlocked_talents.has(selected_talent)
	button.tooltip_text = _format_cost(talent["cost"], false)
	button.pressed.connect(_on_unlock_talent)
	details.add_child(button)


func _build_stages_tab() -> void:
	var title := _make_label("Stage Select", 24, ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(6, 0)
	title.size = Vector2(320, 32)
	content.add_child(title)
	var hint := _make_label("Higher stages drop higher-level equipment and region materials.", 14, TEXT_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	hint.position = Vector2(420, 2)
	hint.size = Vector2(640, 28)
	content.add_child(hint)
	var stage_scroll := ScrollContainer.new()
	stage_scroll.position = Vector2(0, 42)
	stage_scroll.size = Vector2(1072, 458)
	stage_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(stage_scroll)
	var stage_list := Control.new()
	stage_list.custom_minimum_size = Vector2(1054, 15 * 42)
	stage_scroll.add_child(stage_list)
	var y := 0
	for index in range(1, 16):
		var stage: Dictionary = rules.get_stage(index)
		var stage_panel := _panel(Vector2(0, y), Vector2(1054, 36))
		stage_list.add_child(stage_panel)
		var stage_icon := ColorRect.new()
		stage_icon.position = Vector2(12, 7)
		stage_icon.size = Vector2(22, 22)
		stage_icon.color = _region_color(String(stage["region"]))
		stage_icon.tooltip_text = String(stage["region"])
		stage_panel.add_child(stage_icon)
		var label := _make_label("%02d  %s  | Item Lv.%d-%d | %s" % [
			index,
			String(stage["name"]),
			int(stage["item_min"]),
			int(stage["item_max"]),
			", ".join(PackedStringArray(stage["materials"]))
		], 14, TEXT_MAIN if index <= best_stage + 1 else TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		label.position = Vector2(48, 6)
		label.size = Vector2(724, 24)
		stage_panel.add_child(label)
		var button := _make_button("Farm", Vector2(84, 26), stage_index == index, GOOD)
		button.position = Vector2(950, 5)
		button.disabled = index > best_stage + 1
		button.pressed.connect(_on_stage_selected.bind(index))
		stage_panel.add_child(button)
		y += 42


func _tick_battle(delta: float) -> void:
	if battle_paused:
		return
	if heroes.is_empty():
		return
	var living: Array = _living_active_heroes()
	if living.is_empty():
		return
	var stage: Dictionary = rules.get_stage(stage_index)
	combat_visual_clock = fmod(combat_visual_clock + delta * float(_battle_speed()), 1.0)
	var is_boss: bool = current_wave >= int(stage["wave_count"])
	var next_visual_state: int = rules.enemy_animation_state(combat_visual_clock, is_boss)
	if next_visual_state != enemy_visual_state:
		enemy_visual_state = next_visual_state
		if is_instance_valid(enemy_sprite_rect):
			var visual_index: int = rules.enemy_visual_index(enemy_name, String(stage["region"]))
			enemy_sprite_rect.texture = _enemy_atlas(visual_index, enemy_visual_state)
	var workshop_level: int = int(buildings.get("workshop", 1))
	var speed_bonus: float = float(_battle_speed()) * (1.0 + workshop_level * 0.06 + (0.08 if unlocked_talents.has("battle_rhythm") else 0.0))
	var damage: float = 0.0
	for hero in living:
		var stats: Dictionary = rules.hero_stats(hero, inventory, buildings, unlocked_talents)
		damage += max(1.0, float(stats["atk"]) * float(stats["speed"]) * float(stats["skill_power"])) * delta * speed_bonus
	if is_boss and unlocked_talents.has("boss_breaker"):
		damage *= 1.15
	enemy_hp -= damage
	if damage > 0.1:
		enemy_flash = 0.08
	if enemy_hp <= 0.0:
		_complete_wave()
		return
	var enemy_damage: float = max(1.0, float(stage["enemy_atk"]) * delta * 0.36)
	for hero in living:
		var stats: Dictionary = rules.hero_stats(hero, inventory, buildings, unlocked_talents)
		hero["hp"] = max(0.0, float(hero["hp"]) - max(0.2, enemy_damage - float(stats["def"]) * 0.012))
	hero_flash = 0.05
	_update_battle_widgets()
	if _living_active_heroes().is_empty():
		_on_team_defeated()


func _complete_wave() -> void:
	var rewards: Dictionary = rules.wave_rewards(stage_index, current_wave, buildings, unlocked_talents)
	_add_materials(rewards)
	_add_log("Wave %d: %s" % [current_wave, _format_cost(rewards, true)])
	for hero in _active_heroes():
		var xp_gain := 8 + stage_index
		if unlocked_talents.has("veteran_trainers"):
			xp_gain = int(float(xp_gain) * 1.15)
		hero["xp"] = int(hero.get("xp", 0)) + xp_gain
	var stage: Dictionary = rules.get_stage(stage_index)
	var boss_wave: bool = current_wave >= int(stage["wave_count"])
	if boss_wave or ((current_wave + stage_index) % 4 == 0):
		item_roll_counter += 1
		var rarity_bonus: int = 12 if unlocked_talents.has("rare_find") else 0
		var item: Dictionary = rules.generate_equipment(stage_index, item_roll_counter, rarity_bonus)
		if auto_salvage_junk and _is_low_rarity_item(item):
			var salvage: Dictionary = rules.salvage_value(item, unlocked_talents)
			_add_materials(salvage)
			_add_log("Auto junk: %s" % [_format_cost(salvage, true)])
		else:
			inventory.append(item)
			_add_log("Gear: %s Lv.%d" % [String(item["name"]), int(item["level"])])
	if boss_wave:
		best_stage = max(best_stage, stage_index)
		stage_index = min(stage_index + 1, best_stage + 1)
		current_wave = 1
		_add_log("Boss cleared. Stage %d opened." % [stage_index])
	else:
		current_wave += 1
	_set_enemy_for_wave()
	_refresh_hero_health(false)
	_save_game(false)
	_refresh_runtime_widgets()


func _on_team_defeated() -> void:
	_add_log("Team retreated. Farming stage %d." % [max(1, best_stage)])
	stage_index = max(1, best_stage)
	current_wave = 1
	_refresh_hero_health(true)
	_set_enemy_for_wave()
	_save_game(false)
	_refresh_runtime_widgets()


func _set_enemy_for_wave() -> void:
	var stage: Dictionary = rules.get_stage(stage_index)
	var enemies: Array = stage["enemies"]
	enemy_name = String(stage["boss"]) if current_wave >= int(stage["wave_count"]) else String(enemies[current_wave % enemies.size()])
	enemy_max_hp = float(stage["enemy_hp"]) * (1.0 + current_wave * 0.10)
	if current_wave >= int(stage["wave_count"]):
		enemy_max_hp *= 1.8
	enemy_hp = enemy_max_hp
	combat_visual_clock = 0.0
	enemy_visual_state = 0
	if is_instance_valid(enemy_sprite_rect):
		var visual_index: int = rules.enemy_visual_index(enemy_name, String(stage["region"]))
		enemy_sprite_rect.texture = _enemy_atlas(visual_index, 0)


func _update_battle_widgets() -> void:
	if enemy_bar != null:
		enemy_bar.max_value = enemy_max_hp
		enemy_bar.value = enemy_hp
	if wave_label != null:
		var stage: Dictionary = rules.get_stage(stage_index)
		wave_label.text = "%s  |  Wave %d/%d" % [String(stage["name"]), current_wave, int(stage["wave_count"])]
	if power_label != null:
		var stage: Dictionary = rules.get_stage(stage_index)
		power_label.text = "Team Power %d / Stage %d" % [_team_power(), int(stage["power"])]


func _refresh_runtime_widgets() -> void:
	_update_battle_widgets()


func _refresh_hero_health(full: bool) -> void:
	for hero in heroes:
		var stats: Dictionary = rules.hero_stats(hero, inventory, buildings, unlocked_talents)
		hero["max_hp"] = float(stats["hp"])
		if full or float(hero.get("hp", 0.0)) <= 0.0:
			hero["hp"] = float(stats["hp"])
		else:
			hero["hp"] = min(float(hero["hp"]) + float(stats["hp"]) * 0.12, float(stats["hp"]))


func _active_heroes() -> Array:
	return heroes.slice(0, min(rules.team_slots(buildings), heroes.size()))


func _living_active_heroes() -> Array:
	var result: Array = []
	for hero in _active_heroes():
		if float(hero.get("hp", 0.0)) > 0.0:
			result.append(hero)
	return result


func _team_power() -> int:
	return rules.team_power(heroes, inventory, buildings, unlocked_talents, rules.team_slots(buildings))


func _add_materials(rewards: Dictionary) -> void:
	for key in rewards:
		materials[key] = int(materials.get(key, 0)) + int(rewards[key])


func _add_log(text: String) -> void:
	battle_log.push_front(text)
	while battle_log.size() > 10:
		battle_log.pop_back()


func _spawn_float(text: String, color: Color) -> void:
	if floating_layer == null:
		return
	var label := _make_label(text, 28, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(430, 280)
	label.size = Vector2(240, 40)
	floating_layer.add_child(label)
	floating_messages.append({"label": label, "life": 1.15, "start_y": 280.0})


func _update_floating_messages(delta: float) -> void:
	for index in range(floating_messages.size() - 1, -1, -1):
		var entry: Dictionary = floating_messages[index]
		var label: Label = entry["label"]
		if not is_instance_valid(label):
			floating_messages.remove_at(index)
			continue
		var life: float = float(entry["life"]) - delta
		entry["life"] = life
		var progress: float = 1.0 - clamp(life / 1.15, 0.0, 1.0)
		label.position.y = float(entry["start_y"]) - progress * 64.0
		label.modulate.a = clamp(life / 1.15, 0.0, 1.0)
		if life <= 0.0:
			label.queue_free()
			floating_messages.remove_at(index)


func _on_tab_pressed(tab_name: String) -> void:
	selected_tab = tab_name
	_build_shell_again()


func _on_guide_open_tab(tab_name: String) -> void:
	selected_tab = tab_name
	_save_game(false)
	_build_shell_again()


func _build_shell_again() -> void:
	if root != null:
		remove_child(root)
		root.queue_free()
	_build_shell()
	_refresh_ui()


func _on_new_game_requested() -> void:
	if is_instance_valid(new_game_dialog):
		new_game_dialog.popup_centered(Vector2i(440, 180))


func _on_new_game() -> void:
	heroes.clear()
	inventory.clear()
	buildings.clear()
	unlocked_talents.clear()
	battle_log.clear()
	selected_tab = "Battle"
	selected_hero = 0
	selected_item = -1
	equipment_filter = "all"
	auto_salvage_junk = false
	selected_building = "forge"
	selected_talent = "battle_rhythm"
	stage_index = 1
	best_stage = 1
	current_wave = 1
	battle_paused = false
	speed_index = 1
	item_roll_counter = 0
	_initialize_state()
	_set_enemy_for_wave()
	_save_game(true)
	_build_shell_again()
	_spawn_float("New game", ACCENT)


func _on_farm_best() -> void:
	stage_index = max(1, best_stage)
	current_wave = 1
	_set_enemy_for_wave()
	_add_log("Farming stage %d." % [stage_index])
	_refresh_ui()


func _on_push_stage() -> void:
	stage_index = best_stage + 1
	current_wave = 1
	_set_enemy_for_wave()
	_add_log("Pushing stage %d." % [stage_index])
	_refresh_ui()


func _on_camp_heal() -> void:
	var cost: Dictionary = {"herbs": 6 + rules.team_slots(buildings) * 3}
	if not rules.can_afford(cost, materials):
		_spawn_float("Need herbs", BAD)
		return
	rules.spend(cost, materials)
	_refresh_hero_health(true)
	_spawn_float("Healed", GOOD)
	_save_game(false)
	_refresh_ui()


func _on_toggle_pause() -> void:
	battle_paused = not battle_paused
	_save_game(false)
	_refresh_ui()


func _on_cycle_speed() -> void:
	speed_index = (speed_index + 1) % 3
	_save_game(false)
	_refresh_ui()


func _battle_speed() -> int:
	return [1, 2, 3][speed_index]


func _on_hero_selected(index: int) -> void:
	selected_hero = index
	_refresh_ui()


func _on_level_hero() -> void:
	var hero: Dictionary = heroes[selected_hero]
	var cost: Dictionary = rules.hero_level_cost(hero)
	if not rules.can_afford(cost, materials):
		_spawn_float("Need resources", BAD)
		return
	rules.spend(cost, materials)
	hero["level"] = int(hero["level"]) + 1
	_refresh_hero_health(false)
	_spawn_float("Level up", GOOD)
	_save_game(false)
	_refresh_ui()


func _on_skill_hero() -> void:
	var hero: Dictionary = heroes[selected_hero]
	var cost: Dictionary = rules.skill_cost(hero)
	if not rules.can_afford(cost, materials):
		_spawn_float("Need resources", BAD)
		return
	rules.spend(cost, materials)
	hero["skill_level"] = int(hero["skill_level"]) + 1
	_spawn_float("Skill up", BLUE)
	_save_game(false)
	_refresh_ui()


func _on_rank_hero() -> void:
	var hero: Dictionary = heroes[selected_hero]
	var cost: Dictionary = rules.class_rank_cost(hero, unlocked_talents.has("class_drill"))
	if int(hero["rank"]) >= 5:
		_spawn_float("Max rank", ACCENT)
		return
	if not rules.can_afford(cost, materials):
		_spawn_float("Need shards", BAD)
		return
	rules.spend(cost, materials)
	hero["rank"] = int(hero["rank"]) + 1
	if int(hero["rank"]) == 5:
		var class_data: Dictionary = rules.get_class_data(String(hero["class_id"]))
		hero["advanced"] = String(class_data["advanced"][0])
	_refresh_hero_health(false)
	_spawn_float("Rank up", ACCENT)
	_save_game(false)
	_refresh_ui()


func _on_item_selected(index: int) -> void:
	selected_item = index
	selected_tab = "Equipment"
	_refresh_ui()


func _on_equipment_filter_pressed(filter_name: String) -> void:
	equipment_filter = filter_name
	selected_tab = "Equipment"
	_refresh_ui()


func _on_toggle_auto_salvage() -> void:
	auto_salvage_junk = not auto_salvage_junk
	_spawn_float("Auto Junk on" if auto_salvage_junk else "Auto Junk off", GOOD if auto_salvage_junk else TEXT_MUTED)
	_save_game(false)
	_refresh_ui()


func _on_toggle_item_lock() -> void:
	if selected_item < 0 or selected_item >= inventory.size():
		return
	var item: Dictionary = inventory[selected_item]
	item["locked"] = not bool(item.get("locked", false))
	_spawn_float("Item locked" if bool(item["locked"]) else "Item unlocked", BLUE if bool(item["locked"]) else TEXT_MUTED)
	_save_game(false)
	_refresh_ui()


func _on_equip_selected_item() -> void:
	if selected_item < 0 or selected_item >= inventory.size():
		return
	var item: Dictionary = inventory[selected_item]
	var hero: Dictionary = heroes[selected_hero]
	if int(hero["level"]) < int(item["required_level"]):
		_spawn_float("Level required", BAD)
		return
	_unequip_item_everywhere(selected_item)
	hero["equipment"][String(item["slot"])] = selected_item
	_refresh_hero_health(false)
	_spawn_float("Equipped", GOOD)
	_save_game(false)
	_refresh_ui()


func _on_auto_equip_selected_hero() -> void:
	if selected_hero < 0 or selected_hero >= heroes.size():
		return
	var hero: Dictionary = heroes[selected_hero]
	var changed := false
	for slot in rules.SLOTS:
		var best_index := _best_item_for_slot(hero, String(slot))
		if best_index >= 0 and int(hero["equipment"].get(slot, -1)) != best_index:
			_unequip_item_everywhere(best_index)
			hero["equipment"][slot] = best_index
			changed = true
	if changed:
		_refresh_hero_health(false)
		_spawn_float("Auto equipped", GOOD)
		_save_game(false)
	else:
		_spawn_float("No upgrade", TEXT_MUTED)
	_refresh_ui()


func _on_upgrade_item() -> void:
	if selected_item < 0 or selected_item >= inventory.size():
		return
	var item: Dictionary = inventory[selected_item]
	var cost: Dictionary = rules.equipment_upgrade_cost(item)
	if not rules.can_afford(cost, materials):
		_spawn_float("Need ore", BAD)
		return
	rules.spend(cost, materials)
	item["level"] = int(item["level"]) + 1
	item["required_level"] = max(int(item["required_level"]), int(item["level"]) - 1)
	item["main"] = rules._item_main_stat(String(item["slot"]), int(item["level"]), String(item["rarity"]))
	_refresh_hero_health(false)
	_spawn_float("Gear up", GOOD)
	_save_game(false)
	_refresh_ui()


func _on_salvage_item() -> void:
	if selected_item < 0 or selected_item >= inventory.size():
		return
	var item: Dictionary = inventory[selected_item]
	if not rules.can_salvage_item(item, _is_item_equipped(selected_item)):
		_spawn_float("Item protected", BAD)
		return
	var value: Dictionary = rules.salvage_value(item, unlocked_talents)
	_add_materials(value)
	inventory.remove_at(selected_item)
	_repair_equipment_indices_after_remove(selected_item)
	selected_item = min(selected_item, inventory.size() - 1)
	_spawn_float("Salvaged", ACCENT)
	_save_game(false)
	_refresh_ui()


func _on_salvage_junk() -> void:
	var totals: Dictionary = {}
	var removed := 0
	for resource_name in rules.RESOURCE_ORDER:
		totals[resource_name] = 0
	for index in range(inventory.size() - 1, -1, -1):
		var item: Dictionary = inventory[index]
		if _is_junk_item(index, item):
			var value: Dictionary = rules.salvage_value(item, unlocked_talents)
			for key in value:
				totals[key] = int(totals.get(key, 0)) + int(value[key])
			inventory.remove_at(index)
			_repair_equipment_indices_after_remove(index)
			removed += 1
	if removed <= 0:
		_spawn_float("No junk", TEXT_MUTED)
		return
	_add_materials(totals)
	selected_item = min(selected_item, inventory.size() - 1)
	_spawn_float("Junk salvaged", ACCENT)
	_add_log("Salvaged %d junk: %s" % [removed, _format_cost(totals, true)])
	_save_game(false)
	_refresh_ui()


func _on_upgrade_building(building_id: String) -> void:
	var level: int = int(buildings.get(building_id, 1))
	var cost: Dictionary = rules.get_building_cost(building_id, level)
	if not rules.can_afford(cost, materials):
		_spawn_float("Need resources", BAD)
		return
	rules.spend(cost, materials)
	buildings[building_id] = min(5, level + 1)
	selected_building = building_id
	_refresh_hero_health(false)
	_spawn_float("Complete", GOOD)
	_save_game(false)
	_refresh_ui()


func _on_upgrade_all_buildings() -> void:
	var upgraded := 0
	var changed := true
	while changed:
		changed = false
		for building_id in rules.get_building_order():
			var level: int = int(buildings.get(building_id, 1))
			var cost: Dictionary = rules.get_building_cost(building_id, level)
			if cost.is_empty():
				continue
			if rules.can_afford(cost, materials):
				rules.spend(cost, materials)
				buildings[building_id] = min(5, level + 1)
				upgraded += 1
				changed = true
	if upgraded <= 0:
		_spawn_float("No upgrades", TEXT_MUTED)
		return
	_refresh_hero_health(false)
	_spawn_float("%d upgrades" % [upgraded], GOOD)
	_add_log("Camp upgraded %d facilities." % [upgraded])
	_save_game(false)
	_refresh_ui()


func _on_facility_service(building_id: String) -> void:
	var level: int = int(buildings.get(building_id, 1))
	var service: Dictionary = rules.facility_service(building_id, level)
	if service.is_empty():
		return
	var cost: Dictionary = service["cost"]
	if not rules.can_afford(cost, materials):
		_spawn_float("Need resources", BAD)
		return
	var service_id := String(service["id"])
	if service_id == "salvage":
		_on_salvage_junk()
		return
	rules.spend(cost, materials)
	match service_id:
		"craft":
			item_roll_counter += 1
			var craft_stage: int = maxi(1, stage_index + level - 1)
			var item: Dictionary = rules.generate_equipment(craft_stage, item_roll_counter, level * 6)
			inventory.append(item)
			selected_item = inventory.size() - 1
			_add_log("Forge crafted %s Lv.%d." % [String(item["name"]), int(item["level"])])
			_spawn_float("Gear crafted", GOOD)
		"train":
			if selected_hero >= 0 and selected_hero < heroes.size():
				var hero: Dictionary = heroes[selected_hero]
				hero["level"] = int(hero["level"]) + 1
				_refresh_hero_health(false)
				_add_log("Academy trained %s to level %d." % [String(hero["name"]), int(hero["level"])])
				_spawn_float("Hero trained", BLUE)
		"restore":
			_refresh_hero_health(true)
			_add_log("Infirmary restored the team.")
			_spawn_float("Team restored", GOOD)
		"trade", "distill":
			var reward: Dictionary = service["reward"]
			_add_materials(reward)
			_add_log("%s: %s." % [String(service["name"]), _format_cost(reward, true)])
			_spawn_float(String(service["name"]), ACCENT)
	_save_game(false)
	_refresh_ui()


func _on_talent_selected(talent_id: String) -> void:
	selected_talent = talent_id
	_refresh_ui()


func _on_unlock_talent() -> void:
	if unlocked_talents.has(selected_talent):
		return
	var talent: Dictionary = rules.get_talent(selected_talent)
	if talent.is_empty():
		return
	if not rules.can_afford(talent["cost"], materials):
		_spawn_float("Need essence", BAD)
		return
	rules.spend(talent["cost"], materials)
	unlocked_talents.append(selected_talent)
	_refresh_hero_health(false)
	_spawn_float("Talent", BLUE)
	_save_game(false)
	_refresh_ui()


func _on_stage_selected(index: int) -> void:
	stage_index = index
	current_wave = 1
	_set_enemy_for_wave()
	_save_game(false)
	_refresh_ui()


func _save_game(show_notice: bool) -> void:
	var save_data: Dictionary = save_rules.build_snapshot(_current_save_state(), Time.get_unix_time_from_system())
	var save_path := _save_file_path()
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(save_data))
	autosave_timer = 0.0
	if show_notice:
		save_notice_timer = 2.0
		if save_status_label != null:
			save_status_label.text = "Saved"


func _current_save_state() -> Dictionary:
	return {
		"materials": materials,
		"heroes": heroes,
		"inventory": inventory,
		"buildings": buildings,
		"unlocked_talents": unlocked_talents,
		"selected_tab": selected_tab,
		"selected_hero": selected_hero,
		"selected_item": selected_item,
		"equipment_filter": equipment_filter,
		"auto_salvage_junk": auto_salvage_junk,
		"selected_building": selected_building,
		"selected_talent": selected_talent,
		"stage_index": stage_index,
		"best_stage": best_stage,
		"battle_paused": battle_paused,
		"speed_index": speed_index,
		"item_roll_counter": item_roll_counter,
	}


func _save_before_exit() -> void:
	if exit_save_completed or heroes.is_empty():
		return
	exit_save_completed = true
	_save_game(false)


func _load_game() -> bool:
	var save_path := _save_file_path()
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	materials = _merge_default_dictionary(rules.starting_materials(), data.get("materials", {}))
	heroes = _load_array(data.get("heroes", []))
	inventory = _load_array(data.get("inventory", []))
	buildings = _merge_default_buildings(data.get("buildings", {}))
	unlocked_talents = _load_string_array(data.get("unlocked_talents", []))
	battle_log = ["Loaded save. Battle restarted at wave 1."]
	selected_tab = String(data.get("selected_tab", "Battle"))
	if not TAB_NAMES.has(selected_tab):
		selected_tab = "Battle"
	selected_hero = clampi(int(data.get("selected_hero", 0)), 0, max(0, heroes.size() - 1))
	selected_item = clampi(int(data.get("selected_item", -1)), -1, max(-1, inventory.size() - 1))
	equipment_filter = String(data.get("equipment_filter", "all"))
	if not ["all", "weapon", "armor", "trinket"].has(equipment_filter):
		equipment_filter = "all"
	auto_salvage_junk = bool(data.get("auto_salvage_junk", false))
	selected_building = String(data.get("selected_building", "forge"))
	selected_talent = String(data.get("selected_talent", "battle_rhythm"))
	stage_index = max(1, int(data.get("stage_index", 1)))
	best_stage = max(1, int(data.get("best_stage", 1)))
	current_wave = 1
	battle_paused = bool(data.get("battle_paused", false))
	speed_index = clampi(int(data.get("speed_index", 1)), 0, 2)
	enemy_name = ""
	enemy_hp = 0.0
	enemy_max_hp = 0.0
	item_roll_counter = int(data.get("item_roll_counter", inventory.size()))
	_repair_loaded_state()
	_set_enemy_for_wave()
	_refresh_hero_health(true)
	_apply_offline_progress(float(data.get("saved_at", 0.0)))
	autosave_timer = 0.0
	return true


func _save_file_path() -> String:
	var override_path := OS.get_environment("IDLE_HERO_CAMP_SAVE_PATH")
	if not override_path.is_empty():
		return override_path
	return ProjectSettings.globalize_path(SAVE_PATH)


func _repair_loaded_state() -> void:
	if heroes.is_empty():
		for hero_def in rules.HEROES:
			heroes.append(rules.create_hero(hero_def))
	for hero in heroes:
		if not hero.has("equipment"):
			hero["equipment"] = {"weapon": -1, "armor": -1, "trinket": -1}
		for slot in rules.SLOTS:
			if not hero["equipment"].has(slot):
				hero["equipment"][slot] = -1
			var item_index: int = int(hero["equipment"][slot])
			if item_index >= inventory.size():
				hero["equipment"][slot] = -1
	if inventory.is_empty():
		for index in range(4):
			inventory.append(rules.generate_equipment(1, index))
	selected_hero = clampi(selected_hero, 0, max(0, heroes.size() - 1))
	selected_item = clampi(selected_item, -1, max(-1, inventory.size() - 1))


func _merge_default_dictionary(defaults: Dictionary, loaded) -> Dictionary:
	var result: Dictionary = defaults.duplicate(true)
	if typeof(loaded) == TYPE_DICTIONARY:
		var loaded_dict: Dictionary = loaded
		for key in loaded_dict:
			result[key] = loaded_dict[key]
	return result


func _merge_default_buildings(loaded) -> Dictionary:
	var result: Dictionary = {}
	for building_id in rules.get_building_order():
		result[building_id] = 1
	if typeof(loaded) == TYPE_DICTIONARY:
		var loaded_dict: Dictionary = loaded
		for key in loaded_dict:
			result[key] = clampi(int(loaded_dict[key]), 1, 5)
	return result


func _load_array(value) -> Array:
	var result: Array = []
	if typeof(value) == TYPE_ARRAY:
		for entry in value:
			if typeof(entry) == TYPE_DICTIONARY:
				result.append((entry as Dictionary).duplicate(true))
	return result


func _load_string_array(value) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) == TYPE_ARRAY:
		for entry in value:
			result.append(String(entry))
	return result


func _apply_offline_progress(saved_at: float) -> void:
	if saved_at <= 0.0:
		return
	var elapsed: int = int(Time.get_unix_time_from_system() - saved_at)
	if elapsed < 30:
		return
	var rewarded_seconds: int = min(elapsed, OFFLINE_REWARD_CAP_SECONDS)
	var reward_cycles: int = max(1, int(rewarded_seconds / 45))
	var stage_for_rewards: int = max(1, min(stage_index, best_stage + 1))
	var combined: Dictionary = {}
	for resource_name in rules.RESOURCE_ORDER:
		combined[resource_name] = 0
	for cycle in range(reward_cycles):
		var wave: int = (cycle % 5) + 1
		var rewards: Dictionary = rules.wave_rewards(stage_for_rewards, wave, buildings, unlocked_talents)
		for key in rewards:
			combined[key] = int(combined.get(key, 0)) + int(rewards[key])
	var speed_multiplier: int = max(1, _battle_speed())
	for key in combined:
		combined[key] = int(float(combined[key]) * min(2.0, 0.75 + speed_multiplier * 0.25))
	_add_materials(combined)
	_add_log("Away %s: %s" % [_format_duration(rewarded_seconds), _format_cost(combined, true)])


func _format_duration(seconds: int) -> String:
	var hours := int(seconds / 3600)
	var minutes := int((seconds % 3600) / 60)
	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	return "%dm" % [max(1, minutes)]


func _compact_number(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % [float(value) / 1000000.0]
	if value >= 10000:
		return "%.1fK" % [float(value) / 1000.0]
	return str(value)


func _selected_item_dict() -> Dictionary:
	if selected_item >= 0 and selected_item < inventory.size():
		return inventory[selected_item]
	return {}


func _item_matches_filter(item: Dictionary) -> bool:
	return equipment_filter == "all" or String(item.get("slot", "")) == equipment_filter


func _equipped_count(hero: Dictionary) -> int:
	var count := 0
	for slot in rules.SLOTS:
		if int(hero["equipment"].get(slot, -1)) >= 0:
			count += 1
	return count


func _best_item_for_slot(hero: Dictionary, slot: String) -> int:
	var best_index := -1
	var best_score := -999999.0
	for index in range(inventory.size()):
		var item: Dictionary = inventory[index]
		if String(item.get("slot", "")) != slot:
			continue
		if int(hero.get("level", 1)) < int(item.get("required_level", 1)):
			continue
		if _is_item_equipped_by_other(index, selected_hero):
			continue
		var score := _item_score(item)
		if score > best_score:
			best_score = score
			best_index = index
	return best_index


func _item_score(item: Dictionary) -> float:
	var score := float(item.get("level", 1)) * 10.0 + float(rules.RARITIES.find(String(item.get("rarity", "Common")))) * 18.0
	var main: Dictionary = item.get("main", {})
	for key in main:
		score += _stat_weight(String(key), float(main[key]))
	var affix: Dictionary = item.get("affix", {})
	if affix.has("stat") and affix.has("value"):
		score += _stat_weight(String(affix["stat"]), float(affix["value"]))
	return score


func _stat_weight(stat: String, value: float) -> float:
	if stat == "hp":
		return value * 0.10
	if stat == "atk":
		return value * 2.4
	if stat == "def":
		return value * 1.5
	if stat == "speed":
		return value * 95.0
	if stat == "crit":
		return value * 120.0
	return value


func _is_item_equipped_by_other(item_index: int, hero_index: int) -> bool:
	for index in range(heroes.size()):
		if index == hero_index:
			continue
		var hero: Dictionary = heroes[index]
		for slot in rules.SLOTS:
			if int(hero["equipment"].get(slot, -1)) == item_index:
				return true
	return false


func _is_item_equipped(item_index: int) -> bool:
	for hero in heroes:
		for slot in rules.SLOTS:
			if int(hero["equipment"].get(slot, -1)) == item_index:
				return true
	return false


func _is_junk_item(item_index: int, item: Dictionary) -> bool:
	if not rules.can_salvage_item(item, _is_item_equipped(item_index)):
		return false
	return _is_low_rarity_item(item)


func _is_low_rarity_item(item: Dictionary) -> bool:
	var rarity := String(item.get("rarity", "Common"))
	return rarity == "Common" or rarity == "Uncommon"


func _repair_equipment_indices_after_remove(removed_index: int) -> void:
	for hero in heroes:
		for slot in rules.SLOTS:
			var item_index := int(hero["equipment"].get(slot, -1))
			if item_index == removed_index:
				hero["equipment"][slot] = -1
			elif item_index > removed_index:
				hero["equipment"][slot] = item_index - 1


func _unequip_item_everywhere(item_index: int) -> void:
	for hero in heroes:
		for slot in rules.SLOTS:
			if int(hero["equipment"].get(slot, -1)) == item_index:
				hero["equipment"][slot] = -1


func _add_cost_button(parent: Control, text: String, pos: Vector2, cost: Dictionary, callback: Callable) -> void:
	var ok: bool = rules.can_afford(cost, materials)
	var button := _make_button(text, Vector2(140, 36), false, GOOD if ok else BAD)
	button.position = pos
	button.tooltip_text = _format_cost(cost, false)
	button.pressed.connect(callback)
	parent.add_child(button)


func _add_resource_cost_row(parent: Control, cost: Dictionary, pos: Vector2, max_items: int) -> void:
	var row := HBoxContainer.new()
	row.position = pos
	row.size = Vector2(304, 22)
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var shown := 0
	for resource_name in rules.RESOURCE_ORDER:
		if not cost.has(resource_name):
			continue
		if shown >= max_items:
			break
		var amount := int(cost[resource_name])
		var enough := int(materials.get(resource_name, 0)) >= amount
		var group := HBoxContainer.new()
		group.custom_minimum_size = Vector2(68, 20)
		group.add_theme_constant_override("separation", 2)
		group.tooltip_text = "%s %d / %d" % [String(resource_name).capitalize(), int(materials.get(resource_name, 0)), amount]
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _resource_atlas(resource_name)
		group.add_child(icon)
		group.add_child(_make_label(str(amount), 12, GOOD if enough else BAD, HORIZONTAL_ALIGNMENT_LEFT))
		row.add_child(group)
		shown += 1


func _hero_tooltip(hero: Dictionary, stats: Dictionary) -> String:
	var class_data: Dictionary = rules.get_class_data(String(hero["class_id"]))
	return "%s\n%s\nHP %d  ATK %d  DEF %d\nSpeed %.2f  Crit %.1f%%\nSkill: %s Lv.%d" % [
		String(hero["name"]),
		String(class_data["role"]),
		int(stats["hp"]),
		int(stats["atk"]),
		int(stats["def"]),
		float(stats["speed"]),
		float(stats["crit"]) * 100.0,
		String(class_data["skill"]),
		int(hero["skill_level"])
	]


func _item_tooltip(item: Dictionary) -> String:
	var lines: Array[String] = [
		"%s %s" % [String(item["rarity"]), String(item["slot"]).capitalize()],
		"Level %d, requires hero level %d" % [int(item["level"]), int(item["required_level"])],
	]
	if bool(item.get("locked", false)):
		lines.append("Locked: protected from salvage")
	var main: Dictionary = item["main"]
	for key in main:
		lines.append("+%s %s" % [str(main[key]), String(key).capitalize()])
	var affix: Dictionary = item["affix"]
	lines.append("+%s %s" % [str(affix["value"]), String(affix["label"])])
	return "\n".join(PackedStringArray(lines))


func _building_tooltip(building_id: String) -> String:
	var building: Dictionary = rules.get_building(building_id)
	var level: int = int(buildings.get(building_id, 1))
	var unlocks: Array = building["unlocks"]
	var text := "%s Lv.%d\n%s\nCurrent: %s" % [
		String(building["name"]),
		level,
		String(building["text"]),
		String(unlocks[min(level - 1, unlocks.size() - 1)])
	]
	return text


func _upgrade_tooltip(building_id: String) -> String:
	var building: Dictionary = rules.get_building(building_id)
	var level: int = int(buildings.get(building_id, 1))
	if level >= 5:
		return "Max level."
	var unlocks: Array = building["unlocks"]
	return "Next: %s\nCost: %s" % [String(unlocks[min(level, unlocks.size() - 1)]), _format_cost(rules.get_building_cost(building_id, level), false)]


func _format_cost(cost: Dictionary, plain: bool) -> String:
	var parts: Array[String] = []
	for key in rules.RESOURCE_ORDER:
		if cost.has(key) and int(cost[key]) != 0:
			var amount := int(cost[key])
			if plain:
				parts.append("%s %s" % [str(amount), String(key).capitalize()])
			else:
				var enough := int(materials.get(key, 0)) >= amount
				parts.append("%s %s %s" % [str(amount), String(key).capitalize(), "OK" if enough else "NO"])
	return ", ".join(PackedStringArray(parts)) if not parts.is_empty() else "Free"


func _make_label(text: String, size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text: String, min_size: Vector2, active: bool = false, color: Color = ACCENT) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_NONE
	var normal := _style(Color(color.r * 0.26, color.g * 0.26, color.b * 0.26), PANEL_BORDER)
	var hover := _style(Color(color.r * 0.42, color.g * 0.42, color.b * 0.42), color)
	var pressed := _style(Color(color.r * 0.55, color.g * 0.55, color.b * 0.55), color)
	var active_style := _style(Color(color.r * 0.44, color.g * 0.44, color.b * 0.44), color)
	button.add_theme_stylebox_override("normal", active_style if active else normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", _style(Color(0.12, 0.12, 0.12), Color(0.22, 0.22, 0.22)))
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.48, 0.48))
	return button


func _panel(pos: Vector2, size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	panel.add_theme_stylebox_override("panel", _style(CARD_BG, PANEL_BORDER))
	return panel


func _make_bar(pos: Vector2, size: Vector2, value: float, maximum: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = size
	bar.max_value = max(1.0, maximum)
	bar.value = clamp(value, 0.0, maximum)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color(0.07, 0.07, 0.08), Color(0.18, 0.18, 0.18)))
	bar.add_theme_stylebox_override("fill", _style(color, color))
	return bar


func _style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _resource_atlas(resource_name: String) -> Texture2D:
	if resource_icon_cache.has(resource_name):
		return resource_icon_cache[resource_name]
	if resource_texture != null:
		var resource_index: int = rules.RESOURCE_ORDER.find(resource_name)
		if resource_index >= 0:
			var atlas := AtlasTexture.new()
			atlas.atlas = resource_texture
			atlas.region = Rect2(resource_index * 64, 0, 64, 64)
			resource_icon_cache[resource_name] = atlas
			return atlas
	var visual: Dictionary = rules.resource_visual(resource_name)
	if visual.is_empty():
		return null
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var color: Color = visual["color"]
	var dark := Color(color.r * 0.36, color.g * 0.36, color.b * 0.36, 1.0)
	var light := Color(min(color.r + 0.24, 1.0), min(color.g + 0.24, 1.0), min(color.b + 0.24, 1.0), 1.0)
	_draw_icon_circle(image, Vector2i(32, 34), 27, Color(0.05, 0.06, 0.07, 0.72))
	var symbol := String(visual["symbol"])
	match symbol:
		"coin":
			_draw_icon_circle(image, Vector2i(32, 32), 18, dark)
			_draw_icon_circle(image, Vector2i(32, 32), 15, color)
			_draw_icon_circle(image, Vector2i(28, 27), 4, light)
			_draw_icon_rect(image, Rect2i(30, 21, 4, 23), light)
		"logs":
			_draw_icon_rect(image, Rect2i(13, 22, 38, 11), dark)
			_draw_icon_rect(image, Rect2i(16, 35, 34, 11), color)
			_draw_icon_circle(image, Vector2i(15, 27), 6, color)
			_draw_icon_circle(image, Vector2i(18, 40), 6, light)
		"ingot":
			_draw_icon_diamond(image, Vector2i(32, 16), Vector2i(52, 30), Vector2i(43, 46), Vector2i(12, 38), dark)
			_draw_icon_diamond(image, Vector2i(32, 19), Vector2i(47, 30), Vector2i(40, 39), Vector2i(18, 35), light)
		"leaves":
			_draw_icon_rect(image, Rect2i(30, 20, 4, 31), dark)
			_draw_icon_circle(image, Vector2i(23, 26), 9, color)
			_draw_icon_circle(image, Vector2i(41, 22), 8, light)
			_draw_icon_circle(image, Vector2i(42, 38), 9, color)
			_draw_icon_circle(image, Vector2i(23, 42), 7, light)
		"bottle":
			_draw_icon_rect(image, Rect2i(26, 15, 12, 10), light)
			_draw_icon_rect(image, Rect2i(20, 24, 24, 27), dark)
			_draw_icon_rect(image, Rect2i(23, 29, 18, 18), color)
			_draw_icon_circle(image, Vector2i(28, 32), 4, light)
		"powder":
			_draw_icon_circle(image, Vector2i(23, 40), 11, dark)
			_draw_icon_circle(image, Vector2i(35, 37), 14, color)
			_draw_icon_circle(image, Vector2i(45, 43), 8, light)
			_draw_icon_circle(image, Vector2i(29, 25), 4, light)
		"flame":
			_draw_icon_diamond(image, Vector2i(36, 10), Vector2i(49, 37), Vector2i(31, 53), Vector2i(17, 36), dark)
			_draw_icon_diamond(image, Vector2i(34, 21), Vector2i(42, 39), Vector2i(31, 48), Vector2i(24, 38), light)
		"crystals":
			_draw_icon_diamond(image, Vector2i(22, 16), Vector2i(31, 32), Vector2i(22, 51), Vector2i(13, 33), color)
			_draw_icon_diamond(image, Vector2i(39, 11), Vector2i(50, 31), Vector2i(39, 48), Vector2i(29, 30), light)
		"relic":
			_draw_icon_circle(image, Vector2i(32, 32), 19, color)
			_draw_icon_circle(image, Vector2i(32, 32), 11, Color(0.05, 0.06, 0.07, 1.0))
			_draw_icon_rect(image, Rect2i(29, 11, 6, 14), light)
			_draw_icon_rect(image, Rect2i(39, 38, 13, 6), dark)
	var texture := ImageTexture.create_from_image(image)
	resource_icon_cache[resource_name] = texture
	return texture


func _guide_icon_texture(kind: String) -> Texture2D:
	if kind == "hero" and not heroes.is_empty():
		return _hero_portrait_texture(heroes[selected_hero])
	if kind == "item" and not inventory.is_empty():
		var index: int = max(0, selected_item)
		return _item_icon_texture(inventory[min(index, inventory.size() - 1)])
	if kind == "talent":
		var talent: Dictionary = rules.get_talent(selected_talent)
		if not talent.is_empty():
			return _talent_icon_texture(talent)
	if kind == "building":
		return _building_atlas(0, int(buildings.get("forge", 1)))
	if kind == "stage":
		return _stage_icon_texture(rules.get_stage(stage_index))
	return _resource_atlas("gold")


func _item_icon_texture(item: Dictionary) -> Texture2D:
	var cache_key := "%s_%s_%d" % [String(item.get("slot", "item")), String(item.get("rarity", "Common")), int(item.get("level", 1))]
	if equipment_icon_cache.has(cache_key):
		return equipment_icon_cache[cache_key]
	if equipment_texture != null:
		var slot_index: int = EQUIPMENT_ATLAS_SLOTS.find(String(item.get("slot", "weapon")))
		var rarity_index: int = EQUIPMENT_ATLAS_RARITIES.find(String(item.get("rarity", "Common")))
		if slot_index >= 0 and rarity_index >= 0:
			var atlas := AtlasTexture.new()
			atlas.atlas = equipment_texture
			atlas.region = Rect2(slot_index * 64, rarity_index * 64, 64, 64)
			equipment_icon_cache[cache_key] = atlas
			return atlas
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var rarity := _rarity_color(String(item.get("rarity", "Common")))
	var dark := Color(rarity.r * 0.35, rarity.g * 0.35, rarity.b * 0.35, 1.0)
	var shine := Color(min(rarity.r + 0.22, 1.0), min(rarity.g + 0.22, 1.0), min(rarity.b + 0.22, 1.0), 1.0)
	_draw_icon_rect(image, Rect2i(6, 6, 52, 52), Color(0.08, 0.09, 0.10, 0.92))
	_draw_icon_outline(image, Rect2i(6, 6, 52, 52), rarity)
	var slot := String(item.get("slot", "weapon"))
	if slot == "weapon":
		_draw_icon_rect(image, Rect2i(30, 12, 8, 34), shine)
		_draw_icon_rect(image, Rect2i(26, 42, 16, 6), dark)
		_draw_icon_rect(image, Rect2i(22, 48, 20, 5), Color(0.48, 0.32, 0.18))
		_draw_icon_rect(image, Rect2i(36, 16, 6, 22), rarity)
	elif slot == "armor":
		_draw_icon_rect(image, Rect2i(18, 16, 28, 30), dark)
		_draw_icon_rect(image, Rect2i(22, 12, 20, 10), rarity)
		_draw_icon_rect(image, Rect2i(24, 24, 16, 18), shine)
		_draw_icon_outline(image, Rect2i(18, 16, 28, 30), rarity)
	else:
		_draw_icon_diamond(image, Vector2i(32, 14), Vector2i(50, 32), Vector2i(32, 52), Vector2i(14, 32), dark)
		_draw_icon_diamond(image, Vector2i(32, 20), Vector2i(44, 32), Vector2i(32, 44), Vector2i(20, 32), shine)
		_draw_icon_rect(image, Rect2i(30, 12, 4, 42), rarity)
	var texture := ImageTexture.create_from_image(image)
	equipment_icon_cache[cache_key] = texture
	return texture


func _hero_portrait_texture(hero: Dictionary) -> Texture2D:
	var class_id := String(hero.get("class_id", "warrior"))
	var rank := int(hero.get("rank", 1))
	var cache_key := "%s_%d" % [class_id, rank]
	if hero_icon_cache.has(cache_key):
		return hero_icon_cache[cache_key]
	if class_sheet_texture != null:
		var class_index: int = CLASS_ATLAS_ORDER.find(class_id)
		if class_index >= 0:
			var atlas := AtlasTexture.new()
			atlas.atlas = class_sheet_texture
			atlas.region = Rect2(0, class_index * 96, 64, 96)
			hero_icon_cache[cache_key] = atlas
			return atlas
	var image := Image.create(80, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var base := _class_color(class_id)
	var dark := Color(base.r * 0.38, base.g * 0.38, base.b * 0.38, 1.0)
	var light := Color(min(base.r + 0.25, 1.0), min(base.g + 0.25, 1.0), min(base.b + 0.25, 1.0), 1.0)
	_draw_icon_rect(image, Rect2i(14, 18, 52, 70), Color(0.08, 0.09, 0.10, 0.92))
	_draw_icon_outline(image, Rect2i(14, 18, 52, 70), base)
	_draw_icon_circle(image, Vector2i(40, 28), 13, light)
	_draw_icon_rect(image, Rect2i(26, 42, 28, 32), dark)
	_draw_icon_rect(image, Rect2i(22, 72, 36, 8), base)
	if class_id == "warrior":
		_draw_icon_rect(image, Rect2i(16, 44, 12, 26), base)
		_draw_icon_rect(image, Rect2i(53, 36, 7, 38), light)
	elif class_id == "ranger":
		_draw_icon_rect(image, Rect2i(54, 34, 4, 36), base)
		_draw_icon_rect(image, Rect2i(58, 42, 10, 3), light)
	elif class_id == "cleric":
		_draw_icon_rect(image, Rect2i(36, 46, 8, 24), light)
		_draw_icon_rect(image, Rect2i(28, 54, 24, 8), light)
	elif class_id == "rogue":
		_draw_icon_rect(image, Rect2i(20, 36, 18, 8), dark)
		_draw_icon_rect(image, Rect2i(50, 46, 10, 24), light)
	elif class_id == "paladin":
		_draw_icon_rect(image, Rect2i(16, 43, 13, 27), light)
		_draw_icon_rect(image, Rect2i(34, 44, 8, 24), Color(0.95, 0.82, 0.32))
	elif class_id == "druid":
		_draw_icon_circle(image, Vector2i(22, 42), 8, light)
		_draw_icon_rect(image, Rect2i(50, 34, 6, 36), Color(0.48, 0.30, 0.16))
	elif class_id == "artificer":
		_draw_icon_circle(image, Vector2i(59, 43), 8, light)
		_draw_icon_rect(image, Rect2i(16, 48, 12, 20), base)
	elif class_id == "necromancer":
		_draw_icon_circle(image, Vector2i(58, 42), 7, Color(0.35, 0.86, 0.72))
		_draw_icon_rect(image, Rect2i(19, 38, 12, 30), dark)
	elif class_id == "monk":
		_draw_icon_rect(image, Rect2i(16, 42, 12, 26), light)
		_draw_icon_rect(image, Rect2i(52, 42, 12, 26), light)
	else:
		_draw_icon_circle(image, Vector2i(60, 42), 7, light)
		_draw_icon_rect(image, Rect2i(57, 48, 6, 22), base)
	if rank >= 5:
		_draw_icon_outline(image, Rect2i(10, 14, 60, 78), Color(1.0, 0.82, 0.28))
	var texture := ImageTexture.create_from_image(image)
	hero_icon_cache[cache_key] = texture
	return texture


func _talent_icon_texture(talent: Dictionary) -> Texture2D:
	var talent_id := String(talent.get("id", "talent"))
	if talent_icon_cache.has(talent_id):
		return talent_icon_cache[talent_id]
	var branch := String(talent.get("branch", "Combat"))
	if talent_texture != null:
		var branch_index: int = TALENT_ATLAS_BRANCHES.find(branch)
		if branch_index >= 0:
			var atlas := AtlasTexture.new()
			atlas.atlas = talent_texture
			atlas.region = Rect2(branch_index * 48, 0, 48, 48)
			talent_icon_cache[talent_id] = atlas
			return atlas
	var color := _branch_color(branch)
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_draw_icon_circle(image, Vector2i(24, 24), 21, Color(0.08, 0.09, 0.10, 0.95))
	_draw_icon_circle(image, Vector2i(24, 24), 17, Color(color.r * 0.35, color.g * 0.35, color.b * 0.35, 1.0))
	if branch == "Combat":
		_draw_icon_rect(image, Rect2i(22, 11, 5, 25), color)
		_draw_icon_rect(image, Rect2i(17, 34, 15, 4), color)
	elif branch == "Economy":
		_draw_icon_circle(image, Vector2i(24, 24), 10, color)
		_draw_icon_rect(image, Rect2i(22, 14, 4, 20), Color(0.95, 0.82, 0.32))
	elif branch == "Loot":
		_draw_icon_diamond(image, Vector2i(24, 10), Vector2i(36, 24), Vector2i(24, 38), Vector2i(12, 24), color)
	elif branch == "Automation":
		_draw_icon_rect(image, Rect2i(14, 14, 20, 20), color)
		_draw_icon_rect(image, Rect2i(20, 8, 8, 32), Color(0.55, 0.70, 0.90))
	else:
		_draw_icon_rect(image, Rect2i(14, 13, 20, 6), color)
		_draw_icon_rect(image, Rect2i(21, 13, 6, 24), color)
	var texture := ImageTexture.create_from_image(image)
	talent_icon_cache[talent_id] = texture
	return texture


func _stage_icon_texture(stage: Dictionary) -> Texture2D:
	var region := String(stage.get("region", "Meadow Road"))
	if stage_icon_cache.has(region):
		return stage_icon_cache[region]
	if stage_texture != null:
		var region_index: int = STAGE_ATLAS_REGIONS.find(region)
		if region_index >= 0:
			var atlas := AtlasTexture.new()
			atlas.atlas = stage_texture
			atlas.region = Rect2(region_index * 48, 0, 48, 48)
			stage_icon_cache[region] = atlas
			return atlas
	var color := _region_color(region)
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_draw_icon_rect(image, Rect2i(5, 5, 38, 38), Color(0.08, 0.09, 0.10, 0.92))
	_draw_icon_outline(image, Rect2i(5, 5, 38, 38), color)
	if region.contains("Meadow"):
		_draw_icon_rect(image, Rect2i(12, 30, 24, 6), color)
		_draw_icon_circle(image, Vector2i(25, 23), 9, Color(0.38, 0.72, 0.34))
	elif region.contains("Iron"):
		_draw_icon_diamond(image, Vector2i(24, 10), Vector2i(37, 23), Vector2i(24, 38), Vector2i(11, 23), color)
	elif region.contains("Grave"):
		_draw_icon_rect(image, Rect2i(17, 14, 14, 25), color)
		_draw_icon_rect(image, Rect2i(13, 22, 22, 5), color)
	elif region.contains("Ember"):
		_draw_icon_diamond(image, Vector2i(24, 9), Vector2i(35, 28), Vector2i(24, 39), Vector2i(13, 28), color)
	else:
		_draw_icon_rect(image, Rect2i(12, 16, 24, 22), color)
		_draw_icon_rect(image, Rect2i(17, 10, 14, 10), color)
	var texture := ImageTexture.create_from_image(image)
	stage_icon_cache[region] = texture
	return texture


func _draw_icon_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)


func _draw_icon_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var radius_sq: int = radius * radius
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var dx: int = x - center.x
			var dy: int = y - center.y
			if dx * dx + dy * dy <= radius_sq and x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)


func _draw_icon_outline(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_icon_rect(image, Rect2i(rect.position.x, rect.position.y, rect.size.x, 2), color)
	_draw_icon_rect(image, Rect2i(rect.position.x, rect.position.y + rect.size.y - 2, rect.size.x, 2), color)
	_draw_icon_rect(image, Rect2i(rect.position.x, rect.position.y, 2, rect.size.y), color)
	_draw_icon_rect(image, Rect2i(rect.position.x + rect.size.x - 2, rect.position.y, 2, rect.size.y), color)


func _draw_icon_diamond(image: Image, top: Vector2i, right: Vector2i, bottom: Vector2i, left: Vector2i, color: Color) -> void:
	var min_y: int = min(top.y, min(right.y, min(bottom.y, left.y)))
	var max_y: int = max(top.y, max(right.y, max(bottom.y, left.y)))
	for y in range(min_y, max_y + 1):
		var t: float = 0.0
		var left_x: float = 0.0
		var right_x: float = 0.0
		if y <= left.y:
			t = float(y - top.y) / max(1.0, float(left.y - top.y))
			left_x = lerpf(float(top.x), float(left.x), t)
			right_x = lerpf(float(top.x), float(right.x), t)
		else:
			t = float(y - left.y) / max(1.0, float(bottom.y - left.y))
			left_x = lerpf(float(left.x), float(bottom.x), t)
			right_x = lerpf(float(right.x), float(bottom.x), t)
		for x in range(int(left_x), int(right_x) + 1):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)


func _hero_atlas(index: int) -> Texture2D:
	if hero_texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = hero_texture
	atlas.region = Rect2((index % 4) * 128, 0, 128, 128)
	return atlas


func _enemy_atlas(index: int, state: int = 0) -> Texture2D:
	if enemy_texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = enemy_texture
	atlas.region = Rect2(rules.enemy_sprite_region(index, state))
	return atlas


func _building_atlas(index: int, level: int) -> Texture2D:
	if building_texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = building_texture
	atlas.region = Rect2(rules.building_sprite_region(index, level))
	return atlas


func _rarity_color(rarity: String) -> Color:
	if rarity == "Legendary":
		return Color(0.95, 0.62, 0.18)
	if rarity == "Epic":
		return Color(0.66, 0.42, 0.92)
	if rarity == "Rare":
		return Color(0.28, 0.52, 0.92)
	if rarity == "Uncommon":
		return Color(0.35, 0.72, 0.38)
	return Color(0.58, 0.60, 0.62)


func _class_color(class_id: String) -> Color:
	if class_id == "warrior":
		return Color(0.75, 0.28, 0.24)
	if class_id == "ranger":
		return Color(0.30, 0.68, 0.34)
	if class_id == "cleric":
		return Color(0.88, 0.78, 0.42)
	if class_id == "rogue":
		return Color(0.55, 0.42, 0.82)
	if class_id == "paladin":
		return Color(0.92, 0.76, 0.34)
	if class_id == "druid":
		return Color(0.34, 0.68, 0.32)
	if class_id == "artificer":
		return Color(0.78, 0.48, 0.22)
	if class_id == "necromancer":
		return Color(0.42, 0.76, 0.66)
	if class_id == "monk":
		return Color(0.82, 0.36, 0.26)
	return Color(0.35, 0.58, 0.90)


func _branch_color(branch: String) -> Color:
	if branch == "Combat":
		return Color(0.78, 0.25, 0.24)
	if branch == "Economy":
		return Color(0.85, 0.67, 0.26)
	if branch == "Loot":
		return Color(0.40, 0.68, 0.92)
	if branch == "Automation":
		return Color(0.48, 0.66, 0.72)
	return Color(0.64, 0.44, 0.88)


func _region_color(region: String) -> Color:
	if region.contains("Meadow"):
		return Color(0.38, 0.68, 0.32)
	if region.contains("Iron"):
		return Color(0.62, 0.62, 0.68)
	if region.contains("Grave"):
		return Color(0.50, 0.45, 0.68)
	if region.contains("Ember"):
		return Color(0.88, 0.36, 0.18)
	return Color(0.64, 0.52, 0.40)
