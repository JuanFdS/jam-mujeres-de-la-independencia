extends Area3D
@onready var camera_3d: Camera3D = %Camera3D

signal started

func _ready() -> void:
	body_entered.connect(on_body_entered)
	toggle_collision(false)

func on_body_entered(body):
	start()

func start():
	set_deferred("monitoring", false)
	camera_3d.stop_following_player()
	toggle_collision(true)
	started.emit()

func finish():
	camera_3d.stop_area_finished(self)
	# la pared de la izquierda la dejamos asi no se puede volver para atras
	$StaticBody3D2/CollisionShape3D.set_deferred("disabled", true)

func toggle_collision(value: bool):
	$StaticBody3D/CollisionShape3D.set_deferred("disabled", not value)
	$StaticBody3D2/CollisionShape3D.set_deferred("disabled", not value)
