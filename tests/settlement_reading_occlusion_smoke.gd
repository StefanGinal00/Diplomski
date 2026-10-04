extends "res://tests/visual_style_slice_smoke.gd"
const Layout := preload("res://WorldLayout.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_reading_occlusion.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 3: await process_frame
	game.get_node("UI").story_player.cancel()
	paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var reader: CanvasLayer = finish.reader
	var player: Player = game.get_node("Player")
	var masks := 0
	for id in ["echo_haven","echo_haven_outskirts","ash_hearth","starfall_citadel"]:
		state.set_current_room(id)
		for frame in 4: await process_frame
		finish.finish_room(id)
		var room := game.get_node(str(Layout.ROOM_NODES[id]))
		for node in finish._members(room):
			if node.has_meta("camera_backdrop_retired"):
				masks += 1
				_check(not node.visible and node.get_child_count()==0,"Retired mask still covers scenery")
		if id=="ash_hearth":
			_check(not room.get_node("StoneWalk").visible,"Flat walk backdrop hides timber footings")
			_check(room.get_node("WalkwayArt").surfaces.size()==44,"Lost textured walk surfaces")
		if id=="starfall_citadel":
			_check(not room.get_node("GardenArbor").visible,"Giant flat arbor still covers painted garden")
			for child in room.get_node("CityDistrictDetails/CelestialGardenDetails").get_children():
				if String(child.name).begins_with("Plant") or String(child.name).begins_with("GardenBed"): _check(not child.visible,"Primitive garden still visible")
		if id not in ["ash_hearth","starfall_citadel"]: continue
		var office := room.get_node("EasternDistricts/FieldOffice" if id=="ash_hearth" else "FieldOffice")
		_check(not office.table.is_visible_in_tree(),"Giant field table covers gameplay")
		var source := office.get_node("ReadingSource")
		_check(source.modulate.a==0 and source.is_visible_in_tree(),"Hidden-source report unavailable")
		var index := -1
		for i in reader.entries.size():
			if reader.entries[i].text==source: index = i
		_check(index>=0,"Missing field report readable")
		if index<0: continue
		player.global_position = reader.entries[index].at
		var before: Dictionary = state.unlocked_shortcuts.duplicate(true)
		var gold: int = state.gold
		reader.open_nearest()
		for frame in 8: await process_frame
		_check(root.get_visible_rect().encloses(reader.panel.get_rect()),"Report overflow after asynchronous container layout")
		_check(reader.is_open() and reader.current==index and paused,"Field report cannot open nearby")
		_check(reader.body.text.contains("TASKS 0/7") and reader.body.text.contains("Guard:"),"Missing field summary/rows")
		reader.close()
		_check(not paused and state.gold==gold and state.unlocked_shortcuts==before,"Reading spends/awards progress")
		var event := "ash_causeway_field_complete" if id=="ash_hearth" else "starfall_outskirts_field_complete"
		state.unlock_shortcut(event)
		reader.open_nearest()
		reader._refresh_text()
		_check(reader.body.text.contains("TASKS 1/7"),"Live report is stale")
		for dimensions in [Vector2i(1280,720),Vector2i(360,640)]:
			root.size = dimensions
			root.content_scale_size = dimensions
			await process_frame
			reader._layout()
			await process_frame
			_check(root.get_visible_rect().encloses(reader.panel.get_rect()),"Field report exceeds viewport")
		reader.close()
		var count: int = reader.entries.size()
		finish.finish_room(id)
		_check(reader.entries.size()==count,"Duplicate field report on revisit")
		player.global_position += Vector2(10000,0)
		reader.open_nearest()
		_check(not reader.is_open(),"Field report opens across map")
	_check(masks>60,"Expansion masks not covered")
	game.queue_free()
	await process_frame
	state.delete_save()
	print("SETTLEMENT READING OCCLUSION TEST PASSED" if failures.is_empty() else "TEST FAILED: "+str(failures))
	print("RETIRED SETTLEMENT MASKS ",masks)
	quit(0 if failures.is_empty() else 1)
