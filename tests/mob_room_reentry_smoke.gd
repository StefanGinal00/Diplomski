extends "res://tests/boss_combat_presentation_smoke.gd"

const MOBS := ["ShaftCrawler", "EchoBroodling", "ShaftWisp", "EchoShade", "RootStalker", "ShaftSentry", "AshSentry"]

func _prime(actor: Node, identity: String, phase: int) -> void:
	if actor is CharacterBody2D: actor.velocity = Vector2(200, -80)
	match identity:
		"ShaftCrawler", "EchoBroodling":
			actor.state = phase
			actor.state_remaining = 0.001
			actor.warning_icon.show()
			if identity == "ShaftCrawler": actor.echo_charge_ready = true
		"ShaftWisp":
			actor.state = phase
			actor.state_time = 0.001
			actor.body_visual.scale = Vector2(1.3, 1.3)
		"EchoShade":
			actor.telegraph_remaining = 0.001 if phase == 1 else 0.0
			actor.dash_remaining = 0.001 if phase == 2 else 0.0
			actor.echo_followup_ready = true
			actor.telegraph.show()
		"RootStalker":
			actor._begin_warning()
			if phase == 2: actor._begin_burst()
			actor.phase_remaining = 0.001
		"ShaftSentry", "AshSentry":
			actor.windup_remaining = 0.001
			actor.warning_ray.show()
			if phase == 2: actor._fire()

func _check_reset(actor: Node, identity: String) -> void:
	match identity:
		"ShaftCrawler", "EchoBroodling":
			_check(actor.state == 3 and actor.state_remaining > 0.5 and actor.attack_cooldown > 0 and not actor.warning_icon.visible, identity + " retained charge/leap")
			if identity == "ShaftCrawler": _check(not actor.echo_charge_ready, "Crawler retained return-tier followup")
		"ShaftWisp":
			_check(actor.state == 0 and actor.state_time >= 0.85 and actor.body_visual.scale == Vector2.ONE, "Wisp retained dive")
		"EchoShade":
			_check(actor.telegraph_remaining == 0 and actor.dash_remaining == 0 and not actor.echo_followup_ready and not actor.telegraph.visible and actor.attack_cooldown >= 1, "Shade retained dash/followup")
		"RootStalker":
			_check(actor.phase == "recovery" and not actor.strike_area.monitoring and not actor.warning_line.visible and actor.body_visual.scale == Vector2.ONE, "Root retained damaging strike/paint")
		"ShaftSentry", "AshSentry":
			_check(actor.windup_remaining == 0 and not actor.warning_ray.visible and actor.cooldown_remaining >= 0.6, identity + " retained near-complete shot")
			for ray in actor.spread_rays: _check(not ray.visible, "Awakened sentry retained fan warning")
	if actor is CharacterBody2D: _check(actor.velocity == Vector2.ZERO, identity + " retained attack momentum")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_mob_room_reentry.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Node2D = game.get_node("Player")
	var room: Node2D = game.get_node("EchoGrotto")
	var manager: Node = game.get_node("WorldPopulation")
	var director: Node = game.get_node("RoomActivityDirector")
	var ledger: Dictionary = state.defeated_enemies.duplicate(true)
	var count := 0
	for tier in [0, 1]:
		for identity in MOBS:
			for phase in [1, 2]:
				state.set_current_room("echo_grotto")
				var actor: Node2D = load("res://%s.tscn" % identity).instantiate()
				actor.name = "ReentryFixture"
				actor.position = Vector2(140, -500)
				state.set_zone_tier(actor.zone_id, tier)
				if identity == "EchoBroodling": actor.counts_for_nest = false
				room.add_child(actor)
				actor.current_health -= 1
				var hp: int = actor.current_health
				var at := actor.position
				var old: WeakRef = weakref(actor)
				_prime(actor, identity, phase)
				# Native room-change listeners disable the room and cancel combat.
				state.set_current_room("training_passage")
				await process_frame
				_check_reset(actor, identity)
				_check(get_nodes_in_group("enemy_projectile").is_empty(), "Room exit retained sentry projectiles")
				state.set_current_room("echo_grotto")
				_check(old.get_ref() == actor and not manager.pending_unloads.has("EchoGrotto"), "Quick return recreated enemy or failed to cancel unload")
				_check(actor.current_health == hp and actor.position == at, "Room exit healed or teleported " + identity)
				_check_reset(actor, identity)
				# Normal same-room notification cannot reset a fresh attack.
				_prime(actor, identity, 1)
				director._on_room_changed("echo_grotto")
				match identity:
					"ShaftCrawler", "EchoBroodling", "ShaftWisp": _check(actor.state == 1, "Same-room activation cancelled preparation")
					"EchoShade": _check(actor.telegraph_remaining > 0, "Same-room activation cancelled shade")
					"RootStalker": _check(actor.phase == "warning", "Same-room activation cancelled roots")
					_: _check(actor.windup_remaining > 0, "Same-room activation cancelled sentry")
				actor.queue_free()
				await process_frame
				count += 1
	# Explicit unload must retire projectiles by both parent and source ownership,
	# even when a caller has not hidden the room or sent a room-change event.
	var source: Node = room.get_node("WildPatrol0")
	var health: int = source.current_health
	var refs: Array[WeakRef] = []
	for host in [room, game]:
		var shot: Node = load("res://EnemyProjectile.tscn").instantiate()
		host.add_child(shot)
		shot.setup(Vector2.RIGHT, source)
		refs.append(weakref(shot))
	var other: Node = load("res://EnemyProjectile.tscn").instantiate()
	game.add_child(other)
	other.setup(Vector2.RIGHT, game.get_node("RangedEnemy"))
	var hp_before: int = player.current_health
	manager.unload_room_population("EchoGrotto")
	for ref in refs:
		var shot: Node = ref.get_ref()
		_check(shot.spent and shot.is_queued_for_deletion(), "Explicit unload left a live hostile projectile")
		shot._on_body_entered(player)
	_check(player.current_health == hp_before and not other.spent, "Unload damaged player or retired unrelated room's shot")
	await process_frame
	for ref in refs: _check(ref.get_ref() == null, "Unloaded shot remained allocated")
	manager._on_room_changed("echo_grotto")
	director._on_room_changed("echo_grotto")
	await process_frame
	_check(room.get_node("WildPatrol0").current_health == health, "Full unload lost survivor health")
	_check(state.defeated_enemies == ledger and state.gold == 0, "Combat suspension recorded defeat/reward")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("MOB ROOM REENTRY TEST PASSED: ", count, " interruption cases plus explicit projectile unload")
		quit(0)
	else:
		print("MOB ROOM REENTRY TEST FAILED: ", failures)
		quit(1)
