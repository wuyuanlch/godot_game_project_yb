class_name Level
extends TileMapLayer


#删除下面代码，转移到hexTileMap.gd中
# var mouse_position := Vector2.ZERO

# var astar :=AStarGrid2D.new()

# func _ready():
# 	astar.region=get_used_rect()
# 	astar.cell_size=tile_set.tile_size

# 	astar.default_compute_heuristic=AStarGrid2D.HEURISTIC_EUCLIDEAN
# 	astar.default_estimate_heuristic=AStarGrid2D.HEURISTIC_EUCLIDEAN
# 	astar.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ALWAYS
# 	astar.update()

# 	for x in range(astar.region.position.x,astar.region.end.x):
# 		for y in range(astar.region.position.y,astar.region.end.y):
# 			var coord=Vector2i(x,y)
# 			var tile_data:=get_cell_tile_data(coord)
# 			if tile_data and tile_data.get_custom_data("unwalkable"):
# 				astar.set_point_solid(coord)

# func _process(delta):
# 		mouse_position = get_global_mouse_position()
#wzy
