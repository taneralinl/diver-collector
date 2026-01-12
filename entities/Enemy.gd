extends Area2D
class_name Enemy
## Base class for all enemy entities in Abyss Diver.
## Type system determines behavior and danger level.

# ═══════════════════════════════════════════════════════════════════════════════
# ENUMS & CONSTANTS
# ═══════════════════════════════════════════════════════════════════════════════

enum Type { MINE, DRIFTING_MINE, JELLYFISH, SHARK }

const TYPE_CONFIG = {
	Type.MINE:          {"speed": 300, "color": Color(0.4, 0.4, 0.4), "behavior": "fall",  "scale": 0.7, "name": "Mine", "texture": "res://assets/obstacle_mine.svg"},
	Type.DRIFTING_MINE: {"speed": 280, "color": Color(1.0, 0.3, 0.3), "behavior": "drift", "scale": 0.8, "name": "Drifting Mine", "texture": "res://assets/obstacle_mine.svg"},
	Type.JELLYFISH:     {"speed": 80,  "color": Color(1.0, 1.0, 1.0), "behavior": "pulse",  "scale": 0.9, "name": "Jellyfish", "texture": "res://assets/enemy_jellyfish.svg"},
	Type.SHARK:         {"speed": 400, "color": Color(1.0, 1.0, 1.0), "behavior": "chase", "scale": 1.1, "name": "Shark", "texture": "res://assets/enemy_shark.svg"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXPORTS & SIGNALS
# ═══════════════════════════════════════════════════════════════════════════════

@export var enemy_type: Type = Type.MINE

signal hit_player

# ═══════════════════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════════════════

var config: Dictionary
var drift_direction = 0.0
var drift_speed = 100.0
var track_speed = 80.0

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	add_to_group("enemies")
	# Ensure collision is detected
	body_entered.connect(_on_body_entered)
	
	config = TYPE_CONFIG.get(enemy_type, TYPE_CONFIG[Type.MINE])
	
	# Apply visual
	# Note: We reset color to white for custom sprites so they show their true colors
	modulate = config.get("color", Color.WHITE) 
	
	if config.has("texture"):
		var tex = load(config.texture)
		if tex:
			$Sprite2D.texture = tex
			
	var target_scale = config.get("scale", 0.7)
	
	# Setup behavior-specific state
	match config.behavior:
		"drift":
			drift_direction = randf_range(-1.0, 1.0)
		"track", "chase":
			pass # Will track player in _process
	
	# Spawn animation with proper scale
	scale = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(target_scale, target_scale), 0.5)
	
	# Debug for visibility
	print("👾 Spawned: %s (Behavior: %s)" % [config.name, config.behavior])

func _process(delta):
	var speed = config.get("speed", 300)
	
	if config.behavior == "pulse":
		position.y -= speed * delta # Rise up
		_do_pulse(delta)
		if position.y < -100: queue_free()
	else:
		position.y += speed * delta # Fall down
		if position.y > 800: queue_free()
	
	# Behavior-specific movement
	match config.behavior:
		"drift": _do_drift(delta)
		"track": _do_track(delta, track_speed)
		"chase": _do_track(delta, track_speed * 2.5)

# ═══════════════════════════════════════════════════════════════════════════════
# BEHAVIORS
# ═══════════════════════════════════════════════════════════════════════════════

func _do_drift(delta):
	position.x += drift_direction * drift_speed * delta
	# Bounce off walls
	if position.x < 180 or position.x > 970:
		drift_direction *= -1

func _do_track(delta, spd):
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var diff = player.global_position.x - global_position.x
	if abs(diff) > 10:
		position.x += sign(diff) * spd * delta

func _do_pulse(delta):
	# Pulsing scale effect
	var pulse = sin(Time.get_ticks_msec() * 0.005) * 0.1
	scale = Vector2(config.scale + pulse, config.scale + pulse)
	
	# Sways slightly
	position.x += sin(Time.get_ticks_msec() * 0.002) * 20.0 * delta

# ═══════════════════════════════════════════════════════════════════════════════
# COLLISION
# ═══════════════════════════════════════════════════════════════════════════════

func _on_body_entered(body):
	if body.is_in_group("player"):
		hit_player.emit()
		
		# VFX: Explosion for Mines
		if enemy_type == Type.MINE or enemy_type == Type.DRIFTING_MINE:
			_spawn_explosion()
		
		# Disappear
		set_deferred("monitoring", false)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(queue_free)

func _spawn_explosion():
	var effect = load("res://entities/CollectionEffect.tscn").instantiate()
	effect.position = global_position
	effect.modulate = Color(1, 0.5, 0.2) # Firey color
	effect.scale_amount_min = 0.5
	effect.scale_amount_max = 1.2
	get_parent().add_child(effect)
