extends Node

@export var currentState :characterStates	# 初始状态
@export var states :Array[characterStates]=[]	# 所有状态数组

func _ready():
	# currentState.notification(5001);
	currentState.enter_state()

func switch_state(state_script: Script) -> void:
	var new_state = states.filter(func(s): return s.get_script() == state_script)[0] if states else null
	
	
	if not new_state:
		return
	if currentState.get_script()==state_script:
		return
	if not new_state.canTransition.call():
		return
	
	currentState.exit_state()
	currentState = new_state
	currentState.enter_state()
