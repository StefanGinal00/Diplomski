extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_branch_exits_suite_save.json"
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame

	var shaft: Node2D = game.get_node("VerticalChamber")
	var crossing_door: Node2D = shaft.get_node("CrossingDoor")
	var gallery_door: Node2D = shaft.get_node("GalleryShortcutDoor")
	var hollow_door: Node2D = shaft.get_node("HollowLowerDoor")
	_check(crossing_door.position.y < hollow_door.position.y - 100.0, "Shaft Crossing and Hollow exits remain side by side")
	_check(gallery_door.position.y < hollow_door.position.y - 100.0, "Shaft Gallery and Hollow exits remain side by side")
	_check(crossing_door.position.x < 45.0 and gallery_door.position.x < shaft.get_node("GallerySpur").position.x, "Shaft branch doors are not at their spur ends")
	_check(shaft.get_node("CrossingReturn").position.distance_to(crossing_door.position) > 45.0, "Crossing return would immediately re-enter its door")
	_check(shaft.get_node("GalleryReturn").position.distance_to(gallery_door.position) > 45.0, "Gallery return would immediately re-enter its door")

	var flooded: Node2D = game.get_node("FloodedGallery")
	_check(absf(flooded.get_node("CisternDoor").position.y - flooded.get_node("CrossingReturnDoor").position.y) > 100.0, "Cistern entrance is still beside Crossing exit")
	_check(flooded.get_node("CisternReturn").position.distance_to(flooded.get_node("CisternDoor").position) > 45.0, "Cistern return would re-enter its door")
	var echo_gallery: Node2D = game.get_node("EchoGallery")
	_check(echo_gallery.get_node("CausewayDoor").position.y < echo_gallery.get_node("ShortcutDoor").position.y - 50.0, "Causeway and Grotto shortcut remain on one corridor")
	_check(echo_gallery.get_node("CausewayReturn").position.distance_to(echo_gallery.get_node("CausewayDoor").position) > 45.0, "Causeway return would re-enter its door")
	var sanctum: Node2D = game.get_node("ResonanceSanctum")
	_check(sanctum.get_node("AshenGate").position.y < sanctum.get_node("GrottoShortcut").position.y - 50.0, "Ashen and Grotto exits remain side by side")
	_check(sanctum.get_node("AshenReturn").position.distance_to(sanctum.get_node("AshenGate").position) > 45.0, "Ashen return would re-enter its gate")
	var nest: Node2D = game.get_node("EchoNest")
	_check(nest.get_node("ShortcutDoor").position.distance_to(nest.get_node("SanctumDoor").position) > 250.0, "Nest shortcut and Sanctum entrance remain clustered")
	_check(nest.get_node("ShortcutDoor").position.y < nest.get_node("ReturnDoor").position.y - 100.0, "Well upper shortcut is not at an upper branch")

	var grotto: Node2D = game.get_node("EchoGrotto")
	var causeway: Node2D = game.get_node("BrokenCauseway")
	_check(grotto.get_node("HavenDoor").position.x >= 190.0, "Haven passage is not at the ledge end")
	_check(causeway.get_node("HearthDoor").position.x >= 185.0, "Hearth passage is not at the ledge end")

	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("BRANCH EXITS TEST PASSED")
		quit(0)
	else:
		print("BRANCH EXITS TEST FAILED: ", failures)
		quit(1)
