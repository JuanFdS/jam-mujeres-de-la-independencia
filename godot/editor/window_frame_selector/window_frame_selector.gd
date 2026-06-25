@tool
extends VBoxContainer

signal animation_selected(animation_name: String)
signal collision_window_changed(begin: int, end: int)
signal combo_window_changed(begin: int, end: int)
signal cancel_window_changed(begin: int, end: int)

var animated_sprite_3d: AnimatedSprite3D
var animation_name: String :
	set(new_value):
		animation_name = new_value
		if not is_node_ready():
			await ready
		on_animation_selected()
@onready var option_button: OptionButton = $HBoxContainer/OptionButton
@onready var collision_sliders = [%CollisionFrameBegin, %CollisionFrameEnd]
@onready var combo_sliders = [%ComboWindowBegin, %ComboWindowEnd]
@onready var cancel_sliders = [%CancelWindowBegin, %CancelWindowEnd]
@onready var slider_pairs: Array = [collision_sliders, combo_sliders, cancel_sliders]
@onready var play_button: Button = %PlayButton
var collision_window: Array :
	set(values):
		if not is_node_ready():
			await ready
		set_window_value(values, collision_sliders)
var combo_window: Array :
	set(values):
		if not is_node_ready():
			await ready
		set_window_value(values, combo_sliders)
var cancel_window: Array :
	set(values):
		if not is_node_ready():
			await ready
		set_window_value(values, cancel_sliders)

func set_window_value(values, hsliders):
	var begin = values.front()
	if begin:
		hsliders.front().value = begin
	var end = values.back()
	if end:
		hsliders.back().value = end

func _sprite_frames() -> SpriteFrames:
	return animated_sprite_3d.sprite_frames

func _ready() -> void:
	if not animated_sprite_3d:
		return
	play_button.pressed.connect(on_play_button_pressed)
	for animation in _sprite_frames().get_animation_names():
		option_button.add_item(animation)
		if animation_name == animation:
			option_button.select(option_button.item_count - 1)
	option_button.item_selected.connect(on_item_selected)
	for slider_pair in slider_pairs:
		for slider in slider_pair:
			slider.min_value = 0
			slider.ticks_on_borders = true
			slider.value_changed.connect(func(new_value):
				animated_sprite_3d.frame = int(new_value)
				animated_sprite_3d.animation = animation_name
				if slider in collision_sliders:
					emit_window_changed(collision_window_changed, collision_sliders)
				elif slider in combo_sliders:
					emit_window_changed(combo_window_changed, combo_sliders)
				elif slider in cancel_sliders:
					emit_window_changed(cancel_window_changed, cancel_sliders)
				queue_redraw()
			)

func emit_window_changed(window_signal: Signal, hsliders: Array):
	var values = hsliders.map(func(slider): return slider.value)
	window_signal.emit(values.min(), values.max())

func on_play_button_pressed():
	animated_sprite_3d.play(animation_name)

func on_item_selected(idx: int):
	self.animation_name = option_button.get_item_text(idx)
	animated_sprite_3d.animation = animation_name
	animation_selected.emit(animation_name)
	queue_redraw()

func _frame_count() -> int:
	if not animated_sprite_3d:
		return 0
	return _sprite_frames().get_frame_count(animation_name)

func on_animation_selected():
	var frame_count: int = _frame_count()
	for slider_pair in slider_pairs:
		for slider in slider_pair:
			slider.tick_count = frame_count + 1
			slider.max_value = frame_count

func _global_grabber_position(slider: HSlider) -> Vector2:
	return slider.get_global_rect().position + Vector2.RIGHT * (slider.get_rect().size.x * (slider.value / slider.max_value))

func is_closer_to_mouse(slider_a: HSlider, slider_b: HSlider):
	return _global_grabber_position(slider_a).distance_squared_to(get_global_mouse_position()) < _global_grabber_position(slider_b).distance_squared_to(get_global_mouse_position())

func _process(_delta: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		for _slider_windows in slider_pairs:
			var slider_windows = _slider_windows.duplicate()
			slider_windows.sort_custom(self.is_closer_to_mouse)
			slider_windows.front().mouse_filter = Control.MOUSE_FILTER_STOP
			slider_windows.back().mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect: Rect2 = $CollisionFrameBegin.get_rect()
	var width: float = rect.size.x
	var step_width: float = width / max(_frame_count(), 1)
	for slider_window_pair in slider_pairs:
		var begin = slider_window_pair.front()
		var end = slider_window_pair.back()
		var collision_frame_begin: float = min(begin.value, end.value)
		var collision_frame_end: float = max(begin.value, end.value)
		draw_rect(
			Rect2(
				begin.position + Vector2.RIGHT * step_width * collision_frame_begin,
				Vector2(step_width * max(0, collision_frame_end - collision_frame_begin), rect.size.y)
				),
			Color.GREEN * Color(1,1,1,0.5)
		)
