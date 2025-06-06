extends NinePatchRect

# 已完成UI的基本功能，拖拽UI可将塔移除，可看预览塔，高亮区
@onready var tower = preload("res://tower/tower.tscn")
@export var map: TileMapLayer
@export var towers_node:Node2D# 专门放置防御塔的节点
@export var preview_towers_node:Node2D#专门放置预览塔的节点
@export var selection_map: TileMapLayer#高亮区的变色节点

var current_highlighted_tile = null
var preview_tower
var current_tile_pos: Vector2i = Vector2i(-1, -1)


func is_in_light_range(tile_pos: Vector2i) -> bool:
	var mouse_pos = map.map_to_local(tile_pos)
	var global_pos = map.to_global(mouse_pos)
	
	for tower_node in towers_node.get_children():
		var light = tower_node.get_node_or_null("PointLight2D")
		if light:
			var light_radius = light.texture_scale * 7 * sqrt(light.height)  # 估算灯光半径
			if global_pos.distance_to(tower_node.global_position) <= light_radius:
				return true
	return false

func _on_gui_input(event):
	if event is InputEventMouseMotion and event.button_mask == 1:
		var mouse_pos = GlobalCamera.get_global_mouse_position()# 可以直接用这个map.get_global_mouse_position()
		var new_tile_pos = map.local_to_map(mouse_pos)

		selection_map.clear()  # 清除之前的高亮
		var tile_data = map.get_cell_tile_data(new_tile_pos)
		var can_place = tile_data and tile_data.get_custom_data("towerable") and !has_tower(new_tile_pos) and is_in_light_range(new_tile_pos)
		var tile_id = 5 if can_place else 6  # 可放置用5，不可用6
		selection_map.set_cell(new_tile_pos, tile_id, Vector2i(0,0))
		
		# 移动时出现预览塔
		if not preview_tower:
			preview_tower = tower.instantiate()
			preview_tower.set_process(false)
			preview_tower.can_look=false			# 预览塔转向暂停
			preview_tower.can_shoot=false		# 预览塔射击暂停
			preview_tower.get_node("PointLight2D").visible=false
			preview_towers_node.add_child(preview_tower)
			
			# 显示预览塔的攻击范围 
			if preview_tower.has_method("show_attack_range"):
				preview_tower.show_attack_range(true)

		if preview_tower:
			var local_pos1 = map.map_to_local(new_tile_pos)
			preview_tower.global_position = map.to_global(local_pos1)
			
	# elif event is InputEventMouseButton and event.button_mask == 0:
	# 修复滚动键也可以放置塔
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		#var mouse_pos1 = get_global_mouse_position()
		var mouse_pos1 = GlobalCamera.get_global_mouse_position()# 可以直接用这个map.get_global_mouse_position()
		
		current_highlighted_tile = map.local_to_map(mouse_pos1)
		current_tile_pos = Vector2i(-1, -1)
		
		# 放开鼠标后出现放置塔
		if current_highlighted_tile:
			
			var tile_data = map.get_cell_tile_data(current_highlighted_tile)
			if tile_data and tile_data.get_custom_data("towerable") and !has_tower(current_highlighted_tile) and is_in_light_range(current_highlighted_tile):
				var tempTower = tower.instantiate()
				
				# 当玩家松开鼠标确认放置防御塔时才添加到 "active_towers" 组内
				tempTower.add_to_group("active_towers")
				
				towers_node.add_child(tempTower)
				var local_pos = map.map_to_local(current_highlighted_tile)
				tempTower.global_position = map.to_global(local_pos)
				tempTower.get_node("PointLight2D").visible=true

				# 对于实际放置的塔，默认隐藏其攻击范围 
				# （你可以根据需要，例如在选中塔的时候再显示它）
				if tempTower.has_method("show_attack_range"):
					tempTower.show_attack_range(false)
					
				# 后续可能增加的逻辑...
				
			selection_map.clear()
		
		if preview_tower:
			preview_tower.queue_free()
			preview_tower = null


func has_tower(tile_pos: Vector2i) -> bool:
	for tower1 in towers_node.get_children():
		if map.local_to_map(tower1.global_position) == tile_pos:
			return true
	return false
# wzy
