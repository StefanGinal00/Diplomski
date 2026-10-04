extends "res://tests/enemy_attack_art_smoke.gd"
const Echo = preload("res://MobDefeatEcho.gd")
const ACTORS := ["Enemy", "AshFiend", "RootStalker", "ShaftSentry", "AshSentry", "ShaftCrawler", "ShaftWisp", "EchoShade", "EchoBroodling", "RangedEnemy"]

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_mob_defeat_echo.json"
	state.start_new_game("normal")
	for actor_name in ACTORS:
		for left in [false, true]:
			var room := Node2D.new()
			root.add_child(room)
			room.process_mode = Node.PROCESS_MODE_DISABLED
			room.rotation = 0.2
			room.scale = Vector2(1.3, 0.85)
			var actor: Node2D = load("res://%s.tscn" % actor_name).instantiate()
			actor.max_health = 20
			room.add_child(actor)
			var art := actor.get_node_or_null("PaintedMobAppearance") as Sprite2D
			if art == null: art = actor.get_node("Appearance")
			art.flip_h = left
			var registration := art.global_transform
			var expected_frame := art.frame
			var expected_material := art.material
			var gold: int = actor.gold_reward
			var count := [0]
			actor.defeated.connect(func(): count[0] += 1)
			actor.take_damage(999)
			actor.take_damage(999)
			_check(actor.is_dead and actor.is_queued_for_deletion() and count[0] == 1, actor_name + ": death/reward lifecycle delayed")
			var echoes := get_nodes_in_group(Echo.GROUP)
			_check(echoes.size() == 1, actor_name + ": missing/duplicate body follow-through")
			var echo: Sprite2D = echoes[0] if echoes.size() == 1 else null
			if echo != null:
				_check(echo.global_transform.is_equal_approx(registration) and echo.flip_h == left and echo.frame == expected_frame, actor_name + ": snapshot lost transform/pose/facing")
				_check(echo.texture == art.texture and echo.offset == art.offset and echo.texture_filter == art.texture_filter, actor_name + ": snapshot loses registration")
				if expected_material != null:
					_check(echo.material != expected_material and echo.material.shader == expected_material.shader, "Ash palette / material not preserved independently")
				_check(echo.get_child_count() == 0, "Mob visual owns physics/debris nodes")
				echo._process(0.12)
				_check(is_equal_approx(echo.self_modulate.a, 0.5), "Mob fade lifetime")
				var lift := -2.0 if actor_name in ["ShaftWisp", "EchoShade"] else 0.0
				_check(echo.global_position.is_equal_approx(registration.origin + Vector2(0, lift)), "Ground feet moved / flying fade did not lift")
			await process_frame
			_check(not is_instance_valid(actor), "Visual delayed native actor deletion")
			var xp_nodes := get_nodes_in_group("xp_orb")
			var gold_nodes := get_nodes_in_group("gold_pickup")
			_check(xp_nodes.size() == 1 and gold_nodes.size() == 1 and gold_nodes[0].gold_value == gold, actor_name + ": missing/duplicated native drops")
			if echo != null:
				echo._process(0.13)
				_check(not echo.visible and echo.is_queued_for_deletion(), "Mob fade did not retire")
			room.queue_free()
			await process_frame
	await _cleanup_and_budget(state)
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: 20 native mob deaths/drops, frame/facing/foot registration, Ash palette, flying drift, hidden poses, neutral exclusion, cleanup and budgets")
	quit(0 if failures.is_empty() else 1)

func _cleanup_and_budget(state: Node) -> void:
	var host := Node2D.new()
	root.add_child(host)
	host.process_mode = Node.PROCESS_MODE_DISABLED
	for name in ACTORS:
		var actor: Node2D = load("res://%s.tscn" % name).instantiate()
		host.add_child(actor)
		var art := actor.get_node_or_null("PaintedMobAppearance") as Sprite2D
		if art == null: art = actor.get_node("Appearance")
		art.modulate = Color.RED
		if art.has_method("contact"): art.contact()
		else: art.frame=(art.frame+1)%(art.hframes*art.vframes)
		actor.hide()
		_check(art.modulate == Color.WHITE and art.frame % art.hframes == 0, name + ": hidden disabled-room pose not reset")
		if art.has_meta("atlas_frame"): _check(art.get_meta("atlas_frame")==0,"Hidden articulated mob retains strike")
		actor.free()
	var neutral: Node2D = load("res://NeutralCreature.tscn").instantiate()
	host.add_child(neutral)
	Echo.hook(neutral.get_node("Sprite2D"), "enemy")
	_check(Echo.spawn(neutral.get_node("Sprite2D"), "enemy") == null and not neutral.is_hostile, "Neutral fauna gained hostile defeat presentation")
	neutral.free()
	var source: Node2D = load("res://ShaftSentry.tscn").instantiate()
	host.add_child(source)
	var art := source.get_node("PaintedMobAppearance") as Sprite2D
	for event in ["room", "rest", "transition", "hidden"]:
		var echo := Echo.spawn(art, "sentry")
		match event:
			"room": state.room_changed.emit("test_room")
			"rest": state.checkpoint_resting.emit("test_lamp")
			"transition": root.get_node("RoomTransition").transition_started.emit("test_room")
			"hidden": host.hide()
		_check(echo.is_queued_for_deletion() and not echo.visible, "Mob cleanup failed: " + event)
		await process_frame
		_check(get_nodes_in_group("boss_cosmetic_effect").is_empty(), "Mob effect leaked: " + event)
		host.show()
	for i in range(40): Echo.spawn(art, "sentry")
	_check(get_nodes_in_group(Echo.GROUP).size() == 16 and get_nodes_in_group("boss_cosmetic_effect").size() == 32, "Crowd defeat exceeds 16-body / 32-total effect budget")
	state.room_changed.emit("clear_crowd")
	await process_frame
	for i in range(63): Burst.spawn(host, Vector2.ZERO, Color.WHITE)
	_check(Echo.spawn(art, "sentry") != null and get_nodes_in_group("boss_cosmetic_effect").size() == 64, "Mob/attack shared cap exceeded")
	_check(Echo.spawn(art, "sentry") == null, "Full shared budget allows more bodies")
	host.queue_free()
	await process_frame
	_check(get_nodes_in_group("boss_cosmetic_effect").is_empty(), "Deleted population retains effects")
