extends CanvasLayer

@export var pause_panel: Panel
	
func start():
	hide() 
	
func quit_game():
	get_tree().quit()
