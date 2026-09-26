extends "res://tests/route_field_dressing_smoke.gd"

const STAR_DETAILS := preload("res://StarfallRouteDressing.gd")


func _landmarks(detail: Node) -> void:
	var flags: Dictionary = root.get_node("GameState").unlocked_shortcuts
	var checks: Array = []
	var events: Array = detail._events()
	match detail.region:
		"StarfallOutskirts":
			checks.append(["Site4/TornStandard", "color", detail.tone.lightened(0.35) if flags.get(events[0], false) and flags.get(events[1], false) else detail.tone])
		"StarfallSilentGate":
			checks.append(["Site3/WardSeal", "color", detail.tone.lightened(0.55) if flags.get("starfall_silent_high", false) and flags.get("starfall_silent_low", false) else detail.tone.darkened(0.4)])
		"StarfallMemoryVault":
			for i in range(3):
				checks.append(["Site3/MemoryStar%d" % i, "color", detail.tone.lightened(0.55) if flags.get(events[i], false) else detail.tone.darkened(0.4)])
		"StarfallRootedHall":
			for i in range(3):
				var event: String = [events[0], "starfall_root_channels", events[1]][i]
				checks.append(["Site4/Seedling%d" % i, "default_color", detail.tone.lightened(0.4) if flags.get(event, false) else detail.tone.darkened(0.4)])
		"StarfallSoulCrucible":
			checks.append(["Site3/ContainmentRing", "default_color", detail.tone.lightened(0.55) if flags.get("starfall_crucible_stabilized", false) else detail.tone.darkened(0.05)])
		"StarfallSunlessPassage":
			for i in range(3):
				checks.append(["Site3/Lantern%d" % i, "color", detail.tone.lightened(0.5) if flags.get(events[i], false) else detail.tone.darkened(0.4)])
		"StarfallRamparts":
			checks.append(["Site3/WardSeal", "color", detail.tone.lightened(0.55) if flags.get(events[2], false) else detail.tone.darkened(0.4)])
	for item in checks:
		_check((detail.get_node(item[0]).get(item[1]) as Color).is_equal_approx(item[2]), "Starfall landmark state stale: %s/%s" % [detail.region, item[0]])


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_star_dressing_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	for room_name in STAR_DETAILS.PROFILES:
		var room := game.get_node(room_name)
		var detail := room.get_node("FieldDressing" if room_name == "StarfallRamparts" else "ExpandedRoute/FieldDressing")
		var id: String = STAR_DETAILS.PROFILES[room_name][0]
		_check(not detail.population_loaded and not detail.has_node("FieldGuide"), "Starfall actors loaded before entry: " + room_name)
		for i in range(7):
			var site := detail.get_node("Site%d" % i)
			_check(site.position.distance_to(STAR_DETAILS.PREVIEW_POINTS[room_name][i]) < 0.02, "Starfall editor preview drifted: " + room_name)
			_check(site.z_index >= 0 and site.get_child_count() >= 3, "Starfall detail hidden/missing")
			_check(site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Scenery changed gameplay collision")
			for j in range(i):
				_check(not Rect2(site.position + Vector2(-175, -235), Vector2(350, 235)).intersects(Rect2(detail.anchors[j] + Vector2(-175, -235), Vector2(350, 235))), "Starfall sites overlap: %s/%d and %d" % [room_name, i, j])
		state.set_current_room(id)
		_freeze(room)
		await physics_frame
		if room_name != "StarfallRamparts":
			var route := room.get_node("ExpandedRoute/StarfallDescent")
			_check(not route.get_node("FieldOperations").signs[-1].get_global_rect().intersects(route.get_node("HiddenStarAmbush").status_label.get_global_rect()), "Reserve instructions overlap guardian status")
		var guide := detail.get_node("FieldGuide")
		guide.set_process(false)
		var guide_id := guide.get_instance_id()
		_floor(guide)
		for marker in guide.route_markers:
			_floor(marker)
		_check(guide.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Starfall guide UI disconnected")
		var nearest := INF
		for enemy in get_nodes_in_group("enemy"):
			if room.is_ancestor_of(enemy):
				nearest = minf(nearest, guide.global_position.distance_to(enemy.global_position))
		_check(nearest > 170, "Starfall guide overlaps hostile patrol: %s distance %s" % [room_name, nearest])
		var crates: Array[Node] = []
		var fauna: Array[Node] = []
		for actor in detail.get_children():
			if actor.is_in_group("breakable"):
				crates.append(actor)
				_floor(actor)
				_check(actor.max_gold <= 4 and actor.empty_drop_chance >= 0.5, "Starfall crate economy changed")
			elif actor.is_in_group("neutral_creature"):
				fauna.append(actor)
				_floor(actor)
				_check(not actor.is_hostile and actor.zone_id == "starfall_reach", "Starfall grazer hostile/wrong zone")
		_check(crates.size() == 3 and fauna.size() == 1, "Wrong Starfall population count")
		var damaged := detail.get_path_to(crates[0])
		var broken := detail.get_path_to(crates[1])
		var grazer := detail.get_path_to(fauna[0])
		crates[0].current_health = 1
		crates[1].empty_drop_chance = 1
		crates[1].take_damage(10)
		fauna[0].take_damage(1)
		var moved: Vector2 = fauna[0].position + Vector2(8, 0)
		fauna[0].position = moved
		await process_frame
		state.set_current_room("training_passage")
		_check(not guide.can_process(), "Off-room guide still active")
		game.get_node("WorldPopulation").unload_room_population(room_name)
		await process_frame
		_check(not detail.has_node(damaged) and not detail.has_node(grazer), "Starfall population failed to unload")
		state.set_current_room(id)
		_freeze(room)
		await process_frame
		_check(detail.get_node(damaged).current_health == 1 and not detail.has_node(broken), "Starfall crates reset on reload")
		_check(detail.get_node(grazer).is_hostile and detail.get_node(grazer).position.is_equal_approx(moved), "Starfall fauna state reset on reload")
		_check(guide.get_instance_id() == guide_id, "Starfall guide duplicated on return")
		_check("0/" in guide.dialogue_lines[0], "Initial guide advice lacks progress")
		_landmarks(detail)
		_check(not state.unlocked_shortcuts.get(id + "_field_complete", false), "Scenery bypassed original task")
		var events: Array = detail._events()
		state.unlock_shortcut(events[0])
		_check(detail.get_node("Site1/Light0").color.is_equal_approx(Color(0.58, 0.95, 0.74)), "First task light did not update")
		_check(detail.get_node("Site1/Light1").color.is_equal_approx(detail.tone.darkened(0.55)), "First task incorrectly lit second")
		_check("1/" in guide.dialogue_lines[0], "Guide partial advice stale")
		_landmarks(detail)
		_check("TASK: PENDING" in detail.get_node("Site6/RouteClue").text, "Partial work unsealed reserve cue")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "star_dressing", "Star Dressing", "starfall_ramparts"), "Dressing partial save failed")
	# Mutate after saving; loading must restore every panel, not retain completion.
	for room_name in STAR_DETAILS.PROFILES:
		var id: String = STAR_DETAILS.PROFILES[room_name][0]
		state.unlock_shortcut(id + "_field_complete")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Dressing partial load failed")
	game = _world()
	await process_frame
	for room_name in STAR_DETAILS.PROFILES:
		var id: String = STAR_DETAILS.PROFILES[room_name][0]
		state.set_current_room(id)
		await process_frame
		var room := game.get_node(room_name)
		_freeze(room)
		var detail := room.get_node("FieldDressing" if room_name == "StarfallRamparts" else "ExpandedRoute/FieldDressing")
		_check("1/" in detail.get_node("FieldGuide").dialogue_lines[0], "Saved panel progress not restored")
		_landmarks(detail)
		_check("TASK: PENDING" in detail.get_node("Site6/RouteClue").text, "Unsaved completion survived reload")
		state.unlock_shortcut(id + "_field_complete")
		_check("GUARDIANS: PENDING" in detail.get_node("Site6/RouteClue").text, "Field completion bypassed guardian cue")
		state.unlock_shortcut(id + "_niche_cleared")
		state.mark_boss_defeated("hollow_sovereign")
		_check("PATROL READY" in detail.get_node("Site6/RouteClue").text, "Ready return cue stale")
		state.unlock_shortcut(id + "_field_return_complete")
		_check("WATCH IS QUIET" in detail.get_node("Site6/RouteClue").text, "Cleared patrol still advertised")
		_check("quiet" in String(detail.get_node("FieldGuide").dialogue_lines[2]).to_lower(), "Cleared guide advice stale")
		# All task lights and original-system models also support completed state.
		for event in detail._events():
			state.unlock_shortcut(event)
		for event in ["starfall_silent_high", "starfall_silent_low", "starfall_root_channels"]:
			state.unlock_shortcut(event)
		_landmarks(detail)
	_check(state.save_at_checkpoint(game.get_node("Player"), game.get_node("QuestManager"), game.get_node("Player").global_position, "star_dressing", "Star Dressing", "starfall_ramparts"), "Completed dressing save failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Completed dressing load failed")
	game = _world()
	await process_frame
	for room_name in STAR_DETAILS.PROFILES:
		state.set_current_room(STAR_DETAILS.PROFILES[room_name][0])
		await process_frame
		var room := game.get_node(room_name)
		var detail := room.get_node("FieldDressing" if room_name == "StarfallRamparts" else "ExpandedRoute/FieldDressing")
		_landmarks(detail)
		_check("WATCH IS QUIET" in detail.get_node("Site6/RouteClue").text, "Saved return cue not restored")
		var total: int = detail._events().size()
		_check("%d/%d" % [total, total] in detail.get_node("FieldGuide").dialogue_lines[0], "Saved completed guide advice not restored")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("STARFALL DRESSING TEST PASSED: 7 routes / 49 sites / 21 supplies / 7 grazers / 7 guides")
		quit(0)
	else:
		print("STARFALL DRESSING TEST FAILED: ", failures)
		quit(1)
