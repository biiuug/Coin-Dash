extends Control

const ACCENT := Color(0.78, 0.63, 0.32)
const TEXT_MAIN := Color(0.90, 0.88, 0.80)
const TEXT_MUTED := Color(0.58, 0.63, 0.67)
const PANEL := Color(0.10, 0.12, 0.15, 0.94)
const SAVE_PATH := "user://idle_hero_camp_save.json"


func _ready() -> void:
	_build_title_screen()


func _build_title_screen() -> void:
	var background := ColorRect.new()
	background.color = Color(0.045, 0.052, 0.065)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var horizon := ColorRect.new()
	horizon.color = Color(0.12, 0.15, 0.17)
	horizon.position = Vector2(0, 390)
	horizon.size = Vector2(1100, 230)
	background.add_child(horizon)

	for index in range(7):
		var post := ColorRect.new()
		post.color = Color(0.18, 0.20, 0.20)
		post.position = Vector2(70 + index * 165, 348 + (index % 2) * 12)
		post.size = Vector2(5, 112)
		background.add_child(post)

	var character := TextureRect.new()
	character.texture = load("res://assets/characters/warden-pixel-sample.png")
	character.position = Vector2(100, 110)
	character.size = Vector2(330, 330)
	character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.add_child(character)

	var menu_panel := Panel.new()
	menu_panel.position = Vector2(530, 112)
	menu_panel.size = Vector2(470, 380)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL
	panel_style.border_color = Color(0.34, 0.38, 0.44)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	menu_panel.add_theme_stylebox_override("panel", panel_style)
	background.add_child(menu_panel)

	var title := _label("IDLE HERO CAMP", 42, ACCENT)
	title.position = Vector2(38, 38)
	title.size = Vector2(394, 58)
	menu_panel.add_child(title)

	var subtitle := _label("Build the camp. Train the company.\nConquer the Crown of Stars.", 18, TEXT_MAIN)
	subtitle.position = Vector2(40, 104)
	subtitle.size = Vector2(390, 64)
	menu_panel.add_child(subtitle)

	var start := _button("CONTINUE" if FileAccess.file_exists(SAVE_PATH) else "START GAME", ACCENT)
	start.position = Vector2(40, 206)
	start.size = Vector2(390, 54)
	start.pressed.connect(_on_start_pressed)
	menu_panel.add_child(start)
	start.grab_focus()

	var save_hint := _label("Local expedition found" if FileAccess.file_exists(SAVE_PATH) else "A new local expedition will begin", 14, TEXT_MUTED)
	save_hint.position = Vector2(40, 268)
	save_hint.size = Vector2(390, 24)
	save_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_panel.add_child(save_hint)

	var quit := _button("QUIT", Color(0.25, 0.28, 0.31))
	quit.position = Vector2(145, 310)
	quit.size = Vector2(180, 40)
	quit.pressed.connect(get_tree().quit)
	menu_panel.add_child(quit)
	start.focus_neighbor_bottom = start.get_path_to(quit)
	quit.focus_neighbor_top = quit.get_path_to(start)

	var controls := _label("ENTER  Select    ARROWS  Navigate", 12, TEXT_MUTED)
	controls.position = Vector2(40, 354)
	controls.size = Vector2(390, 18)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_panel.add_child(controls)

	var version := _label("VERSION 1.0", 12, TEXT_MUTED)
	version.position = Vector2(16, 584)
	version.size = Vector2(160, 22)
	background.add_child(version)


func _on_start_pressed() -> void:
	SceneTransition.change_scene("res://Main.tscn", "OPENING THE CAMP")


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", TEXT_MAIN)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color.darkened(0.45)
	normal.border_color = color
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color.darkened(0.25)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.60)
	button.add_theme_stylebox_override("pressed", pressed)
	return button
