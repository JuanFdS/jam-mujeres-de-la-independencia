@tool
extends Node3D

@export var posibles_escenas: Array[PackedScene]
@export var material: Material

@export_tool_button("Generar montanias")
var _generar_montanias = generar_montanias

func generar_montanias():
	get_children().map(func(child): child.queue_free())
	for i in range(30):
		var montania = posibles_escenas.pick_random().instantiate()
		add_child(montania)
		montania.scale = Vector3.ONE * 0.2
		montania.get_children().front().material_override = material
		montania.position.z = randf_range(-150, -500)
		#montania.scale *= abs(montania.position.z / 100)
		#montania.position.y -= montania.position.z
		montania.position.x = i * 2

func _ready() -> void:
	if not Engine.is_editor_hint():
		generar_montanias()
