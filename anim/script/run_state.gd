extends characterStates
class_name run_state


func _on_enter() -> void:
	enemy_node.animPlayer.play("walk")
	if not enemy_node.chaseArea.body_entered.is_connected(_on_body_entered):
		enemy_node.chaseArea.body_entered.connect(_on_body_entered)


func _on_exit() -> void:
	enemy_node.chaseArea.body_entered.disconnect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if enemy_node.velocity == Vector2.ZERO:
		enemy_node.state_machine_node.switch_state(idle_state)


func _on_body_entered(body) -> void:
	if body.is_in_group("active_towers"):
		enemy_node.state_machine_node.switch_state(attack_state)
