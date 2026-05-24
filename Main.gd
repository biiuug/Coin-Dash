extends Node2D

const FlappyRules = preload("res://FlappyRules.gd")

const VIEW_SIZE := Vector2(960.0, 540.0)
const BIRD_SIZE := Vector2(38.0, 38.0)
const BIRD_X := 180.0
const GRAVITY := 1450.0
const FLAP_VELOCITY := -440.0
const PIPE_WIDTH := 72.0
const PIPE_GAP := 150.0
const PIPE_SPEED := 250.0
const PIPE_SPACING := 315.0
const FLOOR_Y := 500.0
const CEILING_Y := 0.0

var rules := FlappyRules.new()
var bird: ColorRect
var score_label: Label
var message_label: Label
var medal_label: Label
var velocity_y := 0.0
var score := 0
var game_over := false
var pipe_pairs: Array[Dictionary] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.47, 0.78, 0.92))
	_build_scene()
	_start_game()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("flap"):
		if game_over:
			_start_game()
		else:
			velocity_y = FLAP_VELOCITY

	if game_over:
		return

	velocity_y += GRAVITY * delta
	bird.position.y += velocity_y * delta
	_update_pipes(delta)
	_check_collisions()


func _build_scene() -> void:
	var sky := ColorRect.new()
	sky.position = Vector2.ZERO
	sky.size = VIEW_SIZE
	sky.color = Color(0.47, 0.78, 0.92)
	add_child(sky)

	var floor := ColorRect.new()
	floor.name = "Floor"
	floor.position = Vector2(0.0, FLOOR_Y)
	floor.size = Vector2(VIEW_SIZE.x, VIEW_SIZE.y - FLOOR_Y)
	floor.color = Color(0.42, 0.70, 0.28)
	add_child(floor)

	bird = ColorRect.new()
	bird.name = "Bird"
	bird.size = BIRD_SIZE
	bird.color = Color(1.0, 0.82, 0.20)
	add_child(bird)

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.position = Vector2(32.0, 24.0)
	score_label.add_theme_font_size_override("font_size", 30)
	add_child(score_label)

	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.position = Vector2(220.0, 205.0)
	message_label.size = Vector2(520.0, 64.0)
	message_label.add_theme_font_size_override("font_size", 34)
	add_child(message_label)

	medal_label = Label.new()
	medal_label.name = "MedalLabel"
	medal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medal_label.position = Vector2(260.0, 268.0)
	medal_label.size = Vector2(440.0, 42.0)
	medal_label.add_theme_font_size_override("font_size", 22)
	add_child(medal_label)

	for index in range(3):
		pipe_pairs.append(_create_pipe_pair(620.0 + PIPE_SPACING * index))


func _start_game() -> void:
	score = 0
	game_over = false
	velocity_y = 0.0
	bird.position = Vector2(BIRD_X, 230.0)
	message_label.text = "Press Space or Click to flap"
	medal_label.text = ""

	for index in pipe_pairs.size():
		_reset_pipe_pair(pipe_pairs[index], 620.0 + PIPE_SPACING * index)

	_update_score()


func _create_pipe_pair(x_position: float) -> Dictionary:
	var top_pipe := ColorRect.new()
	top_pipe.color = Color(0.16, 0.58, 0.22)
	add_child(top_pipe)

	var bottom_pipe := ColorRect.new()
	bottom_pipe.color = Color(0.16, 0.58, 0.22)
	add_child(bottom_pipe)

	var pair := {
		"top": top_pipe,
		"bottom": bottom_pipe,
		"scored": false,
		"gap_y": 0.0,
	}
	_reset_pipe_pair(pair, x_position)
	return pair


func _reset_pipe_pair(pair: Dictionary, x_position: float) -> void:
	var gap_y := 135.0 + fmod((x_position * 1.37) + float(score * 53), 225.0)
	pair.gap_y = gap_y
	pair.scored = false

	var top_pipe: ColorRect = pair.top
	var bottom_pipe: ColorRect = pair.bottom
	top_pipe.position = Vector2(x_position, CEILING_Y)
	top_pipe.size = Vector2(PIPE_WIDTH, gap_y - PIPE_GAP * 0.5)
	bottom_pipe.position = Vector2(x_position, gap_y + PIPE_GAP * 0.5)
	bottom_pipe.size = Vector2(PIPE_WIDTH, FLOOR_Y - bottom_pipe.position.y)


func _update_pipes(delta: float) -> void:
	var farthest_x := 0.0
	for pair in pipe_pairs:
		var top_pipe: ColorRect = pair.top
		farthest_x = max(farthest_x, top_pipe.position.x)

	for pair in pipe_pairs:
		var top_pipe: ColorRect = pair.top
		var bottom_pipe: ColorRect = pair.bottom
		top_pipe.position.x -= PIPE_SPEED * delta
		bottom_pipe.position.x = top_pipe.position.x

		if rules.pipe_scored(top_pipe.position.x + PIPE_WIDTH, BIRD_X, pair.scored):
			pair.scored = true
			score += 1
			_update_score()
			message_label.text = ""

		if top_pipe.position.x + PIPE_WIDTH < 0.0:
			farthest_x += PIPE_SPACING
			_reset_pipe_pair(pair, farthest_x)


func _check_collisions() -> void:
	var bird_rect := Rect2(bird.position, bird.size)
	if bird.position.y <= CEILING_Y or bird.position.y + BIRD_SIZE.y >= FLOOR_Y:
		_end_game()
		return

	for pair in pipe_pairs:
		var top_pipe: ColorRect = pair.top
		var bottom_pipe: ColorRect = pair.bottom
		if bird_rect.intersects(Rect2(top_pipe.position, top_pipe.size)):
			_end_game()
			return
		if bird_rect.intersects(Rect2(bottom_pipe.position, bottom_pipe.size)):
			_end_game()
			return


func _end_game() -> void:
	game_over = true
	message_label.text = "Game Over - press Space to restart"
	medal_label.text = "Medal: %s" % rules.get_medal(score)


func _update_score() -> void:
	score_label.text = "Score: %d" % score
