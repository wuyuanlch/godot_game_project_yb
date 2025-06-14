extends Node

@export var currentState :Node	# 初始状态
@export var states :Array[characterStates]=[]	# 所有状态数组

func _ready():
	currentState.notification(5001);

func switch_state(state_script: Script) -> void:
	# 查找与参数state_script匹配的状态实例
	var new_state = states.filter(func(s): return s.get_script() == state_script)[0] if states else null
	# 目标状态是否存在
	if not new_state:
		return
	# 是否已经是当前状态
	if currentState.get_script()==state_script:
		return
	# 是否满足过渡条件(canTransition)
	if not new_state.canTransition.call():
		return
	
	currentState.notification(5002) 	# 退出状态
	currentState=new_state	#切换成新状态
	currentState.notification(5001)		# 进入状态
