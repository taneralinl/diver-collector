extends Node2D

func _ready():
	var tween = create_tween().set_parallel(true)
	# Expand and fade
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func setup(color: Color, tier: int):
	modulate = color
	# Change appearance based on tier?
	if tier >= 3: # Large/Heavy
		scale = Vector2(1.5, 1.5)
