extends Node

@export var currentState :Node
@export var states :Array[characterStates]=[]

func _ready():
	currentState.notification(5001);

func switch_state(state_script: Script) -> void:
	var new_state = states.filter(func(s): return s.get_script() == state_script)[0] if states else null

	if not new_state:
		return
	if currentState.get_script()==state_script:
		return
	if not new_state.canTransition.call():
		return
	
	currentState.notification(5002)
	currentState=new_state
	currentState.notification(5001)
