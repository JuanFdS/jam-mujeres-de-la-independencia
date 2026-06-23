extends CharacterBody3D

@export var SPEED = 0.8
const JUMP_VELOCITY = 2.0

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
var attacking: bool = false
var hurting: bool = false

enum State {
	Idle,
	Attacking,
	Hurting
}

var state = State.Idle

func change_state(new_state: State):
	state = new_state

func _players() -> Array:
	return get_tree().get_nodes_in_group("player")

func _ready() -> void:
	animated_sprite_3d.animation_finished.connect(on_animation_finished)

func on_animation_finished():
	if animated_sprite_3d.animation == "jab" or animated_sprite_3d.animation == "hurt":
		change_state(State.Idle)

func update_velocity():
	match state:
		State.Attacking:
			velocity = Vector3.ZERO
		State.Hurting:
			velocity = Vector3.ZERO
		State.Idle:
			var players = _players().duplicate()
			players.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
			var closest_player: Player = players.front()
			var direction :=\
				(transform.basis * (global_position.direction_to(closest_player.global_position) * Vector3(1, 0, 1))).normalized()
			velocity = direction * SPEED

func _physics_process(_delta: float) -> void:
	update_velocity()
	move_and_slide()
	_update_animation()

func attack_fast():
	if is_on_floor():
		change_state(State.Attacking)

func _update_animation() -> void:
	match state:
		State.Hurting:
			if animated_sprite_3d.animation != "hurt":
				animated_sprite_3d.play("hurt")
		State.Attacking:
			if animated_sprite_3d.animation != "jab":
				animated_sprite_3d.play("jab")
		State.Idle:
			if velocity.y > 0:
				if animated_sprite_3d.animation != "jump":
					animated_sprite_3d.play("jump")
			elif velocity.y < 0:
				animated_sprite_3d.play("fall")
			elif is_zero_approx(velocity.x) and is_zero_approx(velocity.z):
				animated_sprite_3d.play("idle")
			else:
				animated_sprite_3d.play("walk")

func hit(attack: Attack.Hit):
	var knockback = 0.1
	global_position.x += attack.direction * knockback
	change_state(State.Hurting)
