extends Node
## Manages entity spawning with score-based type selection.

# ═══════════════════════════════════════════════════════════════════════════════
# EXPORTS
# ═══════════════════════════════════════════════════════════════════════════════

@export var collectible_scene: PackedScene
@export var enemy_scene: PackedScene
@export var min_spawn_time = 0.5
@export var max_spawn_time = 2.0

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════════════════════════

signal collectible_spawned(instance)
signal enemy_spawned(instance)

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTS — Score thresholds for entity types (using int instead of class refs)
# ═══════════════════════════════════════════════════════════════════════════════

# Collectible.Type: PEARL=0, SMALL_FISH=1, MEDIUM_FISH=2, LARGE_FISH=3, TREASURE=4
var COLLECTIBLE_THRESHOLDS = {
	0:   0, # PEARL
	50:  1, # SMALL_FISH
	150: 2, # MEDIUM_FISH
	300: 3, # LARGE_FISH
	500: 4  # TREASURE
}

# Enemy.Type: MINE=0, DRIFTING_MINE=1, JELLYFISH=2, SHARK=3
var ENEMY_THRESHOLDS = {
	0:   0, # MINE
	100: 1, # DRIFTING_MINE
	200: 2, # JELLYFISH
	400: 3  # SHARK
}

# ═══════════════════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════════════════

var spawn_timer: Timer
var enemy_ratio = 0.2 # Dynamic, updated by ProgressionSystem

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	_setup_timer()

func _setup_timer():
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════════

func start_spawning():
	_schedule_next_spawn()

func stop_spawning():
	spawn_timer.stop()

func clear_entities():
	get_tree().call_group("spawned_entities", "queue_free")

# ═══════════════════════════════════════════════════════════════════════════════
# SPAWNING LOGIC
# ═══════════════════════════════════════════════════════════════════════════════

func _schedule_next_spawn():
	spawn_timer.wait_time = randf_range(min_spawn_time, max_spawn_time)
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if randf() > enemy_ratio:
		_spawn_collectible()
	else:
		_spawn_enemy()
	
	_schedule_next_spawn()

func _spawn_collectible():
	if not collectible_scene: return
	
	var entity = collectible_scene.instantiate()
	var score = _get_current_score()
	
	# Select type based on score + weighted random for variety
	entity.collectible_type = _select_collectible_type(score)
	
	_place_entity(entity)
	collectible_spawned.emit(entity)

func _spawn_enemy():
	if not enemy_scene: return
	
	var entity = enemy_scene.instantiate()
	var score = _get_current_score()
	
	# Select type based on score
	entity.enemy_type = _select_enemy_type(score)
	
	_place_entity(entity)
	enemy_spawned.emit(entity)

# ═══════════════════════════════════════════════════════════════════════════════
# TYPE SELECTION (Weighted Random with Score Gates)
# ═══════════════════════════════════════════════════════════════════════════════

func _select_collectible_type(score: int) -> int:
	# Get available types based on score
	var available = []
	for threshold in COLLECTIBLE_THRESHOLDS.keys():
		if score >= threshold:
			available.append(COLLECTIBLE_THRESHOLDS[threshold])
	
	if available.is_empty():
		return 0 # PEARL
	
	# Weighted selection: favor lower tiers, rare higher tiers
	var weights = [60, 25, 10, 4, 1] # Pearl to Treasure
	var total_weight = 0
	var weighted_pool = []
	
	for i in range(available.size()):
		var w = weights[min(i, weights.size() - 1)]
		total_weight += w
		weighted_pool.append({"type": available[i], "weight": w})
	
	var roll = randf() * total_weight
	var cumulative = 0.0
	for item in weighted_pool:
		cumulative += item.weight
		if roll <= cumulative:
			return item.type
	
	return 0 # PEARL

func _select_enemy_type(score: int) -> int:
	var available = []
	for threshold in ENEMY_THRESHOLDS.keys():
		if score >= threshold:
			available.append(ENEMY_THRESHOLDS[threshold])
	
	if available.is_empty():
		return 0 # MINE
	
	# Random selection from available types
	return available[randi() % available.size()]

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func _place_entity(entity):
	# Abyss Trench bounds
	var min_x = 180.0
	var max_x = 970.0
	
	var spawn_y = -20.0
	# If it's an enemy and it's a Jellyfish (Index 2 in Enemy.Type), spawn at bottom
	if entity is Enemy and entity.enemy_type == 2:
		spawn_y = 820.0
		
	entity.position = Vector2(randf_range(min_x, max_x), spawn_y)
	entity.add_to_group("spawned_entities")
	get_tree().current_scene.call_deferred("add_child", entity)

func _get_current_score() -> int:
	var score_sys = get_tree().get_first_node_in_group("score_system")
	if score_sys and score_sys.has_method("get_score"):
		return score_sys.get_score()
	return 0
