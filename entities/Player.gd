extends CharacterBody2D
## Player controller with shop upgrade support.

signal dashed

# ═══════════════════════════════════════════════════════════════════════════════
# BASE STATS (Modified by shop upgrades)
# ═══════════════════════════════════════════════════════════════════════════════

@export var base_speed = 650.0
@export var dash_speed = 900.0
@export var dash_duration = 0.2
@export var friction = 2500.0
@export var acceleration = 4000.0
@export var base_magnet_range = 250.0

# ═══════════════════════════════════════════════════════════════════════════════
# RUNTIME STATE
# ═══════════════════════════════════════════════════════════════════════════════

var speed = 650.0
var is_dashing = false
var dash_timer = 0.0
var magnet_active = false
var magnet_range = 250.0
var has_extra_life = false
var extra_life_used = false

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	add_to_group("player")
	apply_upgrades()
	
	# Add Bubble Trail
	var trail = load("res://entities/BubbleTrail.tscn").instantiate()
	trail.name = "BubbleTrail"
	trail.position = Vector2(0, 15)
	add_child(trail)

func apply_upgrades():
	"""Apply shop upgrades to player stats."""
	var economy = get_tree().get_first_node_in_group("economy_system")
	if not economy:
		speed = base_speed
		magnet_range = base_magnet_range
		return
	
	# Speed Boost: +10% per level
	speed = base_speed * economy.get_speed_multiplier()
	
	# Magnet Range: +25% per level
	magnet_range = base_magnet_range * economy.get_magnet_range_multiplier()
	
	# Extra Life
	has_extra_life = economy.has_extra_life()
	extra_life_used = false
	
	# Update Tool Visuals
	var equip_sys = get_tree().get_first_node_in_group("equipment_system")
	if equip_sys:
		update_tool_visual(equip_sys.get_tool_tier())
	
	print("🎮 Player Upgrades Applied:")
	print("   Speed: %.0f (%.0fx)" % [speed, economy.get_speed_multiplier()])
	print("   Magnet Range: %.0f (%.0fx)" % [magnet_range, economy.get_magnet_range_multiplier()])
	print("   Extra Life: %s" % has_extra_life)

func update_tool_visual(tier: int):
	# Create sprite if not exists
	var tool_sprite = get_node_or_null("ToolSprite")
	if not tool_sprite:
		tool_sprite = Sprite2D.new()
		tool_sprite.name = "ToolSprite"
		tool_sprite.position = Vector2(0, 10) # Offset from center
		tool_sprite.scale = Vector2(0.5, 0.5)
		add_child(tool_sprite)
	
	# Load tool texture
	var tex_path = ""
	match tier:
		1: tex_path = "res://assets/tool_net.svg"
		2: tex_path = "res://assets/tool_hook.svg"
		3: tex_path = "res://assets/tool_harpoon.svg"
		4: tex_path = "res://assets/tool_drone.svg"
		_: tex_path = "" # Hands (no tool)
	
	if tex_path != "":
		tool_sprite.texture = load(tex_path)
		tool_sprite.visible = true
	else:
		tool_sprite.visible = false

# ═══════════════════════════════════════════════════════════════════════════════
# PHYSICS
# ═══════════════════════════════════════════════════════════════════════════════

func _physics_process(delta):
	# Dashing Logic
	if Input.is_action_just_pressed("ui_accept") and not is_dashing:
		start_dash()
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity = velocity.limit_length(speed)
	
	# Movement Logic
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if is_dashing:
		pass # Maintain dash velocity
	else:
		if direction.length() > 0:
			velocity = velocity.move_toward(direction * speed, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			
	# Apply Tilt
	if velocity.x != 0:
		rotation_degrees = lerp(rotation_degrees, velocity.x / speed * 15.0, 0.2)
	else:
		rotation_degrees = lerp(rotation_degrees, 0.0, 0.2)
	
	# Update Bubble Trail
	var trail = get_node_or_null("BubbleTrail")
	if trail:
		trail.emitting = velocity.length() > 50
		if is_dashing:
			trail.amount = 30
			trail.speed_scale = 2.0
		else:
			trail.amount = 12
			trail.speed_scale = 0.8
	
	move_and_slide()
	
	# Clamp Position
	position.x = clamp(position.x, 180, 972)
	position.y = clamp(position.y, 50, 600)

# ═══════════════════════════════════════════════════════════════════════════════
# ABILITIES
# ═══════════════════════════════════════════════════════════════════════════════

func enable_magnet():
	if magnet_active: return
	magnet_active = true
	print("🧲 Magnet Activated! Range: %.0f" % magnet_range)
	
	# Add Area2D dynamically
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = magnet_range
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.area_entered.connect(_on_magnet_area_entered)

func _on_magnet_area_entered(_area):
	pass # Logic handled in Collectible.gd

func start_dash():
	is_dashing = true
	dash_timer = dash_duration
	
	var dash_dir = velocity.normalized()
	if dash_dir == Vector2.ZERO:
		dash_dir = Vector2.RIGHT
		
	velocity = dash_dir * dash_speed
	dashed.emit()
	_play_tool_animation()

func _play_tool_animation():
	var tool_sprite = get_node_or_null("ToolSprite")
	if not tool_sprite or not tool_sprite.visible: return
	
	var tween = create_tween().set_parallel(true)
	# Quick thrust/swing forward
	tween.tween_property(tool_sprite, "position:x", 15.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(tool_sprite, "rotation_degrees", 20.0, 0.1)
	
	# Return to normal
	var back_tween = create_tween().set_parallel(true)
	back_tween.tween_property(tool_sprite, "position:x", 0.0, 0.2).set_delay(0.1)
	back_tween.tween_property(tool_sprite, "rotation_degrees", 0.0, 0.2).set_delay(0.1)

func trigger_capture_vfx(tier: int, target_pos: Vector2):
	"""Visual feedback unique to each tool tier."""
	match tier:
		0: # Bare Hands: Simple flash
			var effect = load("res://entities/CaptureEffect.tscn").instantiate()
			effect.global_position = target_pos
			get_parent().add_child(effect)
			effect.setup(Color.YELLOW, 0)
		1: # Net: Scaling white circle
			var effect = load("res://entities/CaptureEffect.tscn").instantiate()
			effect.global_position = target_pos
			get_parent().add_child(effect)
			effect.setup(Color.WHITE, 1)
		2, 3: # Hook/Harpoon: Line thrust
			var line = Line2D.new()
			line.width = 4.0 if tier == 2 else 10.0
			line.default_color = Color(0.9, 0.9, 1.0, 0.7)
			line.add_point(global_position)
			line.add_point(target_pos)
			get_parent().add_child(line)
			
			var tween = create_tween()
			tween.tween_property(line, "modulate:a", 0.0, 0.1)
			tween.tween_callback(line.queue_free)
		4: # Drone: Pulse ring
			var effect = load("res://entities/CaptureEffect.tscn").instantiate()
			effect.global_position = target_pos
			effect.scale = Vector2(0.5, 0.5)
			get_parent().add_child(effect)
			effect.setup(Color.CYAN, 4)
			var tween = create_tween()
			tween.tween_property(effect, "scale", Vector2(4.0, 4.0), 0.2)

func get_magnet_position():
	return global_position

# ═══════════════════════════════════════════════════════════════════════════════
# DAMAGE
# ═══════════════════════════════════════════════════════════════════════════════

func take_damage() -> bool:
	"""Returns true if player survives (has extra life)."""
	if has_extra_life and not extra_life_used:
		extra_life_used = true
		print("💀 Extra Life Used!")
		# Visual feedback
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.RED, 0.1)
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		return true
	return false
