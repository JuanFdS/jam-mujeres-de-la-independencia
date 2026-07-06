extends Node3D

@onready var actions_in_order = get_children()

func _ready():
	get_parent().started.connect(start)

func start():
	for action in actions_in_order:
		action.start()
		await action.finished
	get_parent().finish()
