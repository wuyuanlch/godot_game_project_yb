extends Button
class_name screenButtons

signal clicked(button)

func _on_pressed():
	clicked.emit(self)
