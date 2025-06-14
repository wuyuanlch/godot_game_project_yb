extends CanvasLayer

@export var pause_panel: Panel
	
func start():
	hide() 
	
func quit_game():
	get_tree().quit()


func _on_load_button_pressed():
	var save_file_path = "user://scene_data.tres"
	
	# 无存档
	if not FileAccess.file_exists(save_file_path):
		return 
		
	var data=ResourceLoader.load(save_file_path) as SceneData
	if not data:
		return
		
	var towers=get_tree().get_nodes_in_group("active_towers")
	for tower in towers:
		tower.queue_free()
		
	for tower in data.tower_array:
		var tower_node=tower.instantiate()
		tower_node.add_to_group("active_towers")
		get_tree().current_scene.get_node("Towers").add_child(tower_node)
		
	var enemies=get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		enemy.queue_free()
		
	for enemy in data.enemy_array:
		var enemy_node=enemy.instantiate()
		get_tree().current_scene.get_node("Spawner").add_child(enemy_node)
	hide()
