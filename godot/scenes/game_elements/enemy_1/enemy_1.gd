extends CharacterBody3D

@export var SPEED = 0.8
const JUMP_VELOCITY = 2.0

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
var attacking: bool = false
var hurting: bool = false
var time_until_next_decision: float = 0.0
@onready var nearby_player_area: Area3D = $NearbyPlayerArea
@export var ATTACK_COOLDOWN: float = 1.5
var time_until_next_attack: float = 0.0

var facing_direction: FacingDirection = FacingDirection.Right

enum FacingDirection {
	Left = -1,
	Right = 1
}


enum State {
	Idle,
	Attacking,
	Hurting,
	Following
}

var state = State.Idle
var state_data = {}

func change_state(new_state: State, data = {}):
	state = new_state
	state_data[state] = data

func _players() -> Array:
	return get_tree().get_nodes_in_group("player")

func _ready() -> void:
	$Debug.watch("State", func(): return State.keys()[state] )
	$Debug.watch("Changing state in...", func(): return "%.2f" % time_until_next_decision )
	animated_sprite_3d.animation_finished.connect(on_animation_finished)

func on_animation_finished():
	if animated_sprite_3d.animation == "jab" or animated_sprite_3d.animation == "hurt":
		change_state(State.Idle)

func update_velocity(delta):
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	match state:
		State.Attacking:
			velocity = Vector3.ZERO
		State.Hurting:
			velocity = Vector3.ZERO
		State.Idle:
			velocity = Vector3.ZERO
		State.Following:
			var players = _players().duplicate()
			players.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
			var closest_player: Player = players.front()
			var direction :=\
				(transform.basis * (global_position.direction_to(closest_player.global_position) * Vector3(1, 0, 1))).normalized()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			facing_direction = FacingDirection.Left if velocity.x < 0 else FacingDirection.Right
			$HitBoxes.scale.x = -facing_direction


func on_player_is_reachable():
	match state:
		State.Idle, State.Following:
			if time_until_next_attack < 0.0:
				attack()

func attack():
	time_until_next_attack = ATTACK_COOLDOWN
	var nearby_player = nearby_player_area.get_overlapping_bodies().front()
	facing_direction = 1 if nearby_player.global_position.x > global_position.x else -1
	change_state(State.Attacking, { "attacked": nearby_player })

func _physics_process(delta: float) -> void:
	time_until_next_attack -= delta
	time_until_next_decision -= delta
	if time_until_next_decision <= 0:
		take_decision()
	update_velocity(delta)
	move_and_slide()
	if nearby_player_area.has_overlapping_bodies():
		on_player_is_reachable()
	_update_animation()

func take_decision() -> void:
	match state:
		State.Attacking:
			return
	var next_state = [State.Idle, State.Following].pick_random()
	change_state(next_state)
	time_until_next_decision = randf_range(1.0, 3.0)

func _update_animation() -> void:
	animated_sprite_3d.flip_h = facing_direction == 1
	match state:
		State.Hurting:
			if animated_sprite_3d.animation != "hurt":
				animated_sprite_3d.play("hurt")
		State.Attacking:
			if animated_sprite_3d.animation != "jab":
				animated_sprite_3d.play("jab")
		State.Idle, State.Following:
			if is_zero_approx(velocity.x) and is_zero_approx(velocity.z):
				animated_sprite_3d.play("idle")
			else:
				animated_sprite_3d.play("walk")

func hit(attack: Attack.Hit):
	var knockback = 0.1
	global_position.x += attack.direction * knockback
	change_state(State.Hurting)
