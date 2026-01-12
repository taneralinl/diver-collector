extends Node
## Handles saving and loading game data.

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════════════════════

const SAVE_PATH = "user://savegame.cfg"

const SECTION_GAME = "game"
const SECTION_ECONOMY = "economy"
const SECTION_UPGRADES = "upgrades"

const KEY_HIGH_SCORE = "high_score"
const KEY_ABYSS_SHARDS = "abyss_shards"

# ═══════════════════════════════════════════════════════════════════════════════
# HIGH SCORE
# ═══════════════════════════════════════════════════════════════════════════════

func save_high_score(score: int):
	var config = _load_config()
	config.set_value(SECTION_GAME, KEY_HIGH_SCORE, score)
	config.save(SAVE_PATH)
	print("💾 High Score saved: %d" % score)

func load_high_score() -> int:
	var config = _load_config()
	return config.get_value(SECTION_GAME, KEY_HIGH_SCORE, 0)

# ═══════════════════════════════════════════════════════════════════════════════
# ECONOMY DATA
# ═══════════════════════════════════════════════════════════════════════════════

func save_abyss_shards(amount: int):
	var config = _load_config()
	config.set_value(SECTION_ECONOMY, KEY_ABYSS_SHARDS, amount)
	config.save(SAVE_PATH)
	print("💾 Abyss Shards saved: %d" % amount)

func load_abyss_shards() -> int:
	var config = _load_config()
	return config.get_value(SECTION_ECONOMY, KEY_ABYSS_SHARDS, 0)

func save_upgrades(upgrades: Dictionary):
	var config = _load_config()
	for upgrade_id in upgrades:
		config.set_value(SECTION_UPGRADES, upgrade_id, upgrades[upgrade_id])
	config.save(SAVE_PATH)
	print("💾 Upgrades saved: %s" % str(upgrades))

func load_upgrades() -> Dictionary:
	var config = _load_config()
	var upgrades = {}
	
	if config.has_section(SECTION_UPGRADES):
		for key in config.get_section_keys(SECTION_UPGRADES):
			upgrades[key] = config.get_value(SECTION_UPGRADES, key, 0)
	
	return upgrades

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func _load_config() -> ConfigFile:
	var config = ConfigFile.new()
	config.load(SAVE_PATH) # Ignore error if file doesn't exist
	return config

func save_all(economy_system):
	"""Convenience method to save all economy data at once."""
	save_abyss_shards(economy_system.get_abyss_shards())
	save_upgrades(economy_system.get_purchased_upgrades())
