extends Node3D

@export var speed = 2.0
@export var direction: float = 0.0
@export var power: float = 1.0

func _ready() -> void:
	$VisibleOnScreenNotifier3D.screen_exited.connect(queue_free)
	$Area3D.area_entered.connect(on_area_entered)

func on_area_entered(area):
	area.hit(Attack.Hit.new(power, global_position, direction, 1.0))

func _physics_process(delta: float) -> void:
	global_translate(Vector3.RIGHT * direction * speed * delta)
