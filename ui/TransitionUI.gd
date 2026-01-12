extends CanvasLayer

signal transition_finished

@onready var color_rect = $ColorRect

func fade_out(duration: float = 0.5):
	color_rect.color.a = 0
	visible = true
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished
	transition_finished.emit()

func fade_in(duration: float = 0.5):
	color_rect.color.a = 1.0
	visible = true
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	await tween.finished
	visible = false
	transition_finished.emit()
