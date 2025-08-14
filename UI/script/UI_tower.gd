extends NinePatchRect

# 已完成UI的基本功能，拖拽UI可将塔移除，可看预览塔，高亮区
@export var tower : PackedScene
var is_first_click: bool = true  # 跟踪点击状态
@onready var pre_tower = preload("res://assets/scenes/tower/preview_tower.tscn")
@export var map_layer: Node2D

@export var towers_node:Node2D# 专门放置防御塔的节点
@export var preview_towers_node:Node2D#专门放置预览塔的节点


var current_highlighted_tile = null
var current_obstruction_tile=null
var preview_tower
var temp_tower
var current_tile_pos: Vector2i = Vector2i(-1, -1)
var map_light_radius_squared: float = 0.0

func _ready() -> void:
	set_process_input(true)
	# update_map_light_radius()


func is_in_light_range(tile_pos: Vector2i) -> bool:	
	var global_pos = map_layer.base_layer.to_global(map_layer.base_layer.map_to_local(tile_pos))
	
			
	for tower_node in towers_node.get_children():
		# 直接访问塔自己算好的半径平方值 (light_radius_squared)，而不需要每次调用一次该函数就计算一次
		if global_pos.distance_squared_to(tower_node.global_position) <= tower_node.light_radius_squared:
			return true
			
	return false

func _input(event):
	# 右键取消逻辑
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		is_first_click = true
		if preview_tower:
			preview_tower.queue_free()
			preview_tower = null
		map_layer.selection_layer.clear()
		return
	
	# 左键点击处理 - 只有第一次点击才检查UI区域
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_first_click:  # 第一次点击才需要检查UI区域
			var mouse_pos = get_global_mouse_position()
			if not get_global_rect().has_point(mouse_pos):
				return  # 第一次点击不在UI区域内，直接返回
	
	# 鼠标移动时更新预览塔和高亮区域
	if is_first_click == false and event is InputEventMouseMotion and preview_tower:
		var mouse_pos = GlobalCamera.get_global_mouse_position()
		var new_tile_pos = map_layer.base_layer.local_to_map(mouse_pos)
		
		# 更新高亮区域
		map_layer.selection_layer.clear()
		var tower_size = preview_tower.tower_size
		for x in range(0, tower_size.x):
			for y in range(0, tower_size.y):
				var check_pos = new_tile_pos + Vector2i(x, y)
				var tile_data = map_layer.base_layer.get_cell_tile_data(check_pos)
				var obstruction_data = map_layer.obstruction_layer.get_cell_tile_data(check_pos)
				var tower_data = map_layer.tower_layer.get_cell_tile_data(check_pos)
				var can_place = tile_data and tile_data.get_custom_data("towerable") and is_in_light_range(new_tile_pos) and (obstruction_data == null or !obstruction_data.get_custom_data("unwalkable")) and (tower_data == null or !tower_data.get_custom_data("unwalkable"))
				var vec=Vector2i(11,28) if can_place else Vector2i(2,25)
				map_layer.selection_layer.set_cell(check_pos, 0, vec)

		# 更新预览塔位置
		var local_pos1 = map_layer.base_layer.map_to_local(new_tile_pos)
		var center_offset = Vector2(
			map_layer.base_layer.tile_set.tile_size.x * (tower_size.x - 1) / 2.0,
			map_layer.base_layer.tile_set.tile_size.y * (tower_size.y - 1) / 2.0
		)
		preview_tower.global_position = map_layer.base_layer.to_global(local_pos1+center_offset)
		return
	
	# 左键释放逻辑
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var mouse_pos = GlobalCamera.get_global_mouse_position()
		var new_tile_pos = map_layer.base_layer.local_to_map(mouse_pos)
		
		if is_first_click:
			# 第一次点击 - 显示预览
			map_layer.selection_layer.clear()
			
			if not preview_tower:
				preview_tower = pre_tower.instantiate()
				var temp_towers = tower.instantiate()
				var tower_sprite = temp_towers.get_node("Sprite2D")
				var towers_size = temp_towers.size
				temp_towers.queue_free()
				
				preview_tower.get_node("Sprite2D").texture = tower_sprite.texture
				preview_tower.get_node("Sprite2D").scale = tower_sprite.scale
				preview_tower.get_node("Sprite2D").flip_h = tower_sprite.flip_h
				preview_towers_node.add_child(preview_tower)
				preview_tower.tower_size = towers_size
			
			var tower_size = preview_tower.tower_size
			
			for x in range(0, tower_size.x):
				for y in range(0, tower_size.y):
					var check_pos = new_tile_pos + Vector2i(x, y)
					var tile_data = map_layer.base_layer.get_cell_tile_data(check_pos)
					var obstruction_data = map_layer.obstruction_layer.get_cell_tile_data(check_pos)
					var tower_data = map_layer.tower_layer.get_cell_tile_data(check_pos)
					var can_place = tile_data and tile_data.get_custom_data("towerable") and is_in_light_range(new_tile_pos) and (obstruction_data == null or !obstruction_data.get_custom_data("unwalkable")) and (tower_data == null or !tower_data.get_custom_data("unwalkable"))
					var vec=Vector2i(11,28) if can_place else Vector2i(2,25)
					map_layer.selection_layer.set_cell(check_pos, 0, vec)

			if preview_tower:
				var local_pos1 = map_layer.base_layer.map_to_local(new_tile_pos)
				var center_offset = Vector2(
					map_layer.base_layer.tile_set.tile_size.x * (tower_size.x - 1) / 2.0,
					map_layer.base_layer.tile_set.tile_size.y * (tower_size.y - 1) / 2.0
				)
				preview_tower.global_position = map_layer.base_layer.to_global(local_pos1+center_offset)
			
			is_first_click = false
		else:
			# 第二次点击 - 放置塔
			current_highlighted_tile = map_layer.base_layer.local_to_map(mouse_pos)
			current_obstruction_tile = map_layer.obstruction_layer.local_to_map(mouse_pos)
			current_tile_pos = Vector2i(-1, -1)
			
			if current_highlighted_tile:
				temp_tower = tower.instantiate()
				var tower_size = temp_tower.size
				var can_place_all = true

				for x in range(0, tower_size.x):
					for y in range(0, tower_size.y):
						var check_pos = current_highlighted_tile + Vector2i(x, y)
						var tile_data = map_layer.base_layer.get_cell_tile_data(check_pos)
						var obstruction_data = map_layer.obstruction_layer.get_cell_tile_data(check_pos)
						var tower_data = map_layer.tower_layer.get_cell_tile_data(check_pos)
						var can_place = tile_data and tile_data.get_custom_data("towerable") and is_in_light_range(current_highlighted_tile) and (obstruction_data == null or !obstruction_data.get_custom_data("unwalkable")) and (tower_data == null or !tower_data.get_custom_data("unwalkable"))
						if !can_place:
							can_place_all = false
				
				if can_place_all:
					temp_tower.initial_tile_pos = current_highlighted_tile
					temp_tower.tower_destroyed.connect(_on_tower_destroyed)
					towers_node.add_child(temp_tower)
					var local_pos = map_layer.base_layer.map_to_local(current_highlighted_tile)
					var center_offset = Vector2(
						map_layer.base_layer.tile_set.tile_size.x * (temp_tower.size.x - 1) / 2.0,
						map_layer.base_layer.tile_set.tile_size.y * (temp_tower.size.y - 1) / 2.0
					)
					temp_tower.global_position = map_layer.base_layer.to_global(local_pos+center_offset)
					temp_tower.get_node("PointLight2D").visible=true
					if temp_tower.has_method("show_attack_range"):
						temp_tower.show_attack_range(false)
					
					for x in range(0, temp_tower.size.x):
						for y in range(0, temp_tower.size.y):
							var pos = current_highlighted_tile + Vector2i(x, y)
							map_layer.tower_layer.set_cell(pos, 0,Vector2i(27,12))
				
				map_layer.selection_layer.clear()
			
			if preview_tower:
				preview_tower.queue_free()
				preview_tower = null
			
			is_first_click = true


func _on_tower_destroyed(tile_pos: Vector2i, size1: Vector2i):
	# 清除tower_map标记
	for x in range(0, size1.x):
		for y in range(0, size.y):
			var pos = tile_pos + Vector2i(x, y)
			map_layer.tower_layer.set_cell(pos, -1)
			
	# 只有有高亮显示时才更新selection_map
	if preview_tower != null:
		# 获取preview_tower的位置
		var mouse_pos = GlobalCamera.get_global_mouse_position()
		var preview_pos = map_layer.base_layer.local_to_map(mouse_pos)
		var preview_size = preview_tower.tower_size
		
		# 只更新preview_tower范围内的不可放置格子
		for x in range(0, preview_size.x):
			for y in range(0, preview_size.y):
				var pos = preview_pos + Vector2i(x, y)
				var tile_data = map_layer.base_layer.get_cell_tile_data(pos)
				var obstruction_data = map_layer.obstruction_layer.get_cell_tile_data(pos)
				var tower_data = map_layer.tower_layer.get_cell_tile_data(pos)
				var can_place = tile_data and tile_data.get_custom_data("towerable") and is_in_light_range(pos) and (obstruction_data == null or !obstruction_data.get_custom_data("unwalkable")) and (tower_data == null or !tower_data.get_custom_data("unwalkable"))
				var vec=Vector2i(11,28) if can_place  else Vector2i(2,25)
				map_layer.selection_layer.set_cell(pos, 0, vec)
