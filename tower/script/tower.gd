class_name Towers
extends StaticBody2D

# 单个防御塔的代码，可朝向敌人，攻击离中心点最近的敌人
var bullet:PackedScene = preload("res://bullet/tower_bullet.tscn")
var current_targets:Array=[]
var curr :CharacterBody2D
var can_shoot:bool=true
var can_look:bool=true
var light_radius_squared: float = 0.0

@onready var detection_area: Area2D = $Area2D
@onready var range_visualizer: Node2D = $RangeVisualizer
@onready var tower_ui_parent: Node2D = $D_U_node
@onready var tower_actions_ui: Control = $D_U_node/TowerActionsUI
@onready var hb_node: Node2D = $HB_node
@onready var health_bar: ProgressBar = $HB_node/HealthBar
@onready var point_light: PointLight2D = $PointLight2D
@onready var sprite: Sprite2D = $Sprite2D


var health: int = 100
var max_health: int = 100

# 加载哪种元素的子弹
const bullet_stats = preload("res://bullet/tower_bullet/default.tres")

func _ready():
	
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
			
	update_health_bar()
	
	# 默认隐藏
	if is_instance_valid(tower_actions_ui):
		tower_actions_ui.visible = false
	
	input_pickable = true
	
	# 在塔创建时，计算并缓存光照半径
	update_light_radius()


func _process(delta):
	if is_instance_valid(curr):
		if can_look:
			sprite.look_at(curr.global_position)
		if can_shoot:
			shoot(bullet_stats)
			can_shoot=false
			$shootingCoolDown.start()
	else:
		for i in get_node("BulletContainer").get_child_count():
			get_node("BulletContainer").get_child(i).queue_free()

	# 将这个中间 Node2D 的旋转设置为防御塔旋转的负值，以抵消防御塔的旋转
	tower_ui_parent.rotation = -self.rotation
	
	# 同理防御塔血条不旋转
	hb_node.rotation = -self.rotation


func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# 检查是否是鼠标左键按下事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 当 _input_event 触发时，意味着鼠标已经点击到这个StaticBody2D的碰撞形状上
		#show_tower_actions_ui(true)
		#show_attack_range(true)
		SelectionManager.select(self)
		
		# 标记事件为已处理，防止其他物体也接收到这个点击事件
		get_viewport().set_input_as_handled()
		
			
func show_tower_actions_ui(visible: bool) -> void:
	if is_instance_valid(tower_actions_ui):
		tower_actions_ui.visible = visible
		if visible:
			var tower_height_local = 0.0
			var collision_shape = get_node("CollisionShape2D")
			if collision_shape and collision_shape.shape is RectangleShape2D:
				tower_height_local = collision_shape.shape.size.y / 2

			var ui_offset_y = -tower_height_local # 塔顶部相对于塔中心的 Y 偏移

			ui_offset_y -= tower_actions_ui.size.y / tower_actions_ui.get_canvas_transform().get_scale().y # 根据UI在Canvas上的实际缩放来调整

			tower_actions_ui.position.x = 0 
			tower_actions_ui.position.y = -tower_height_local - tower_actions_ui.size.y / 6
			
			var camera = get_viewport().get_camera_2d()
			
			
func shoot(stats: BulletStats)->void:
	var temp_bullet:CharacterBody2D = bullet.instantiate()
	
	temp_bullet.target = curr
	temp_bullet.is_tower_bullet = true
	
	temp_bullet.tower_bullet_damage = stats.damage 
	temp_bullet.speed = stats.speed

	if temp_bullet.has_node("Sprite2D"): 
		var bullet_sprite: Sprite2D = temp_bullet.get_node("Sprite2D")
		if stats.texture: 
			bullet_sprite.texture = stats.texture
		#print(bullet_sprite.texture)

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


func tower_take_damage(damage:int)->void:
	health -= damage
	health = max(health, 0)

	update_health_bar()
	
	if health<=0:
		queue_free()


func update_light_radius():
	if not is_instance_valid(point_light):
		light_radius_squared = 0.0 
		return

	const LIGHT_RADIUS_MULTIPLIER = 7.0
	
	var radius = point_light.texture_scale * LIGHT_RADIUS_MULTIPLIER * sqrt(point_light.height)
	
	light_radius_squared = pow(radius, 2)


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


func show_attack_range(is_visible: bool) -> void:
	if is_instance_valid(range_visualizer):
		range_visualizer.visible = is_visible


func update_health_bar() -> void: 
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = health
		# 血量不满时显示，满血时隐藏
		health_bar.visible = health < max_health


func _on_delete_button_pressed() -> void:
	#show_tower_actions_ui(false)
	#show_attack_range(false)
	SelectionManager.deselect_all()
	queue_free()
	

func _on_upgrade_button_pressed() -> void:
	#show_tower_actions_ui(false)
	#show_attack_range(false)
	SelectionManager.deselect_all()
	print("防御塔被升级！")

	# 如果升级会影响到灯光（比如范围变大），那就在这里重新计算一次
	# 假设升级会改变 point_light 的 height 或 texture_scale
	# get_tree().create_timer(0.1).timeout.connect(update_light_radius) # 延迟一点点调用，确保升级属性已生效
	# update_light_radius() 


func select():
	show_tower_actions_ui(true)
	show_attack_range(true)


func deselect():
	show_tower_actions_ui(false)
	show_attack_range(false)
