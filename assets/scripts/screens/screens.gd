extends CanvasLayer

@onready var start_UI=$StartUI
@onready var pause_UI=$PauseUI

var current_scenen=null

func _ready():
	register_buttons()
	change_screen(start_UI)

func register_buttons():
	var buttons =get_tree().get_nodes_in_group("ScreenButton")
	if buttons.size()>0:
		for button in buttons:
			if button is screenButtons:
				button.clicked.connect(_on_button_pressed)

func _on_button_pressed(button):
	match button.name:
		"StartButton":
			change_screen(null)
		"StopButton":
			get_tree().paused = true
			change_screen(pause_UI)
		"ResumeButton":
			change_screen(null)
			get_tree().paused = false
		"SaveButton":
			save_button_pressed()
		"LoadButton":
			load_button_pressed()
			get_tree().paused = false
		"QuitButton":
			get_tree().quit()


func change_screen(new_screen):
	if current_scenen!=null:
		current_scenen.disappear()
		print(2)
	current_scenen=new_screen
	print(current_scenen)
	if current_scenen!=null:
		current_scenen.appear()
		print(3)

func load_button_pressed():
	var data=ResourceLoader.load("res://assets/scripts/save/load/scene_data.tres") as SceneData
	var towers=get_tree().get_nodes_in_group("Tower")
	for tower in towers:
		tower.queue_free()
	for tower in data.tower_array:
		var tower_node=tower.instantiate()
		tower_node.add_to_group("Tower")
		get_tree().current_scene.get_node("Game/Towers").add_child(tower_node)
	var enemies=get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		enemy.queue_free()
		
	for enemy in data.enemy_array:
		var enemy_node=enemy.instantiate()
		get_tree().current_scene.get_node("Game/Spawner").add_child(enemy_node)
	change_screen(null)
	print("load")

func save_button_pressed():
	var data=SceneData.new()
	
	var towers=get_tree().get_nodes_in_group("Tower")
	for tower in towers:
		var tower_scene=PackedScene.new()
		tower_scene.pack(tower)
		data.tower_array.append(tower_scene)
	var enemies=get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		var enemy_scene=PackedScene.new()
		enemy_scene.pack(enemy)
		data.enemy_array.append(enemy_scene)
	ResourceSaver.save(data,"res://assets/scripts/save/load/scene_data.tres")
	print("save")
