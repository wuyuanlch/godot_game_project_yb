extends Node2D

var shape_to_draw: Shape2D = null
# 设置一个舒服的颜色和透明度来显示范围 (RGBA)
var draw_color: Color = Color(0.0, 0.7, 1.0, 0.1) # 淡蓝色，半透明

func _draw() -> void:
	if not shape_to_draw:
		return

	if shape_to_draw is CircleShape2D:
		draw_circle(Vector2.ZERO, shape_to_draw.radius, draw_color)


func update_shape(new_shape: Shape2D) -> void:
	shape_to_draw = new_shape
	queue_redraw() 

func set_draw_color(color: Color) -> void:
	draw_color = color
	queue_redraw()
