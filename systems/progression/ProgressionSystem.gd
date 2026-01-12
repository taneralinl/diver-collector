extends Node

var spawner_system
var score_system

# Tuning parameters
const BASE_MIN_SPAWN = 0.5
const BASE_MAX_SPAWN = 1.5
const DIFFICULTY_STEP = 50 # Increase difficulty every 50 points

func setup(spawner, scorer):
	spawner_system = spawner
	score_system = scorer
	# Connect to score updates
	score_system.score_updated.connect(_on_score_updated)

func _on_score_updated(score):
	# Calculate difficulty level (0, 1, 2...)
	var level = floor(score / DIFFICULTY_STEP)
	
	# Scale spawn times inversely to level
	# Formula: NewTime = BaseTime * (0.9 ^ level)
	var multiplier = pow(0.9, level)
	
	var new_min = max(0.2, BASE_MIN_SPAWN * multiplier)
	var new_max = max(0.4, BASE_MAX_SPAWN * multiplier)
	
	if spawner_system:
		spawner_system.min_spawn_time = new_min
		spawner_system.max_spawn_time = new_max
		
		# Enemy scaling: Increase enemy ratio based on score
		# Base: 20%, Max: 50%
		var enemy_ratio = min(0.5, 0.2 + (score / 1000.0))
		spawner_system.enemy_ratio = enemy_ratio
		
		# Log difficulty increase
		if score > 0 and score % DIFFICULTY_STEP == 0:
			print("📈 Progression: Level %d | Spawn: %.2f-%.2f | Enemies: %.0f%%" % [level, new_min, new_max, enemy_ratio * 100])

func reset_difficulty():
	if spawner_system:
		spawner_system.min_spawn_time = BASE_MIN_SPAWN
		spawner_system.max_spawn_time = BASE_MAX_SPAWN
