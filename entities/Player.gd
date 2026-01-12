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
var is_dead = false # Prevents movement and actions
var has_extra_life = false
var extra_life_used = false
var trail: Node2D # Using generic Node2D or CPUParticles2D

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	add_to_group("player")
	
	# Update root sprite to new torso
	$Sprite2D.texture = load("res://assets/diver_v2_torso.svg")
	$Sprite2D.scale = Vector2(1.0, 1.0)
	
	# Initial Setup
	apply_upgrades()
	
	# Add Bubble Trail
	trail = load("res://entities/BubbleTrail.tscn").instantiate()
	trail.name = "BubbleTrail"
	trail.position = Vector2(0, 15)
	add_child(trail)
	
	_setup_hand_net()
	_setup_legs()

var leg_l: Sprite2D
var leg_r: Sprite2D
var anim_time = 0.0

func _setup_legs():
	# Container for legs to keep them behind body
	var legs_parent = Node2D.new()
	legs_parent.name = "LegsContainer"
	legs_parent.z_index = -1
	legs_parent.position = Vector2(0, 10) # Hip position
	add_child(legs_parent)
	
	# Assets
	var leg_tex = load("res://assets/diver_v2_leg.svg")
	var fin_tex = load("res://assets/diver_v2_fin.svg")
	
	# Left Leg
	leg_l = Sprite2D.new()
	leg_l.name = "LegL"
	leg_l.texture = leg_tex
	leg_l.offset = Vector2(0, 15) # Pivot at top
	leg_l.position = Vector2(-10, 0)
	legs_parent.add_child(leg_l)
	
	# Right Leg
	leg_r = Sprite2D.new()
	leg_r.name = "LegR"
	leg_r.texture = leg_tex
	leg_r.modulate = Color(0.8, 0.8, 0.9) # Subtle darkness for depth
	leg_r.offset = Vector2(0, 15)
	leg_r.position = Vector2(10, 0)
	legs_parent.add_child(leg_r)
	
	# Fins
	for leg in [leg_l, leg_r]:
		var fin = Sprite2D.new()
		fin.name = "Fin"
		fin.texture = fin_tex
		fin.position = Vector2(0, 32)
		fin.offset = Vector2(15, 0) # Pivot at base of fin
		leg.add_child(fin)

func _setup_hand_net():
	# Arm Container (Pivot point)
	var arm_pivot = Marker2D.new()
	arm_pivot.name = "ArmPivot"
	arm_pivot.position = Vector2(15, 10) # Aligned with new torso shoulder
	add_child(arm_pivot)
	
	# Arm Sprite
	var arm = Sprite2D.new()
	arm.name = "Arm"
	arm.texture = load("res://assets/diver_arm.svg")
	arm.offset = Vector2(10, 0) # Pivot at shoulder
	arm_pivot.add_child(arm)
	
	# Hand Net
	var net = Sprite2D.new()
	net.name = "HandNet"
	net.texture = load("res://assets/hand_net.svg")
	net.position = Vector2(22, 0)
	arm_pivot.add_child(net)
	
	# Hook
	var hook = Sprite2D.new()
	hook.name = "Hook"
	hook.texture = load("res://assets/tool_hook_small.svg")
	hook.position = Vector2(22, 0)
	arm_pivot.add_child(hook)
	
	# Harpoon
	var harpoon = Sprite2D.new()
	harpoon.name = "Harpoon"
	harpoon.texture = load("res://assets/tool_harpoon_small.svg")
	harpoon.position = Vector2(22, 0)
	arm_pivot.add_child(harpoon)
	
	# Drone (The small version)
	var drone = Sprite2D.new()
	drone.name = "Drone"
	drone.texture = load("res://assets/tool_drone.svg")
	drone.scale = Vector2(0.4, 0.4)
	drone.position = Vector2(22, 0)
	arm_pivot.add_child(drone)
	
	# Tool Rope (Line2D)
	var rope = Line2D.new()
	rope.name = "ToolRope"
	rope.width = 1.5
	rope.default_color = Color(0.55, 0.45, 0.35) # Rope brown
	rope.visible = false
	arm_pivot.add_child(rope)
	
	arm_pivot.visible = false

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
	var pivot = get_node_or_null("ArmPivot")
	if not pivot: return
	
	# Determine active tool name
	var tool_name = ""
	match tier:
		1: tool_name = "HandNet"
		2: tool_name = "Hook"
		3: tool_name = "Harpoon"
		4: tool_name = "Drone"
	
	# Show/Hide correct tool for idle state (if desired)
	# For now, we only show tools during capture per user request focus
	# But we can keep them ready here
	for child in pivot.get_children():
		if child is Sprite2D and child.name != "Arm":
			child.visible = (child.name == tool_name)
	
	# Keep pivot hidden until capture starts
	pivot.visible = false

# ═══════════════════════════════════════════════════════════════════════════════
# PHYSICS
# ═══════════════════════════════════════════════════════════════════════════════

func _physics_process(delta):
	if is_dead: return # No movement if dead
	
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
	if trail:
		trail.emitting = velocity.length() > 50
		if is_dashing:
			trail.amount = 30
			trail.speed_scale = 2.0
		else:
			trail.amount = 12
			trail.speed_scale = 0.8
	
	_animate_swimming(delta)
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
	_animate_dash_vfx()

func _animate_dash_vfx():
	# Intense kick flare
	var tween = create_tween().set_parallel(true)
	tween.tween_property(leg_l, "scale", Vector2(1.2, 1.5), 0.1)
	tween.tween_property(leg_r, "scale", Vector2(1.2, 1.5), 0.1)
	tween.set_parallel(false)
	tween.tween_property(leg_l, "scale", Vector2(0.8, 1.2), 0.2)
	tween.tween_property(leg_r, "scale", Vector2(0.8, 1.2), 0.2)
	
	_play_tool_animation()

func _animate_swimming(delta: float):
	if not leg_l or not leg_r: return
	
	var current_vel = velocity.length()
	var is_moving = current_vel > 10.0
	
	# Adjust animation speed based on velocity
	var freq = 5.0
	var amp = 15.0 # Degrees
	
	if is_moving:
		freq = 12.0 * (current_vel / speed)
		amp = 25.0 * (current_vel / speed)
	else:
		# Idle treading water
		freq = 3.0
		amp = 5.0
	
	if is_dashing:
		freq = 25.0
		amp = 40.0
	
	anim_time += delta * freq
	
	# Sinusoidal kick
	var leg_rot = sin(anim_time) * amp
	leg_l.rotation_degrees = leg_rot
	leg_r.rotation_degrees = -leg_rot
	
	# Fin flex (extra juice)
	var fin_l = leg_l.get_node("Fin")
	var fin_r = leg_r.get_node("Fin")
	if fin_l and fin_r:
		fin_l.rotation_degrees = 90 + (leg_rot * 0.5)
		fin_r.rotation_degrees = 90 - (leg_rot * 0.5)
	
	# Body bobbing and tilting
	var bob = cos(anim_time * 0.5) * 3.0
	var tilt = clamp(velocity.x * 0.05, -15.0, 15.0)
	
	if is_dead:
		# Very subtle sinking bob
		bob = cos(anim_time * 0.2) * 5.0
		tilt = $Sprite2D.rotation_degrees # Keep whatever tilt it had
		
	$Sprite2D.position.y = bob
	$Sprite2D.rotation_degrees = tilt
	$ArmPivot.position.y = 10 + bob # Updated offset for new torso
	$ArmPivot.rotation_degrees = tilt
	
	# Legs follow tilt but slightly delayed for fluid look
	var legs_node = get_node("LegsContainer")
	if legs_node:
		legs_node.rotation_degrees = lerp(legs_node.rotation_degrees, tilt * 0.5, 0.1)
		legs_node.position.y = 20 + bob

func _play_tool_animation():
	# Simple forward tilt on dash
	var pivot = get_node_or_null("ArmPivot")
	if not pivot: return
	
	var tween = create_tween()
	pivot.visible = true
	tween.tween_property(pivot, "rotation_degrees", 45.0, 0.1).set_trans(Tween.TRANS_BACK)
	tween.tween_property(pivot, "rotation_degrees", 0.0, 0.2).set_delay(0.1)
	tween.tween_callback(func(): pivot.visible = false)

func trigger_capture_vfx(tier: int, target_pos: Vector2):
	"""Visual feedback unique to each tool tier."""
	_animate_tool_capture(target_pos, tier)
	
	# Spawn impact effect
	var effect = load("res://entities/CaptureEffect.tscn").instantiate()
	effect.global_position = target_pos
	get_parent().add_child(effect)
	
	var color = Color.YELLOW # Default
	match tier:
		1: color = Color.WHITE
		2: color = Color.ROYAL_BLUE
		3: color = Color.DARK_ORANGE
		4: color = Color.CYAN
	
	effect.setup(color, tier)

func _animate_tool_capture(target_pos: Vector2, tier: int):
	if is_dead: return
	
	var pivot = get_node_or_null("ArmPivot")
	var arm = pivot.get_node_or_null("Arm") if pivot else null
	var rope = pivot.get_node_or_null("ToolRope") if pivot else null
	if not pivot or not arm or not rope: return
	
	# 1. Selection
	var tool_name = ""
	match tier:
		1: tool_name = "HandNet"
		2: tool_name = "Hook"
		3: tool_name = "Harpoon"
		4: tool_name = "Drone"
	
	for child in pivot.get_children():
		if child is Sprite2D and child.name != "Arm":
			child.visible = (child.name == tool_name)
	
	# Rope setup
	rope.clear_points()
	rope.visible = (tier == 2 or tier == 3)
	if tier == 2: # Hook: Brown rope
		rope.default_color = Color(0.55, 0.45, 0.35)
		rope.width = 2.0
	elif tier == 3: # Harpoon: Steel cable
		rope.default_color = Color(0.7, 0.7, 0.8)
		rope.width = 1.0
	
	pivot.visible = true
	
	# 2. Physics / Aim
	var local_target = to_local(target_pos) - pivot.position
	var angle = local_target.angle()
	var dist = clamp(local_target.length(), 30.0, 160.0)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(pivot, "rotation", angle, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 3. Motion Profiles
	match tier:
		0: # BARE HANDS: Arm extension
			tween.tween_property(arm, "scale:x", 1.8, 0.1).set_trans(Tween.TRANS_CUBIC)
		1: # NET: Scoop
			var net = pivot.get_node("HandNet")
			tween.tween_property(net, "position:x", dist * 0.5, 0.1).set_trans(Tween.TRANS_BACK)
			tween.tween_property(net, "scale", Vector2(1.6, 1.6), 0.1)
			tween.tween_property(arm, "scale:x", 1.4, 0.1)
		2, 3: # HOOK / HARPOON: Extend with Rope
			var active_tool = pivot.get_node(tool_name)
			var time = 0.1 if tier == 2 else 0.05
			
			# Thrust tool
			tween.tween_property(active_tool, "position:x", dist, time).set_trans(Tween.TRANS_EXPO)
			
			# Sync Rope points in process (better than tween_method for real-time tracking)
			var rope_sync = create_tween()
			rope_sync.tween_method(func(_v):
				rope.clear_points()
				rope.add_point(Vector2(10, 0)) # shoulder
				rope.add_point(active_tool.position) # tool tip
			, 0.0, 1.0, time)
			
		4: # DRONE: Launch and Return
			var drone = pivot.get_node("Drone")
			var global_start = drone.global_position
			drone.top_level = true
			drone.global_position = global_start
			tween.tween_property(drone, "global_position", target_pos, 0.2).set_trans(Tween.TRANS_CUBIC)
			
	# 4. Cleanup / Return (Reeling)
	tween.set_parallel(false)
	tween.tween_interval(0.08) # Hit-stop feel
	
	var back = create_tween().set_parallel(true)
	back.tween_property(pivot, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	back.tween_property(arm, "scale:x", 1.0, 0.2)
	
	# Reel Rope and Tool
	var reel_tool = pivot.get_node_or_null(tool_name)
	if reel_tool and (tier == 2 or tier == 3):
		var back_time = 0.3 if tier == 2 else 0.15
		back.tween_property(reel_tool, "position:x", 22.0, back_time).set_trans(Tween.TRANS_BACK)
		
		var rope_reel = create_tween()
		rope_reel.tween_method(func(_v):
			rope.clear_points()
			rope.add_point(Vector2(10, 0))
			rope.add_point(reel_tool.position)
		, 0.0, 1.0, back_time)
		
	elif tier == 4 and reel_tool: # Drone return
		var target_loc = pivot.global_position + Vector2(22, 0)
		back.tween_property(reel_tool, "global_position", target_loc, 0.25)
		back.set_parallel(false)
		back.tween_callback(func(): 
			reel_tool.top_level = false
			reel_tool.position = Vector2(22, 0)
			pivot.visible = false
		)
	
	if tier != 4:
		back.set_parallel(false)
		back.tween_callback(func(): 
			pivot.visible = false
			rope.visible = false
			if reel_tool: reel_tool.position = Vector2(22, 0)
			arm.scale.x = 1.0
			pivot.rotation = 0
		)

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
func trigger_death(type: int):
	"""Handles unique death sequences for each enemy type."""
	if is_dead: return
	is_dead = true
	
	# Stop any current dash/move
	velocity = Vector2.ZERO
	if trail: trail.emitting = false
	
	var tween = create_tween()
	
	match type:
		0, 1: # MINE / DRIFTING_MINE
			# Flash red, shake violently, explode
			tween.tween_property(self, "modulate", Color.ORANGE_RED, 0.1)
			tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
			tween.tween_property(self, "modulate", Color.BLACK, 0.2)
			tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.2)
			
		2: # JELLYFISH
			# Shock effect: flicker white/blue, sink slowly
			for i in range(5):
				tween.tween_property(self, "modulate", Color(2, 2, 5), 0.05) # Over-bright blue
				tween.tween_property(self, "modulate", Color.WHITE, 0.05)
			
			# Sink away
			tween.tween_property(self, "position:y", position.y + 100, 1.5).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(self, "modulate:a", 0.0, 1.5)
			
		3: # SHARK
			# Eaten: sudden camera snap, diver vanishes
			tween.tween_property(self, "scale", Vector2(1.2, 0.2), 0.05) # Squashed
			tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
			tween.parallel().tween_property(self, "modulate", Color.RED, 0.1)

	tween.tween_callback(func(): visible = false)

func reset():
	"""Restores the player to a clean state for a new run."""
	is_dead = false
	visible = true
	scale = Vector2(1, 1)
	modulate = Color.WHITE
	rotation = 0
	velocity = Vector2.ZERO
	position = Vector2(576, 500) # Default start position
	
	if trail:
		trail.emitting = true
	
	# Reset visual components
	$Sprite2D.position = Vector2.ZERO
	$Sprite2D.rotation = 0
	
	var pivot = get_node_or_null("ArmPivot")
	if pivot:
		pivot.visible = false
		pivot.rotation = 0
		var arm = pivot.get_node_or_null("Arm")
		if arm: arm.scale.x = 1.0
	
	var legs = get_node_or_null("LegsContainer")
	if legs:
		legs.rotation = 0
		legs.position = Vector2(0, 10)
