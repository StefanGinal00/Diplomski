extends "res://tests/shaft_hollow_smoke.gd"

# Scripted integration: actual doors, mechanisms, damage/death signals and
# reward APIs. Player setup is teleported; this is not movement/combat pacing.
const ROOM_NAMES := {"shaft_hollow": "ShaftHollow", "shaft_crossing": "DrownedCrossing", "shaft_gallery": "FloodedGallery", "shaft_cistern": "BlackwaterCistern", "shaft_approach": "WardenApproach"}
var transitions := 0


func _world() -> Node:
	var game := load("res://Game.tscn").instantiate() as Node
	root.add_child(game)
	current_scene = game
	return game


func _door(game: Node, path: String, target: String) -> void:
	var state := root.get_node("GameState")
	var player := game.get_node("Player") as Player
	var door := game.get_node(path)
	var source: String = state.current_room_id
	player.global_position = door.global_position
	door._on_body_entered(player)
	_check(state.current_room_id == source, path + ": walking into the door transitioned automatically")
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	door._unhandled_input(event)
	await _wait_for_transition(player)
	_check(state.current_room_id == target, path + ": wrong room after explicit interaction")
	transitions += 1
	for enemy in get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)


func _clear(encounter: Node, player: Player) -> void:
	encounter._on_body_entered(player)
	await process_frame
	_check(encounter.spawned_enemies.size() == 2, "Expected two local guardians")
	for enemy in encounter.spawned_enemies:
		enemy.set_physics_process(false)
		enemy.take_damage(enemy.max_health)
	await process_frame
	_check(encounter.completed, "Guardian damage did not complete encounter")


func _fits_hud(ui: Node) -> void:
	for info in [[ui.objective_label, 310.0], [ui.notification_label, 440.0]]:
		var label: Label = info[0]
		var font := label.get_theme_font("font")
		var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		_check(width <= float(info[1]) - 12, "New guidance exceeds its HUD panel: " + label.text)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shaft_progression_feedback_save.json"
	state.start_new_game("normal")
	var game := _world()
	await process_frame
	var player := game.get_node("Player") as Player
	player.set_physics_process(false)
	var ui := game.get_node("UI")
	state.set_current_room("sunken_shaft")
	await _door(game, "VerticalChamber/HollowUpperDoor", "shaft_hollow")
	var hollow := game.get_node("ShaftHollow")
	_check(not hollow.get_node("Relay").activate(player), "Main relay ignored its original guardians")
	for name in ["HollowWispNear", "HollowWispFar"]:
		var guardian := hollow.get_node(name)
		guardian.take_damage(guardian.max_health)
	_check(hollow.get_node("Relay").activate(player), "Hollow relay did not activate")
	await _door(game, "ShaftHollow/CrossingDoor", "shaft_drift")
	await _door(game, "ShaftDriftworks/UpperShortcutDoor", "shaft_crossing")
	game.get_node("DrownedCrossing/Valve").activate(player)
	_check("CURRENTS CALMED" in ui.objective_label.text and "SAFE" not in ui.objective_label.text, "Draining the sluice incorrectly advertised a safe room")
	_check("FOES REMAIN" in ui.notification_label.text, "Sluice notification concealed remaining danger")
	_fits_hud(ui)
	await _door(game, "DrownedCrossing/GalleryDoor", "shaft_gallery")
	var gallery := game.get_node("FloodedGallery")
	var route := gallery.get_node("ExpandedRoute/AuthoredDescent")
	await _clear(route.get_node("HiddenDepthAmbush"), player)
	_check("ALCOVE CLEARED" in ui.notification_label.text, "Niche completion was mislabeled as a control or overwritten by ordinary loot")
	_check("0/2" in ui.objective_label.text and not gallery.get_node("WardenShortcutDoor")._requirements_met(), "Optional niche bypassed Gallery mechanisms")
	_check(route.get_node("HiddenDepthCache").open(player), "Niche reward did not open")
	gallery.get_node("LowerControl").activate(player)
	_check("1/2" in ui.objective_label.text, "First control not reflected in HUD")
	gallery.get_node("WardenShortcutDoor").activate(player)
	_check(state.current_room_id == "shaft_gallery" and not root.get_node("RoomTransition").is_transitioning, "One control allowed actual travel through the Warden gate")
	_check(not gallery.get_node("CisternDoor")._requirements_met(), "Gallery bypassed the unfinished Cistern pump")
	gallery.get_node("CisternDoor").activate(player)
	_check(state.current_room_id == "shaft_gallery" and not root.get_node("RoomTransition").is_transitioning, "Unfinished pump allowed actual travel through the Cistern gate")
	await _door(game, "FloodedGallery/CrossingReturnDoor", "shaft_crossing")
	await _door(game, "DrownedCrossing/CisternDoor", "shaft_cistern")
	var cistern := game.get_node("BlackwaterCistern")
	_check(not cistern.get_node("HighDial").activate(player), "Wrong first dial was accepted")
	cistern.get_node("NearDial").activate(player)
	_check("1/3" in ui.objective_label.text, "Partial dial progress missing from HUD")
	# This snapshot deliberately retains one Gallery control, not a partial
	# three-dial sequence or any future awakened trial rewards.
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "feedback_test", "Feedback Test", "shaft_cistern"), "Partial progression snapshot failed")
	cistern.get_node("HighDial").activate(player)
	cistern.get_node("FarDial").activate(player)
	await _door(game, "BlackwaterCistern/GalleryShortcutDoor", "shaft_gallery")
	state.set_zone_tier("sunken_shaft", 1)
	_check("1/2" in ui.objective_label.text, "Awakened side objective hid an unfinished main mechanism")
	gallery.get_node("UpperControl").activate(player)
	_check("RETURN TRIAL" in ui.objective_label.text, "Completing main mechanism did not expose awakened branch")
	await _door(game, "FloodedGallery/WardenShortcutDoor", "shaft_approach")
	_check("LOWER THE BRIDGE" in ui.objective_label.text, "Approach main mechanism lost priority")
	game.get_node("WardenApproach/CounterweightCrank").activate(player)
	# The return tier is set explicitly here; boss combat is covered elsewhere.
	for room_id in ROOM_NAMES:
		state.set_current_room(room_id)
		await process_frame
		player.set_physics_process(false)
		var room := game.get_node(ROOM_NAMES[room_id])
		room.process_mode = Node.PROCESS_MODE_DISABLED
		_check("RETURN TRIAL" in ui.objective_label.text, room_id + ": missing return-visit objective")
		var sites := room.get_node("ExpandedRoute/AuthoredDescent/ExplorationSites")
		var reward := sites.get_node("AwakenedTrialReward")
		_check(not reward.open(player), room_id + ": return reserve opened early")
		await _clear(sites.get_node("AwakenedTrial"), player)
		_check("CLAIM RETURN RESERVE" in ui.objective_label.text, room_id + ": stale objective after guardians")
		_check("RETURN TRIAL CLEARED" in ui.notification_label.text, room_id + ": misleading completion notification")
		_fits_hud(ui)
		_check(reward.open(player) and not reward.open(player), room_id + ": reward was not one-time")
		_check("RETURN RESERVE CLAIMED" in ui.objective_label.text, room_id + ": stale objective after reward")
		_fits_hud(ui)
	# Restoring the earlier snapshot must restore the corresponding guidance.
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Partial snapshot could not reload")
	game = _world()
	await process_frame
	ui = game.get_node("UI")
	player = game.get_node("Player")
	player.set_physics_process(false)
	_check(state.get_zone_tier("sunken_shaft") == 0 and "DIALS 0/3" in ui.objective_label.text, "Rollback retained awakening or transient dial progress")
	for room_id in ROOM_NAMES:
		_check(not state.unlocked_shortcuts.get(room_id + "_return_trial_cleared", false) and not state.opened_caches.get(room_id + "_trial_reserve", false), room_id + ": unsaved reward/completion survived rollback")
	state.set_current_room("shaft_gallery")
	await process_frame
	_check("1/2" in ui.objective_label.text and not game.get_node("FloodedGallery/WardenShortcutDoor")._requirements_met(), "Rollback lost partial control progress or kept shortcut open")
	state.set_zone_tier("sunken_shaft", 1)
	_check("1/2" in ui.objective_label.text, "Awakening hid an unfinished saved main task")
	game.get_node("FloodedGallery/UpperControl").activate(player)
	_check("RETURN TRIAL" in ui.objective_label.text, "Unsaved return completion survived rollback")
	var sites := game.get_node("FloodedGallery/ExpandedRoute/AuthoredDescent/ExplorationSites")
	await _clear(sites.get_node("AwakenedTrial"), player)
	sites.get_node("AwakenedTrialReward").open(player)
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), player.global_position, "feedback_test", "Feedback Test", "shaft_gallery"), "Completed snapshot failed")
	game.queue_free()
	await process_frame
	_check(state.load_game(), "Completed snapshot could not reload")
	game = _world()
	await process_frame
	_check("RETURN RESERVE CLAIMED" in game.get_node("UI").objective_label.text, "Completed return guidance did not restore")
	_check(not game.get_node("FloodedGallery/ExpandedRoute/AuthoredDescent/ExplorationSites/AwakenedTrialReward").open(game.get_node("Player")), "Saved return reserve paid again")
	state.delete_save()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("SHAFT PROGRESSION FEEDBACK TEST PASSED: ", transitions, " door transitions, 5 return objectives, partial/completed save rollback")
		quit(0)
	else:
		print("SHAFT PROGRESSION FEEDBACK TEST FAILED: ", failures.size())
		quit(1)
