extends RigidBody3D
@onready var area_3d: Area3D = $Area3D

func _ready() -> void:
	area_3d.area_entered.connect(on_area_entered)

func on_area_entered(body):
	body.hit(Attack.Hit.new(4, global_position, sign(linear_velocity.x), 1.0))
	queue_free()
