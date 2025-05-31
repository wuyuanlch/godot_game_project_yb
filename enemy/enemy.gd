extends CharacterBody2D

## 怪物类型数据数组
#在 enemy.tscn 场景配置这个数组，填入多个 MonsterStats 资源
@export var available_monster_types: Array[MonsterStats]

## 运行时确定的怪物属性 (不再 @export)
var current_monster_stats: MonsterStats 
var health: int
var power: int
var speed: int = 50 # 默认速度, 会被 MonsterStats 覆盖
var max_health: int

# 使用相对路径获取grid (Spawner子节点需要向上两级)
@onready var grid: Node2D = $"../../Map"
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar		

var target_path : Array[Vector2i] = []
var current_grid_pos: Vector2i  # 添加敌人当前网格位置

var target_tower: Node2D = null # 当前目标防御塔
var recheck_towers_timer: Timer # 用于周期性重新检查塔的计时器
var is_placed: bool = false # 新增：标记塔是否已正式放置，默认为 false
var towers_in_range: Array[Node2D] = [] # 范围内的防御塔数组

const RECHECK_INTERVAL: float = 0.5 # 每隔1秒重新检查一次塔

var bullet: PackedScene=preload("res://bullet/enemy_bullet.tscn")
var curr: Node2D
var bullet_damage: int
var can_shoot: bool=true

const bullet_stats = preload("res://bullet/enemy_bullet/default.tres")


func _ready():
	# 从配置的类型中随机选择一个
	current_monster_stats = available_monster_types.pick_random()
	if current_monster_stats:
		apply_monster_stats(current_monster_stats)
	else:
		max_health = 1 
		health = max_health
		update_health_bar() 

	
	# 初始化并启动用于重新检查防御塔的计时器
	recheck_towers_timer = Timer.new()
	recheck_towers_timer.wait_time = RECHECK_INTERVAL
	recheck_towers_timer.one_shot = false # 设置为重复触发
	recheck_towers_timer.timeout.connect(update_target_and_path)
	add_child(recheck_towers_timer)
	recheck_towers_timer.start()

	# 初始时检查一次防御塔 (延迟调用以确保场景中其他节点已准备好)
	call_deferred("update_target_and_path")


func find_closest_tower() -> Node2D:
	var closest_tower: Node2D = null
	var min_distance_sq: float = INF # 使用距离的平方以避免开方运算

	if not is_instance_valid(grid) or not is_instance_valid(grid.base_layer):
		printerr("find_closest_tower: Grid 或 base_layer 未准备好。")
		return null
	
	# 在寻找最近塔之前更新当前网格位置
	current_grid_pos = grid.base_layer.local_to_map(global_position)

	var available_towers: Array = get_tree().get_nodes_in_group("active_towers")
	
	if available_towers.is_empty():
		return null # 没有找到任何塔

	for tower_candidate in available_towers:
		if not is_instance_valid(tower_candidate): 
			continue

		var tower_grid_pos: Vector2i = grid.base_layer.local_to_map(tower_candidate.global_position)
		var distance_sq: float = current_grid_pos.distance_squared_to(tower_grid_pos)

		if distance_sq < min_distance_sq:
			min_distance_sq = distance_sq
			closest_tower = tower_candidate
			
	return closest_tower


func update_target_and_path() -> void:
	if not is_instance_valid(grid) or not grid.astar:
		printerr("update_target_and_path: Grid 或 AStar 未准备好。")
		target_path = [] 
		return

	var new_target_tower: Node2D = find_closest_tower()

	if new_target_tower == null: 
		target_tower = null
		target_path = [] 
		return

	# 如果目标塔改变了，或者当前没有路径，则重新计算路径
	if new_target_tower != target_tower or target_path.is_empty():
		target_tower = new_target_tower
		
		# 确保用于寻路的起点 current_grid_pos 是最新的
		current_grid_pos = grid.base_layer.local_to_map(global_position)
		var tower_map_pos: Vector2i = grid.base_layer.local_to_map(target_tower.global_position)
		
		# 检查起点和终点对于A*寻路是否有效（是否是障碍物）
		if grid.astar.is_point_solid(current_grid_pos) or grid.astar.is_point_solid(tower_map_pos):
			target_path = [] 
			return

		target_path = grid.astar.get_id_path(current_grid_pos, tower_map_pos)
		
		if target_path.is_empty() and current_grid_pos != tower_map_pos :
			pass
			

func update_health_bar() -> void:
	if health_bar: 
		health_bar.max_value = max_health
		health_bar.value = health
		#print("健康: ", health)
		#print("健康bar: ", health_bar.value)
		
		if health <= 0:
			health_bar.visible = false 
	
	# 受伤时才显示血条
	health_bar.visible = health < max_health


func apply_monster_stats(stats: MonsterStats):
	if not is_instance_valid(stats):
		return

	self.max_health = stats.health
	self.health = stats.health
	self.power = stats.power
	if stats.speed > 0: 
		self.speed = stats.speed
	
	if stats.texture:
		sprite_2d.texture = stats.texture
	
	update_health_bar()


# 改为 _physics_process 以处理物理运动
func _physics_process(delta: float):
	if not is_instance_valid(grid) or not is_instance_valid(grid.base_layer):
		velocity = Vector2.ZERO 
		move_and_slide()
		return

	# 如果有防御塔在攻击范围内，则停止移动
	if not towers_in_range.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 更新敌人当前的网格位置 
	current_grid_pos = grid.base_layer.local_to_map(global_position)

	if target_tower == null or not is_instance_valid(target_tower):
		# 如果没有目标塔或目标塔失效 
		# recheck_towers_timer 会周期性地尝试寻找新塔
		# 在此期间，如果路径也为空，则敌人应该停止
		if target_path.is_empty():
			velocity = Vector2.ZERO
			move_and_slide()
			return

	if not target_path.is_empty():
		var next_grid_point: Vector2i = target_path[0]
		var target_world_position: Vector2 = grid.base_layer.map_to_local(next_grid_point)
		
		var direction: Vector2 = (target_world_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide() 

		# 检查是否到达路径点
		if global_position.distance_to(target_world_position) < 4.0:
			target_path.remove_at(0)
			if target_path.is_empty():
				# 已经到达目标塔所在的格子附近
				# recheck_towers_timer 将会处理后续的目标更新或重新寻路
				velocity = Vector2.ZERO # 到达后暂时停止，等待下一次timer触发索敌
				update_target_and_path()
	else:
		velocity = Vector2.ZERO # 停止移动
		move_and_slide()


func _process(delta):
	if is_instance_valid(curr):
		if can_shoot:
			shoot(bullet_stats)
			can_shoot=false
			$shootingCoolDown.start()

#射击
func shoot(stats: BulletStats)->void:
	var temp_bullet:CharacterBody2D=bullet.instantiate()
	
	temp_bullet.target = curr
	temp_bullet.is_enemy_bullet = true
	
	temp_bullet.enemy_bullet_damage = stats.damage 
	# print(temp_bullet.tower_bullet_damage)
	temp_bullet.speed = stats.speed

	if temp_bullet.has_node("Sprite2D"): 
		var bullet_sprite: Sprite2D = temp_bullet.get_node("Sprite2D")
		if stats.texture: 
			bullet_sprite.texture = stats.texture
			
	get_node("BulletContainer").add_child(temp_bullet)
	temp_bullet.global_position = $Aim.global_position


func take_damage(damage:int)->void:
	health -= damage
	health = max(health, 0)
	update_health_bar()

	if health<=0:
		queue_free()


func _on_attack_range_body_exited(body):
	if body.is_in_group("active_towers"):
		towers_in_range.erase(body)
		if towers_in_range.is_empty():
			update_target_and_path()  # 重新寻找目标并计算路径


func _on_attack_range_body_entered(body):
	if body.is_in_group("active_towers"):
		towers_in_range.append(body)
		velocity = Vector2.ZERO
		curr=body
		move_and_slide()


func _on_shooting_cool_down_timeout():
	can_shoot=true
