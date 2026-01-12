extends CanvasLayer

@onready var score_label = $HUD/MarginContainer/TopBar/ScorePanel/ScoreLabel
@onready var pearl_label = $HUD/MarginContainer/TopBar/PearlPanel/HBox/PearlLabel
@onready var tool_name_label = $HUD/MarginContainer/BottomBar/EquipmentPanel/ToolName
@onready var zone_label = $HUD/MarginContainer/BottomBar/ZoneLabel

@onready var menu_layer = $MenuLayer
@onready var game_over_layer = $GameOverLayer
@onready var final_score_label = $GameOverLayer/GameOverPanel/PanelContainer/VBoxContainer/FinalScoreLabel
@onready var high_score_label = $MenuLayer/MenuPanel/PanelContainer/VBoxContainer/HighScoreLabel

signal start_requested
signal restart_requested

func _ready():
	show_menu()
	# Set simple text for tool (could be icon later)
	update_equipment("Bare Hands") 

func update_score(score: int):
	if score_label:
		score_label.text = "Depth: %dm" % score

func update_pearls(amount: int):
	if pearl_label:
		pearl_label.text = str(amount)

func update_equipment(tool_name: String):
	if tool_name_label:
		tool_name_label.text = tool_name

func update_zone(zone_name: String):
	if zone_label:
		zone_label.text = zone_name.to_upper()

func update_high_score(score: int):
	if high_score_label:
		high_score_label.text = "Max Depth: %dm" % score

func show_menu():
	menu_layer.visible = true
	game_over_layer.visible = false
	$HUD.visible = false

func show_game_over(final_score: int):
	menu_layer.visible = false
	game_over_layer.visible = true
	$HUD.visible = false
	final_score_label.text = "Reached: %dm" % final_score

func show_playing():
	menu_layer.visible = false
	game_over_layer.visible = false
	$HUD.visible = true

func _on_start_button_pressed():
	animate_button($MenuLayer/MenuPanel/PanelContainer/VBoxContainer/StartButton, func(): start_requested.emit())

func _on_restart_button_pressed():
	animate_button($GameOverLayer/GameOverPanel/PanelContainer/VBoxContainer/RestartButton, func(): restart_requested.emit())

func animate_button(btn: Control, callback: Callable):
	var tween = create_tween()
	# Pop effect
	tween.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_callback(callback)
