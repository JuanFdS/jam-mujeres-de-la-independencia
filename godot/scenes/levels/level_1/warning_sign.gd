extends Sprite3D

@export var hazard: Node3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	visible = false

func start():
	global_position.z = hazard.global_position.z
	animation_player.play("blink")
