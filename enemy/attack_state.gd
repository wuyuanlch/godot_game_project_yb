extends characterStates
class_name attack_state

func enterState()->void:
	enemy_node.animPlayer.play("attack")
	if not enemy_node.chaseArea.body_exited.is_connected(_on_body_exited):
		enemy_node.chaseArea.body_exited.connect(_on_body_exited)

func exitState()->void:
	enemy_node.chaseArea.body_exited.disconnect(_on_body_exited)
