extends Node2D
@onready var pause_panel: Panel = $PauseUI/Pause/PausePanel

# Called when the node enters the scene tree for the first time.
func _ready():
	pause_panel.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
