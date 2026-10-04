extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_localized_encounter_suite_save.json"
	var holder := Node2D.new()
	root.add_child(holder)
	var encounter := (load("res://LocalizedEncounter.tscn") as PackedScene).instantiate() as Area2D
	encounter.enemy_scenes.append(load("res://ShaftCrawler.tscn") as PackedScene)
	encounter.enemy_scenes.append(load("res://ShaftWisp.tscn") as PackedScene)
	encounter.spawn_offsets.append(Vector2(-80, -31))
	encounter.spawn_offsets.append(Vector2(80, -95))
	encounter.zone_id = "sunken_shaft"
	encounter.completion_event_id = "feedback_guardians_cleared"
	encounter.encounter_title = "SUPPLY WATCH"
	holder.add_child(encounter)
	var state := root.get_node("GameState")
	for id in ["feedback_first", "feedback_second"]:
		var cache := load("res://ResonanceCache.tscn").instantiate() as Area2D
		cache.cache_id = id
		cache.required_event_ids = PackedStringArray([encounter.completion_event_id])
		holder.add_child(cache)
	var player_probe := Node2D.new()
	player_probe.add_to_group("player")
	holder.add_child(player_probe)
	encounter._on_body_entered(player_probe)
	await process_frame
	await process_frame
	_check(encounter.triggered and encounter.spawned_enemies.size() == 2, "Localized encounter did not lazily spawn its wave")
	_check(encounter.spawned_enemies[0].get("zone_id") == "sunken_shaft", "Localized encounter lost its zone difficulty id")
	encounter._on_body_entered(player_probe)
	await process_frame
	_check(encounter.spawned_enemies.size() == 2, "Localized encounter spawned its one-shot wave twice")
	for enemy in encounter.spawned_enemies: enemy.die()
	_check("REWARD UNSEALED" in encounter.status_label.text, "Cleared guardians do not advertise pending rewards")
	state.open_cache("unrelated_feedback_cache")
	_check("REWARD UNSEALED" in encounter.status_label.text, "Unrelated receipt marks reward claimed")
	state.open_cache("feedback_first")
	_check("REWARD UNSEALED" in encounter.status_label.text, "One receipt hides the second reward")
	state.open_cache("feedback_second")
	_check("REWARD CLAIMED" in encounter.status_label.text, "All reward receipts not reflected")
	holder.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("LOCALIZED ENCOUNTER TEST PASSED")
		quit(0)
	else:
		print("LOCALIZED ENCOUNTER TEST FAILED: ", failures)
		quit(1)
