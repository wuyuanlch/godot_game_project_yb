extends Node
class_name characterStates

@onready var enemy_node: Enemies = get_owner() as Enemies
var canTransition: Callable = func(): return true	# canTransition: 可调用的过渡条件函数，默认返回true

func _ready():
	set_physics_process(false)
	set_process_input(false)

	
func enter_state() -> void:
	set_physics_process(true)
	set_process_input(true)
	_on_enter()

func exit_state() -> void:
	set_physics_process(false)
	set_process_input(false)
	_on_exit()
	
func _on_enter() -> void:
	pass

func _on_exit() -> void:
	pass


# 当碰撞到"active_towers"组对象时切换到攻击状态
func _on_body_entered(body)->void:
	if body.is_in_group("active_towers"):
		enemy_node.state_machine_node.switch_state(attack_state)

# 当离开"active_towers"组对象时切换到空闲状态
func _on_body_exited(body)->void:
	if body.is_in_group("active_towers"):
		enemy_node.state_machine_node.switch_state(idle_state)
