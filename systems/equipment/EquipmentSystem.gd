extends Node
class_name EquipmentSystem
## Manages player equipment progression.
## Tool tiers determine what collectibles can be captured.

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════════════════════════

signal tool_upgraded(new_tier: int, tool_name: String)

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════════════════════

const TOOLS = {
	0: {"name": "Bare Hands",  "unlock_score": 0,   "can_capture_tier": 1},
	1: {"name": "Collector Net", "unlock_score": 50,  "can_capture_tier": 2},
	2: {"name": "Grappling Hook", "unlock_score": 150, "can_capture_tier": 3},
	3: {"name": "Harpoon Gun",  "unlock_score": 350, "can_capture_tier": 4},
	4: {"name": "Capture Drone", "unlock_score": 600, "can_capture_tier": 5}
}

# ═══════════════════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════════════════

var current_tool_tier: int = 0

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	add_to_group("equipment_system")

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════════

func get_tool_tier() -> int:
	return current_tool_tier

func get_tool_name() -> String:
	return TOOLS.get(current_tool_tier, TOOLS[0]).name

func check_upgrade(score: int):
	"""Check if score unlocks a new tool tier."""
	for tier in range(4, -1, -1): # Check highest first
		var tool_data = TOOLS.get(tier, {})
		if score >= tool_data.get("unlock_score", 9999) and tier > current_tool_tier:
			_upgrade_to(tier)
			break

func reset():
	"""Reset to starting equipment, checking for shop upgrades."""
	# Check if player has Starting Net upgrade
	var economy = get_tree().get_first_node_in_group("economy_system")
	if economy and economy.has_starting_net():
		current_tool_tier = 1 # Start with Net
		print("🔧 Starting with: Collector Net (from Shop)")
	else:
		current_tool_tier = 0 # Bare Hands

# ═══════════════════════════════════════════════════════════════════════════════
# PRIVATE
# ═══════════════════════════════════════════════════════════════════════════════

func _upgrade_to(tier: int):
	current_tool_tier = tier
	var tool_name = TOOLS.get(tier, TOOLS[0]).name
	tool_upgraded.emit(tier, tool_name)
	print("🔧 Equipment Upgraded: %s (Tier %d)" % [tool_name, tier])
