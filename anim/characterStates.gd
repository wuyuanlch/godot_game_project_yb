extends Node
class_name characterStates

@onready var enemy_node: Enemies = get_owner() as Enemies
var canTransition: Callable = func(): return true	# canTransition: 可调用的过渡条件函数，默认返回true

func _ready():
	set_physics_process(false)
	set_process_input(false)

# 处理状态切换通知(5001=进入状态，5002=退出状态)
func _notification(what:int)->void:
	if what==5001:
		enterState()
		set_physics_process(true)
		set_process_input(true)
	elif what==5002:
		set_physics_process(false)
		set_process_input(false)
		exitState();

# 状态进入时的逻辑（空实现）
func enterState()->void:
	pass
# 状态退出时的逻辑（空实现）
func exitState()->void:
	pass

# 当碰撞到"active_towers"组对象时切换到攻击状态
func _on_body_entered(body)->void:
	if body.is_in_group("active_towers"):
		enemy_node.state_machine_node.switch_state(attack_state)

# 当离开"active_towers"组对象时切换到空闲状态
func _on_body_exited(body)->void:
	if body.is_in_group("active_towers"):
		enemy_node.state_machine_node.switch_state(idle_state)