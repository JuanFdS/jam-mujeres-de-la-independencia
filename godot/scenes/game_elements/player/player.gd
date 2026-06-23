class_name Player
extends CharacterBody3D

const SPEED = 0.8
const JUMP_VELOCITY = 2.0
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D

var facing_direction: FacingDirection = FacingDirection.Right

enum FacingDirection {
	Left = -1,
	Right = 1
}

enum State {
	Idle,
	Attacking,
	Hurting
}

var state: State = State.Idle
var _state_data: Dictionary = {}

func _current_attack():
	match state:
		State.Attacking:
			return state_data()["attack"]
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
	animated_sprite_3d.animation_finished.connect(on_animation_finished)

func on_animation_finished():
	match state:
		State.Attacking:
			if animated_sprite_3d.animation == _current_attack().animation:
				change_state(State.Idle)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var movement := (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if State.Attacking == state:
		direction = Vector3.ZERO
		movement = Vector3.ZERO

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
	_update_animation()

func try_fast_attack():
	match state:
		State.Idle:
			if is_on_floor():
				change_state(State.Attacking, { "attack": $HitBoxes/Attack1 })
		State.Attacking:
			var next_attack = _current_attack().get_combo_attack()
			if next_attack:
				change_state(State.Attacking, { "attack": next_attack })

func _update_animation() -> void:
	match state:
		State.Attacking:
			animated_sprite_3d.play(_current_attack().animation)
		_:
			if velocity.y > 0:
				if animated_sprite_3d.animation != "jump":
					animated_sprite_3d.play("jump")
			elif velocity.y < 0:
				animated_sprite_3d.play("fall")
			elif is_zero_approx(velocity.x) and is_zero_approx(velocity.z):
				animated_sprite_3d.play("idle")
			else:
				animated_sprite_3d.play("walk")
