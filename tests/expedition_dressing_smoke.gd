extends "res://tests/route_field_dressing_smoke.gd"

const EXP_DETAILS := preload("res://ExpeditionFieldDressing.gd")
const EXP_ROOMS := [["shaft_drift", "ShaftDriftworks", 4], ["echo_depths", "EchoDepths", 3], ["ash_emberspine", "AshEmberspine", 4]]


func _cues(detail: Node) -> void:
	var state := root.get_node("GameState")
	var flags: Dictionary = state.unlocked_shortcuts
	var profile: Dictionary = EXP_DETAILS.PROFILES[detail.region]
	var count := 0
	for i in range(2):
		var active := bool(flags.get(profile["events"][i], false))
		count += int(active)
		var color: Color = Color(0.5, 0.93, 0.75) if active else detail.tone.darkened(0.3)
		_check(detail.get_node("Site1/Light%d" % i).color.is_equal_approx(color), "Expedition register light stale")
		if detail.region == "drift":
			_check(detail.get_node("Site3/Valve%d" % i).default_color.is_equal_approx(color), "Drift manifold does not track individual pump")
		elif detail.region == "depths":
			_check(detail.get_node("Site5/LensLight%d" % i).color.is_equal_approx(color), "Depths lens does not track individual signal")
		else:
			_check(detail.get_node("Site4/KilnWindow%d" % i).color.is_equal_approx(Color(0.33, 0.54, 0.58) if active else Color(0.95, 0.4, 0.15)), "Emberspine kiln does not track individual coolant")
	_check("%d/2" % count in detail.get_node("Site1/RouteClue").text, "Expedition progress caption stale")
	if detail.has_node("FieldGuide"):
		_check("%d/2" % count in detail.get_node("FieldGuide").dialogue_lines[0], "Expedition guide advice stale")
		if flags.get(profile["returned"], false):
			var signs: Array = detail.get_parent().get_node("FieldOperations").signs
			_check("CLEARED" in signs[0].text and not "After the Castellan" in signs[0].text and not "RETURN AFTER THE MATRIARCH" in signs[0].text, "Old expedition sign advertises cleared return")
	if detail.region == "drift":
		_check(detail.get_node("Site5/Wheel").default_color.is_equal_approx(detail.tone.lightened(0.5) if flags.get(profile["events"][1], false) else detail.tone), "Crown flywheel lit from wrong pump")
		var mechanic := detail.get_parent().get_node_or_null("Infrastructure/Mechanic")
		if mechanic != null:
			_check("%d/2" % count in mechanic.dialogue_lines[0], "Tova repair count stale")
			if flags.get(profile["returned"], false):
				_check(not "return to the northwestern" in " ".join(mechanic.dialogue_lines), "Tova advertised a cleared trial")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_exp_dressing_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	for entry in EXP_ROOMS:
		var room := game.get_node(entry[1])
		var detail := room.get_node("FieldDressing")
		_check(not detail.population_loaded and not detail.has_node("FieldGuide"), "Expedition actors loaded before entry")
		for i in range(8):
			var site := detail.get_node("Site%d" % i)
			_check(site.position.distance_to(EXP_DETAILS.PREVIEW_POINTS[detail.region][i]) < 0.02, "Expedition editor preview drifted")
			_check(site.z_index >= 0 and site.get_child_count() >= 3, "Expedition scenery hidden/missing")
			_check(site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Expedition dressing changed collision")
			for j in range(i):
				_check(not Rect2(site.position + Vector2(-175, -235), Vector2(350, 235)).intersects(Rect2(detail.anchors[j] + Vector2(-175, -235), Vector2(350, 235))), "Expedition sites overlap: %s/%d and %d" % [entry[1], i, j])
		state.set_current_room(entry[0])
		_freeze(room)
		await physics_frame
		var guide := room.get_node("Infrastructure/Mechanic") if detail.region == "drift" else detail.get_node("FieldGuide")
		guide.set_process(false)
		if detail.region != "drift":
			for caption in ["DeepExitSign", "LowerLiftHint"]:
				_check(not guide.get_node("NameLabel").get_global_rect().intersects(room.get_node(caption).get_global_rect()), "Expedition guide name overlaps exit/lift guidance")
		var guide_id := guide.get_instance_id()
		_floor(guide)
		for marker in guide.route_markers:
			_floor(marker)
		_check(guide.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Expedition guide has no dialogue UI")
		if detail.region == "drift":
			_check(not detail.has_node("FieldGuide"), "Duplicated Tova with a second guide")
		else:
			var nearest := INF
			for enemy in get_nodes_in_group("enemy"):
				if room.is_ancestor_of(enemy):
					nearest = minf(nearest, guide.global_position.distance_to(enemy.global_position))
			_check(nearest > 170, "Expedition guide overlaps hostile patrol: %s distance %s" % [entry[1], nearest])
		var crates: Array[Node] = []
		var fauna: Array[Node] = []
		for actor in detail.get_children():
			if actor.is_in_group("breakable"):
				crates.append(actor)
				_floor(actor)
				_check(actor.max_gold <= 4 and actor.empty_drop_chance >= 0.5, "Expedition crate economy changed")
			elif actor.is_in_group("neutral_creature"):
				fauna.append(actor)
				_floor(actor)
				_check(not actor.is_hostile and actor.zone_id == detail._zone(), "Expedition grazer hostile/wrong zone")
		_check(crates.size() == entry[2] and fauna.size() == 1, "Wrong expedition actor count")
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
		_check(not guide.can_process(), "Off-room expedition guide still active")
		game.get_node("WorldPopulation").unload_room_population(entry[1])
		await process_frame
		_check(not detail.has_node(damaged) and not detail.has_node(grazer), "Expedition dressing actors did not unload")
		state.set_current_room(entry[0])
		_freeze(room)
		await process_frame
		_check(detail.get_node(damaged).current_health == 1 and not detail.has_node(broken), "Expedition crates reset on revisit")
		_check(detail.get_node(grazer).is_hostile and detail.get_node(grazer).position.is_equal_approx(moved), "Expedition fauna state reset")
		_check(guide.get_instance_id() == guide_id, "Revisit duplicated expedition guide")
		var profile: Dictionary = EXP_DETAILS.PROFILES[detail.region]
		_check(not state.unlocked_shortcuts.get(profile["complete"], false), "Dressing completed a field task")
		_cues(detail)
		state.unlock_shortcut(profile["events"][0])
		_cues(detail)
		_check("TASK: PENDING" in detail.get_node("Site7/RouteClue").text, "Partial task completed reserve cue")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "exp_dressing", "Expedition Dressing", "ash_emberspine"), "Expedition partial save failed")
	for entry in EXP_ROOMS:
		var detail := game.get_node(entry[1] + "/FieldDressing")
		state.unlock_shortcut(EXP_DETAILS.PROFILES[detail.region]["events"][1])
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Expedition partial load failed")
	game = _world()
	await process_frame
	for entry in EXP_ROOMS:
		state.set_current_room(entry[0])
		await process_frame
		var room := game.get_node(entry[1])
		_freeze(room)
		var detail := room.get_node("FieldDressing")
		var profile: Dictionary = EXP_DETAILS.PROFILES[detail.region]
		_cues(detail)
		_check("1/2" in detail.get_node("Site1/RouteClue").text and "TASK: PENDING" in detail.get_node("Site7/RouteClue").text, "Unsaved task completion survived rollback")
		state.set_zone_tier(detail._zone(), 1)
		_check("FINISH LOCAL REQUIREMENTS" in detail.get_node("Site7/RouteClue").text, "Awakening bypassed task requirements")
		state.unlock_shortcut(profile["events"][1])
		_cues(detail)
		if detail.region == "emberspine":
			_check("DEEP GUARD: PENDING" in detail.get_node("Site7/RouteClue").text and "FINISH LOCAL REQUIREMENTS" in detail.get_node("Site7/RouteClue").text, "Cooling bypassed deep guard cue")
			state.unlock_shortcut(profile["guard"])
		_check("RETURN: READY" in detail.get_node("Site7/RouteClue").text, "Return-ready cue stale")
		state.unlock_shortcut(profile["returned"])
		_cues(detail)
		_check("WATCH IS QUIET" in detail.get_node("Site7/RouteClue").text, "Cleared return still advertised")
		if detail.has_node("FieldGuide"):
			_check("quiet" in String(detail.get_node("FieldGuide").dialogue_lines[2]).to_lower(), "Cleared return guide advice stale")
	_check(state.save_at_checkpoint(game.get_node("Player"), game.get_node("QuestManager"), game.get_node("Player").global_position, "exp_dressing", "Expedition Dressing", "ash_emberspine"), "Completed expedition save failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Completed expedition load failed")
	game = _world()
	await process_frame
	for entry in EXP_ROOMS:
		state.set_current_room(entry[0])
		await process_frame
		var detail := game.get_node(entry[1] + "/FieldDressing")
		_cues(detail)
		_check("2/2" in detail.get_node("Site1/RouteClue").text and "WATCH IS QUIET" in detail.get_node("Site7/RouteClue").text, "Completed expedition cues not restored")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("EXPEDITION DRESSING TEST PASSED: 24 sites / 11 crates / 3 neutral grazers / 2 new guides")
		quit(0)
	else:
		print("EXPEDITION DRESSING TEST FAILED: ", failures)
		quit(1)
