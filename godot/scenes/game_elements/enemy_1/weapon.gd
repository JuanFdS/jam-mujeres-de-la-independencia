extends Node3D

@onready var animated_sprite_3d: AnimatedSprite3D = $"../AnimatedSprite3D"
const PROJECTILE = preload("res://scenes/game_elements/enemy_1/projectile.tscn")

@export var power: float = 1.0

func _ready() -> void:
	animated_sprite_3d.animation_changed.connect(func():
		if animated_sprite_3d.animation == "attack":
			scale.x = -owner.facing_direction
			var projectile = PROJECTILE.instantiate()
			owner.get_parent().add_child(projectile)
			projectile.power = power
			projectile.global_position = $SpawnPosition.global_position
			projectile.direction = owner.facing_direction
	)

func _physics_process(delta: float) -> void:
	scale.x = -owner.facing_direction
	
