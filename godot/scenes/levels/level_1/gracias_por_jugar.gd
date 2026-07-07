extends Control

func _ready():
	visible = false
	$Button.pressed.connect(func(): get_tree().reload_current_scene())

func mostrar():
	visible = true

func _process(delta: float) -> void:
	if visible and Input.is_action_just_pressed("start"):
		get_tree().reload_current_scene()
