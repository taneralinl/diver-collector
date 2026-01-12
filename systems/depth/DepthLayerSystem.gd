extends Node

# Depth Layer System: Changes background color based on score milestones

var background_ocean: TextureRect

const DEPTH_LAYERS = {
	0: {"name": "Shallows", "color": Color(0.2, 0.5, 0.8)},      # Light blue
	100: {"name": "Twilight", "color": Color(0.1, 0.3, 0.6)},    # Darker blue
	250: {"name": "Midnight", "color": Color(0.05, 0.1, 0.3)},   # Deep blue
	500: {"name": "Abyss", "color": Color(0.1, 0.0, 0.15)}       # Dark purple/black
}

signal layer_changed(layer_name: String)

var current_layer = 0

func _ready():
	# Find the background Ocean node
	var bg_layer = get_tree().get_first_node_in_group("background")
	if bg_layer:
		background_ocean = bg_layer.get_node_or_null("Ocean")

func update_depth(score: int):
	var new_layer = 0
	
	# Determine current layer based on score
	for threshold in DEPTH_LAYERS.keys():
		if score >= threshold:
			new_layer = threshold
	
	# Only animate if layer changed
	if new_layer != current_layer:
		current_layer = new_layer
		_transition_to_layer(new_layer)

func _transition_to_layer(layer: int):
	if not background_ocean: return
	
	var layer_data = DEPTH_LAYERS.get(layer, DEPTH_LAYERS[0])
	var target_color = layer_data["color"]
	
	# Smooth transition
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background_ocean, "modulate", target_color, 1.0)
	
	layer_changed.emit(layer_data["name"])
	print("Depth Layer: %s (Score >= %d)" % [layer_data["name"], layer])

func reset():
	current_layer = 0
	if background_ocean:
		background_ocean.modulate = DEPTH_LAYERS[0]["color"]
