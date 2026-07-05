extends Camera3D

@export var follow_speed: float = 0.5
@export var player: CharacterBody3D
var following_player: bool = true

func _process(delta: float) -> void:
	if following_player:
		global_position.x = player.global_position.x
		h_offset = move_toward(h_offset, 0.0, follow_speed * delta)
	$Pivot/SpotLight3D.position.x = h_offset

func stop_following_player():
	following_player = false
	
func follow_player():
	h_offset = global_position.x - player.global_position.x
	following_player = true
