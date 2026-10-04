extends "res://tests/enemy_attack_art_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_combat_readability.json"
	state.start_new_game("normal")
	var room := Node2D.new()
	root.add_child(room)
	room.process_mode = Node.PROCESS_MODE_DISABLED
	for actor_name in ["Enemy", "AshFiend"]:
		var actor: Node2D = load("res://%s.tscn" % actor_name).instantiate()
		room.add_child(actor)
		var body := actor.get_node("PaintedMobAppearance")
		if actor_name == "AshFiend":
			_check(not actor.get_node("BackFlames").visible, "Legacy polygon behind painted fiend")
		actor.max_health = 10
		actor.current_health = 10
		body.contact()
		actor.take_damage(1) # No knockback: still needs visible hit feedback.
		body._process(0)
		_check(body.modulate == actor.hit_flash_color, actor_name + " lost non-stun hit flash")
		actor.take_damage(1, Vector2(-100, -50))
		body._process(0)
		_check(body.pose == 5 and body.release_remaining == 0, "Attack masks stagger")
		actor.hit_flash_remaining = 0
		actor.hit_stun_remaining = 0
		body._process(0)
		_check(body.modulate == Color.WHITE, "Damage tint did not clear")
		for rate in [30, 60, 120]:
			body.distance = 0
			var changes := 0
			var previous := -1
			for tick in range(rate):
				actor.position.x += 70.0 / rate
				body._process(1.0 / rate)
				if previous != body.pose:
					changes += 1
				previous = body.pose
			_check(changes >= 4 and changes <= 6, "Gait flickers or depends on render FPS")
		body.contact()
		actor.hide()
		actor.position.x += 1000
		actor.show()
		body._process(0)
		_check(body.pose == 0 and body.distance == 0, "Room re-entry retained stride/attack")
		actor.free()
	for actor_name in ["ShaftSentry", "AshSentry"]:
		var sentry: Node2D = load("res://%s.tscn" % actor_name).instantiate()
		room.add_child(sentry)
		sentry.take_damage(1)
		sentry.get_node("PaintedMobAppearance")._process(0)
		_check(sentry.get_node("PaintedMobAppearance").modulate == sentry.eye.modulate and sentry.eye.modulate != Color.WHITE, "Sentry flash remained on hidden eye")
		sentry.free()
	for data in [["ShaftCrawler", "state_remaining"], ["EchoBroodling", "state_remaining"], ["ShaftWisp", "state_time"], ["EchoShade", "telegraph_remaining"], ["RootStalker", "phase_remaining"]]:
		var actor: Node2D = load("res://%s.tscn" % data[0]).instantiate()
		room.add_child(actor)
		var fx := actor.get_node("AttackPresentation")
		if data[0] == "RootStalker": actor.phase = "warning"
		elif data[0] != "EchoShade": actor.state = 1
		fx.age = 99.2 # Preparation must not depend on world age.
		actor.set(data[1], 0.6)
		fx._physics_process(0)
		_check(fx.animation_frame == 0, "Windup did not begin at ignition")
		actor.set(data[1], 0.2)
		fx._physics_process(0.4)
		_check(fx.animation_frame == 1, "Windup did not progress")
		actor.set(data[1], 0.05)
		fx._physics_process(0.15)
		_check(fx.animation_frame == 1, "Windup loops backwards")
		if data[0] == "RootStalker":
			var shape = actor.get_node("StrikeArea/CollisionShape2D").shape
			var original_size: Vector2 = shape.size
			for side in [-1, 1]:
				actor.strike_area.position.x = side * 51
				var rect: Rect2 = fx._root_visual_rect()
				_check(rect.end.y == 15 and rect.position.y == -33 and rect.size.x == 94, "Root art not grounded inside native volume")
				_check(rect.get_center().x == side * 51, "Root art lost facing / reach")
			_check(shape.size == original_size, "Grounding moved real hitbox")
			actor.phase = "burst"
			for tick in range(21):
				fx._physics_process(1.0 / 60)
				_check(fx.animation_frame in [2, 3] and fx.attacking, "Damaging roots dissipate early")
			actor.phase = "recovery"
			fx._physics_process(0)
			_check(fx.recovering and not fx.attacking and fx.animation_frame == 4, "Missing non-damaging breakup")
			fx._physics_process(0.08)
			_check(fx.recovering and fx.animation_frame == 5, "Missing final particles")
			fx._physics_process(0.08)
			_check(not fx.recovering, "Root afterimage leaked")
		actor.hide()
		_check(not fx.recovering and not fx.preparing and fx.animation_frame == 0, "Hidden room retained warning")
		actor.free()
	# Saturation: budget is cosmetic and finite, even with simultaneous impacts.
	for index in range(100):
		Burst.spawn(room, Vector2(index, 0), Color.WHITE, "contact", Vector2(13, 13), 0.18, index % 20)
	_check(get_nodes_in_group("boss_cosmetic_effect").size() == 64, "Cosmetic budget exceeded")
	for fx in get_nodes_in_group("boss_cosmetic_effect"):
		fx._process(0.2)
	await process_frame
	_check(get_nodes_in_group("boss_cosmetic_effect").is_empty(), "Saturated effects did not expire")
	room.free()
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: gait at 30/60/120fps, damage feedback, monotonic windups, live roots, recovery, visibility and saturated VFX cleanup")
	quit(0 if failures.is_empty() else 1)
