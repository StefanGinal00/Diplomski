extends "res://tests/shaft_guard_combat_smoke.gd"

const Impact = preload("res://ProjectileImpact.gd")
var art: Sprite2D
var damage_events: Array[Dictionary] = []


func _prepare() -> void:
	art._clear_damage_feedback()
	player.invulnerability_timer.stop()
	player._on_invulnerability_timer_timeout()
	player.max_health = 10
	player.current_health = 10
	player.second_breath_active = false
	player.health_changed.emit(10, 10)
	art._clear_damage_feedback()
	player.velocity = Vector2(7, 2)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_player_damage_feedback_save.json"
	state.start_new_game("normal")
	player = _player()
	player.position = Vector2(300, 100)
	player.get_node("Camera2D").enabled = false
	art = player.get_node("Appearance")
	art.set_process(false)
	player.damage_received.connect(func(amount: int, force: Vector2, outcome: String): damage_events.append({"amount": amount, "force": force, "outcome": outcome}))
	var body_rid: RID = player.player_collision.shape.get_rid()
	var body_transform := player.player_collision.transform
	var attack_shape: RID = player.attack_cast.shape.get_rid()
	for armored in [false, true]:
		if armored:
			state.add_item("guardian_band")
			state.equip_item("guardian_band", "defense")
		for force in [Vector2(120, -80), Vector2(-120, -80), Vector2.ZERO]:
			_prepare()
			await process_frame
			player.attack_cooldown_timer.stop()
			player.try_attack()
			var cooldown := player.attack_cooldown_timer.time_left
			var visual_time := player.attack_visual_timer.time_left
			var before := damage_events.size()
			player.take_damage(3, force)
			var amount := 2 if armored else 3
			_check(player.current_health == 10 - amount and damage_events.size() == before + 1 and damage_events.back().amount == amount and damage_events.back().outcome == "hurt", "Accepted post-defense hit event wrong")
			_check(player.velocity == (Vector2(7, 2) if force == Vector2.ZERO else force), "Feedback changes knockback")
			_check(player.is_invulnerable and player.modulate.a == 0.5 and player.invulnerability_timer.time_left > 0, "Feedback changes immunity")
			_check(art.damage_flash_remaining == 0.12 and art.self_modulate != Color.WHITE and art.attack_class.is_empty(), "Damage flash/attack cancellation missing")
			_check(is_instance_valid(art.damage_burst) and art.damage_burst.style == "player_hurt", "Hurt burst missing")
			if is_instance_valid(art.damage_burst):
				var aim := Vector2(signf(force.x), 0) if force.x != 0 else Vector2.UP
				_check(art.damage_burst.global_position.is_equal_approx(player.global_position + Vector2(0, -3)) and art.damage_burst.global_transform.x.is_equal_approx(aim), "Hurt burst direction/position wrong")
			var immunity := player.invulnerability_timer.time_left
			player.take_damage(3, force)
			_check(damage_events.size() == before + 1, "Invulnerable hit emits extra event")
			art._process(0.16)
			_check(art.self_modulate == Color.WHITE and art.damage_flash_remaining == 0, "Damage flash persists")
			_check(player.attack_cooldown_timer.time_left == cooldown and player.attack_visual_timer.time_left == visual_time and player.invulnerability_timer.time_left == immunity, "Feedback changes combat timers")
	state.unequip_defense()
	_prepare()
	await process_frame
	var before := damage_events.size()
	player.take_damage(0)
	player.take_damage(-1)
	player.heal(2)
	player.begin_safe_rest()
	player.take_damage(3)
	player.end_safe_rest()
	player.set_physics_process(false)
	_check(damage_events.size() == before and art.self_modulate == Color.WHITE and not is_instance_valid(art.damage_burst), "Heal/rest/rejected hits create damage feedback")
	# Rescue returns to exactly the same HP: health deltas alone miss this hit.
	_prepare()
	player.current_health = 2
	player.health_changed.emit(2, 10)
	art._clear_damage_feedback()
	player.activate_second_breath()
	player.take_damage(5, Vector2(-150, -60))
	_check(player.current_health == 2 and not player.second_breath_active and not player.is_dead and player.velocity == Vector2(7, 2), "Second Breath mechanics changed")
	_check(damage_events.back().outcome == "second_breath" and art.hurt_remaining > 0 and art.damage_burst.style == "player_rescue", "Equal-HP rescue lacks separate feedback")
	_check(player.is_invulnerable and player.modulate.a == 0.5, "Rescue immunity changed")
	for event in ["rest", "room", "transition", "hidden", "pause"]:
		_prepare()
		await process_frame
		player.take_damage(1)
		if event == "rest":
			state.checkpoint_resting.emit("test_lamp")
		elif event == "room":
			state.room_changed.emit("test_room")
		elif event == "transition":
			root.get_node("RoomTransition").transition_started.emit("test_room")
		elif event == "hidden":
			player.process_mode = Node.PROCESS_MODE_DISABLED
			player.hide()
			player.show()
			player.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			art.set_process(true)
			paused = true
			var flash: float = art.damage_flash_remaining
			for frame in range(3):
				await process_frame
			_check(art.damage_flash_remaining == flash, "Pause consumes damage flash")
			paused = false
			art.set_process(false)
			art._clear_damage_feedback()
		_check(art.damage_flash_remaining == 0 and art.self_modulate == Color.WHITE and not is_instance_valid(art.damage_burst), "Cleanup failed: " + event)
		await process_frame
	_prepare()
	await process_frame
	for index in range(Impact.MAX_ACTIVE):
		Impact.spawn(player, Vector2.ZERO, Vector2.RIGHT, "arc", Color.WHITE, "actor")
	player.take_damage(1)
	_check(player.current_health == 9 and art.damage_flash_remaining > 0 and not is_instance_valid(art.damage_burst), "Saturated effect budget drops damage or body cue")
	for effect in get_nodes_in_group(Impact.GROUP):
		effect.queue_free()
	_prepare()
	await process_frame
	# Actual enemy projectile collision, not a direct call to player damage.
	before = damage_events.size()
	var shot: Area2D = load("res://EnemyProjectile.tscn").instantiate()
	root.add_child(shot)
	shot.position = player.position + Vector2(-45, 0)
	shot.setup(Vector2.RIGHT, null)
	for frame in range(60):
		await physics_frame
	_check(player.current_health == 9 and damage_events.size() == before + 1 and not is_instance_valid(shot), "Actual enemy shot feedback/hit count wrong")
	_prepare()
	player.current_health = 1
	player.take_damage(5)
	_check(player.is_dead and not player.visible and damage_events.back().outcome == "fatal" and art.self_modulate == Color.WHITE, "Fatal handling changed or leaves flash")
	before = damage_events.size()
	player.take_damage(1)
	await process_frame
	player.respawn()
	player.set_physics_process(false)
	_check(damage_events.size() == before and art.self_modulate == Color.WHITE and art.hurt_remaining == 0 and not is_instance_valid(art.damage_burst), "Death rejection/respawn leaks feedback")
	_check(player.player_collision.shape.get_rid() == body_rid and player.player_collision.transform == body_transform and player.attack_cast.shape.get_rid() == attack_shape, "Damage feedback changes collision")
	_prepare()
	player.take_damage(1)
	var last_burst: Node2D = art.damage_burst
	player.queue_free()
	await process_frame
	await process_frame
	_check(not is_instance_valid(last_burst), "Deleting player retains sibling burst")
	state.delete_save()
	if failures.is_empty():
		print("PLAYER DAMAGE FEEDBACK TEST PASSED: armor/directions/timers, rejection/rest/heal, equal-HP rescue, cap, pause, lifecycle, real projectile, death/respawn and collision")
		quit(0)
	else:
		quit(1)
