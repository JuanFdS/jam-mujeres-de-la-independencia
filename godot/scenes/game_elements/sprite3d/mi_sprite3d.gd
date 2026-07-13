@tool
extends AnimatedSprite3D

const DEFAULT_FPS_FOR_ANIMATION: int = 10

var fps_for_all_animations: int = DEFAULT_FPS_FOR_ANIMATION
@onready var shadow: AnimatedSprite3D
@export var render_priority_offset: int = 10
@export var all_animations_same_fps: bool = false :
	set(new_value):
		all_animations_same_fps = new_value
		notify_property_list_changed()

func _property_can_revert(property: StringName) -> bool:
	return property in ["fps_for_all_animations"]

func _property_get_revert(property: StringName) -> Variant:
	if property == "fps_for_all_animations":
		return DEFAULT_FPS_FOR_ANIMATION
	return null

func _get_property_list() -> Array[Dictionary]:
	if all_animations_same_fps:
		return [{
			"name": "fps_for_all_animations",
			"type": TYPE_INT,
			
		}]

	return []

func _ready() -> void:
	
	if Engine.is_editor_hint(): return 
	if all_animations_same_fps:
		for animation_name in sprite_frames.get_animation_names():
			sprite_frames.set_animation_speed(animation_name, fps_for_all_animations)
	set_process(false)
	_create_shadow()
	await get_tree().process_frame
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	#$"../Debug".watch("render priority", func(): return render_priority)
	set_process(true)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return 
	render_priority = round(global_position.z * 100.0) + render_priority_offset
	shadow.animation = animation
	for property in ["flip_h", "animation", "frame"]:
		shadow[property] = self[property]

func _create_shadow():
	shadow = duplicate()
	shadow.script = null
	add_child(shadow)
	shadow.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	shadow.scale = Vector3.ONE
	shadow.position = Vector3.ZERO
	#shadow.offset.y = 100
	
