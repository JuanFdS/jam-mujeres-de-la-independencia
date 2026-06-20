extends Node3D

var watchers: Dictionary[String, Callable]
@onready var label_3d: Label3D = $Label3D

func watch(property_name: String, block: Callable):
	watchers[property_name] = block

func _process(_delta: float) -> void:
	label_3d.text = ""
	for property in watchers.keys():
		label_3d.text = "%s: %s}\n" % [property, watchers[property].call()]
