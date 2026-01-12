extends Node

func _ready():
	# Allow systems to initialize first
	get_tree().create_timer(1.0).timeout.connect(run_health_check)

func run_health_check():
	print("----- QA SYSTEM HEALTH CHECK -----")
	var passed = true
	
	# Check for System Existence
	var main = get_tree().current_scene
	if not main:
		_fail("Current Scene not found!")
		passed = false
	
	if main.get_node_or_null("ScoreSystem"):
		_pass("ScoreSystem found")
	else:
		_fail("ScoreSystem MISSING")
		passed = false
		
	if main.get_node_or_null("SpawnerSystem"):
		_pass("SpawnerSystem found")
	else:
		_fail("SpawnerSystem MISSING")
		passed = false

	if main.get_node_or_null("GameUI"):
		_pass("GameUI found")
	else:
		_fail("GameUI MISSING")
		passed = false
		
	# Check for Player
	if main.get_node_or_null("Player"):
		_pass("Player Entity found")
	else:
		_fail("Player Entity MISSING")
		passed = false

	if passed:
		print(">> ALL SYSTEMS GO. READY FOR DEPLOYMENT.")
	else:
		push_error(">> QA FAILED. CHECK ERRORS ABOVE.")
	print("----------------------------------")

func _pass(msg):
	print("[PASS] " + msg)

func _fail(msg):
	push_error("[FAIL] " + msg)
