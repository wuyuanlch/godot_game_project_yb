extends Camera2D

var move_speed = 100
var num_scale = 1.0
var min_scale = 0.5
var max_scale = 2.0
var move_direction = Vector2.ZERO
var actual_position = position
var target_position = position

var new_position
var camera_limits = Rect2(-70, -30, 600, 300) 


func _input(event):
	# 鼠标滚轮缩放处理
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			num_scale = min(num_scale + 0.05, max_scale)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			num_scale = max(num_scale - 0.05, min_scale)
		zoom = Vector2(num_scale, num_scale)
		


# 摄像机按WSAD上下左右移动
func _process(delta):
	# 实时检测按键状态
	move_direction = Vector2.ZERO
	if Input.is_action_pressed("up"):
		move_direction.y -= 1
	if Input.is_action_pressed("down"):
		move_direction.y += 1
	if Input.is_action_pressed("left"):
		move_direction.x -= 1
	if Input.is_action_pressed("right"):
		move_direction.x += 1
	
	# 平滑移动处理
	var new_position = position + move_direction.normalized() * move_speed * delta
	if move_direction != Vector2.ZERO:
		#position += move_direction.normalized() * move_speed * delta
		var viewport_half_size = get_viewport_rect().size / 2.0 / zoom

		## 窗口移动限制
		new_position.x = clamp(new_position.x, camera_limits.position.x + viewport_half_size.x, camera_limits.end.x - viewport_half_size.x)
		new_position.y = clamp(new_position.y, camera_limits.position.y + viewport_half_size.y, camera_limits.end.y - viewport_half_size.y)
		
		position = new_position
		
		
func _ready():
	## It's good practice to ensure the camera starts within limits
	var viewport_half_size = get_viewport_rect().size / 2.0 / zoom
	position.x = clamp(position.x, camera_limits.position.x + viewport_half_size.x, camera_limits.end.x - viewport_half_size.x)
	position.y = clamp(position.y, camera_limits.position.y + viewport_half_size.y, camera_limits.end.y - viewport_half_size.y)
	
# wzy
