extends Node2D

const PLAYER_SPEED := 260.0
const PLAYER_SIZE := Vector2(42.0, 42.0)
const COIN_SIZE := Vector2(24.0, 24.0)
const PLAY_AREA := Rect2(Vector2(32.0, 72.0), Vector2(896.0, 488.0))

var score := 0
var player: ColorRect
var score_label: Label
var coins: Array[ColorRect] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.08, 0.09, 0.11))
	_build_demo()


func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	player.position += direction * PLAYER_SPEED * delta
	player.position = player.position.clamp(PLAY_AREA.position, PLAY_AREA.end - PLAYER_SIZE)
	_check_coin_pickups()


func _build_demo() -> void:
	var title := Label.new()
	title.text = "Coin Dash"
	title.position = Vector2(32.0, 18.0)
	title.add_theme_font_size_override("font_size", 30)
	add_child(title)

	score_label = Label.new()
	score_label.position = Vector2(760.0, 24.0)
	score_label.add_theme_font_size_override("font_size", 22)
	add_child(score_label)

	var hint := Label.new()
	hint.text = "Move with arrow keys or WASD"
	hint.position = Vector2(32.0, 538.0)
	hint.add_theme_font_size_override("font_size", 18)
	hint.modulate = Color(0.78, 0.82, 0.88)
	add_child(hint)

	var arena := ColorRect.new()
	arena.position = PLAY_AREA.position
	arena.size = PLAY_AREA.size
	arena.color = Color(0.14, 0.16, 0.19)
	add_child(arena)

	player = ColorRect.new()
	player.position = Vector2(112.0, 128.0)
	player.size = PLAYER_SIZE
	player.color = Color(0.28, 0.72, 1.0)
	add_child(player)

	var coin_positions := [
		Vector2(280.0, 150.0),
		Vector2(520.0, 250.0),
		Vector2(760.0, 180.0),
		Vector2(390.0, 430.0),
		Vector2(700.0, 440.0),
	]

	for coin_position in coin_positions:
		var coin := ColorRect.new()
		coin.position = coin_position
		coin.size = COIN_SIZE
		coin.color = Color(1.0, 0.78, 0.16)
		coins.append(coin)
		add_child(coin)

	_update_score()


func _check_coin_pickups() -> void:
	var player_rect := Rect2(player.position, player.size)

	for coin in coins:
		if coin.visible and player_rect.intersects(Rect2(coin.position, coin.size)):
			coin.visible = false
			score += 1
			_update_score()

	if score == coins.size():
		_respawn_coins()


func _respawn_coins() -> void:
	score = 0
	for coin in coins:
		coin.visible = true
	_update_score()


func _update_score() -> void:
	score_label.text = "Score: %d/%d" % [score, coins.size()]
