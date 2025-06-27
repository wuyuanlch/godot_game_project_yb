extends NinePatchRect

# 已完成UI的基本功能，拖拽UI可将塔移除，可看预览塔，高亮区
@onready var tower = preload("res://tower/tower.tscn")
@export var map: TileMapLayer
@export var obstruction_map:TileMapLayer
@export var tower_map:TileMapLayer
@export var towers_node:Node2D# 专门放置防御塔的节点
@export var preview_towers_node:Node2D#专门放置预览塔的节点
@export var selection_map: TileMapLayer#高亮区的变色节点
@onready var point_light: PointLight2D = $"../../../../Map/CanBuildArea"

var current_highlighted_tile = null
var current_obstruction_tile=null
var preview_tower
var temp_tower
var current_tile_pos: Vector2i = Vector2i(-1, -1)
var map_light_radius_squared: float = 0.0

func _ready() -> void:
	update_map_light_radius()

#func is_in_light_range(tile_pos: Vector2i) -> bool:
	#var mouse_pos = map.map_to_local(tile_pos)
	#var global_pos = map.to_global(mouse_pos)
	#
	#for tower_node in towers_node.get_children():
		#var light = tower_node.get_node_or_null("PointLight2D")
		#
		#if light:
			## 这里优化一下，避免sqrt运算，减少计算开销
			## var light_radius = light.texture_scale * 7 * sqrt(light.height)  # 估算灯光半径
			#var light_radius_squared = pow(light.texture_scale * 7 * sqrt(light.height), 2)
#
			#if global_pos.distance_squared_to(tower_node.global_position) <= light_radius_squared:
				#return true
				#
	#return false

func is_in_light_range(tile_pos: Vector2i) -> bool:	
	var global_pos = map.to_global(map.map_to_local(tile_pos))
	
	# 初始光源判断
	if is_instance_valid(point_light): 
		if global_pos.distance_squared_to(point_light.global_position) <= map_light_radius_squared:
			return true
			
	for tower_node in towers_node.get_children():
		# 直接访问塔自己算好的半径平方值 (light_radius_squared)，而不需要每次调用一次该函数就计算一次
		if global_pos.distance_squared_to(tower_node.global_position) <= tower_node.light_radius_squared:
			return true
			
	return false

func _on_gui_input(event):
	if event is InputEventMouseMotion and event.button_mask == 1:
		var mouse_pos = GlobalCamera.get_global_mouse_position()# 可以直接用这个map.get_global_mouse_position()
		var new_tile_pos = map.local_to_map(mouse_pos)
		var new_obstruction_pos = obstruction_map.local_to_map(mouse_pos)

		# selection_map.clear()  # 清除之前的高亮
		# var tile_data = map.get_cell_tile_data(new_tile_pos)
		# var obstruction_data = obstruction_map.get_cell_tile_data(new_obstruction_pos)
		# preview_tower = tower.instantiate()
		# var can_place = tile_data and tile_data.get_custom_data("towerable") and !has_tower(new_tile_pos,preview_tower.size) and is_in_light_range(new_tile_pos) and (obstruction_data == null or !obstruction_data.get_custom_data("unwalkable"))
		# var tile_id = 5 if can_place else 6  # 可放置用5，不可用6
		# selection_map.set_cell(new_tile_pos, tile_id, Vector2i(0,0))
		# var vec=Vector2i(11,28) if can_place else Vector2i(2,25)
		# selection_map.set_cell(new_tile_pos, 0, vec)
		
		selection_map.clear()
		# var can_place_all = true

		# 移动时出现预览塔
		if not preview_tower:
			preview_tower = tower.instantiate()
			preview_tower.set_process(false)
			preview_tower.can_look=false			# 预览塔转向暂停
			preview_tower.can_shoot=false		# 预览塔射击暂停
			preview_tower.get_node("PointLight2D").visible=false
			preview_tower.get_node("CollisionShape2D").set_deferred("disabled", true)
			preview_towers_node.add_child(preview_tower)
		
		var tower_size = preview_tower.size
		
		for x in range(0, tower_size.x):
			for y in range(0, tower_size.y):
				var check_pos = new_tile_pos + Vector2i(x, y)
				var tile_data = map.get_cell_tile_data(check_pos)
				var obstruction_data = obstruction_map.get_cell_tile_data(check_pos)
				var tower_data = tower_map.get_cell_tile_data(check_pos)
				var can_place = tile_data and tile_data.get_custom_data("towerable")  and is_in_light_range(new_tile_pos) and (obstruction_data == null or !obstruction_data.get_custom_data("unwalkable")) and (tower_data == null or !tower_data.get_custom_data("unwalkable"))
				var vec=Vector2i(11,28) if can_place  else Vector2i(2,25)
				selection_map.set_cell(check_pos, 0, vec)
			
			# 显示预览塔的攻击范围 
			if preview_tower.has_method("show_attack_range"):
				preview_tower.show_attack_range(true)

		if preview_tower:
			var local_pos1 = map.map_to_local(new_tile_pos)
			var center_offset = Vector2(
				map.tile_set.tile_size.x * (tower_size.x - 1) / 2.0,
				map.tile_set.tile_size.y * (tower_size.y - 1) / 2.0
			)
			preview_tower.global_position = map.to_global(local_pos1+center_offset)
			
	# elif event is InputEventMouseButton and event.button_mask == 0:
	# 修复滚动键也可以放置塔
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		#var mouse_pos1 = get_global_mouse_position()
		var mouse_pos1 = GlobalCamera.get_global_mouse_position()# 可以直接用这个map.get_global_mouse_position()
		
		current_highlighted_tile = map.local_to_map(mouse_pos1)
		current_obstruction_tile = obstruction_map.local_to_map(mouse_pos1)
		current_tile_pos = Vector2i(-1, -1)
		
		# 放开鼠标后出现放置塔
		if current_highlighted_tile:
			temp_tower = tower.instantiate()
			var tower_size = temp_tower.size
			var can_place_all = true

			# 检查所有格子是否可放置
			for x in range(0, tower_size.x):
				for y in range(0, tower_size.y):
					var check_pos = current_highlighted_tile + Vector2i(x, y)
					var tile_data = map.get_cell_tile_data(check_pos)
					var obstruction_data = obstruction_map.get_cell_tile_data(check_pos)
					var tower_data = tower_map.get_cell_tile_data(check_pos)
					var can_place = tile_data and tile_data.get_custom_data("towerable")  and is_in_light_range(current_highlighted_tile) and (obstruction_data == null or !obstruction_data.get_custom_data("unwalkable"))and (tower_data == null or !tower_data.get_custom_data("unwalkable"))
					if !can_place:
						can_place_all = false
			
			# 只有所有格子都可放置时才放置塔
			if can_place_all:
				temp_tower.add_to_group("active_towers")
				temp_tower.initial_tile_pos = current_highlighted_tile  # 记录初始位置
				temp_tower.tower_destroyed.connect(_on_tower_destroyed)  # 连接信号
				towers_node.add_child(temp_tower)
				var local_pos = map.map_to_local(current_highlighted_tile)
				var center_offset = Vector2(
					map.tile_set.tile_size.x * (temp_tower.size.x - 1) / 2.0,
					map.tile_set.tile_size.y * (temp_tower.size.y - 1) / 2.0
				)
				temp_tower.global_position = map.to_global(local_pos+center_offset)
				temp_tower.get_node("PointLight2D").visible=true
				if temp_tower.has_method("show_attack_range"):
					temp_tower.show_attack_range(false)
				# 标记这些格子为不可行走
				for x in range(0, temp_tower.size.x):
					for y in range(0, temp_tower.size.y):
						var pos = current_highlighted_tile + Vector2i(x, y)
						tower_map.set_cell(pos, 0,Vector2i(27,12))  # 使用适当的格子ID
			
			selection_map.clear()
		
		if preview_tower:
			preview_tower.queue_free()
			preview_tower = null

			# var tile_data = map.get_cell_tile_data(current_highlighted_tile)
			# var obstruction_data = obstruction_map.get_cell_tile_data(current_obstruction_tile)
			# temp_tower = tower.instantiate()
			# if tile_data and tile_data.get_custom_data("towerable") and !has_tower(current_highlighted_tile,temp_tower.size) and is_in_light_range(current_highlighted_tile)and (obstruction_data == null or !obstruction_data.get_custom_data("unwalkable")):
				# temp_tower = tower.instantiate()
				
				# 当玩家松开鼠标确认放置防御塔时才添加到 "active_towers" 组内
				# temp_tower.add_to_group("active_towers")
				
				# towers_node.add_child(temp_tower)
				# var local_pos = map.map_to_local(current_highlighted_tile)
				# var center_offset = Vector2(
				# 	map.tile_set.tile_size.x * (temp_tower.size.x - 1) / 2.0,
				# 	map.tile_set.tile_size.y * (temp_tower.size.y - 1) / 2.0
				# )
				# temp_tower.global_position = map.to_global(local_pos+center_offset)
				# temp_tower.get_node("PointLight2D").visible=true

				# 对于实际放置的塔，默认隐藏其攻击范围 
				# （你可以根据需要，例如在选中塔的时候再显示它）
				# if temp_tower.has_method("show_attack_range"):
				# 	temp_tower.show_attack_range(false)
					
				# 后续可能增加的逻辑...
				
			# selection_map.clear()
		
		# if preview_tower:
		# 	preview_tower.queue_free()
		# 	preview_tower = null


# func has_tower(tile_pos: Vector2i,size: Vector2i) -> bool:
# 	for x in range(0, size.x):
# 		for y in range(0, size.y):
# 			var check_pos = tile_pos + Vector2i(x, y)
# 			for tower1 in towers_node.get_children():
# 				if map.local_to_map(tower1.global_position) == tile_pos:
# 					return true
# 	return false
# wzy


func _on_tower_destroyed(tile_pos: Vector2i, size: Vector2i):
	# 清除tower_map标记
	for x in range(0, size.x):
		for y in range(0, size.y):
			var pos = tile_pos + Vector2i(x, y)
			tower_map.set_cell(pos, -1)
			
	# 只有有高亮显示时才更新selection_map
	if preview_tower != null:
		# 获取preview_tower的位置
		var mouse_pos = GlobalCamera.get_global_mouse_position()
		var preview_pos = map.local_to_map(mouse_pos)
		var preview_size = preview_tower.size
		
		# 只更新preview_tower范围内的不可放置格子
		for x in range(0, preview_size.x):
			for y in range(0, preview_size.y):
				var pos = preview_pos + Vector2i(x, y)
				var tile_data = map.get_cell_tile_data(pos)
				var obstruction_data = obstruction_map.get_cell_tile_data(pos)
				var tower_data = tower_map.get_cell_tile_data(pos)
				var can_place = tile_data and tile_data.get_custom_data("towerable") and is_in_light_range(pos) and (obstruction_data == null or !obstruction_data.get_custom_data("unwalkable")) and (tower_data == null or !tower_data.get_custom_data("unwalkable"))
				var vec=Vector2i(11,28) if can_place  else Vector2i(2,25)
				selection_map.set_cell(pos, 0, vec)

func update_map_light_radius():
	if not is_instance_valid(point_light):
		map_light_radius_squared = 0.0 
		return

	const LIGHT_RADIUS_MULTIPLIER = 31.0
	
	var radius = point_light.texture_scale * LIGHT_RADIUS_MULTIPLIER * sqrt(point_light.height)
	
	map_light_radius_squared = pow(radius, 2)
