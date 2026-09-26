extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_cinder_town_expansion_suite_save.json"
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var town: Node2D = game.get_node("CinderHearth")
	var districts: Node2D = town.get_node("EasternDistricts")
	_check(not districts.is_population_loaded() and not districts.has_node("Veyra"), "The unvisited Cinder districts eagerly loaded their residents")
	state.set_current_room("ash_hearth")
	await process_frame
	_check(districts.is_population_loaded(), "Entering Cinder Hearth did not stream its district residents")
	_check(town.get_node("RightWall").position.x >= 4200.0, "Cinder Hearth did not grow beyond its original street")
	_check(town.get_node("ThroneShortcut").position.x > 4000.0, "Far gate still sits next to the entrance market")
	_check(districts.get_node("EastMarketStreet/CollisionShape2D").shape.size.x > 2500.0, "New town street is not connected")
	_check(districts.has_node("KilnArcade") and districts.has_node("CopperLibraryWalk") and districts.has_node("CinderWatch"), "Town lacks distinct elevated districts")
	_check(districts.has_node("KilnLoft") and districts.has_node("WatchHouse") and districts.has_node("MarketAwning0") and districts.has_node("CaravanCart2") and districts.has_node("WardLaundry3"), "New Cinder districts lack houses and lived-in street detail")
	var residents := 0
	for child in districts.get_children():
		if child.is_in_group("town_resident"):
			residents += 1
			_check(child.route_markers.size() >= 2, "A new resident has no working walking route")
		_check(not child.is_in_group("enemy"), "An enemy spawned inside the safe town")
	_check(residents >= 11, "The expanded town lacks residents")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("CINDER TOWN EXPANSION TEST PASSED")
		quit(0)
	else:
		print("CINDER TOWN EXPANSION TEST FAILED: ", failures)
		quit(1)
