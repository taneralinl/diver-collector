extends Node2D
## Main Orchestrator — Initializes and connects all game systems.

# ═══════════════════════════════════════════════════════════════════════════════
# SYSTEM REFERENCES
# ═══════════════════════════════════════════════════════════════════════════════

var spawner_system
var score_system
var game_state_system
var persistence_system
var progression_system
var sound_manager
var depth_layer_system
var equipment_system
var economy_system
var game_ui
var shop_ui
var transition_ui

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	print("🎮 Abyss Diver [v0.0.0.1] Starting... Initializing Systems")
	_initialize_systems()

func _initialize_systems():
	# 0. UI System & Background
	var bg = load("res://ui/Background.tscn").instantiate()
	add_child(bg)
	
	game_ui = load("res://ui/GameUI.tscn").instantiate()
	game_ui.name = "GameUI"
	add_child(game_ui)
	
	transition_ui = load("res://ui/TransitionUI.tscn").instantiate()
	add_child(transition_ui)
	
	# QA System
	var qa_system = load("res://systems/qa/QASystem.gd").new()
	qa_system.name = "QASystem"
	add_child(qa_system)
	
	# 1. Score System
	score_system = load("res://systems/scoring/ScoreSystem.gd").new()
	score_system.name = "ScoreSystem"
	add_child(score_system)
	score_system.score_updated.connect(_on_score_updated)
	
	# 2. Spawner System
	spawner_system = load("res://systems/spawner/SpawnerSystem.gd").new()
	spawner_system.name = "SpawnerSystem"
	add_child(spawner_system)
	spawner_system.stop_spawning()
	
	# Load new entity scenes
	spawner_system.collectible_scene = load("res://entities/Collectible.tscn")
	spawner_system.enemy_scene = load("res://entities/Enemy.tscn")
	
	spawner_system.collectible_spawned.connect(_on_collectible_spawned)
	spawner_system.enemy_spawned.connect(_on_enemy_spawned)
	
	# 3. Game State System
	game_state_system = load("res://systems/game_state/GameStateSystem.gd").new()
	game_state_system.name = "GameStateSystem"
	add_child(game_state_system)
	
	# 4. Persistence System
	persistence_system = load("res://systems/persistence/PersistenceSystem.gd").new()
	persistence_system.name = "PersistenceSystem"
	add_child(persistence_system)
	
	# Load High Score
	var saved_high_score = persistence_system.load_high_score()
	score_system.set_high_score(saved_high_score)
	game_ui.update_high_score(saved_high_score)
	
	# Wiring Signals
	game_state_system.game_started.connect(_on_game_started)
	game_state_system.game_over.connect(_on_game_over)
	
	# UI Signals
	game_ui.start_requested.connect(_on_start_requested)
	game_ui.restart_requested.connect(_on_restart_requested)

	# 5. Progression System
	var prog_sys = load("res://systems/progression/ProgressionSystem.gd").new()
	prog_sys.name = "ProgressionSystem"
	add_child(prog_sys)
	prog_sys.setup(spawner_system, score_system)
	self.progression_system = prog_sys

	# 6. Audio System
	var snd_mgr = load("res://systems/audio/SoundManager.gd").new()
	snd_mgr.name = "SoundManager"
	add_child(snd_mgr)
	self.sound_manager = snd_mgr

	# 7. Depth Layer System
	var depth_sys = load("res://systems/depth/DepthLayerSystem.gd").new()
	depth_sys.name = "DepthLayerSystem"
	add_child(depth_sys)
	self.depth_layer_system = depth_sys

	# 8. Equipment System
	equipment_system = load("res://systems/equipment/EquipmentSystem.gd").new()
	equipment_system.name = "EquipmentSystem"
	add_child(equipment_system)
	equipment_system.tool_upgraded.connect(_on_tool_upgraded)

	# 9. Economy System
	economy_system = load("res://systems/economy/EconomySystem.gd").new()
	economy_system.name = "EconomySystem"
	add_child(economy_system)
	
	# Connect Economy Signals to UI
	economy_system.pearls_changed.connect(game_ui.update_pearls)
	economy_system.save_requested.connect(func(): persistence_system.save_all(economy_system))

	# Connect Depth Signals to UI
	if depth_layer_system:
		depth_layer_system.layer_changed.connect(func(zone):
			game_ui.update_zone(zone)
			game_ui.show_notification("%s REACHED" % zone.to_upper())
		)
	
	# Load saved economy data
	economy_system.set_abyss_shards(persistence_system.load_abyss_shards())
	economy_system.set_purchased_upgrades(persistence_system.load_upgrades())

	# 10. Shop UI
	shop_ui = load("res://ui/ShopUI.tscn").instantiate()
	shop_ui.name = "ShopUI"
	add_child(shop_ui)
	shop_ui.setup(economy_system)
	shop_ui.continue_pressed.connect(_on_shop_continue)

	print("✅ All Systems Initialized")

# ═══════════════════════════════════════════════════════════════════════════════
# GAME STATE HANDLERS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_start_requested():
	if transition_ui:
		await transition_ui.fade_out()
		game_state_system.start_game()
		await transition_ui.fade_in()
	else:
		game_state_system.start_game()

func _on_game_started():
	score_system.reset_score()
	spawner_system.clear_entities()
	if progression_system:
		progression_system.reset_difficulty()
	if depth_layer_system:
		depth_layer_system.reset()
	if equipment_system:
		equipment_system.reset()
	if economy_system:
		economy_system.reset_run()
	
	# Reset UI visuals
	game_ui.update_score(0)
	game_ui.update_pearls(0)
	game_ui.update_zone("Shallows")
	if equipment_system:
		game_ui.update_equipment(equipment_system.get_tool_name())
	
	spawner_system.start_spawning()
	game_ui.show_playing()
	
	# Reset Player
	var player = $Player
	if player:
		if not player.is_in_group("player"): 
			player.add_to_group("player")
		player.position = Vector2(576, 500)
		player.visible = true
		player.magnet_active = false
		
		# Apply shop upgrades to player
		if player.has_method("apply_upgrades"):
			player.apply_upgrades()
		
		if player.has_signal("dashed") and not player.dashed.is_connected(_on_player_dashed):
			player.dashed.connect(_on_player_dashed)
			
	$Camera2D.position = Vector2(576, 324)

func _on_game_over():
	spawner_system.stop_spawning()
	shake_screen(10.0, 0.5)
	if sound_manager: 
		sound_manager.play_hit_sfx()
	
	var final_score = score_system.get_score()
	var current_high = score_system.get_high_score()
	
	if final_score > current_high:
		persistence_system.save_high_score(final_score)
		game_ui.update_high_score(final_score)
	
	# Convert run pearls to abyss shards
	if economy_system:
		var depth_bonus = 1.0 + (depth_layer_system.current_layer / 500.0) if depth_layer_system else 1.0
		economy_system.convert_pearls_to_shards(depth_bonus)
		persistence_system.save_all(economy_system)
	
	game_ui.show_game_over(final_score)

# ═══════════════════════════════════════════════════════════════════════════════
# ENTITY HANDLERS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_collectible_spawned(collectible):
	if collectible.has_signal("collected"):

		collectible.collected.connect(func(): 
			var value = collectible.get_value()
			score_system.add_score(value)
			
			# VFX: Specialized Tool Feedback (Shows the CURRENT tool in action)
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("trigger_capture_vfx") and equipment_system:
				player.trigger_capture_vfx(equipment_system.get_tool_tier(), collectible.position)
			
			# VFX: Spawn Particles
			var effect = load("res://entities/CollectionEffect.tscn").instantiate()
			effect.position = collectible.position
			
			# Customize particles based on tier
			if value < 25: # Small pearl
				effect.scale_amount_min = 0.1
				effect.scale_amount_max = 0.2
				effect.amount = 3
			else: # Bigger fish
				effect.scale_amount_min = 0.3
				effect.scale_amount_max = 0.6
				effect.amount = 8
				shake_screen(3.0, 0.2)
				
				# Hit Stop (Juice)
				if value >= 100: # Large targets
					Engine.time_scale = 0.05
					await get_tree().create_timer(0.05, true, false, true).timeout
					Engine.time_scale = 1.0
			
			add_child(effect)
			
			# Track pearls for economy
			if economy_system:
				economy_system.add_pearls(value)
			if sound_manager: 
				sound_manager.play_capture_sfx(collectible.config.tier)
		)

func _on_enemy_spawned(enemy):
	if enemy.has_signal("hit_player"):
		enemy.hit_player.connect(func(): _on_player_hit())

# ═══════════════════════════════════════════════════════════════════════════════
# SCORE & PROGRESSION HANDLERS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_score_updated(new_score):
	if game_ui:
		game_ui.update_score(new_score)
	
	# Update Depth Layer visuals
	if depth_layer_system:
		depth_layer_system.update_depth(new_score)
	
	# Parallax Background Scroll & Ray Fade
	var bg = get_tree().get_first_node_in_group("background")
	if bg and bg is ParallaxBackground:
		bg.scroll_offset.y = new_score * 0.5
		
		# Fade God Rays as we go deeper (Visible at 0, invisible at 1000m)
		var rays = bg.get_node_or_null("LayerRays/GodRays")
		if rays:
			rays.modulate.a = clamp(1.0 - (new_score / 1500.0), 0.0, 1.0)
	
	# Check for Equipment Upgrades
	if equipment_system:
		equipment_system.check_upgrade(new_score)

func _on_tool_upgraded(_new_tier, tool_name):
	# Update UI
	if game_ui:
		game_ui.update_equipment(tool_name)
		game_ui.show_notification("%s UNLOCKED!" % tool_name.to_upper())
	
	# Play sound?
	# if sound_manager: sound_manager.play_upgrade_sfx()
	print("🔧 Tool Upgraded! %s" % tool_name)

# ═══════════════════════════════════════════════════════════════════════════════
# PLAYER HANDLERS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_player_dashed():
	if sound_manager: 
		sound_manager.play_dash_sfx()

func _on_player_hit():
	"""Handle player being hit — check for extra life."""
	var player = $Player
	if player and player.has_method("take_damage"):
		if player.take_damage():
			# Survived with extra life
			shake_screen(5.0, 0.3)
			return
	# No extra life — game over
	game_state_system.end_game()

func _on_restart_requested():
	# Show shop before next run
	if shop_ui:
		if transition_ui:
			await transition_ui.fade_out()
			shop_ui.show_shop()
			await transition_ui.fade_in()
		else:
			shop_ui.show_shop()
	else:
		game_state_system.start_game()

func _on_shop_continue():
	if transition_ui:
		await transition_ui.fade_out()
		game_state_system.start_game()
		await transition_ui.fade_in()
	else:
		game_state_system.start_game()

# ═══════════════════════════════════════════════════════════════════════════════
# EFFECTS
# ═══════════════════════════════════════════════════════════════════════════════

func shake_screen(intensity: float, duration: float):
	var cam = $Camera2D
	if not cam: return
	
	var tween = create_tween()
	for i in range(10):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(cam, "offset", offset, duration / 10.0)
	tween.tween_property(cam, "offset", Vector2.ZERO, 0.1)
