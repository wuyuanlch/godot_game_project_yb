extends Resource
class_name MonsterStats

@export var monster_name: String = "Unnamed Monster" # 怪物名称 (可选, 用于调试或UI)
#@export var texture: Texture2D                  # 怪物的纹理
@export var animations: SpriteFrames 
@export var health: int = 10                    # 怪物的血量
@export var power: int = 1                      # 怪物的强度/攻击力
@export var speed: int = 50                     # 怪物的移动速度 (可选)
#@export var defense: int = 1 				   # 怪物的护甲
