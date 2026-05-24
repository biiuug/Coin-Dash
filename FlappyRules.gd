extends RefCounted


func get_medal(score: int) -> String:
	if score >= 25:
		return "Gold"
	if score >= 12:
		return "Silver"
	if score >= 5:
		return "Bronze"
	return "None"


func pipe_scored(pipe_right_edge: float, bird_x: float, already_scored: bool) -> bool:
	return not already_scored and pipe_right_edge < bird_x
