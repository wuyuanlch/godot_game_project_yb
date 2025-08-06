extends Node2D

# 敌人生成配置
@export_group("Spawn Settings")
@export var spawn_interval := 4.0 # 敌人生成间隔(秒)
@export var spawn_count := 3     # 每次生成的敌人数量
@export var small_enemies: Array[PackedScene]
# 节点引用
@export var map_layer: Node2D

var current_wave := 0
@export var max_waves := 15

var timer: Timer

# 使用寻路系统
func _ready():
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_spawn_timer)
	timer.start(spawn_interval)
	# 初始生成一批
	_on_spawn_timer()


func _on_spawn_timer():
	if current_wave >= max_waves:
		print("所有波数已生成！游戏胜利！")
		timer.stop()
		return
	
	if get_tree().get_nodes_in_group("Tower").is_empty():
		return
	
	current_wave += 1
	# 获取地图边缘有效生成位置
	var map_rect = map_layer.base_layer.get_used_rect()
	var valid_spawns = []
	var edge_cells = []
	
	# 检测边缘单元格
	for x in range(map_rect.position.x, map_rect.end.x):
		for y in range(map_rect.position.y, map_rect.end.y):
			var cell = Vector2i(x,y)
			if map_layer.base_layer.get_cell_source_id(cell) != -1:
				for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var neighbor = cell + dir
					if map_layer.base_layer.get_cell_source_id(neighbor) == -1:
						edge_cells.append(cell)
						break
	
	# 从边缘向内偏移1-3格作为生成位置
	for cell in edge_cells:
		var inward_dir = Vector2i.ZERO
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor = cell + dir
			if map_layer.base_layer.get_cell_source_id(neighbor) != -1:
				inward_dir = dir
				break
		if inward_dir != Vector2i.ZERO:
			for i in range(1, 4):
				var spawn_pos = cell + inward_dir * i
				if (map_layer.base_layer.get_cell_source_id(spawn_pos) != -1 
					and not map_layer.astar.is_point_solid(spawn_pos)):
					valid_spawns.append(spawn_pos)
	
	valid_spawns.shuffle()
	
	# 生成敌人
	for i in range(min(spawn_count, valid_spawns.size())):
		if small_enemies.is_empty():
			return
		
		var enemy_index = randi() % small_enemies.size()
		var enemy_scene = small_enemies[enemy_index]
		var enemy = enemy_scene.instantiate()
		enemy.position = map_layer.base_layer.map_to_local(valid_spawns[i])
		add_child(enemy)
