extends Node

signal score_updated(new_score)

var current_score = 0
var high_score = 0

func _ready():
	add_to_group("score_system")
	reset_score()

func add_score(amount: int):
	current_score += amount
	if current_score > high_score:
		high_score = current_score
	emit_signal("score_updated", current_score)

func reset_score():
	current_score = 0
	emit_signal("score_updated", current_score)

func set_high_score(value: int):
	high_score = value
	print("ScoreSystem: High Score Loaded -> ", high_score)

func get_score() -> int:
	return current_score

func get_high_score() -> int:
	return high_score
