extends "res://tests/route_field_dressing_smoke.gd"

const INDUSTRY_ROOMS := [["ash_forge", "CinderForge", 3], ["ash_barracks", "EmberBarracks", 3], ["ash_reservoir", "SlagReservoir", 3], ["ash_hearth_outskirts", "CinderHearthOutskirts", 5]]


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_industry_dressing_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	for entry in INDUSTRY_ROOMS:
		var room := game.get_node(entry[1])
		var detail := room.get_node("AshSwitchback/FieldDressing")
		_check(not detail.population_loaded and not detail.has_node("FieldGuide"), "Industry actors loaded before entry")
		for i in range(7):
			var site := detail.get_node("Site%d" % i)
			_check(site.z_index >= 0 and site.get_child_count() >= 3, "Industry detail hidden/missing")
			_check(site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Industry scenery changed collision")
			for j in range(i):
				_check(not Rect2(site.position + Vector2(-175, -235), Vector2(350, 235)).intersects(Rect2(detail.anchors[j] + Vector2(-175, -235), Vector2(350, 235))), "Industry sites overlap: %s/%d and %d" % [entry[0], i, j])
		state.set_current_room(entry[0])
		_freeze(room)
		await physics_frame
		var guides: Array[Node] = []
		if entry[0] == "ash_hearth_outskirts":
			_check(not detail.has_node("FieldGuide"), "Outskirts duplicated its scouts")
			for i in range(2):
				guides.append(room.get_node("AshSwitchback/FieldOperations/WatchScout%d" % i))
		else:
			guides.append(detail.get_node("FieldGuide"))
		var guide_ids: Array[int] = []
		for guide in guides:
			guide.set_process(false)
			guide_ids.append(guide.get_instance_id())
			_floor(guide)
			for marker in guide.route_markers:
				_floor(marker)
			_check(guide.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Industry guide UI disconnected")
			if entry[0] != "ash_hearth_outskirts":
				var nearest := INF
				for enemy in get_nodes_in_group("enemy"):
					if room.is_ancestor_of(enemy):
						nearest = minf(nearest, guide.global_position.distance_to(enemy.global_position))
				_check(nearest > 170, "Industry guide overlaps initial hostile patrol")
		var crates: Array[Node] = []
		var fauna: Array[Node] = []
		for actor in detail.get_children():
			if actor.is_in_group("breakable"):
				crates.append(actor)
				_floor(actor)
				_check(actor.max_gold <= 4 and actor.empty_drop_chance >= 0.5, "Industry crate economy changed")
			elif actor.is_in_group("neutral_creature"):
				fauna.append(actor)
				_floor(actor)
				_check(not actor.is_hostile and actor.zone_id == "ashen_bastion", "Industry grazer hostile/wrong zone")
		_check(crates.size() == entry[2] and fauna.size() == 1, "Wrong industry population count")
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
		for guide in guides:
			_check(not guide.can_process(), "Off-room industry guide still active")
		game.get_node("WorldPopulation").unload_room_population(entry[1])
		await process_frame
		_check(not detail.has_node(damaged) and not detail.has_node(grazer), "Industry population failed to unload")
		state.set_current_room(entry[0])
		_freeze(room)
		await process_frame
		_check(detail.get_node(damaged).current_health == 1 and not detail.has_node(broken), "Industry crates reset on reload")
		_check(detail.get_node(grazer).is_hostile and detail.get_node(grazer).position.is_equal_approx(moved), "Industry fauna state reset on reload")
		for i in range(guides.size()):
			_check(is_instance_valid(guides[i]) and guides[i].get_instance_id() == guide_ids[i], "Guide duplicated on return")
		_check("0/" in guides[0].dialogue_lines[0], "Initial industry advice lacks progress")
		_check(not state.unlocked_shortcuts.get("ash_" + detail.region + "_field_complete", false), "Scenery bypassed original task")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("ASH INDUSTRY DRESSING TEST PASSED")
		quit(0)
	else:
		print("ASH INDUSTRY DRESSING TEST FAILED: ", failures)
		quit(1)
