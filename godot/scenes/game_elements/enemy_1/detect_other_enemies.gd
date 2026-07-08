extends Area3D

@onready var enemy = get_parent()

func _ready():
	enemy.entered_state.connect(func(state):
		if state == Enemy.State.KnockedDown and enemy.state_data()["hits_others"]:
			set_deferred("monitoring", true)
			await get_tree().create_timer(0.5).timeout
			set_deferred("monitoring", false)
	)
	enemy.exited_state.connect(func(state):
		if state == Enemy.State.KnockedDown:
			set_deferred("monitoring", false)
	)
	body_entered.connect(on_body_entered)

func on_body_entered(an_enemy):
	if an_enemy == enemy:
		return
	an_enemy.hit(Attack.Hit.new(2, global_position, sign(enemy.velocity.x), 2))
