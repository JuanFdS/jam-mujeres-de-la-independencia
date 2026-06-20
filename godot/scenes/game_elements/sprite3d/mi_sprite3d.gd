extends AnimatedSprite3D

@onready var shadow: AnimatedSprite3D
@export var render_priority_offset: int = 0

func _ready() -> void:
	set_process(false)
	await get_tree().process_frame
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_create_shadow()
	$"../Debug".watch("render priority", func(): return render_priority)
	set_process(true)

func _process(_delta: float) -> void:
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
	
