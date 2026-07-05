extends Node3D
const ENEMY = preload("uid://dh702s8odk4e6")

@export var trigger_node_path: NodePath = NodePath("..")
@onready var trigger_node = get_node_or_null(trigger_node_path)
@export var spawn_points: Array = []

@onready var enemies: Array = []

signal combat_finished

func _ready() -> void:
	if spawn_points.is_empty():
		spawn_points = get_children()
	if trigger_node.has_signal("started"):
		trigger_node.started.connect(start_combat)
	$"../Debug".watch("Size", func(): return enemies.size())

func start_combat():
	spawn_enemies()

func spawn_enemies():
	for spawn_point in spawn_points:
		var enemy = ENEMY.instantiate()
		spawn_point.add_child(enemy)
		enemies.push_back(enemy)
		enemy.defeated.connect(func(): enemy_defeated(enemy))

func enemy_defeated(enemy):
	enemies.erase(enemy)
	if enemies.is_empty():
		if trigger_node.has_method("finish"):
			trigger_node.finish()
		combat_finished.emit()

	
