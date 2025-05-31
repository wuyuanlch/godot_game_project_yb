class_name Bullet
extends CharacterBody2D


# 子弹的攻击代码，碰到敌人会造成伤害和消失
var target:Node2D
var speed:int = 50

var enemy_bullet_damage: int 
var tower_bullet_damage: int = 2
var is_enemy_bullet:bool = false  
var is_tower_bullet:bool = false  

func _process(delta):
	if is_instance_valid(target):
		var target_pos=target.get_node("CollisionShape2D").global_position
		velocity=global_position.direction_to(target_pos) * speed
		look_at(target_pos)

		move_and_slide()
	else:
		queue_free()


func _on_collision_body_entered(body):
	#print(1)
	if body.is_in_group("Enemy"):
		if is_tower_bullet:
			body.take_damage(tower_bullet_damage)
		#print(tower_bullet_damage)
		queue_free()

	elif body.is_in_group("Tower"):
		if is_enemy_bullet:
			body.tower_take_damage(enemy_bullet_damage)
		#print(2)
		queue_free()
# wzy
