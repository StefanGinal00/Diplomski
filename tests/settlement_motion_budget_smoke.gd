extends "res://tests/visual_style_slice_smoke.gd"
const Layout := preload("res://WorldLayout.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_motion_budget.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 3: await process_frame
	game.get_node("UI").story_player.cancel()
	paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var ambience: Node = finish.ambience
	var previous: Array[Node2D] = []
	for id in ["echo_haven","echo_haven_outskirts","ash_hearth","starfall_citadel"]:
		state.set_current_room(id)
		for frame in 3: await process_frame
		finish.finish_room(id)
		for old in previous: _check(old.rotation==0 and old.skew==0,"Previous room ornament still moving")
		var room := game.get_node(str(Layout.ROOM_NODES[id]))
		var decor := room.get_node("SettlementAtmosphere")
		for detail in decor.hangings: _check(detail in ambience.candidates,"New ornament bypassed room ambience")
		if id=="starfall_citadel": _check(decor.landmarks[0] in ambience.candidates,"Fountain animation not registered")
		var view := Rect2(room.global_position-Vector2(10000,10000),Vector2(30000,30000))
		ambience.set_low_quality(false)
		ambience.select_visible(view)
		_check(ambience.active.size()>0 and ambience.active.size()<=18,"Standard prop budget exceeded")
		ambience.set_low_quality(true)
		ambience.select_visible(view)
		_check(ambience.active.size()<=8,"Low-cost prop budget exceeded")
		var count: int = ambience.candidates.size()
		finish.finish_room(id)
		_check(count==ambience.candidates.size(),"Revisit duplicates candidates")
		ambience.select_visible(Rect2(Vector2(1000000,1000000),Vector2.ONE))
		_check(ambience.active.is_empty(),"Offscreen props still animate")
		ambience.select_visible(Rect2(decor.hangings[0].global_position-Vector2(50,50),Vector2(100,100)))
		previous.clear()
		for detail in ambience.active:
			if detail in decor.hangings:
				previous.append(detail)
				detail.animate(3)
		_check(not previous.is_empty(),"Nearby pendants never selected")
		print("SETTLEMENT MOTION ",id," ",decor.hangings.size()," hanging; 18/8 cap verified")
	game.queue_free()
	await process_frame
	state.delete_save()
	print("SETTLEMENT MOTION BUDGET TEST PASSED" if failures.is_empty() else "TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
