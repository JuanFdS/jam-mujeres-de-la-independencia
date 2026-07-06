extends Node3D

signal finished

@export var time_until_hazard_start: float = 0.5
@export var time_until_disappear_after_hazard_started: float = 3.0
@onready var barrel: RigidBody3D = $Barrel

func start():
	$Warning.start()
	await get_tree().create_timer(time_until_hazard_start).timeout
	barrel.start()
	await get_tree().create_timer(time_until_disappear_after_hazard_started).timeout
	$Warning.queue_free()
	finished.emit()
