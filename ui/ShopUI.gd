extends CanvasLayer
## Shop UI Screen — Display and purchase upgrades between runs.

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════════════════════════

signal continue_pressed

# ═══════════════════════════════════════════════════════════════════════════════
# REFERENCES
# ═══════════════════════════════════════════════════════════════════════════════

@onready var shards_label = $MainPanel/PanelContainer/VBox/Margin/Header/CoinsLabel
@onready var upgrades_container = $MainPanel/PanelContainer/VBox/ScrollWrap/ScrollContainer/UpgradesContainer
@onready var continue_button = $MainPanel/PanelContainer/VBox/Footer/ContinueButton

var economy_system

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)

func setup(econ_sys):
	economy_system = econ_sys
	economy_system.abyss_shards_changed.connect(_update_shards_display)
	economy_system.upgrade_purchased.connect(_refresh_upgrades)

func show_shop():
	visible = true
	_update_shards_display(economy_system.get_abyss_shards())
	_refresh_upgrades("")
	
	# Add Reset Button if not exists
	var reset_exists = false
	var container = $MainPanel/PanelContainer/VBox
	for child in container.get_children():
		if child.name == "ResetButton":
			reset_exists = true
			break
			
	if not reset_exists:
		var reset_btn = Button.new()
		reset_btn.name = "ResetButton"
		reset_btn.text = "RESET PROGRESS (DANGER)"
		reset_btn.modulate = Color(1.0, 0.3, 0.3)
		reset_btn.custom_minimum_size = Vector2(200, 40)
		reset_btn.size_flags_horizontal = 4
		reset_btn.pressed.connect(func():
			if economy_system: economy_system.reset_persistence()
			_refresh_upgrades("")
			_update_shards_display(0)
		)
		$MainPanel/PanelContainer/VBox.add_child(reset_btn)
		reset_btn.pressed.connect(func(): animate_button(reset_btn, func(): pass)) # Already connected reset logic above

func hide_shop():
	visible = false

# ═══════════════════════════════════════════════════════════════════════════════
# UI UPDATES
# ═══════════════════════════════════════════════════════════════════════════════

func _update_shards_display(amount: int):
	if shards_label:
		shards_label.text = "💎 %d Abyss Shards" % amount

func _refresh_upgrades(_upgrade_id: String):
	# Clear existing buttons
	for child in upgrades_container.get_children():
		child.queue_free()
	
	# Create upgrade buttons
	var upgrades = economy_system.get_all_upgrades()
	for upgrade_id in upgrades:
		var upgrade = upgrades[upgrade_id]
		var current_level = economy_system.get_upgrade_level(upgrade_id)
		var max_level = upgrade.max_level
		var cost = economy_system._calculate_cost(upgrade_id) if current_level < max_level else 0
		var can_buy = economy_system.can_purchase(upgrade_id)
		
		var button = _create_upgrade_button(upgrade_id, upgrade, current_level, max_level, cost, can_buy)
		upgrades_container.add_child(button)

func _create_upgrade_button(upgrade_id: String, upgrade: Dictionary, level: int, max_level: int, cost: int, can_buy: bool) -> Button:
	var button = Button.new()
	
	if level >= max_level:
		button.text = "%s [MAX]" % upgrade.name
		button.disabled = true
	else:
		button.text = "%s (Lv.%d/%d) - %d 💎" % [upgrade.name, level, max_level, cost]
		button.disabled = not can_buy
	
	button.tooltip_text = upgrade.description
	button.custom_minimum_size = Vector2(300, 50)
	
	button.pressed.connect(func(): _on_upgrade_pressed(upgrade_id, button))
	
	# Style
	if can_buy:
		button.modulate = Color(0.8, 1.0, 0.8)
	elif level >= max_level:
		button.modulate = Color(0.6, 0.6, 0.6)
	else:
		button.modulate = Color(1.0, 0.8, 0.8)
	
	return button

func animate_button(btn: Control, callback: Callable):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.05).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.05)
	tween.tween_callback(callback)

# ═══════════════════════════════════════════════════════════════════════════════
# HANDLERS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_upgrade_pressed(upgrade_id: String, btn: Control):
	animate_button(btn, func(): economy_system.purchase_upgrade(upgrade_id))

func _on_continue_pressed():
	animate_button(continue_button, func():
		hide_shop()
		continue_pressed.emit()
	)
