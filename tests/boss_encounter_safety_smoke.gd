extends "res://tests/boss_combat_presentation_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_boss_encounter_safety.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.process_mode = Node.PROCESS_MODE_DISABLED
	await process_frame
	var player: Player = game.get_node("Player")
	var transition := root.get_node("RoomTransition")
	for data in CASES:
		state.current_room_id = data[1]
		var boss: CharacterBody2D = load("res://%s.tscn" % data[0]).instantiate()
		game.add_child(boss)
		boss.target_player = player
		var safety := boss.get_node("EncounterSafety")
		var health: int = boss.current_health
		for reason in ["death", "room", "rest", "transition", "hidden"]:
			state.current_room_id = data[1]
			player.is_dead = false
			boss.show()
			safety.should_suspend()
			for timer in safety.TIMERS:
				if safety.properties.has(timer): boss.set(timer, 0.4)
			boss.velocity = Vector2(100, 50)
			if safety.properties.has("active"): boss.active = true
			var bolt: Area2D = load("res://EnemyProjectile.tscn").instantiate()
			game.add_child(bolt)
			bolt.setup(Vector2.RIGHT, boss)
			match reason:
				"death":
					player.is_dead = true
					boss._physics_process(0.8)
				"room": state.set_current_room("starfall_citadel")
				"rest": state.checkpoint_resting.emit("test_lamp")
				"transition": transition.transition_started.emit("starfall_citadel")
				"hidden": boss.hide()
			for timer in safety.TIMERS:
				if safety.properties.has(timer):
					_check(float(boss.get(timer)) == 0, data[0] + "/" + reason + ": stale " + timer)
			_check(boss.velocity == Vector2.ZERO, data[0] + "/" + reason + ": stale movement")
			_check(bolt.is_queued_for_deletion(), data[0] + "/" + reason + ": live hostile bolt")
			_check(boss.current_health == health, data[0] + "/" + reason + ": cancellation changed health")
			await process_frame
		player.is_dead = false
		boss.queue_free()
		await process_frame
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty(): print("BOSS ENCOUNTER SAFETY TEST PASSED: 7 bosses x 5 interruptions, timers, velocity, bolts, health")
	quit(0 if failures.is_empty() else 1)
