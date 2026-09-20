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
	state.save_path = "res://_tmp_tide_well_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player = game.get_node("Player")
	var grotto = game.get_node("EchoGrotto")
	var well = game.get_node("TideWell")
	var top_lift = well.get_node("UpperLift")
	var bottom_lift = well.get_node("LowerLift")
	var surge = well.get_node("Surge")
	var ui = game.get_node("UI")
	_check(get_first_node_in_group("tide_entry") != null, "Tide entry marker missing")
	_check(get_first_node_in_group("grotto_tide_return") != null, "Grotto return marker missing")
	_check(not bool(state.unlocked_shortcuts.get("tide_lift", false)), "Tide lift began unlocked")
	_check("LIFT LOCKED" in top_lift.prompt.text, "Upper lift was not locked from above")
	for index in range(1, 8):
		_check(well.get_node("Step%d/CollisionShape2D" % index).one_way_collision, "Tide step %d blocks upward jumps" % index)
		if index > 1:
			_check(well.get_node("Step%d" % index).position.y - well.get_node("Step%d" % (index - 1)).position.y <= 70.0, "Tide step %d is too far apart" % index)
	grotto.get_node("TideDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_tide_well", "Tide door did not enter well")
	_check(game.get_node("AmbientSoundscape").current_track == "echo_tide_well", "Tide ambience missing")
	_check("DESCEND FOR TIDE CORE" in ui.objective_label.text, "Tide objective missing")
	player.max_health = 100
	player.current_health = 100
	surge._advance_phase()
	_check(surge.phase == "warning", "Tide surge did not telegraph")
	surge._advance_phase()
	_check(surge.phase == "active", "Tide surge did not activate")
	player.global_position = surge.global_position
	player.velocity = Vector2.ZERO
	await create_timer(0.12).timeout
	_check(player.current_health == 99, "Tide surge did not damage player exactly once")
	await create_timer(0.12).timeout
	_check(player.current_health == 99, "Tide surge repeatedly damaged player in one pulse")
	var core = well.get_node("TideCore")
	core._on_body_entered(player)
	await process_frame
	_check(state.has_item("tide_core"), "Tide Core was not collected")
	_check("ENTER ECHO NEST" in ui.objective_label.text, "Tide objective did not point to Nest")
	well.get_node("DeepShade").take_damage(999)
	await process_frame
	player.global_position = bottom_lift.global_position
	player.velocity = Vector2.ZERO
	bottom_lift.player_in_range = player
	var interact := InputEventAction.new()
	interact.action = "interact"
	interact.pressed = true
	bottom_lift._unhandled_input(interact)
	await create_timer(0.5).timeout
	_check(bool(state.unlocked_shortcuts.get("tide_lift", false)), "Bottom lift did not unlock shortcut")
	_check(player.global_position.distance_to(well.get_node("UpperLiftMarker").global_position) < 45.0, "Bottom lift did not reach top")
	_check("TIDE LIFT" in top_lift.prompt.text, "Upper lift did not show unlocked state")
	_check("ENTER ECHO NEST" in ui.objective_label.text, "Tide objective lost the next route")
	top_lift._use_lift(player)
	await create_timer(0.5).timeout
	_check(player.global_position.distance_to(well.get_node("LowerLiftMarker").global_position) < 45.0, "Upper lift did not return to bottom")
	var lamp = well.get_node("TideLamp/RespawnPoint")
	_check(state.save_at_checkpoint(player, game.get_node("QuestManager"), lamp.global_position, "tide_well_lamp", "Tide Well Lamp", "echo_tide_well"), "Tide save failed")
	state.inventory.erase("tide_core")
	state.unlocked_shortcuts.erase("tide_lift")
	_check(state.load_game(), "Tide save could not load")
	_check(state.has_item("tide_core") and bool(state.unlocked_shortcuts.get("tide_lift", false)), "Tide progress not restored")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	well = game.get_node("TideWell")
	_check(not well.has_node("TideCore"), "Unique Tide Core respawned after load")
	_check("TIDE LIFT" in well.get_node("UpperLift/Prompt").text, "Saved Tide lift visuals not restored")
	player = game.get_node("Player")
	well.get_node("LowerLift")._use_lift(player)
	await create_timer(0.5).timeout
	well.get_node("ReturnDoor")._on_body_entered(player)
	await create_timer(0.5).timeout
	_check(state.current_room_id == "echo_grotto", "Tide return door did not reach Grotto")
	_check(player.global_position.distance_to(game.get_node("EchoGrotto/TideReturn").global_position) < 45.0, "Tide return reached wrong marker")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("TIDE WELL TEST PASSED")
		quit(0)
	else:
		print("TIDE WELL TEST FAILED: ", failures)
		quit(1)
