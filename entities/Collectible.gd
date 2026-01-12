extends Area2D
class_name Collectible
## Base class for all collectible entities in Abyss Diver.
## Tier system determines value and capture requirements.

# ═══════════════════════════════════════════════════════════════════════════════
# ENUMS & CONSTANTS
# ═══════════════════════════════════════════════════════════════════════════════

enum Type { PEARL, SMALL_FISH, MEDIUM_FISH, LARGE_FISH, TREASURE, SCRAP }
enum Tier { T1, T2, T3, T4, T5 }

const TYPE_CONFIG = {
	Type.PEARL:       {"tier": Tier.T1, "value": 10,  "color": Color(1.0, 1.0, 1.0),    "name": "Pearl",       "scale": 0.5, "speed": 200, "texture": "res://assets/coin_pearl.svg"},
	Type.SMALL_FISH:  {"tier": Tier.T2, "value": 25,  "color": Color(1.0, 1.0, 1.0),    "name": "Small Fish",  "scale": 0.6, "speed": 220, "texture": "res://assets/fish_small.svg"},
	Type.MEDIUM_FISH: {"tier": Tier.T3, "value": 50,  "color": Color(1.0, 1.0, 1.0),    "name": "Medium Fish", "scale": 0.8, "speed": 180, "texture": "res://assets/fish_medium.svg"},
	Type.LARGE_FISH:  {"tier": Tier.T4, "value": 100, "color": Color(1.0, 1.0, 1.0),    "name": "Large Fish",  "scale": 1.0, "speed": 150, "texture": "res://assets/fish_large.svg"},
	Type.TREASURE:    {"tier": Tier.T5, "value": 250, "color": Color(1.0, 1.0, 1.0),   "name": "Treasure",    "scale": 1.2, "speed": 120, "texture": "res://assets/treasure.svg"},
	Type.SCRAP:       {"tier": Tier.T1, "value": 15,  "color": Color(1.0, 0.8, 0.6),    "name": "Fish Scrap",  "scale": 0.4, "speed": 150, "texture": "res://assets/loot_scrap.svg"}
}

# Tool tiers required to capture each collectible tier
const TOOL_REQUIREMENTS = {
	Tier.T1: 0, # Hands
	Tier.T2: 1, # Net
	Tier.T3: 2, # Hook
	Tier.T4: 3, # Harpoon
	Tier.T5: 4  # Drone
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXPORTS & SIGNALS
# ═══════════════════════════════════════════════════════════════════════════════

@export var speed = 200.0
@export var collectible_type: Type = Type.PEARL

signal collected
signal missed

# ═══════════════════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════════════════

var config: Dictionary
var is_being_attracted = false

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	add_to_group("collectibles")
	
	config = TYPE_CONFIG.get(collectible_type, TYPE_CONFIG[Type.PEARL])
	
	# Apply visual based on type
	# Note: We reset color to white for custom sprites so they show their true colors
	modulate = config.get("color", Color.WHITE) 
	
	if config.has("texture"):
		var tex = load(config.texture)
		if tex:
			$Sprite2D.texture = tex
			
	speed = config.get("speed", 200)
	var target_scale = config.get("scale", 0.5)
	
	# Spawn animation with proper scale
	scale = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(target_scale, target_scale), 0.4)
	
	# Debug for visibility
	print("🐟 Spawned: %s (Value: %d)" % [config.name, config.value])

func _process(delta):
	position.y += speed * delta
	_handle_attraction(delta)
	
	if position.y > 700:
		missed.emit()
		queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════════

func get_value() -> int:
	return config.get("value", 10)

func get_tier() -> Tier:
	return config.get("tier", Tier.T1)

func get_required_tool_tier() -> int:
	return TOOL_REQUIREMENTS.get(get_tier(), 0)

func can_be_captured_by(tool_tier: int) -> bool:
	return tool_tier >= get_required_tool_tier()

# ═══════════════════════════════════════════════════════════════════════════════
# ATTRACTION SYSTEM (Hook/Magnet)
# ═══════════════════════════════════════════════════════════════════════════════

func _handle_attraction(delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.magnet_active:
		is_being_attracted = false
		return
	
	var dist = global_position.distance_to(player.global_position)
	if dist < player.magnet_range:
		is_being_attracted = true
		var direction = (player.global_position - global_position).normalized()
		position += direction * 550.0 * delta
		queue_redraw()
	else:
		is_being_attracted = false
		queue_redraw()

func _draw():
	if not is_being_attracted: return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var local_player_pos = to_local(player.global_position)
	draw_line(Vector2.ZERO, local_player_pos, Color(0.6, 0.6, 0.7, 0.8), 3.0)
	draw_circle(local_player_pos, 4.0, Color(0.8, 0.8, 0.9))

# ═══════════════════════════════════════════════════════════════════════════════
# COLLECTION
# ═══════════════════════════════════════════════════════════════════════════════

func _on_body_entered(body):
	if not body.is_in_group("player"): return
	
	# Check if player has required tool
	var player_tool_tier = _get_player_tool_tier(body)
	if not can_be_captured_by(player_tool_tier):
		# Can't capture - bounce away!
		_bounce_away()
		return
	
	# Successful collection
	collected.emit()
	
	# Pinata Mechanic: Medium/Large entities explode into smaller loot
	if config.tier >= Tier.T3: # Medium Fish, Large Fish, Treasure
		_explode_into_loot()
	
	set_deferred("monitoring", false)
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)

func _explode_into_loot():
	"""Spawn individual pearls/scraps in a burst."""
	var count = 3 if config.tier == Tier.T4 else 6
	var scene_path = "res://entities/Collectible.tscn"
	var collectible_scene = load(scene_path)
	
	# Determine what type of loot to drop
	var loot_type = Type.PEARL 
	if collectible_type == Type.LARGE_FISH or collectible_type == Type.MEDIUM_FISH:
		loot_type = Type.SCRAP
	
	for i in range(count):
		var loot = collectible_scene.instantiate()
		loot.collectible_type = loot_type
		loot.position = global_position
		
		# Give it some initial velocity/push
		get_parent().add_child(loot)
		
		var angle = randf() * TAU
		var mag = randf_range(50, 150)
		var jump_offset = Vector2(cos(angle), sin(angle)) * mag
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(loot, "position", loot.position + jump_offset, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _get_player_tool_tier(_player) -> int:
	# Check if player has equipment system
	var equip_sys = get_tree().get_first_node_in_group("equipment_system")
	if equip_sys and equip_sys.has_method("get_tool_tier"):
		return equip_sys.get_tool_tier()
	# Default: assume basic tool (can catch T1-T2)
	return 1

func _bounce_away():
	# Visual feedback for "can't capture"
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", config.color, 0.2)
	position.x += randf_range(-50, 50)
