extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_town_ambient_life_suite_save.json"
	await _inspect_town("res://EchoHaven.tscn", ["Neris", "Calen", "Ivara", "Vey"], [["Neris", "Calen"], ["Ivara", "Vey"]])
	await _inspect_town("res://CinderHearth.tscn", ["Dara", "Bram", "Oren"], [["Dara", "Bram"]])
	if failures.is_empty():
		print("TOWN AMBIENT LIFE TEST PASSED")
		quit(0)
	else:
		print("TOWN AMBIENT LIFE TEST FAILED: ", failures)
		quit(1)


func _inspect_town(scene_path: String, wanderer_names: Array, talk_pairs: Array) -> void:
	var town: Node2D = load(scene_path).instantiate()
	root.add_child(town)
	await process_frame
	var residents: Array[Node] = []
	var initial_positions: Dictionary = {}
	var furthest_walks: Dictionary = {}
	var entered_buildings: Dictionary = {}
	for resident_name in wanderer_names:
		var resident: Area2D = town.get_node(str(resident_name)) as Area2D
		residents.append(resident)
		resident.set_process(false)
		initial_positions[resident_name] = resident.position
		furthest_walks[resident_name] = 0.0
		entered_buildings[resident_name] = false
		_check(resident.route_markers.size() >= 2, "%s lacks a walking route in %s" % [resident_name, scene_path])
		for marker in resident.route_markers:
			_check(marker.get_parent() == town, "%s route leaves its own town" % resident_name)
	if scene_path.ends_with("CinderHearth.tscn"):
		_check(town.get_node("Mira").route_markers.is_empty(), "Quest giver Mira should remain at her post")
		_check(town.get_node("Tarin").route_markers.is_empty(), "Gate watch Tarin should remain at his post")

	var first: Area2D = residents[0] as Area2D
	first.pause_remaining = 0.0
	var held_position: Vector2 = first.position
	first.set_player_dialogue_active(true)
	first._process(1.0)
	_check(first.position == held_position, "%s walks away during player dialogue" % first.name)
	first.set_player_dialogue_active(false)

	for step in range(1800):
		for resident in residents:
			resident._process(0.1)
			var resident_name: String = str(resident.name)
			furthest_walks[resident_name] = maxf(float(furthest_walks[resident_name]), resident.position.distance_to(initial_positions[resident_name]))
			if resident.indoor_state == "inside" and not resident.visible:
				entered_buildings[resident_name] = true
			_check(resident.position.x >= 15.0 and resident.position.x < 1210.0, "%s left the town walkway" % resident_name)
		if step % 20 == 0:
			await process_frame
	for resident_name in wanderer_names:
		_check(float(furthest_walks[resident_name]) > 30.0, "%s did not walk around %s" % [resident_name, scene_path])
		_check(bool(entered_buildings[resident_name]), "%s never entered a building in %s" % [resident_name, scene_path])
	for pair in talk_pairs:
		var speaker: Area2D = town.get_node(str(pair[0])) as Area2D
		var listener: Area2D = town.get_node(str(pair[1])) as Area2D
		_check(speaker.social_line_index > 0 and listener.social_line_index > 0, "%s and %s never spoke in %s" % [pair[0], pair[1], scene_path])
	for resident in residents:
		resident.set_process(true)
	town.queue_free()
	await process_frame
