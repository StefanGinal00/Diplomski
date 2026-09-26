extends "res://tests/route_field_dressing_smoke.gd"

const ASH_ROOMS := [["ash_causeway", "BrokenCauseway"], ["ash_chapel", "AshChapel"]]


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_ash_route_dressing_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	for entry in ASH_ROOMS:
		var room := game.get_node(entry[1])
		var detail := room.get_node("AshSwitchback/FieldDressing")
		_check(not detail.population_loaded and not detail.has_node("FieldGuide"), "Ash field population loaded before entry")
		for i in range(7):
			var site := detail.get_node("Site%d" % i)
			_check(site.z_index >= 0, "Ash scenery would be hidden behind opaque chamber draw")
			_check(site.get_child_count() >= 3 and site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Missing scenery or extra collision")
			for j in range(i):
				var footprint := Rect2(site.position + Vector2(-175, -235), Vector2(350, 235))
				var other := Rect2(detail.anchors[j] + Vector2(-175, -235), Vector2(350, 235))
				_check(not footprint.intersects(other), "Field scenes overlap: %s/%d and %d" % [entry[0], i, j])
		state.set_current_room(entry[0])
		_freeze(room)
		await physics_frame
		var guide := detail.get_node("FieldGuide")
		guide.set_process(false)
		var guide_id := guide.get_instance_id()
		_floor(guide)
		for marker in guide.route_markers:
			_floor(marker)
		_check(guide.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Ash guide UI disconnected")
		var nearest := INF
		for enemy in get_nodes_in_group("enemy"):
			if room.is_ancestor_of(enemy):
				nearest = minf(nearest, guide.global_position.distance_to(enemy.global_position))
		_check(nearest > 170, "Field guide inside hostile patrol")
		var crates: Array[Node] = []
		var fauna: Array[Node] = []
		for actor in detail.get_children():
			if actor.is_in_group("breakable"):
				crates.append(actor)
				_floor(actor)
				_check(actor.max_gold <= 4 and actor.empty_drop_chance >= 0.5, "Supplies too generous")
			elif actor.is_in_group("neutral_creature"):
				fauna.append(actor)
				_floor(actor)
				_check(not actor.is_hostile and actor.zone_id == "ashen_bastion", "Wrong fauna allegiance/zone")
		_check(crates.size() == 3 and fauna.size() == 1, "Unexpected Ash field population")
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
		_check(not guide.can_process(), "Off-room guide keeps processing")
		game.get_node("WorldPopulation").unload_room_population(entry[1])
		await process_frame
		_check(not detail.has_node(damaged) and not detail.has_node(grazer), "Props/fauna did not unload")
		state.set_current_room(entry[0])
		_freeze(room)
		await process_frame
		_check(detail.get_node(damaged).current_health == 1 and not detail.has_node(broken), "Supplies reset on return")
		_check(detail.get_node(grazer).is_hostile and detail.get_node(grazer).position.is_equal_approx(moved), "Fauna reset on return")
		_check(detail.get_node("FieldGuide").get_instance_id() == guide_id, "Guide duplicated on return")
		_check("0/" in guide.dialogue_lines[0], "Initial guide advice missing")
		_check(not state.unlocked_shortcuts.get(entry[0] + "_field_complete", false), "Dressing granted field completion")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("ASH ROUTE DRESSING TEST PASSED")
		quit(0)
	else:
		print("ASH ROUTE DRESSING TEST FAILED: ", failures)
		quit(1)
