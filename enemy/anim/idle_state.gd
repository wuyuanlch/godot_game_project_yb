extends characterStates
class_name idle_state

	
func _on_enter() -> void:
	enemy_node.animPlayer.play("idle")
	if not enemy_node.chaseArea.body_entered.is_connected(_on_body_entered):
		enemy_node.chaseArea.body_entered.connect(_on_body_entered)


func _on_exit() -> void:
	enemy_node.chaseArea.body_entered.disconnect(_on_body_entered)


func _physics_process(delta):
	# 检测敌人速度，非零时切换到run_state状态
	if enemy_node.velocity!=Vector2.ZERO:
		enemy_node.state_machine_node.switch_state(run_state)
