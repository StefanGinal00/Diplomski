extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_entry_growth_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	var total := 0
	for named in preload("res://EchoEntryGrowthArt.gd").KINDS:
		var room := game.get_node(named)
		var art := room.get_node("EchoEntryGrowthArt")
		var before := _physics_snapshot(room)
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		var count: int = art.props.size()
		art._build()
		game.get_node("WorldPopulation")._build_growth(room, game.get_node("WorldPopulation").ROOMS[named])
		_check(art.built and not art.is_processing() and art.get_child_count() == 0 and art.props.size() == count and art.retired.size() == 10, "Entry growth duplicated or not static")
		_check(_physics_snapshot(room) == before and flags == state.unlocked_shortcuts, "Entry flora changed gameplay")
		for leaf in art.retired:
			_check(not leaf.visible and leaf.get_child_count() == 0, "Old floating triangles visible")
		for prop in art.props:
			var rect: Rect2 = prop.rect
			var floor_rect: Rect2 = prop.support
			var source: Rect2 = art.SOURCES[prop.kind][1]
			_check(is_equal_approx(rect.size.x / source.size.x, rect.size.y / source.size.y), "Entry art distorted")
			_check(absf(rect.end.y - floor_rect.position.y) < 0.01 and rect.position.x >= floor_rect.position.x and rect.end.x <= floor_rect.end.x, "Entry flora lacks full floor support")
			_check(absf(rect.get_center().x - prop.anchor.x) <= 60.01 and absf(rect.end.y - prop.anchor.y) <= 32.01, "Entry flora moved too far")
			for obstacle in art.floor_rects:
				_check(not rect.grow(-0.05).intersects(obstacle), "Entry flora intersects a platform")
			total += 1
		print("ENTRY GROWTH ", named, " ", count)
	_check(total >= 28, "Expected expanded regional supported entry clusters")
	_check(game.get_node("ShaftHollow").has_node("EchoEntryGrowthArt") and not game.get_node("ShaftHollow/WildGrowth0_0").visible, "Shaft flora still uses triangles")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("REGIONAL ENTRY GROWTH TEST PASSED: ", total, " grounded clusters; unchanged physics and idempotence")
		quit(0)
	else:
		quit(1)
