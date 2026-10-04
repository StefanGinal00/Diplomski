extends "res://tests/enemy_attack_art_smoke.gd"

class Target extends StaticBody2D:
	var received := 0
	func take_damage(amount: int, _force: Vector2) -> void:
		received += amount

func _shot(host: Node2D, source: Node, aim: Vector2) -> Area2D:
	var shot: Area2D = load("res://EnemyProjectile.tscn").instantiate()
	host.add_child(shot)
	shot.set_physics_process(false)
	shot.setup(aim, source)
	return shot

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_enemy_projectile_contact.json"
	state.start_new_game("normal")
	var host := Node2D.new()
	root.add_child(host)
	host.process_mode = Node.PROCESS_MODE_DISABLED
	host.rotation = 0.4
	host.scale = Vector2(1.5, 1.5)
	var source := Node2D.new()
	host.add_child(source)
	for identity in Art.PROJECTILES:
		for aim in [Vector2.RIGHT, Vector2.LEFT, Vector2(-1, -1).normalized(), Vector2(1, 1).normalized()]:
			var shot := _shot(host, source, aim)
			shot.global_position = Vector2(120, 70)
			var paint := shot.get_node("BossProjectileArt")
			paint.style = identity
			_check(shot.global_transform.x.normalized().is_equal_approx(aim), "Projectile art ignores world-space aim")
			var target := Target.new()
			host.add_child(target)
			target.add_to_group("player")
			shot._on_body_entered(source)
			_check(not shot.spent and get_nodes_in_group("boss_cosmetic_effect").is_empty(), "Source consumes projectile")
			shot._on_body_entered(target)
			shot._on_body_entered(target)
			shot._on_body_entered(host)
			var effects := get_nodes_in_group("boss_cosmetic_effect")
			_check(target.received == shot.damage and effects.size() == 1, "One projectile produced repeated hits/effects")
			_check(shot.spent and not shot.visible, "Spent shot lingers visibly")
			var contact_point: Vector2 = shot.global_position
			shot._physics_process(0.1)
			_check(shot.global_position == contact_point, "Spent shot keeps moving")
			if effects.size() == 1:
				var effect: Node2D = effects[0]
				_check(effect.global_position.is_equal_approx(contact_point) and effect.global_transform.x.is_equal_approx(aim), "Impact placement/aim inherits room transform")
				_check(effect.texture_frame == Art.PROJECTILES[identity] and effect.animation_frame == 4, "Impact restarts a full live projectile")
				_check(is_equal_approx(effect.paint_rotation, PI * 0.5 if identity == "ash_sentry" else 0.0), "Flame impact lost travel alignment")
				effect._process(0.1)
				_check(effect.animation_frame == 5, "Impact does not finish breakup")
				effect._process(0.1)
				_check(effect.is_queued_for_deletion() and not effect.visible, "Expired impact remains visible")
			target.queue_free()
			await process_frame
	var wall_shot := _shot(host, source, Vector2.RIGHT)
	var protected := Target.new()
	host.add_child(protected)
	protected.add_to_group("player")
	wall_shot._on_body_entered(host)
	wall_shot._on_body_entered(protected)
	_check(protected.received == 0, "Terrain-consumed shot damages a later target")
	protected.queue_free()
	await process_frame
	for effect in get_nodes_in_group("boss_cosmetic_effect"):
		effect.queue_free()
	await process_frame
	for event in ["room", "rest", "transition", "hidden", "expiry"]:
		var container := Node2D.new()
		host.add_child(container)
		var shot := _shot(container, source, Vector2.LEFT)
		var effect := Burst.spawn(container, Vector2.ZERO, Color.WHITE, "impact", Vector2(14, 14), 0.18, 0)
		match event:
			"room": state.room_changed.emit("test_room")
			"rest": state.checkpoint_resting.emit("test_lamp")
			"transition": root.get_node("RoomTransition").transition_started.emit("test_room")
			"hidden": container.hide() # Already process-disabled via host.
			"expiry":
				shot.lifetime = 0.01
				shot._physics_process(0.02)
				effect._process(0.2)
		_check(shot.spent and not shot.visible and not effect.visible, "Immediate cleanup failed: " + event)
		await process_frame
		_check(not is_instance_valid(shot) and not is_instance_valid(effect), "Hidden/expired nodes leaked: " + event)
		container.free()
	var transition := root.get_node("RoomTransition")
	transition.is_transitioning = true
	_check(Burst.spawn(host, Vector2.ZERO, Color.WHITE) == null, "Transition accepts new bursts")
	var blocked := _shot(host, source, Vector2.RIGHT)
	_check(blocked.spent, "Transition accepts live hostile shot")
	transition.is_transitioning = false
	var hidden_parent := Node2D.new()
	host.add_child(hidden_parent)
	hidden_parent.hide()
	var hidden_shot := _shot(hidden_parent, source, Vector2.RIGHT)
	_check(hidden_shot.spent and not hidden_shot.has_node("BossProjectileArt"), "Hidden parent accepts a new hostile shot")
	_check(Burst.spawn(hidden_parent, Vector2.ZERO, Color.WHITE) == null, "Hidden parent accepts a new burst")
	host.queue_free()
	await process_frame
	await _live_overlap()
	await _muzzle_alignment()
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: 40 oriented impacts, 14 boss muzzle directions, single-hit budget, terrain ordering, lifecycle cleanup, 4 live overlap collisions")
	quit(0 if failures.is_empty() else 1)

func _live_overlap() -> void:
	for aim in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2(-1, -1).normalized()]:
		var host := Node2D.new()
		root.add_child(host)
		var targets: Array[Target] = []
		for index in range(2):
			var target := Target.new()
			target.add_to_group("player")
			var shape := CollisionShape2D.new()
			var rectangle := RectangleShape2D.new()
			rectangle.size = Vector2(18, 18)
			shape.shape = rectangle
			target.add_child(shape)
			target.position = aim * 40
			host.add_child(target)
			targets.append(target)
		var shot := _shot(host, host, aim)
		shot.set_physics_process(true)
		for tick in range(36):
			await physics_frame
		_check(targets[0].received + targets[1].received == 1, "Real overlapping targets exceed hostile single-hit budget")
		_check(not is_instance_valid(shot), "Physical collision did not consume shot")
		host.queue_free()
		await process_frame

func _muzzle_alignment() -> void:
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = game.get_node("Player")
	for data in preload("res://tests/boss_combat_presentation_smoke.gd").CASES:
		var boss: CharacterBody2D = load("res://%s.tscn" % data[0]).instantiate()
		game.add_child(boss)
		boss.target_player = player
		var fx := boss.get_node("CombatPresentation")
		var art := boss.get_node("PaintedAppearance")
		if art.property_names.has("active"): boss.active = true
		for aim in [Vector2.RIGHT, Vector2(-1, -0.3).normalized()]:
			var muzzle: Vector2 = boss.get_node("Muzzle").global_position
			player.global_position = muzzle + aim * 200
			if art.property_names.has("locked_shot_direction"):
				boss.locked_shot_direction = aim
				# Sentinel's committed shot must ignore a late target crossover.
				player.global_position = muzzle - aim * 200
			fx.release("volley")
			var effects := get_nodes_in_group("boss_cosmetic_effect")
			_check(effects.size() == 1, "Muzzle spawned extra/unexpected effects")
			if effects.size() == 1:
				_check(effects[0].global_position.is_equal_approx(muzzle) and effects[0].global_transform.x.is_equal_approx(aim), data[0] + ": muzzle art ignores authoritative shot direction")
			for effect in effects: effect.queue_free()
			await process_frame
		boss.free()
	game.queue_free()
	await process_frame
