class_name Player
extends CharacterBody3D

const SPEED = 0.8
const JUMP_VELOCITY = 2.0
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
const STUN_TIME = 0.25

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
	Running
}

var state: State = State.Idle
var _state_data: Dictionary = {}

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

func enter_state():
	match state:
		State.Attacking:
			_current_attack().start()

func _ready() -> void:
	add_to_group("player")
	$Debug.watch("State", func(): return State.keys()[state])
	animated_sprite_3d.animation_finished.connect(on_animation_finished)

func on_animation_finished():
	match state:
		State.Attacking:
			if animated_sprite_3d.animation == _current_attack().animation:
				change_state(State.Idle)

func _physics_process(delta: float) -> void:
	match state:
		State.Hurting:
			state_data()["stun_time_left"] -= delta
			if state_data()["stun_time_left"] < 0:
				change_state(State.Idle)
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		match state:
			State.Hurting:
				pass
			State.Attacking:
				if _current_attack().is_cancellable():
					change_state(State.Jumping)
					velocity.y = JUMP_VELOCITY
			_:
				change_state(State.Jumping)
				velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var movement := (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	match state:
		State.Hurting:
			direction = Vector3.ZERO
			movement = Vector3.ZERO
		State.Attacking:
			if _current_attack().is_cancellable() and (facing_direction * direction.x < 0):
				change_state(State.Running)
			else:
				direction = Vector3(facing_direction, 0, 0)
				movement = state_data()["attack"].movement_speed_multiplier * movement

	if direction.x:
		animated_sprite_3d.flip_h = direction.x < 0
		facing_direction = FacingDirection.Left if direction.x < 0 else FacingDirection.Right
	if movement:
		velocity.x = movement.x * SPEED
		velocity.z = movement.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	$HitBoxes.scale.x = facing_direction

	if Input.is_action_just_pressed("attack_fast"):
		try_fast_attack()

	move_and_slide()
	update_state_based_on_movement()
	_update_animation()

func hit(attack):
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
				if _current_attack().is_air and _current_attack().is_cancellable():
					change_state(State.Idle)

func try_fast_attack():
	match state:
		State.Hurting:
			pass
		State.Idle, State.Running:
			change_state(State.Attacking, { "attack": $HitBoxes/Attack1 })
		State.Jumping:
			change_state(State.Attacking, { "attack": $HitBoxes/AirAttack })
		State.Attacking:
			var next_attack = _current_attack().get_combo_attack()
			if next_attack:
				change_state(State.Attacking, { "attack": next_attack })

func _update_animation() -> void:
	match state:
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
