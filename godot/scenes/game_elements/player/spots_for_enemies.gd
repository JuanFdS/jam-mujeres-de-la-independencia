extends Node3D

# PositionNode -> Enemy
@onready var spots: Dictionary

func _ready() -> void:
	for position_node in get_children():
		spots[position_node] = null

func has_free_spots() -> bool:
	return spots.keys().any(is_free)

func is_free(position_node) -> bool:
	return spots[position_node] == null

func has_reservation(enemy) -> bool:
	return spots.find_key(enemy) != null

func reserve_spot(enemy: Node3D):
	var free_spots: Array = spots.keys().filter(is_free)
	if free_spots.is_empty():
		return
	var enemy_position := enemy.global_position
	free_spots.sort_custom(func(a: Node3D, b: Node3D):
		return a.global_position.distance_squared_to(enemy_position) < b.global_position.distance_squared_to(enemy_position)
	)
	var closest_free_spot: Node3D = free_spots.front()
	spots[closest_free_spot] = enemy
	return closest_free_spot

func free_spot(enemy: Node3D):
	var occupied_spot: Node3D = spots.find_key(enemy)
	spots[occupied_spot] = null
	
func spot(enemy: Node3D):
	var occupied_spot: Node3D = spots.find_key(enemy)
	return occupied_spot

func _physics_process(delta: float) -> void:
	for spot in spots.keys():
		var enemy = spots[spot]
		if enemy:
			spot.global_position.y = enemy.global_position.y
