@tool
class_name Attack
extends Node3D

@onready var area_3d: Area3D = $Area3D
@export var power: float = 1.0
var attacker: CharacterBody3D
var collision_time_left: float = 0.0
@export var animation: String = ""
@export_storage var collision_frame_begin: int = 0
@export_storage var collision_frame_end: int = 0

@export_storage var combo_window_frame_begin: int = 0
@export_storage var combo_window_frame_end: int = 0
@export var next_combo_attack: Attack

func _extend_inspector_property(
	inspector: ExtendableInspector,
	_type: int,
	property_name: String,
	_hint_type: int,
	_hint_string: String,
	_usage_flags: int,
	_wide: bool):
		if property_name == "animation":
			var window_frame_selector = preload("uid://dd1jpdh0c2p1i").instantiate()
			window_frame_selector.animated_sprite_3d = _animated_sprite_3d()
			window_frame_selector.animation_name = animation
			window_frame_selector.collision_window = [collision_frame_begin, collision_frame_end]
			window_frame_selector.combo_window = [combo_window_frame_begin, combo_window_frame_end]
			inspector.add_property_editor("animation", window_frame_selector, true)
			window_frame_selector.animation_selected.connect(func(animation_name):
				animation = animation_name
			)
			window_frame_selector.collision_window_changed.connect(func(begin, end):
				collision_frame_begin = begin
				collision_frame_end = end
			)
			window_frame_selector.combo_window_changed.connect(func(begin, end):
				combo_window_frame_begin = begin
				combo_window_frame_end = end
			)
			return true
		return false

func _animated_sprite_3d() -> AnimatedSprite3D:
	return attacker.get_node("AnimatedSprite3D")

func _toggle_collision(value: bool) -> void:
	area_3d.set_deferred("monitoring", value)

func _ready() -> void:
	attacker = find_parent("HitBoxes").get_parent()
	if Engine.is_editor_hint():
		return
	_toggle_collision(false)
	area_3d.area_entered.connect(on_area_entered)
	_animated_sprite_3d().frame_changed.connect(on_frame_changed)
	_animated_sprite_3d().animation_changed.connect(on_frame_changed)

func on_frame_changed():
	var sprite := _animated_sprite_3d()
	var attack_should_collide = sprite.animation == animation and sprite.frame in range(collision_frame_begin, collision_frame_end)
	_toggle_collision(attack_should_collide)

func get_combo_attack():
	var sprite := _animated_sprite_3d()
	var can_combo = sprite.animation == animation and sprite.frame in range(combo_window_frame_begin, combo_window_frame_end)
	if can_combo:
		return next_combo_attack
	return null

func start():
	pass

func stop():
	pass

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if collision_time_left > 0.0:
		collision_time_left = move_toward(collision_time_left, 0.0, delta)
		if collision_time_left <= 0.0:
			_toggle_collision(false)

func on_area_entered(area_hit):
	area_hit.hit(Hit.new(power, attacker.global_position, attacker.facing_direction))

class Hit:
	var power: float
	var global_position: Vector3
	var direction: Player.FacingDirection = Player.FacingDirection.Left
	
	func _init(_power, _global_position, _direction):
		power = _power
		global_position = _global_position
		direction = _direction
