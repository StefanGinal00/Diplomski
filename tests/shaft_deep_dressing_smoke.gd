extends "res://tests/route_field_dressing_smoke.gd"

const DEEP_ROOMS := [["shaft_gallery", "FloodedGallery", 4, 1], ["shaft_cistern", "BlackwaterCistern", 3, 2], ["shaft_approach", "WardenApproach", 3, 1]]


func _detail(game: Node, room_name: String) -> Node:
	return game.get_node(room_name + "/ExpandedRoute/FieldDressing")


func _enter(game: Node, entry: Array) -> Node:
	root.get_node("GameState").set_current_room(entry[0])
	var room := game.get_node(entry[1])
	_freeze(room)
	room.get_node("ExpandedRoute/AuthoredDescent/ExplorationSites/FieldResident").set_process(false)
	return room


func _guide(room: Node) -> Node:
	return room.get_node("ExpandedRoute/AuthoredDescent/ExplorationSites/FieldResident")


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_deep_dressing_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player: Player = game.get_node("Player")
	player.set_physics_process(false)
	for entry in DEEP_ROOMS:
		var detail := _detail(game, entry[1])
		_check(not detail.population_loaded, "Deep room populated before entry")
		for i in range(7):
			var site := detail.get_node("Site%d" % i)
			_check(site.position.distance_to(detail.ROUTE_ANCHORS[entry[0]][i]) < 0.02, "Preview anchor differs from supported runtime floor")
			for j in range(i):
				_check(site.position.distance_to(detail.anchors[j]) > 360, "Local displays overlap")
			_check(site.get_child_count() >= 3 and site.find_children("*", "CollisionObject2D", true, false).is_empty(), "Missing scenery or unintended collision")
		var room := _enter(game, entry)
		await physics_frame
		var crates: Array[Node] = []
		var grazers: Array[Node] = []
		for actor in detail.get_children():
			if actor.is_in_group("breakable"):
				crates.append(actor)
				_floor(actor)
				_check(actor.max_gold <= 4 and actor.empty_drop_chance >= 0.5, "Excessive supply reward")
			elif actor.is_in_group("neutral_creature"):
				grazers.append(actor)
				_floor(actor)
				_check(not actor.is_hostile and actor.zone_id == "sunken_shaft", "Wrong fauna disposition or zone")
		_check(crates.size() == entry[2] and grazers.size() == entry[3], "Wrong deep room dressing population")
		var guide := _guide(room)
		var guide_id := guide.get_instance_id()
		_check(guide.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Guide UI disconnected")
		_check(not detail.has_node("FieldGuide") and not detail.has_node("SalvageCache"), "Duplicate NPC/reward")
		var damaged := detail.get_path_to(crates[0])
		var broken := detail.get_path_to(crates[1])
		var grazer := detail.get_path_to(grazers[0])
		crates[0].current_health = 1
		crates[1].empty_drop_chance = 1
		crates[1].take_damage(10)
		grazers[0].take_damage(1)
		var moved: Vector2 = grazers[0].position + Vector2(8, 0)
		grazers[0].position = moved
		await process_frame
		state.set_current_room("training_passage")
		game.get_node("WorldPopulation").unload_room_population(entry[1])
		await process_frame
		_check(not detail.has_node(damaged) and not detail.has_node(grazer), "Dressing did not unload")
		_enter(game, entry)
		await process_frame
		_check(detail.get_node(damaged).current_health == 1 and not detail.has_node(broken), "Supply state reset on return")
		_check(detail.get_node(grazer).is_hostile and detail.get_node(grazer).position.is_equal_approx(moved), "Grazer state reset on return")
		_check(_guide(room).get_instance_id() == guide_id, "Returning duplicated guide")
		var route := room.get_node("ExpandedRoute/AuthoredDescent")
		var trial := route.get_node("HiddenDepthAmbush")
		var cache := route.get_node("HiddenDepthCache")
		_check(not cache.open(player), "Guarded cache opened early")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Niche lacks two guardians")
		trial.spawned_enemies[0].die()
		_check(not cache.open(player) and detail.get_node("Site4/GuardianSeal0").visible, "One guardian cleared both seals")
		trial.spawned_enemies[1].die()
		_check(cache.open(player) and not cache.open(player) and not detail.get_node("Site4/GuardianSeal0").visible, "Niche reward/cue broken")
		_check("separate cache" in guide.dialogue_lines[1], "Guide lacks independent niche advice")
	_check(not state.unlocked_shortcuts.get("shaft_gallery_lower", false) and not state.unlocked_shortcuts.get("shaft_cistern_pump", false) and not state.unlocked_shortcuts.get("shaft_approach_bridge", false), "Niche bypassed main mechanics")
	var gallery := _enter(game, DEEP_ROOMS[0])
	var gd := _detail(game, "FloodedGallery")
	_check(gallery.get_node("LowerControl").activate(player), "Lower control failed")
	_check("CALMED" in gd.get_node("Site0/RouteClue").text and "PRESSURIZED" in gd.get_node("Site3/RouteClue").text, "Pressure banks did not update independently")
	_check(not gallery.get_node("WardenShortcutDoor")._requirements_met() and "Find the upper" in _guide(gallery).dialogue_lines[0], "One bank opened passage or wrong guide advice")
	for i in range(7):
		_check(gallery.get_node("ExpandedRoute/AuthoredDescent/GalleryPressureJet%02d" % i).disabled == (i < 4), "Lower control calmed wrong jet bank")
	var cistern := _enter(game, DEEP_ROOMS[1])
	var cd := _detail(game, "BlackwaterCistern")
	_check(not cistern.get_node("HighDial").activate(player), "Wrong first dial accepted")
	_check(cistern.get_node("NearDial").activate(player), "Near dial failed")
	_check("1/3" in cd.get_node("Site0/RouteClue").text and "1/3" in _guide(cistern).dialogue_lines[0], "Transient dial progress not shown")
	_check(not cistern.get_node("FarDial").activate(player), "Wrong third dial accepted")
	_check("0/3" in cd.get_node("Site0/RouteClue").text and is_equal_approx(cd.get_node("Site3/Water").scale.y, 1), "Wrong sequence left cues active")
	_check(cistern.get_node("NearDial").activate(player), "Near dial retry failed")
	# Snapshot keeps the completed Gallery bank, but not the unfinished puzzle.
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "deep_dressing", "Deep Dressing", "shaft_cistern"), "Partial snapshot failed")
	_check(cistern.get_node("HighDial").activate(player) and cistern.get_node("FarDial").activate(player), "Correct sequence failed")
	_check(is_equal_approx(cd.get_node("Site3/Water").scale.y, 0.2), "Completed pump did not lower gauge")
	for i in range(3):
		_check(cistern.get_node("ExpandedRoute/AuthoredDescent/CisternPressureWave%d" % i).disabled, "Completed pump left pressure hazard")
	_check(gallery.get_node("UpperControl").activate(player), "Upper control failed")
	var approach := _enter(game, DEEP_ROOMS[2])
	_check(approach.get_node("CounterweightCrank").activate(player), "Counterweight failed")
	_check("LOWERED" in _detail(game, "WardenApproach").get_node("Site3/RouteClue").text and "return bridge is lowered" in _guide(approach).dialogue_lines[0], "Bridge cue/advice stale")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial snapshot load failed")
	game = _world()
	await process_frame
	player = game.get_node("Player")
	player.set_physics_process(false)
	gallery = _enter(game, DEEP_ROOMS[0])
	gd = _detail(game, "FloodedGallery")
	_check("CALMED" in gd.get_node("Site0/RouteClue").text and "PRESSURIZED" in gd.get_node("Site3/RouteClue").text, "Saved partial bank/rollback failed")
	cistern = _enter(game, DEEP_ROOMS[1])
	cd = _detail(game, "BlackwaterCistern")
	_check("0/3" in cd.get_node("Site0/RouteClue").text and is_equal_approx(cd.get_node("Site3/Water").scale.y, 1), "Unfinished puzzle or unsaved pump survived load")
	_check("NOT RELEASED" in _detail(game, "WardenApproach").get_node("Site3/RouteClue").text, "Unsaved bridge survived load")
	for entry in DEEP_ROOMS:
		var room := _enter(game, entry)
		_check(not _detail(game, entry[1]).get_node("Site4/GuardianSeal0").visible, "Saved niche cue reset")
		_check(not room.get_node("ExpandedRoute/AuthoredDescent/HiddenDepthCache").open(player), "Saved niche paid again")
	_check(gallery.get_node("UpperControl").activate(player), "Upper control retry failed")
	for dial in ["NearDial", "HighDial", "FarDial"]:
		_check(cistern.get_node(dial).activate(player), "Pump retry failed")
	approach = _enter(game, DEEP_ROOMS[2])
	_check(approach.get_node("CounterweightCrank").activate(player), "Counterweight retry failed")
	state.set_zone_tier("sunken_shaft", 1)
	for entry in DEEP_ROOMS:
		var room := _enter(game, entry)
		_check("lowest side branch has awakened" in _guide(room).dialogue_lines[0], "New clues overwrote awakened trial advice")
		var sites := room.get_node("ExpandedRoute/AuthoredDescent/ExplorationSites")
		var trial := sites.get_node("AwakenedTrial")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2, "Awakened branch lacks its two guardians")
		for enemy in trial.spawned_enemies:
			enemy.die()
		_check(sites.get_node("AwakenedTrialReward").open(player) and not sites.get_node("AwakenedTrialReward").open(player), "Return reserve not one-time")
		_check("quiet again" in _guide(room).dialogue_lines[0], "Completed return advice lost")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "deep_dressing", "Deep Dressing", "shaft_approach"), "Completed snapshot failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Completed snapshot load failed")
	game = _world()
	await process_frame
	_check("CALMED" in _detail(game, "FloodedGallery").get_node("Site3/RouteClue").text, "Saved upper bank cue reset")
	_check(is_equal_approx(_detail(game, "BlackwaterCistern").get_node("Site3/Water").scale.y, 0.2), "Saved pump cue reset")
	_check("LOWERED" in _detail(game, "WardenApproach").get_node("Site3/RouteClue").text, "Saved bridge cue reset")
	for entry in DEEP_ROOMS:
		var room := _enter(game, entry)
		var sites := room.get_node("ExpandedRoute/AuthoredDescent/ExplorationSites")
		_check(sites.get_node("AwakenedTrial").completed and sites.get_node("AwakenedTrialReward").opened, "Completed return trial/reward reset on load")
		_check("quiet again" in _guide(room).dialogue_lines[0], "Saved completed return advice reset")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("SHAFT DEEP DRESSING TEST PASSED")
		quit(0)
	else:
		print("SHAFT DEEP DRESSING TEST FAILED: ", failures)
		quit(1)
