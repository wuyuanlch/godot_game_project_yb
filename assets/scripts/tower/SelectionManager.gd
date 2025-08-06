extends Node

# 定义一个信号，当选择发生变化时发出
signal selection_changed(new_selection)

var current_selection = null


func select(node):
	if node == current_selection:
		return

	# 如果之前有选中的对象，先取消它的选中状态
	if is_instance_valid(current_selection):
		if current_selection.has_method("deselect"):
			current_selection.deselect()

	# 更新当前选中的对象
	current_selection = node

	# 如果新选中的对象有效，则通知它被选中了
	if is_instance_valid(current_selection):
		if current_selection.has_method("select"):
			current_selection.select()

	# 发出信号，通知全局选择已变更
	selection_changed.emit(current_selection)



func deselect_all():
	select(null)
