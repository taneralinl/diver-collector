extends Node2D

func _ready():
	var tween = create_tween().set_parallel(true)
	# Expand and fade
	tween.tween_property(self, "scale", scale * 2.5, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func setup(color: Color, tier: int):
	modulate = color
	# Increase size for higher tiers
	scale = Vector2(1.0, 1.0) + Vector2(0.5, 0.5) * tier
	
	# Add a light rotation for juice
	rotation = randf() * PI
