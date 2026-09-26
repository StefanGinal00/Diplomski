extends "res://tests/ash_field_operations_smoke.gd"


func _connected(city: Node2D, upper: Node2D) -> void:
	var decks: Array[Rect2] = [Rect2(0, 393, 6250, 14)]
	for node in upper.get_children():
		if node is StaticBody2D:
			var collision := node.get_node("CollisionShape2D") as CollisionShape2D
			var size := (collision.shape as RectangleShape2D).size
			_check(collision.one_way_collision, "Upper terrace blocks ascent from below")
			decks.append(Rect2(node.position - size * 0.5, size))
	var reached: Array[int] = [0]
	var cursor := 0
	while cursor < reached.size():
		var from := decks[reached[cursor]]
		cursor += 1
		for index in range(decks.size()):
			if reached.has(index):
				continue
			var to := decks[index]
			var gap := maxf(from.position.x, to.position.x) - minf(from.end.x, to.end.x)
			if absf(from.position.y - to.position.y) <= 55 and gap <= 65:
				reached.append(index)
	_check(reached.size() == decks.size(), "An upper terrace/stair is disconnected from the street")
	_check(city.get_node("Roof").position.y == -1950, "Original roof still blocks the upper city")
	_check(city.get_node("LeftWall/CollisionShape2D").shape.size.y == 2450, "City side boundary does not enclose upper streets")
	for route in upper.stair_routes:
		for index in range(1, route.size()):
			var delta: Vector2 = route[index] - route[index - 1]
			_check(absf(delta.y) <= 50.1 and absf(delta.x) <= 70, "A city stair needs an upgraded jump")


func _wait_lift(player: Player) -> void:
	var transition := root.get_node("RoomTransition")
	var deadline := Time.get_ticks_msec() + 5000
	while transition.is_transitioning and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not transition.is_transitioning, "City lift transition timed out")
	player.set_physics_process(false)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_upper_city_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var city := game.get_node("StarfallCitadel") as Node2D
	var upper := city.get_node("UpperCity") as Node2D
	var player := game.get_node("Player") as Player
	player.set_physics_process(false)
	_check(not upper.population_loaded and not upper.has_node("Iven"), "Upper city loaded residents before entry")
	for i in range(4):
		_check(not upper.has_node("WorkplaceResident%d" % i), "Workplace resident loaded before city entry")
		_check(upper.get_node("Workplace%d" % i).find_children("*", "CollisionObject2D", true, false).is_empty(), "City workplace scenery blocks pedestrians")
	_connected(city, upper)
	state.set_current_room("starfall_citadel")
	await process_frame
	await physics_frame
	var count := 0
	for npc in get_nodes_in_group("town_resident"):
		if not upper.is_ancestor_of(npc):
			continue
		count += 1
		_floor(npc)
		_check(npc.route_markers.size() == 3, "Upper resident lacks a home/social route")
		for marker in npc.route_markers:
			_floor(marker)
		_check(npc.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Upper resident has no dialogue UI")
	_check(count == 12, "Expected twelve upper-city residents")
	for hostile in get_nodes_in_group("enemy") + get_nodes_in_group("boss"):
		_check(not city.is_ancestor_of(hostile), "Upper city is not peaceful")
	var reward := upper.get_node("CitySurveyReward")
	_floor(reward)
	_check(not reward.open(player), "Survey gift ignored unvisited landmarks")
	for i in range(3):
		var plaque := upper.get_node("Landmark%d" % i)
		_floor(plaque)
		_press(plaque, player)
	_check(not reward.open(player) and "3/4" in upper.survey_label.text, "Partial survey unlocked the gift")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), city.get_node("MarketLamp/RespawnPoint").global_position, "starfall_market_lamp", "Market", "starfall_citadel"), "Partial city survey failed to save")
	_press(upper.get_node("Landmark3"), player)
	_check(reward.open(player) and not reward.open(player), "City survey reward is missing or repeatable")
	_check("GIFT COLLECTED" in upper.survey_label.text, "Survey board did not refresh after collection")
	var gold := int(state.gold)
	_press(upper.get_node("StreetLift"), player)
	_check(not root.get_node("RoomTransition").is_transitioning and not state.unlocked_shortcuts.has("starfall_city_crown_lift"), "Street lift bypasses first ascent")
	_press(upper.get_node("CrownLift"), player)
	await _wait_lift(player)
	_check(player.global_position.distance_to(upper.get_node("StreetArrival").global_position) < 3, "Crown lift missed the street arrival")
	_press(upper.get_node("StreetLift"), player)
	await _wait_lift(player)
	_check(player.global_position.distance_to(upper.get_node("CrownArrival").global_position) < 3 and state.current_room_id == "starfall_citadel", "Street lift split the city or missed the crown")
	var resident_id := upper.get_node("Iven").get_instance_id()
	var worker_id := upper.get_node("WorkplaceResident0").get_instance_id()
	state.set_current_room("training_passage")
	_check(not upper.get_node("Iven").can_process(), "Upper NPC processes outside city")
	_check(not upper.get_node("WorkplaceResident0").can_process(), "Workplace NPC processes outside city")
	state.set_current_room("starfall_citadel")
	_check(upper.get_node("Iven").get_instance_id() == resident_id and state.gold == gold, "Revisit duplicated residents or rewards")
	_check(upper.get_node("WorkplaceResident0").get_instance_id() == worker_id, "Revisit duplicated workplace resident")
	_check(state.load_game(), "Partial city survey failed to load")
	game.queue_free()
	await process_frame
	game = _world()
	await process_frame
	upper = game.get_node("StarfallCitadel/UpperCity")
	_check("3/4" in upper.survey_label.text and not upper.get_node("CitySurveyReward").opened, "Lamp rollback did not restore partial survey")
	_check(not state.unlocked_shortcuts.has("starfall_city_crown_lift"), "Unsaved crown lift survived rollback")
	player = game.get_node("Player")
	player.set_physics_process(false)
	_press(upper.get_node("Landmark3"), player)
	_check(upper.get_node("CitySurveyReward").open(player), "Rolled-back survey cannot be completed again")
	_press(upper.get_node("CrownLift"), player)
	await _wait_lift(player)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "starfall_market_lamp", "Market", "starfall_citadel"), "Completed city survey failed to save")
	gold = state.gold
	_check(state.load_game(), "Completed city survey failed to load")
	game.queue_free()
	await process_frame
	game = _world()
	await process_frame
	upper = game.get_node("StarfallCitadel/UpperCity")
	_check("GIFT COLLECTED" in upper.survey_label.text and upper.get_node("CitySurveyReward").opened, "Saved city gift became farmable")
	_check(bool(state.unlocked_shortcuts.get("starfall_city_crown_lift", false)) and state.gold == gold, "Completed city save lost lift or economy state")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if failures.is_empty():
		print("STARFALL UPPER CITY TEST PASSED")
		quit(0)
	else:
		print("STARFALL UPPER CITY TEST FAILED: ", failures)
		quit(1)
