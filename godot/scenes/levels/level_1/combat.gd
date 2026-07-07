extends Node3D

@export var trigger_node_path: NodePath = NodePath("..")
@onready var trigger_node = get_node_or_null(trigger_node_path)
@export var spawn_points: Array = []
@export var delay_in_seconds: float = 0.0
@onready var enemies: Array = []
@export var start_on_stop_area_start: bool = true

signal finished

func _ready() -> void:
	if spawn_points.is_empty():
		spawn_points = get_children()
	if trigger_node.has_signal("started") and start_on_stop_area_start:
		trigger_node.started.connect(start)

func start():
	spawn_enemies()

func spawn_enemies():
	for spawn_point in spawn_points:
		var enemy = spawn_point.enemy_scene.instantiate()
		spawn_point.add_child(enemy)
		enemies.push_back(enemy)
		enemy.defeated.connect(func(): enemy_defeated(enemy))

func enemy_defeated(enemy):
	enemies.erase(enemy)
	if enemies.is_empty():
		if trigger_node.has_method("finish"):
			trigger_node.finish()
		finished.emit()

	
