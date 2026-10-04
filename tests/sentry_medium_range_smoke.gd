extends "res://tests/shaft_guard_combat_smoke.gd"

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_sentry_medium_range.json"
	for tier in [0,1]:
		state.start_new_game("normal")
		state.set_zone_tier("sunken_shaft",tier)
		player=_player()
		player.global_position=Vector2(270,-2)
		player.max_health=100
		player.current_health=100
		var sentry: StaticBody2D = load("res://ShaftSentry.tscn").instantiate()
		root.add_child(sentry)
		var warned := false
		for step in 240:
			await physics_frame
			warned = warned or sentry.windup_remaining>0
		_check(warned and player.current_health<100,"Sentry does not engage at 270px, tier "+str(tier))
		sentry.queue_free()
		player.queue_free()
		await process_frame
	state.delete_save()
	print("SENTRY MEDIUM RANGE TEST PASSED" if failures.is_empty() else "SENTRY MEDIUM RANGE TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
