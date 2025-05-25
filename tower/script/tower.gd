class_name Towers
extends StaticBody2D

# 单个防御塔的代码，可朝向敌人，攻击离中心点最近的敌人
var bullet:PackedScene=preload("res://tower/bullet.tscn")
var bullet_damage:int = 1
var current_targets:Array=[]
var curr :CharacterBody2D
var can_shoot:bool=true
var can_look:bool=true

@onready var detection_area: Area2D = $Area2D
@onready var range_visualizer: Node2D = $RangeVisualizer


func _ready():
	
	#add_to_group("active_towers")
	
	# 初始化 RangeVisualizer 的形状并默认隐藏它
	if is_instance_valid(range_visualizer) and range_visualizer.has_method("update_shape"):
		# Area2D 的第一个子节点通常是其 CollisionShape2D
		var collision_shape_node = detection_area.get_child(0)
		if collision_shape_node is CollisionShape2D:
			range_visualizer.update_shape(collision_shape_node.shape)

		range_visualizer.visible = false # 默认隐藏范围显示
	else:
		if not is_instance_valid(range_visualizer):
			print_debug("Tower: RangeVisualizer node not found or invalid.")
		elif not range_visualizer.has_method("update_shape"):
			print_debug("Tower: RangeVisualizer is missing 'update_shape' method.")


func _process(delta):
	if is_instance_valid(curr):
		if can_look:
			look_at(curr.global_position)
		if can_shoot:
			shoot()
			can_shoot=false
			$shootingCoolDown.start()
	else:
		for i in get_node("BulletContainer").get_child_count():
			get_node("BulletContainer").get_child(i).queue_free()


func shoot()->void:
	var temp_bullet:CharacterBody2D=bullet.instantiate()
	temp_bullet.target = curr
	temp_bullet.bullet_damage = bullet_damage
	get_node("BulletContainer").add_child(temp_bullet)
	temp_bullet.global_position = $Aim.global_position


func choose_target(_current_targets:Array)->void:
	var temp_array:Array = _current_targets
	var current_target : CharacterBody2D = null
	var closest_distance = INF
	const TARGET_COORD = Vector2i(18, -6)			# 暂时先用这个点代替，后续会以敌人距离最近的防御塔进行移动
	
	for enemy in temp_array:
		if enemy.is_in_group("Enemy"):
			# 使用敌人的网格位置计算距离
			var distance = enemy.current_grid_pos.distance_to(TARGET_COORD)
			
			# 选择距离终点最近的敌人
			if distance < closest_distance:
				closest_distance = distance
				current_target = enemy
	
	curr = current_target


func _on_area_2d_body_entered(body):

	if body.is_in_group("Enemy"):
		current_targets.append(body)
		choose_target(current_targets)
	

func _on_area_2d_body_exited(body):
	if body.is_in_group("Enemy"):
			current_targets.erase(body)
			choose_target(current_targets)


func _on_shooting_cool_down_timeout():
	can_shoot=true
# wzy

func show_attack_range(is_visible: bool) -> void:
	if is_instance_valid(range_visualizer):
		range_visualizer.visible = is_visible
