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
	holder.add_child(encounter)
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
	holder.queue_free()
	await process_frame
	if failures.is_empty():
		print("LOCALIZED ENCOUNTER TEST PASSED")
		quit(0)
	else:
		print("LOCALIZED ENCOUNTER TEST FAILED: ", failures)
		quit(1)
