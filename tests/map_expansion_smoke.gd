extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_map_expansion_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var ui = game.get_node("UI")
	var routes := [
		["ShaftDriftworks", "ShaftHollow", "DriftDoor", "CrossingDoor", "shaft_drift", "shaft_drift_entry", "shaft_drift_return", "DrownedCrossing", "HollowEntry"],
		["EchoDepths", "EchoGallery", "DepthsDoor", "ArchiveDoor", "echo_depths", "echo_depths_entry", "echo_depths_return", "PrismArchive", "ArchiveEntry"],
		["AshEmberspine", "BrokenCauseway", "EmberspineDoor", "ForgeDoor", "ash_emberspine", "ash_emberspine_entry", "ash_emberspine_return", "CinderForge", "ForgeEntry"],
		["StarfallRamparts", "StarfallOutskirts", "RampartsDoor", "SilentGateDoor", "starfall_ramparts", "starfall_ramparts_entry", "starfall_ramparts_return", "StarfallSilentGate", "Entry"],
	]
	var all_cache_ids: Dictionary = {}
	for route_info in routes:
		var wing: Node2D = game.get_node(route_info[0])
		var hub: Node2D = game.get_node(route_info[1])
		var hub_door: Node2D = hub.get_node(route_info[2])
		var forward_door: Node2D = hub.get_node(route_info[3])
		var low_door: Node2D = wing.get_node("LowerReturnDoor")
		var high_door: Node2D = wing.get_node("UpperShortcutDoor")
		var width: float = wing.route["width"]
		_check(width >= 7000.0 and wing._main_data().size() == 8 and wing._branch_data().size() == 4, "A zone wing lacks its expanded chamber graph")
		var highest := 10000.0
		var lowest := -10000.0
		var rises := 0
		var drops := 0
		for room_index in range(8):
			var room: Rect2 = wing._main_rect(room_index)
			highest = minf(highest, room.position.y)
			lowest = maxf(lowest, room.end.y)
			_check(wing.has_node("MainRoom%dFloor0" % room_index), "A wing chamber lacks a continuous floor")
			if room_index < 7:
				var next_room: Rect2 = wing._main_rect(room_index + 1)
				rises += 1 if next_room.end.y < room.end.y else 0
				drops += 1 if next_room.end.y > room.end.y else 0
				_check(wing.has_node("MainLink%dShaftStep0" % room_index), "A wing chamber link has no reversible shaft")
		_check(lowest - highest >= 1400.0 and rises >= 1 and drops >= 2, "A wing is still a flat or one-way route")
		_check(wing.has_node("LoopLinkShaftStep0") or wing.has_node("LoopLinkTunnelFloor"), "A wing has no alternate route")
		_check(not wing.has_node("Tier0_Span0"), "A wing regressed to repeated platform shelves")
		var final_room: Rect2 = wing._main_rect(7)
		_check(absf(wing.get_node("UpperShortcutDoor").position.y - (final_room.end.y - 33.0)) < 1.0, "The story exit is not in the final chamber")
		_check(wing.get_node("ReturnLiftBottom").activates_shortcut and not wing.get_node("ReturnLiftTop").activates_shortcut, "The return lift can skip the first traversal")
		_check(get_first_node_in_group(route_info[5]) == wing.get_node("Entry"), "Wing entry marker is missing or duplicated")
		_check(get_first_node_in_group(route_info[6]) == hub.get_node(route_info[2].trim_suffix("Door") + "Return"), "Hub return marker is missing or duplicated")
		_check(hub_door.target_room_id == route_info[4] and low_door.target_room_id == wing.route["hub_id"] and high_door.target_room_id == wing.route["next_id"], "A wing does not connect hub and next story room")
		_check(high_door.status_label.text == wing.route["exit_label"], "High exit shows the wrong destination")
		_check(wing.get_node("TrailLamp").room_id == route_info[4], "Wing lamp has the wrong room id")
		_check(not wing.is_population_loaded() and not wing.has_node("Patrol0"), "An unvisited chamber wing eagerly loaded its encounters")
		state.set_current_room(route_info[4])
		await process_frame
		_check(wing.is_population_loaded(), "Entering a chamber wing did not stream its encounters")
		var enemies := 0
		var neutral := 0
		var crates := 0
		for child in wing.get_children():
			if child.is_in_group("enemy"):
				enemies += 1
				_check(str(child.get("zone_id")) == str(wing.route["zone"]), "Wing enemy has the wrong difficulty zone")
			elif child.is_in_group("neutral_creature"):
				neutral += 1
			elif child.is_in_group("breakable"):
				crates += 1
		_check(enemies == 24 and neutral == 7 and crates == 16, "A chamber wing lacks dispersed enemies, fauna or breakables")
		_check(wing.has_node("Flora7_7") and wing.has_node("BranchRoom3Floor0"), "A route has no deep flora or side chamber")
		for cache_name in ["MidCache", "RimCache"]:
			var cache = wing.get_node(cache_name)
			_check(not all_cache_ids.has(cache.cache_id), "Wing cache ids are not unique")
			all_cache_ids[cache.cache_id] = true
		if route_info[4] == "shaft_drift":
			state.unlock_shortcut("shaft_hollow_relay")
		elif route_info[4] == "echo_depths":
			state.add_item("gallery_prism")
		state.set_current_room(wing.route["hub_id"])
		_check(forward_door._uses_first_visit_route(), "First visit can still skip the expanded route")
		await forward_door.activate(player)
		_check(state.current_room_id == route_info[4] and player.global_position.distance_to(wing.get_node("Entry").global_position) < 45.0, "Could not enter the multi-level main route")
		_check("HIGH EXIT" in ui.objective_label.text and "CACHES 0/2" in ui.objective_label.text, "The new route has no first-visit navigation cue")
		await low_door.activate(player)
		_check(state.current_room_id == wing.route["hub_id"] and player.global_position.distance_to(hub.get_node(route_info[2].trim_suffix("Door") + "Return").global_position) < 45.0, "Lower return does not allow backtracking")
		await forward_door.activate(player)
		await high_door.activate(player)
		_check(state.current_room_id == wing.route["next_id"] and player.global_position.distance_to(game.get_node(route_info[7]).get_node(route_info[8]).global_position) < 45.0, "High exit did not reach the next story room")
		_check(not forward_door._uses_first_visit_route(), "Direct shortcut did not open after reaching the next room")
		state.set_current_room(wing.route["hub_id"])
		await forward_door.activate(player)
		_check(state.current_room_id == wing.route["next_id"], "An explored route did not become a shortcut")
	_check(game.get_node("AshEmberspine").has_node("LowerHazard0") and game.get_node("StarfallRamparts").has_node("LowerHazard1"), "Hazard zones lack their first-visit traps")
	_check(not game.get_node("EchoDepths").has_node("LowerHazard0"), "Echo route inherited an unrelated fire/root hazard")

	var haven: Node2D = game.get_node("EchoHaven")
	var hearth: Node2D = game.get_node("CinderHearth")
	var city: Node2D = game.get_node("StarfallCitadel")
	for town_id in ["echo_haven", "ash_hearth", "starfall_citadel"]:
		state.set_current_room(town_id)
		await process_frame
	for town in [haven, hearth]:
		var expansion: Node2D = town.get_node("UpperVillage")
		_check(expansion.get_child_count() >= 12 and expansion.get_node("WestBalcony") != null if town == haven else expansion.get_child_count() >= 12 and expansion.get_node("SmithyWalk") != null, "A small settlement has no upper neighborhood")
	for npc_path in ["EchoHaven/UpperVillage/Tessan", "EchoHaven/UpperVillage/Lumen", "EchoHaven/UpperVillage/Selis", "EchoHaven/UpperVillage/Tovan", "CinderHearth/UpperVillage/Kael", "CinderHearth/UpperVillage/Soren", "CinderHearth/UpperVillage/Rellan", "CinderHearth/UpperVillage/Yara", "StarfallCitadel/LibraryRooftop/Erian", "StarfallCitadel/LibraryRooftop/Marwen", "StarfallCitadel/LibraryRooftop/Caelis", "StarfallCitadel/LibraryRooftop/Dorian"]:
		var npc = game.get_node(npc_path)
		_check(npc.is_in_group("town_resident") and npc.interaction_requested.is_connected(Callable(ui, "_on_npc_interaction_requested")), "A new peaceful resident is not connected to dialogue")
	_check(city.get_node("LibraryRooftop/LibraryRoofWalk").position.y < city.get_node("GardenBalcony").position.y - 80.0, "Citadel library has no new rooftop route")
	for enemy in get_nodes_in_group("enemy"):
		_check(not city.is_ancestor_of(enemy) and not haven.is_ancestor_of(enemy) and not hearth.is_ancestor_of(enemy), "A safe settlement contains an enemy")
	ui._update_route_summary()
	_check("11 PLAYABLE ROOMS" in ui.map_route_label.text and "BROKEN RAMPARTS" in ui.map_route_label.text, "World map does not show the expanded routes")
	var trail_lamp = game.get_node("ShaftDriftworks/TrailLamp")
	player.global_position = trail_lamp.get_node("RespawnPoint").global_position
	state.set_current_room("shaft_drift")
	_check(trail_lamp._save_progress(player), "New route lamp could not save")
	_check(state.load_game() and state.checkpoint_lamp_id == "shaft_drift_lamp", "New route lamp could not restore its save")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("MAP EXPANSION TEST PASSED")
		quit(0)
	else:
		print("MAP EXPANSION TEST FAILED: ", failures)
		quit(1)
