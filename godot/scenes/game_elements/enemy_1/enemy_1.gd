extends CharacterBody3D

signal defeated

@export var SPEED = 0.8
const JUMP_VELOCITY = 2.0

@export var max_hp: float = 10.0
@onready var hp: float = max_hp
@onready var times_it_will_fall: int = 1
@onready var times_it_has_already_fallen: int = 0
var points_at_which_it_will_fall: Array

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
var attacking: bool = false
var hurting: bool = false
var time_until_next_decision: float = 0.0
@onready var nearby_player_area: Area3D = $NearbyPlayerArea
@export var ATTACK_COOLDOWN: float = 1.5
var time_until_next_attack: float = 0.0
@export var in_screen_notifiers: Array[VisibleOnScreenNotifier3D]

const NEAR_SPOT_THRESHOLD: float = 0.05

var facing_direction: FacingDirection = FacingDirection.Right

enum FacingDirection {
	Left = -1,
	Right = 1
}


enum State {
	Idle,
	Attacking,
	Hurting,
	Following,
	KnockedDown,
	Defeated
}

var state = State.Idle
var _state_data = {}


func _ready() -> void:
	#$Debug.watch("State", func(): return State.keys()[state] )
	#$Debug.watch("Changing state in...", func(): return "%.2f" % time_until_next_decision )
	#$Debug.watch("HP: ", func(): return hp )
	animated_sprite_3d.animation_finished.connect(on_animation_finished)
	var step = max_hp / (times_it_will_fall + 1)
	for i in range(times_it_will_fall):
		points_at_which_it_will_fall.insert(i, step * (i + 1))
	points_at_which_it_will_fall.reverse()
	#$Debug.watch("Points at it will fall: ", func(): return points_at_which_it_will_fall )

func state_data():
	return _state_data[state]

func change_state(new_state: State, data = {}):
	exit_state()
	state = new_state
	if (data != {}) or (not _state_data.has(state)):
		_state_data[state] = data
	enter_state()

func exit_state():
	pass

func enter_state():
	match state:
		State.KnockedDown, State.Defeated:
			var attack = state_data().attack
			var knockback = attack.knockback
			velocity.x = attack.direction * knockback
		State.Hurting:
			var attack = state_data().attack
			var knockback = attack.knockback
			velocity.x = attack.direction * knockback
		State.Following:
			if state_data().has("closest_player") and state_data().has("spot"):
				var previous_player = state_data()["closest_player"]
				var spots = spots_of(previous_player)
				if spots.has_reservation(self):
					state_data()["spot"] = spots.spot(self)
					return

			var player = closest_player()
			state_data()["closest_player"] = player
			if not player:
				change_state(State.Idle)
				return
			var spot = spots_of(player).reserve_spot(self)
			state_data()["spot"] = spot
			if not spot:
				change_state(State.Idle)
				return

func spots_of(player):
	return player.get_node("SpotsForEnemies")

func _players() -> Array:
	return get_tree().get_nodes_in_group("player")


func on_animation_finished():
	if animated_sprite_3d.animation == "attack" or animated_sprite_3d.animation == "hurt":
		change_state(State.Idle)

func closest_player() -> Player:
	var players = _players().duplicate().filter(func(player): return spots_of(player).has_free_spots())
	if players.is_empty():
		return null
	players.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
	return players.front()

func update_velocity(delta):
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	match state:
		State.KnockedDown, State.Defeated, State.Hurting:
			velocity = velocity.move_toward(Vector3.ZERO, delta)
		State.Attacking:
			velocity = Vector3.ZERO
		State.Idle:
			velocity = Vector3.ZERO
		State.Following:
			var spot = state_data()["spot"]
			$DebugSphere.global_position = spot.global_position
			if not reached_spot():
				var direction :=\
					(transform.basis * (global_position.direction_to(spot.global_position) * Vector3(1, 0, 1))).normalized()
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
				facing_direction = FacingDirection.Left if velocity.x < 0 else FacingDirection.Right
			$HitBoxes.scale.x = -facing_direction


func on_player_is_reachable():
	match state:
		State.Idle, State.Following:
			if time_until_next_attack < 0.0 and in_screen_notifiers.all(func(notifier): return notifier.is_on_screen()):
				attack_player()

func attack_player():
	time_until_next_attack = ATTACK_COOLDOWN
	var nearby_player = nearby_player_area.get_overlapping_bodies().front()
	facing_direction = 1 if nearby_player.global_position.x > global_position.x else -1
	change_state(State.Attacking, { "attacked": nearby_player })

func process_state(delta: float):
	match state:
		State.KnockedDown:
			state_data().knocked_down_time_left -= delta
			if state_data().knocked_down_time_left < 0.0:
				change_state(State.Idle)
		State.Defeated:
			state_data().time_left -= delta
			if state_data().time_left < 0.0:
				queue_free()
				defeated.emit()

func _physics_process(delta: float) -> void:
	time_until_next_attack -= delta
	time_until_next_decision -= delta
	if time_until_next_decision <= 0:
		take_decision()
	process_state(delta)
	update_velocity(delta)
	move_and_slide()
	if nearby_player_area.has_overlapping_bodies():# and reached_spot():
		on_player_is_reachable()
	_update_animation()

func reached_spot() -> bool:
	return State.Following == state and state_data()["spot"].global_position.distance_to(global_position) < NEAR_SPOT_THRESHOLD

func take_decision() -> void:
	match state:
		State.Attacking, State.Hurting, State.KnockedDown, State.Defeated:
			return
	var next_state = [State.Idle, State.Following].filter(func(potential_new_state): return potential_new_state != state).pick_random()
	change_state(next_state)
	time_until_next_decision = randf_range(1.0, 3.0)

func _update_animation() -> void:
	animated_sprite_3d.flip_h = facing_direction == 1
	match state:
		State.Defeated:
			if not animated_sprite_3d.animation in ["knockedout", "defeated"]:
				animated_sprite_3d.play("knockedout")
			elif animated_sprite_3d.frame_progress >= 1.0:
				animated_sprite_3d.play("defeated")
		State.KnockedDown:
			if animated_sprite_3d.animation != "knockedout":
				animated_sprite_3d.play("knockedout")
		State.Hurting:
			if animated_sprite_3d.animation != "hurt":
				animated_sprite_3d.play("hurt")
		State.Attacking:
			if animated_sprite_3d.animation != "attack":
				animated_sprite_3d.play("attack")
		State.Idle, State.Following:
			if is_zero_approx(velocity.x) and is_zero_approx(velocity.z):
				animated_sprite_3d.play("idle")
			else:
				animated_sprite_3d.play("walk")

func hit(attack: Attack.Hit):
	match state:
		State.KnockedDown, State.Defeated:
			return
	hp -= attack.power
	if hp <= 0.0:
		change_state(State.Defeated, { "attack": attack, "time_left": 2.0 })
	elif times_it_has_already_fallen < times_it_will_fall and hp <= points_at_which_it_will_fall[times_it_has_already_fallen]:
		times_it_has_already_fallen += 1
		change_state(State.KnockedDown, { "attack": attack, "knocked_down_time_left": randf_range(1.5, 2.0) })
	else:
		change_state(State.Hurting, { "attack": attack })

	
