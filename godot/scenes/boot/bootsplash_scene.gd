class_name BootsplashScene
extends Control

@export var fade_duration:float = 0.5
@export var stay_duration:float = 0.1
@export var node:PackedScene
@export var next_scene:PackedScene
@export var interuptable:bool = true

@onready var control = %NodeContainer
@onready var instance:Node2D = node.instantiate()
var fade_in_tween: Tween

var fading_out: bool = false

func _ready():
	instance.modulate.a = 0.0
	control.add_child(instance)
	fade_in_tween = create_tween()
	fade_in_tween.set_trans(Tween.TRANS_CUBIC)
	fade_in_tween.set_ease(Tween.EASE_IN)
	fade_in_tween.tween_property(instance, "modulate:a", 1.0, fade_duration)\
	.from(0.0)\
	.finished.connect(_fade_out)
	
func _process(_delta):
	if interuptable and (Input.is_action_just_pressed("exit") or Input.is_action_just_pressed("continue")):
		_fade_out()
	
func _fade_out():
	if fading_out:
		return
	fading_out = true
	if is_instance_valid(fade_in_tween):
		fade_in_tween.kill()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	await tween.tween_property(instance, "modulate:a", 0.0, fade_duration / 3).finished
	_change_scene()

func _change_scene():
	get_tree().change_scene_to_packed(next_scene)
