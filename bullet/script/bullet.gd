extends CharacterBody2D

@export var bullet_Stats:Resource=load("res://bullet/bullet01.tres")

# 子弹的攻击代码，碰到敌人会造成伤害和消失
var target:Node2D
# var speed:int =bullet_Stats.speed
# var bullet_damage:int=bullet_Stats.power

func _process(delta):
	if is_instance_valid(target):
		var target_pos=target.get_node("CollisionShape2D").global_position
		velocity=global_position.direction_to(target_pos)*bullet_Stats.speed
		look_at(target_pos)

		move_and_slide()
	else:
		queue_free()


func _on_collision_body_entered(body):
	#print(1)
	if body.is_in_group("Enemy"):
		body.take_damage(bullet_Stats.power)
		#print(2)
		queue_free()

	if body.is_in_group("Tower"):
		body.tower_take_damage(bullet_Stats.power)
		print(2)
		queue_free()
# wzy
