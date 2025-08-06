extends Node2D

@onready var label: Label = $Label

var position_tween: Tween
var scale_tween: Tween


func _ready() -> void:
	scale = Vector2.ZERO
	

func display_damage_text(damage_amount: int):
	if position_tween and position_tween.is_running():
		position_tween.kill()
	if scale_tween and scale_tween.is_running():
		scale_tween.kill()
	
	label.text = str(damage_amount)
	
	position_tween = create_tween()
	scale_tween = create_tween()
	
	position_tween.tween_property(self, "global_position", global_position + Vector2.UP * 16, 0.3)
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	
	position_tween.tween_property(self, "global_position", global_position + Vector2.UP * 24, 0.4)
	scale_tween.tween_property(self, "scale", Vector2.ZERO, 0.4)
	
	position_tween.tween_callback(queue_free)
