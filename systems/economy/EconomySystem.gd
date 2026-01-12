extends Node
class_name EconomySystem
## Manages dual currency system and meta-progression upgrades.

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════════════════════════

signal pearls_changed(amount: int)
signal abyss_shards_changed(amount: int)
signal upgrade_purchased(upgrade_id: String)
signal save_requested

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTS — Purchasable Upgrades
# ═══════════════════════════════════════════════════════════════════════════════

const UPGRADES = {
	"speed_boost": {
		"name": "Speed Boost",
		"description": "+10% Movement Speed",
		"cost": 500,
		"max_level": 5,
		"effect_per_level": 0.1
	},
	"magnet_range": {
		"name": "Magnet Range+",
		"description": "+25% Hook Range",
		"cost": 400,
		"max_level": 4,
		"effect_per_level": 0.25
	},
	"starting_net": {
		"name": "Starting Net",
		"description": "Start with Collector Net",
		"cost": 1000,
		"max_level": 1,
		"effect_per_level": 1
	},
	"extra_life": {
		"name": "Extra Life",
		"description": "Survive one hit per run",
		"cost": 2000,
		"max_level": 1,
		"effect_per_level": 1
	},
	"pearl_magnet": {
		"name": "Pearl Magnet",
		"description": "+50% Base Collection Range",
		"cost": 600,
		"max_level": 3,
		"effect_per_level": 0.5
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════════════════

var run_pearls: int = 0        # Temporary (current run)
var abyss_shards: int = 0        # Permanent (meta currency)
var purchased_upgrades: Dictionary = {} # {upgrade_id: level}

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	add_to_group("economy_system")

# ═══════════════════════════════════════════════════════════════════════════════
# RUN CURRENCY (Pearls)
# ═══════════════════════════════════════════════════════════════════════════════

func add_pearls(amount: int):
	run_pearls += amount
	pearls_changed.emit(run_pearls)

func get_pearls() -> int:
	return run_pearls

func reset_run():
	run_pearls = 0
	pearls_changed.emit(run_pearls)

# ═══════════════════════════════════════════════════════════════════════════════
# META CURRENCY (Abyss Shards)
# ═══════════════════════════════════════════════════════════════════════════════

func convert_pearls_to_shards(depth_bonus: float = 1.0):
	"""Called at end of run. Converts pearls to abyss shards with bonus."""
	var conversion = int(run_pearls * depth_bonus)
	abyss_shards += conversion
	abyss_shards_changed.emit(abyss_shards)
	print("💎 Converted %d Pearls → %d Abyss Shards (%.1fx bonus)" % [run_pearls, conversion, depth_bonus])
	return conversion

func get_abyss_shards() -> int:
	return abyss_shards

func set_abyss_shards(amount: int):
	abyss_shards = amount
	abyss_shards_changed.emit(abyss_shards)

# ═══════════════════════════════════════════════════════════════════════════════
# UPGRADES
# ═══════════════════════════════════════════════════════════════════════════════

func get_upgrade_level(upgrade_id: String) -> int:
	return purchased_upgrades.get(upgrade_id, 0)

func can_purchase(upgrade_id: String) -> bool:
	if not UPGRADES.has(upgrade_id):
		return false
	
	var upgrade = UPGRADES[upgrade_id]
	var current_level = get_upgrade_level(upgrade_id)
	
	if current_level >= upgrade.max_level:
		return false
	
	var cost = _calculate_cost(upgrade_id)
	return abyss_shards >= cost

func purchase_upgrade(upgrade_id: String) -> bool:
	if not can_purchase(upgrade_id):
		return false
	
	var cost = _calculate_cost(upgrade_id)
	abyss_shards -= cost
	purchased_upgrades[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	
	abyss_shards_changed.emit(abyss_shards)
	upgrade_purchased.emit(upgrade_id)
	save_requested.emit()
	
	print("🛒 Purchased: %s (Level %d) for %d Abyss Shards" % [
		UPGRADES[upgrade_id].name, 
		purchased_upgrades[upgrade_id], 
		cost
	])
	return true

func _calculate_cost(upgrade_id: String) -> int:
	var base_cost = UPGRADES[upgrade_id].cost
	var level = get_upgrade_level(upgrade_id)
	# Each level costs 50% more
	return int(base_cost * pow(1.5, level))

func get_all_upgrades() -> Dictionary:
	return UPGRADES

func get_purchased_upgrades() -> Dictionary:
	return purchased_upgrades

func set_purchased_upgrades(data: Dictionary):
	purchased_upgrades = data

func reset_persistence():
	"""Reset all progress (Abyss Shards & Upgrades)."""
	abyss_shards = 0
	purchased_upgrades.clear()
	abyss_shards_changed.emit(abyss_shards)
	save_requested.emit()
	print("🔥 Economy Hard Reset Performed")

# ═══════════════════════════════════════════════════════════════════════════════
# EFFECT GETTERS (For game systems to query)
# ═══════════════════════════════════════════════════════════════════════════════

func get_speed_multiplier() -> float:
	var level = get_upgrade_level("speed_boost")
	return 1.0 + (level * UPGRADES["speed_boost"].effect_per_level)

func get_magnet_range_multiplier() -> float:
	var level = get_upgrade_level("magnet_range")
	return 1.0 + (level * UPGRADES["magnet_range"].effect_per_level)

func has_starting_net() -> bool:
	return get_upgrade_level("starting_net") > 0

func has_extra_life() -> bool:
	return get_upgrade_level("extra_life") > 0

func get_collection_range_multiplier() -> float:
	var level = get_upgrade_level("pearl_magnet")
	return 1.0 + (level * UPGRADES["pearl_magnet"].effect_per_level)
