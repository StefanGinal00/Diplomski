extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_training_passage_decor_suite_save.json"
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await physics_frame
	var decor: Node2D = game.get_node("TrainingPassageDecor")
	var details: Node2D = decor.get_node("GeneratedPassageDetails")
	_check(details.has_node("CampStep") and details.has_node("CampRoof"), "Opening camp lacks its optional climb")
	var camp_step: StaticBody2D = details.get_node("CampStep")
	var camp_roof: StaticBody2D = details.get_node("CampRoof")
	_check(400.0 - camp_step.position.y <= 65.0 and camp_step.position.y - camp_roof.position.y <= 60.0, "Opening camp climb exceeds the basic jump rhythm")
	_check(details.has_node("AqueductArch0") and details.has_node("OldWaterLine"), "Opening passage lacks an aqueduct landmark")
	_check(details.has_node("SentinelDais") and details.has_node("GateArch"), "Sentinel arena lacks a readable court")
	_check(details.has_node("WayfarerMoth"), "Opening rest has no neutral cave life")
	_check(game.get_node("ExitPortal").position == Vector2(1335, 366), "Passage exit moved while adding decor")
	_check(game.get_node("Checkpoint").position == Vector2(560, 376), "Opening checkpoint moved while adding decor")
	state.set_current_room("sunken_shaft")
	_check(not decor.visible and decor.process_mode == Node.PROCESS_MODE_DISABLED, "Training details remain active in distant rooms")
	state.set_current_room("training_passage")
	_check(decor.visible and decor.process_mode == Node.PROCESS_MODE_INHERIT, "Training details did not reactivate on return")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("TRAINING PASSAGE DECOR TEST PASSED")
		quit(0)
	else:
		print("TRAINING PASSAGE DECOR TEST FAILED: ", failures)
		quit(1)
