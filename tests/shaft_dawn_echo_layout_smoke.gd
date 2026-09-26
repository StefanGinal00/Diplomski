extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("GameState").save_path = "res://_tmp_shaft_dawn_echo_layout_suite_save.json"
	var state := root.get_node("GameState")
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	state.set_current_room("shaft_cistern")
	await process_frame
	var echo := game.get_node("BlackwaterCistern/DawnEcho") as Node2D
	var crawler := game.get_node("BlackwaterCistern/ChannelCrawler") as Node2D
	state.mark_boss_defeated("hollow_sovereign")
	print("SHAFT ECHO DIAGNOSTIC: echo=", echo.position, " crawler=", crawler.position, " distance=", echo.global_position.distance_to(crawler.global_position), " threat=", echo._has_nearby_threat())
	var passed: bool = echo.global_position.distance_to(crawler.global_position) < echo.threat_radius and echo._has_nearby_threat()
	game.queue_free()
	await process_frame
	if passed:
		print("SHAFT DAWN ECHO LAYOUT TEST PASSED")
		quit(0)
	else:
		print("SHAFT DAWN ECHO LAYOUT TEST FAILED")
		quit(1)
