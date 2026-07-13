class_name Player
extends CharacterBody3D

@export var player_id: int = 1
@export var vertical_speed = 1.5
@export var horizontal_speed = 1.0
const JUMP_VELOCITY = 2.0
@export var DASH_SPEED = 1.7
@export var DASH_ATTACK_SPEED = 2.5
@export var DASH_TIME: float = 0.5
@export var AFTER_IMAGE_DASH_COOLDOWN: float = 0.1
@export var AFTER_IMAGE_ATTACK_DASH_COOLDOWN: float = 0.02
@export var time_until_next_after_image_dash: float = 0.0
var dash_time_left: float = 0.0
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
const STUN_TIME = 0.25
@export var max_hp: float = 20
@onready var hp: float = max_hp :
	set(new_value):
		hp = new_value
		%HealthBar.value = hp
@export var dash_cooldown: float = 0.3
var time_until_next_cooldown: float = 0.0

var buffered_inputs: Dictionary[StringName, float] = {}
@export var buffer_time = 0.2

var facing_direction: FacingDirection = FacingDirection.Right

enum FacingDirection {
	Left = -1,
	Right = 1
}

enum State {
	Idle,
	Attacking,
	Hurting,
	Jumping,
	Running,
	Dashing,
	Grabbing
}

enum AttackType {
	Dash,
	Air,
	Ground
}

var state: State = State.Idle
var _state_data: Dictionary = {}

func _ready() -> void:
	add_to_group("player")
	#$Debug.watch("State", func(): return State.keys()[state])
	#$Debug.watch("V", func(): return velocity.x)
	
	animated_sprite_3d.animation_finished.connect(on_animation_finished)
	%HealthBar.max_value = max_hp
	%HealthBar.value = hp
	$GrabArea.body_entered.connect(func(body):
		match state:
			State.Running:
				grab(body)
	)

func grab(enemy):
	change_state(State.Grabbing, { "grabbed_enemy": enemy })
	enemy.be_grabbed_by(self, %GrabPoint)

func _current_attack() -> Attack:
	match state:
		State.Attacking:
			return (state_data()["attack"] as Attack)
	return null

func change_state(new_state: State, new_state_data: Dictionary = {}):
	exit_state()
	state = new_state
	_state_data[state] = new_state_data
	enter_state()

func state_data() -> Dictionary:
	return _state_data[state]

func exit_state():
	match state:
		State.Attacking:
			_current_attack().stop()
		State.Dashing:
			time_until_next_after_image_dash = 0.0
			time_until_next_cooldown = dash_cooldown
		State.Grabbing:
			state_data()["grabbed_enemy"].freed_from_grab()

func enter_state():
	match state:
		State.Dashing:
			dash_time_left = DASH_TIME
		State.Attacking:
			match _current_attack().attack_type:
				AttackType.Dash:
					var new_facing_direction = Input.get_axis("left_%s" % player_id, "right_%s" % player_id)
					if new_facing_direction != 0:
						facing_direction = new_facing_direction
					velocity = Vector3.ZERO
			_current_attack().start()



func on_animation_finished():
	match state:
		State.Attacking:
			if animated_sprite_3d.animation == _current_attack().animation:
				change_state(State.Idle)

func is_action_buffered(action_name: StringName) -> bool:
	return buffered_inputs.has(action_name) and buffered_inputs[action_name] > 0.0

func action_consumed_from_buffer(action_name: StringName) -> void:
	buffered_inputs.erase(action_name)

func buffer_action(action_name: StringName) -> void:
	buffered_inputs[action_name] = buffer_time

func _physics_process(delta: float) -> void:
	for buffered_input in buffered_inputs.keys():
		buffered_inputs[buffered_input] = move_toward(buffered_inputs[buffered_input], 0.0, delta)
	time_until_next_cooldown -= delta
	match state:
		State.Hurting:
			state_data()["stun_time_left"] -= delta
			if state_data()["stun_time_left"] < 0:
				change_state(State.Idle)
		State.Attacking:
			match _current_attack().attack_type:
				AttackType.Dash:
					time_until_next_after_image_dash -= delta
					if time_until_next_after_image_dash < 0.0:
						after_image()
						time_until_next_after_image_dash = AFTER_IMAGE_ATTACK_DASH_COOLDOWN
		State.Dashing:
			time_until_next_after_image_dash -= delta
			if time_until_next_after_image_dash < 0.0:
				after_image()
				time_until_next_after_image_dash = AFTER_IMAGE_DASH_COOLDOWN
			dash_time_left -= delta
			if dash_time_left < 0.0:
				change_state(State.Idle)

	if not is_on_floor():
		velocity += get_gravity() * delta

	var jump_action = "jump_%s" % player_id
	if Input.is_action_just_pressed(jump_action):
		buffer_action(jump_action)
	if is_action_buffered(jump_action) and is_on_floor():
		match state:
			State.Hurting:
				pass
			State.Attacking:
				if _current_attack().is_cancellable():
					action_consumed_from_buffer(jump_action)
					change_state(State.Jumping)
					velocity.y = JUMP_VELOCITY
			_:
				action_consumed_from_buffer(jump_action)
				change_state(State.Jumping)
				velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left_%s" % player_id, "right_%s" % player_id, "up_%s" % player_id, "down_%s" % player_id)
	var movement := (transform.basis * Vector3(sign(input_dir.x), 0, sign(input_dir.y)))
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	match state:
		State.Grabbing:
			movement = Vector3.ZERO
		State.Dashing:
			direction = Vector3(facing_direction, 0, 0)
			movement = direction * DASH_SPEED
		State.Hurting:
			direction = Vector3.ZERO
			movement = Vector3.ZERO
		State.Attacking:
			if _current_attack().is_cancellable() and (facing_direction * direction.x < 0):
				change_state(State.Running)
			else:
				direction = Vector3(facing_direction, 0, 0)
				match _current_attack().attack_type:
					AttackType.Dash:
						movement = velocity.lerp(direction * DASH_ATTACK_SPEED, 1 - exp(-15 * delta))
					_:
						movement = _current_attack().movement_speed_multiplier * movement

	if direction.x:
		animated_sprite_3d.flip_h = direction.x < 0
		facing_direction = FacingDirection.Left if direction.x < 0 else FacingDirection.Right
	if movement:
		velocity.x = movement.x * horizontal_speed
		velocity.z = movement.z * vertical_speed
	else:
		velocity.x = move_toward(velocity.x, 0, horizontal_speed)
		velocity.z = move_toward(velocity.z, 0, vertical_speed)
	

	$HitBoxes.scale.x = facing_direction
	$GrabPointPivot.scale.x = facing_direction

	var attack_action = "attack_%s" % player_id
	if Input.is_action_just_pressed(attack_action):
		buffer_action(attack_action)
	if is_action_buffered(attack_action):
		try_fast_attack()
		
	var dash_action = "dash_%s" % player_id
	if Input.is_action_just_pressed(dash_action):
		buffer_action(dash_action)

	if is_action_buffered(dash_action):
		try_dash()

	move_and_slide()
	update_state_based_on_movement()
	_update_animation()

func hit(attack: Attack.Hit):
	match state:
		State.Dashing:
			return
	hp -= attack.power
	change_state(State.Hurting, { "stun_time_left": STUN_TIME })

func update_state_based_on_movement():
	if not is_on_floor():
		match state:
			State.Idle, State.Running:
				change_state(State.Jumping)
			State.Attacking:
				pass

	if is_on_floor():
		var is_moving = not(is_zero_approx(velocity.x) and is_zero_approx(velocity.z))
		match state:
			State.Idle:
				if is_moving:
					change_state(State.Running)
			State.Running:
				if not is_moving:
					change_state(State.Idle)
			State.Jumping:
				if is_on_floor():
					change_state(State.Idle)
			State.Attacking:
				if _current_attack().attack_type == AttackType.Air and _current_attack().is_cancellable():
					change_state(State.Idle)

func try_dash():
	var dash_action = "dash_%s" % player_id
	if time_until_next_cooldown > 0.0:
		return
	match state:
		State.Hurting:
			pass
		State.Idle, State.Running:
			action_consumed_from_buffer(dash_action)
			change_state(State.Dashing, { "dash_direction": facing_direction })
		State.Attacking:
			if _current_attack().is_cancellable():
				if _current_attack().attack_type == AttackType.Air:
					pass
				else:
					action_consumed_from_buffer(dash_action)
					change_state(State.Dashing, { "dash_direction": facing_direction })

func try_fast_attack():
	var attack_action = "attack_%s" % player_id
	match state:
		State.Grabbing:
			action_consumed_from_buffer(attack_action)
			state_data()["grabbed_enemy"].thrown()
			change_state(State.Attacking, { "attack": $HitBoxes/Attack1 })
		State.Hurting:
			pass
		State.Dashing:
			action_consumed_from_buffer(attack_action)
			change_state(State.Attacking, { "attack": $HitBoxes/DashAttack })
		State.Idle, State.Running:
			action_consumed_from_buffer(attack_action)
			change_state(State.Attacking, { "attack": $HitBoxes/Attack1 })
		State.Jumping:
			action_consumed_from_buffer(attack_action)
			change_state(State.Attacking, { "attack": $HitBoxes/AirAttack })
		State.Attacking:
			var next_attack = _current_attack().get_combo_attack()
			if next_attack:
				action_consumed_from_buffer(attack_action)
				change_state(State.Attacking, { "attack": next_attack })

func _update_animation() -> void:
	if state == State.Dashing:
		$AnimatedSprite3D.modulate.a = 0.5
	else:
		$AnimatedSprite3D.modulate.a = 1.0
	
	match state:
		State.Grabbing:
			animated_sprite_3d.play("grab")
		State.Dashing:
			if animated_sprite_3d.animation != "dash":
				animated_sprite_3d.play("dash")
		State.Hurting:
			animated_sprite_3d.play("hurt")
		State.Attacking:
			animated_sprite_3d.play(_current_attack().animation)
		State.Running:
			animated_sprite_3d.play("walk")
		State.Idle:
			animated_sprite_3d.play("idle")
		State.Jumping:
			if velocity.y > 0:
				if animated_sprite_3d.animation != "jump":
					animated_sprite_3d.play("jump")
			elif velocity.y < 0:
				animated_sprite_3d.play("fall")
				
				
func after_image():
	var current_texture = $AnimatedSprite3D.sprite_frames.get_frame_texture($AnimatedSprite3D.animation, $AnimatedSprite3D.frame % $AnimatedSprite3D.sprite_frames.get_frame_count($AnimatedSprite3D.animation))
	var after_image := Sprite3D.new()
	after_image.centered = $AnimatedSprite3D.centered
	after_image.offset = $AnimatedSprite3D.offset
	after_image.billboard = $AnimatedSprite3D.billboard
	after_image.texture_filter = $AnimatedSprite3D.texture_filter
	# Set the texture and frame of the after_image
	after_image.flip_h = $AnimatedSprite3D.flip_h
	after_image.texture = current_texture
	after_image.global_transform = $AnimatedSprite3D.global_transform
	#after_image.frame = $Sprite2D.frame
	## Calculate the frame size and coordinates
	#var frame_size = current_texture.get_size() / Vector2($Sprite2D.hframes, $Sprite2D.vframes)
	#var frame_coords = Vector2($Sprite2D.frame % $Sprite2D.hframes, $Sprite2D.frame / $Sprite2D.hframes) * frame_size
	# Enable region and set the region rectangle
	#after_image.region_enabled = true
	#after_image.region_rect = Rect2(frame_coords, frame_size)
	# Set global position and modulate alpha
	#after_image.modulate.a = 0.5
	# Add after_image as a child
	add_child(after_image)
	after_image.render_priority = $AnimatedSprite3D.render_priority - 1
	
	after_image.top_level = true
	after_image.global_position = $AnimatedSprite3D.global_position
	# Wait before removing the after_image
	create_tween().tween_property(after_image, "modulate:a", 0.0, 0.5).from(0.8).set_trans(Tween.TRANS_CUBIC)
	await get_tree().create_timer(0.5).timeout
	after_image.queue_free()
