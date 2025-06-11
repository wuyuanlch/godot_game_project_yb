extends Node
class_name characterStates

@onready var enemy_node: Enemies = get_owner() as Enemies
var canTransition: Callable = func(): return true

func _ready():
	set_physics_process(false)
	set_process_input(false)

func _notification(what:int)->void:
	if what==5001:
		enterState()
		set_physics_process(true)
		set_process_input(true)
	elif what==5002:
		set_physics_process(false)
		set_process_input(false)
		exitState();
func enterState()->void:
	pass
func exitState()->void:
	pass

func _on_body_entered(body)->void:
	if body.is_in_group("active_towers"):
		enemy_node.state_machine_node.switch_state(attack_state)

func _on_body_exited(body)->void:
	if body.is_in_group("active_towers"):
		enemy_node.state_machine_node.switch_state(idle_state)