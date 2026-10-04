extends "res://tests/projectile_impact_smoke.gd"
const VARIANTS := ["basic_arrow", "piercing_arrow", "ember_arrow", "arc_bolt", "frost_orb"]

func _shot(room: Node, variant: String) -> Node2D:
	var magical := variant in ["arc_bolt", "frost_orb"]
	var shot: Node2D = load("res://PlayerMagicProjectile.tscn" if magical else "res://PlayerArrow.tscn").instantiate()
	room.add_child(shot)
	if magical:
		shot.setup(Vector2(-1, -1), null, variant)
	else:
		shot.setup(Vector2(-1, -1), null, "ember_arrow" if variant == "ember_arrow" else "basic_arrow", 0, 1 if variant == "piercing_arrow" else 0)
	return shot

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_player_projectile_lifecycle.json"
	state.start_new_game("normal")
	var connections: int = state.room_changed.get_connections().size()
	for variant in VARIANTS:
		for event in ["room", "rest", "transition", "hidden", "expiry"]:
			for pending in [false, true]:
				var room := Node2D.new()
				room.process_mode = Node.PROCESS_MODE_DISABLED
				room.rotation = 0.4
				root.add_child(room)
				# Non-Canvas intermediary verifies hidden-grandparent cleanup.
				var container := Node.new()
				room.add_child(container)
				var shot := _shot(container, variant)
				_check(shot.global_transform.x.normalized().is_equal_approx(Vector2(-1, -1).normalized()), "World-facing disagrees with flight")
				var target := ContactTarget.new()
				target.add_to_group("enemy")
				root.add_child(target)
				if pending:
					shot._on_body_entered(target)
					_check(shot.pending_hits == 1 and not shot.lifecycle_retired, "Contact hiding cancels valid reserved hit")
				match event:
					"room": state.room_changed.emit("other_room")
					"rest": state.checkpoint_resting.emit("test_lamp")
					"transition": root.get_node("RoomTransition").transition_started.emit("other_room")
					"hidden": room.hide()
					"expiry":
						# Expiry normally runs before contacts; explicitly retire a
						# reserved hit to test the same cancellation barrier.
						if pending: shot._retire()
						else:
							shot.lifetime = 0.001
							shot._physics_process(0.01)
				_check(shot.lifecycle_retired and shot.stopped and not shot.visible and shot.is_queued_for_deletion(), "Lifecycle event does not retire: " + event)
				var at := shot.global_position
				shot._physics_process(0.1)
				_check(shot.global_position == at, "Retired shot moves")
				shot._on_body_entered(target)
				await process_frame
				_check(target.damage_received == 0 and not is_instance_valid(shot), "Retired shot applies deferred/late damage: " + event)
				room.queue_free()
				target.queue_free()
				await process_frame
		# Contact-hidden normal hits still resolve; piercing remains alive.
		var room := Node2D.new()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(room)
		var shot := _shot(room, variant)
		var target := ContactTarget.new()
		target.add_to_group("enemy")
		room.add_child(target)
		var damage: int = shot.damage
		shot._on_body_entered(target)
		await process_frame
		_check(target.damage_received == damage, "Normal reserved hit lost")
		if variant in ["piercing_arrow", "frost_orb"]:
			_check(is_instance_valid(shot) and not shot.stopped and shot.remaining_hits == 1 and shot.pending_hits == 0 and shot.monitoring, "Piercing did not resume")
		room.queue_free()
		await process_frame
		var hidden_room := Node2D.new()
		hidden_room.hide()
		root.add_child(hidden_room)
		var hidden_shot := _shot(hidden_room, variant)
		_check(hidden_shot.lifecycle_retired and hidden_shot.source == null, "Hidden spawn reactivated by setup")
		hidden_room.queue_free()
		var transition := root.get_node("RoomTransition")
		transition.is_transitioning = true
		var late := _shot(root, variant)
		_check(late.lifecycle_retired and late.is_queued_for_deletion(), "Spawn survives active transition")
		transition.is_transitioning = false
		await process_frame
		var paused_shot := _shot(root, variant)
		var paused_position := paused_shot.global_position
		var paused_lifetime: float = paused_shot.lifetime
		paused = true
		for tick in range(3):
			await process_frame
		_check(paused_shot.global_position == paused_position and paused_shot.lifetime == paused_lifetime, "Pause consumes projectile movement/lifetime")
		state.checkpoint_resting.emit("paused_rest")
		_check(paused_shot.lifecycle_retired and not paused_shot.visible, "Rest during pause retains projectile")
		await process_frame
		paused = false
	_check(get_nodes_in_group("player_projectile").is_empty(), "Projectile group leaks")
	_check(state.room_changed.get_connections().size() == connections, "Lifecycle signal receivers leak")
	state.delete_save()
	if failures.is_empty():
		print("TEST PASSED: 50 lifecycle/deferred-hit cases, five normal hits, piercing resume, hidden/transition spawns, paused rest, aim and signal disposal")
	quit(0 if failures.is_empty() else 1)
