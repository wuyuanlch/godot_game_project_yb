extends characterStates
class_name run_state

func enterState()->void:
	enemy_node.animPlayer.play("walk")
	if not enemy_node.chaseArea.body_entered.is_connected(_on_body_entered):
		enemy_node.chaseArea.body_entered.connect(_on_body_entered)
func exitState()->void:
	enemy_node.chaseArea.body_entered.disconnect(_on_body_entered)

func _physics_process(delta):
	if enemy_node.velocity==Vector2.ZERO:
		enemy_node.state_machine_node.switch_state(idle_state)


