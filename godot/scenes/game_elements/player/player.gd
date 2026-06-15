extends CharacterBody3D


const SPEED = 0.8
const JUMP_VELOCITY = 2.0
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D

var attacking: bool = false

func _ready() -> void:
	animated_sprite_3d.animation_finished.connect(on_animation_finished)

func on_animation_finished():
	if animated_sprite_3d.animation == "jab":
		attacking = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var movement := (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if attacking:
		direction = Vector3.ZERO
		movement = Vector3.ZERO

	if direction.x:
		animated_sprite_3d.flip_h = direction.x < 0
	if movement:
		velocity.x = movement.x * SPEED
		velocity.z = movement.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if Input.is_action_just_pressed("attack_fast"):
		attack_fast()

	move_and_slide()
	_update_animation()

func attack_fast():
	if is_on_floor():
		attacking = true

func _update_animation() -> void:
	if attacking:
		if animated_sprite_3d.animation != "jab":
			animated_sprite_3d.play("jab")
	elif velocity.y > 0:
		if animated_sprite_3d.animation != "jump":
			animated_sprite_3d.play("jump")
	elif velocity.y < 0:
		animated_sprite_3d.play("fall")
	elif is_zero_approx(velocity.x) and is_zero_approx(velocity.z):
		animated_sprite_3d.play("idle")
	else:
		animated_sprite_3d.play("walk")
