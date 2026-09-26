extends SceneTree

const BACKDROP = preload("res://BiomeBackdrop.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_biome_backdrop_suite_save.json"
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var backdrop: Control = game.get_node("Background/BiomeBackdrop")
	_check(backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Biome backdrop blocks pointer input")
	var expectations := {
		"training_passage": "training",
		"sunken_shaft": "shaft",
		"shaft_cistern": "shaft",
		"echo_grotto": "echo",
		"echo_haven": "echo_town",
		"ash_forge": "ash",
		"ash_hearth": "ash_town",
		"starfall_sunless_passage": "starfall",
		"starfall_citadel": "starfall_town",
	}
	for room_id in expectations:
		_check(backdrop.biome_for_room(room_id) == expectations[room_id], "%s uses the wrong backdrop family" % room_id)
	state.set_current_room("echo_grotto")
	_check(backdrop.target_biome == "echo" and backdrop.transition == 0.0, "Room change did not begin an Echo backdrop transition")
	backdrop._process(0.9)
	_check(backdrop.transition == 1.0, "Backdrop palette transition did not complete")
	state.set_current_room("ash_hearth")
	_check(backdrop.target_biome == "ash_town", "Safe Ash settlement did not receive its warm town palette")
	var training_top: Color = BACKDROP.PALETTES["training"]["top"]
	var starfall_top: Color = BACKDROP.PALETTES["starfall"]["top"]
	_check(training_top != starfall_top, "Regions do not have distinct background palettes")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("BIOME BACKDROP TEST PASSED")
		quit(0)
	else:
		print("BIOME BACKDROP TEST FAILED: ", failures)
		quit(1)
