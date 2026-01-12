extends Node

signal game_started
signal game_over

enum State {
	MENU,
	PLAYING,
	GAME_OVER
}

var current_state = State.MENU

func start_game():
	current_state = State.PLAYING
	emit_signal("game_started")
	print("GameState: GAME STARTED")

func end_game():
	current_state = State.GAME_OVER
	emit_signal("game_over")
	print("GameState: GAME OVER")

func reset_to_menu():
	current_state = State.MENU
	# Reload scene logic usually handled by Main
