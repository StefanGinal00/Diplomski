extends SceneTree

var failures: Array[String] = []
const ROOMS := {
	"shaft_hollow": "ShaftHollow",
	"shaft_crossing": "DrownedCrossing",
	"shaft_gallery": "FloodedGallery",
	"shaft_cistern": "BlackwaterCistern",
	"shaft_approach": "WardenApproach",
}


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _new_world() -> Node:
	var game := load("res://Game.tscn").instantiate() as Node
	root.add_child(game)
	current_scene = game
	return game


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_exploration_save.json"
	state.start_new_game("normal")
	var game := _new_world()
	await process_frame
	var player = game.get_node("Player")
	_check(not game.has_node("ShaftHollow/ExpandedRoute/AuthoredDescent/ExplorationSites"), "Unvisited room eagerly loaded its field camp")
	for room_id in ROOMS:
		state.set_current_room(room_id)
		await process_frame
		var route = game.get_node(ROOMS[room_id] + "/ExpandedRoute/AuthoredDescent")
		var sites = route.get_node("ExplorationSites")
		_check(not route.get_node("Branch1_Label").visible, "Generic branch heading overlaps camp name")
		_check(route.get_node("Branch5_Label").text == "RETURN AFTER THE WARDEN", "First-clear return branch guidance is wrong")
		_check(route.get_node("Niche4_Label").text == "DEFEAT BOTH GUARDIANS", "High-niche guidance is missing")
		var resident = sites.get_node("FieldResident")
		_check(resident.route_markers.size() == 2 and resident.dialogue_lines.size() == (4 if room_id == "shaft_hollow" else 3) and not resident.is_in_group("enemy"), "Field guide lacks a walkable local path or clues")
		_check(resident.interaction_requested.is_connected(Callable(game.get_node("UI"), "_on_npc_interaction_requested")), "Field guide was not connected to dialogue")
		var trial = sites.get_node("AwakenedTrial")
		trial._on_body_entered(player)
		await process_frame
		_check(not trial.triggered and not sites.get_node("AwakenedTrialReward").open(player), "Return trial or reward unlocked before the first clear")
		var first = route.get_node("HiddenDepthAmbush")
		var cache = route.get_node("HiddenDepthCache")
		_check(not cache.open(player), "Guarded first-clear reward opened without defeating guardians")
		first._on_body_entered(player)
		await process_frame
		_check(first.spawned_enemies.size() == 2, "First-clear alcove did not spawn its two guardians")
		first.spawned_enemies[0].die()
		_check(not first.completed and not cache.open(player), "One guardian was enough to unlock both-guardian reward")
		first.spawned_enemies[1].die()
		_check(route.get_node("Niche4_Label").text == "CACHE UNSEALED", "Guardian defeat did not update the niche sign")
		_check(first.completed and cache.open(player) and not cache.open(player), "First-clear reward was not unlocked exactly once")
		_check(route.get_node("Niche4_Label").text == "CLAIMED", "Collected niche reward still advertised as available")
		for info in [["Niche4_Label", first, cache], ["Branch5_Label", trial, sites.get_node("AwakenedTrialReward")]]:
			var status: Label = route.get_node(info[0])
			_check(status.get_minimum_size().y <= status.size.y, "Site status text is clipped")
			_check(not status.get_global_rect().intersects(info[1].status_label.get_global_rect()), "Site status overlaps encounter title")
			_check(not status.get_global_rect().intersects(info[2].prompt.get_global_rect()), "Site status overlaps cache prompt")
		state.set_current_room("training_passage")
		state.set_current_room(room_id)
		await process_frame
		_check(sites == route.get_node("ExplorationSites"), "Returning to a room duplicated its field camp")
	state.set_current_room("shaft_hollow")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "exploration_test", "Exploration Test", "shaft_hollow"), "Could not save first-clear exploration progress")
	state.set_zone_tier("sunken_shaft", 1)
	for room_id in ROOMS:
		state.set_current_room(room_id)
		await process_frame
		var sites = game.get_node(ROOMS[room_id] + "/ExpandedRoute/AuthoredDescent/ExplorationSites")
		var trial = sites.get_node("AwakenedTrial")
		_check("DORMANT" not in trial.status_label.text, "Trial sign did not react to the zone awakening")
		_check(sites.get_parent().get_node("Branch5_Label").text == "DEFEAT BOTH GUARDIANS", "Return sign did not awaken")
		trial._on_body_entered(player)
		await process_frame
		_check(trial.spawned_enemies.size() == 2 and trial.triggered, "Awakened branch did not create its encounter")
		for enemy in trial.spawned_enemies:
			enemy.die()
		_check(sites.get_parent().get_node("Branch5_Label").text == "CACHE UNSEALED", "Return reward sign did not unseal")
		_check(trial.completed and sites.get_node("AwakenedTrialReward").open(player), "Awakened encounter did not release its reserve")
		_check(sites.get_parent().get_node("Branch5_Label").text == "CLAIMED", "Return reward sign did not show collection")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "First-clear checkpoint could not reload")
	game = _new_world()
	await process_frame
	player = game.get_node("Player")
	var route = game.get_node("ShaftHollow/ExpandedRoute/AuthoredDescent")
	_check(route.get_node("Niche4_Label").text == "CLAIMED" and route.get_node("Branch5_Label").text == "RETURN AFTER THE WARDEN", "Site signs did not restore the saved first-clear state")
	_check(route.get_node("HiddenDepthCache").opened and route.get_node("HiddenDepthAmbush").completed, "Saved first-clear reward or encounter completion reset")
	var trial = route.get_node("ExplorationSites/AwakenedTrial")
	var reward = route.get_node("ExplorationSites/AwakenedTrialReward")
	_check(not trial.completed and not reward.opened and not reward.open(player), "Unsaved return trial or reward survived checkpoint rollback")
	state.set_zone_tier("sunken_shaft", 1)
	trial._on_body_entered(player)
	await process_frame
	for enemy in trial.spawned_enemies:
		enemy.die()
	_check(reward.open(player), "Return reward could not be reclaimed after rollback")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "exploration_test", "Exploration Test", "shaft_hollow"), "Could not save completed return trial")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Return trial checkpoint could not reload")
	game = _new_world()
	await process_frame
	trial = game.get_node("ShaftHollow/ExpandedRoute/AuthoredDescent/ExplorationSites/AwakenedTrial")
	trial._on_body_entered(game.get_node("Player"))
	await process_frame
	_check(trial.completed and trial.spawned_enemies.is_empty(), "Saved completed trial spawned its guardians again")
	_check(game.get_node("ShaftHollow/ExpandedRoute/AuthoredDescent/ExplorationSites/AwakenedTrialReward").opened, "Saved return reward reopened")
	_check(game.get_node("ShaftHollow/ExpandedRoute/AuthoredDescent/Branch5_Label").text == "CLAIMED", "Saved return sign lost its collected state")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("SHAFT EXPLORATION SITES TEST PASSED")
		quit(0)
	else:
		print("SHAFT EXPLORATION SITES TEST FAILED: ", failures)
		quit(1)
