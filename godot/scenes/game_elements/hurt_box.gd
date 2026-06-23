extends Area3D

@export var hittable: Node3D

func _ready():
	if not hittable:
		hittable = get_parent()

func hit(attack: Attack.Hit):
	hittable.hit(attack)
