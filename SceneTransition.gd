extends CanvasLayer

const FADE_TIME := 0.28
const LOAD_HOLD_TIME := 0.65

var blocker: ColorRect
var loading_label: Label
var loading_fill: ColorRect
var transitioning := false
var transition_clock := 0.0


func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS

	blocker = ColorRect.new()
	blocker.color = Color(0.045, 0.052, 0.065, 1.0)
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.modulate.a = 0.0
	blocker.visible = false
	add_child(blocker)

	loading_label = Label.new()
	loading_label.text = "PREPARING EXPEDITION"
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 20)
	loading_label.add_theme_color_override("font_color", Color(0.78, 0.63, 0.32))
	loading_label.position = Vector2(350, 292)
	loading_label.size = Vector2(400, 36)
	blocker.add_child(loading_label)

	var loading_track := ColorRect.new()
	loading_track.color = Color(0.16, 0.18, 0.21)
	loading_track.position = Vector2(400, 338)
	loading_track.size = Vector2(300, 6)
	blocker.add_child(loading_track)

	loading_fill = ColorRect.new()
	loading_fill.color = Color(0.78, 0.63, 0.32)
	loading_fill.position = Vector2.ZERO
	loading_fill.size = Vector2(0, 6)
	loading_track.add_child(loading_fill)


func _process(delta: float) -> void:
	if not transitioning:
		return
	transition_clock += delta
	var dot_count := int(transition_clock * 4.0) % 4
	loading_label.text = "%s%s" % [loading_label.tooltip_text, ".".repeat(dot_count)]
	loading_fill.size.x = lerpf(loading_fill.size.x, 300.0, minf(1.0, delta * 4.0))


func change_scene(scene_path: String, message: String = "PREPARING EXPEDITION") -> void:
	if transitioning:
		return
	transitioning = true
	transition_clock = 0.0
	loading_label.tooltip_text = message
	loading_label.text = message
	loading_fill.size.x = 0.0
	blocker.visible = true
	blocker.modulate.a = 0.0

	var fade_out := create_tween()
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(blocker, "modulate:a", 1.0, FADE_TIME)
	await fade_out.finished

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		loading_label.text = "SCENE FAILED TO LOAD"
		await get_tree().create_timer(1.0, true, false, true).timeout
		_finish_transition()
		return

	await get_tree().process_frame
	await get_tree().create_timer(LOAD_HOLD_TIME, true, false, true).timeout
	var fade_in := create_tween()
	fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(blocker, "modulate:a", 0.0, FADE_TIME)
	await fade_in.finished
	_finish_transition()


func _finish_transition() -> void:
	blocker.visible = false
	blocker.modulate.a = 0.0
	loading_fill.size.x = 0.0
	transitioning = false
