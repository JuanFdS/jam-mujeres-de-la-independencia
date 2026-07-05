extends Camera3D

@export var follow_speed: float = 1.5
@export var player: CharacterBody3D
var following_player: bool = true
var last_stop_position: float = -100.0
@onready var original_y := global_position.y

func _process(delta: float) -> void:
	if following_player:
		global_position.x = max(last_stop_position, player.global_position.x)
		last_stop_position = global_position.x
		h_offset = move_toward(h_offset, 0.0, follow_speed * delta)
		if y_position():
			global_position.y = y_position()
	$Pivot/SpotLight3D.position.x = h_offset
	$Pivot/SpotLight3D.position.y = v_offset

func y_position():
	var ray_cast: RayCast3D = player.get_node("RayCast3D")
	if ray_cast.get_collider():
		return original_y + ray_cast.get_collision_point().y

func stop_following_player():
	following_player = false
	
func follow_player():
	h_offset = global_position.x - max(last_stop_position, player.global_position.x)
	if y_position():
		v_offset = global_position.y - y_position()
	following_player = true

func stop_area_finished(stop_area):
	follow_player()
