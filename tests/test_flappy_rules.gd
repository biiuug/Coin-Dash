extends SceneTree

func _init() -> void:
	var rules_script := load("res://FlappyRules.gd")
	if rules_script == null:
		push_error("FlappyRules.gd is missing")
		quit(1)
		return

	var rules = rules_script.new()
	_assert_equal(rules.get_medal(0), "None", "zero score has no medal")
	_assert_equal(rules.get_medal(5), "Bronze", "five points earns bronze")
	_assert_equal(rules.get_medal(12), "Silver", "twelve points earns silver")
	_assert_equal(rules.get_medal(25), "Gold", "twenty-five points earns gold")
	_assert_true(rules.pipe_scored(100.0, 120.0, false), "unscored pipe behind player scores")
	_assert_false(rules.pipe_scored(180.0, 120.0, false), "pipe ahead of player does not score")
	_assert_false(rules.pipe_scored(140.0, 120.0, true), "already scored pipe does not score twice")
	quit()


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, expected, actual])
		quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		quit(1)


func _assert_false(value: bool, message: String) -> void:
	if value:
		push_error(message)
		quit(1)
