extends "res://tests/starfall_task_art_smoke.gd"
const Atlas := preload("res://StarfallTaskAtlas.gd")
const Task := preload("res://StarfallTaskArt.gd")
const Support := preload("res://WorldSupport.gd")

func _foot(art: Node2D) -> Vector2:
	var sprite: Sprite2D = art.painted
	return sprite.to_global(Vector2(0,sprite.offset.y-sprite.texture.get_height()/2+float(sprite.get_meta("contact_row"))))

func _check_art(art: Node2D) -> void:
	_check(art.support.has_area(),"Unsupported task prop: "+str(art.get_path()))
	_check(absf(_foot(art).y-art.support.position.y)<.01,"Task foot floats: "+str(art.get_path()))
	_check(not art.is_processing() and not art.is_physics_processing(),"Per-prop callbacks added")
	_check(art.painted.texture is AtlasTexture,"Task did not use its painted atlas")
	_check(is_equal_approx(art.painted.scale.x,art.painted.scale.y),"Nonuniform task distortion")
	_check(art.painted_bounds().size.x<=90.1 and art.painted_bounds().size.y<=60.1,"Oversized task marker")
	for retired in art.retired: _check(not retired.visible,"Old task sketch returned")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_painted_tasks_save.json"; state.start_new_game("normal")
	for key in Atlas.DATA:
		var tex := Atlas.texture(key)
		_check(tex==Atlas.texture(key),"Repeated task crops allocate a new texture")
		_check(tex.atlas.get_width()<=1024 and tex.atlas.get_image().has_mipmaps(),"Task texture exceeds import budget/missing mipmaps")
		_check(Rect2(Vector2.ZERO,tex.atlas.get_size()).encloses(tex.region),"Task crop outside sheet")
	var game: Node2D = load("res://Game.tscn").instantiate(); root.add_child(game); current_scene = game
	for tick in 4: await process_frame
	game.get_node("UI").story_player.cancel(); paused = false
	var player: Player = game.get_node("Player"); player.set_physics_process(false)
	var finish := game.get_node("WorldPresentationFinish")
	var registers := 0; var controls := 0; var landmarks := 0
	for room_name in preload("res://StarfallRouteDressing.gd").PROFILES:
		var id: String = preload("res://StarfallRouteDressing.gd").PROFILES[room_name][0]
		state.set_current_room(id)
		for tick in 3: await process_frame
		finish.finish_room(id)
		var room := game.get_node(NodePath(room_name)); room.process_mode = Node.PROCESS_MODE_DISABLED
		var dressing := room.get_node("FieldDressing" if room_name=="StarfallRamparts" else "ExpandedRoute/FieldDressing")
		var register := dressing.get_node("Site1/TaskArt")
		_check_art(register); registers += 1
		var natural := room.get_node_or_null("NaturalContours")
		if natural!=null:
			for mound in natural.mounds:
				_check(not register.painted_bounds().intersects(mound.get_meta("natural_mound_bounds")),"Terrain buries the ledger feet")
		_check(register.captions.size()==register.states.size(),"Lost task captions")
		_check(register.reading_report().contains("PENDING"),"New register claims completion")
		for label in register.captions:
			_check(label.size.x<=30 and label.get_theme_font_size("font_size")==6,"Oversized ledger caption")
		var native := _physics_snapshot(room)
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		var count: int = room.find_children("*","",true,false).size()
		finish.finish_room(id)
		_check(_physics_snapshot(room)==native and state.unlocked_shortcuts==flags,"Reentry changes physics/task progress")
		_check(room.find_children("*","",true,false).size()==count,"Reentry duplicates painted props")
		var report := {}
		for entry in finish.reader.entries:
			if entry.get("physical_board")==register: report = entry
		_check(not report.is_empty(),"Painted ledger has no G reading entry")
		if not report.is_empty():
			player.global_position = register.to_global(Vector2(-32,register.foot_y-24))
			finish.reader._refresh_nearest()
			_check(finish.reader.nearest>=0 and finish.reader.entries[finish.reader.nearest].get("physical_board")==register,"Ledger chooses another notice")
			_check(not finish.reader.marker_art.visible,"Duplicate sign overlays painted ledger")
			finish.reader.open_nearest()
			_check(finish.reader.is_open() and finish.reader.body.text.contains("PENDING"),"Ledger G panel lost live task details")
			var displayed: String = finish.reader.body.text
			var source_text: String = report.text.text
			for tick in 15: finish.reader._refresh_text()
			_check(finish.reader.body.text==displayed and report.text.text==source_text,"Reading recursively appends status to the authoritative clue")
			state.unlock_shortcut(dressing._events()[0]); await process_frame
			finish.reader._refresh_text()
			_check(finish.reader.body.text.contains("RECORDED"),"Open ledger does not refresh progress")
			finish.reader.close()
		var ops := room.get_node_or_null("ExpandedRoute/StarfallDescent/FieldOperations")
		if ops==null: continue
		for station in ops.controls:
			var art: Node2D = station.get_node("TaskArt")
			_check_art(art); controls += 1
			var body_bounds: Rect2 = art.painted.global_transform*art.painted.get_rect()
			for ceiling in Support.floors(finish._members(room)):
				if ceiling.end.y<art.support.position.y-4:
					_check(not ceiling.intersects(body_bounds),"Task penetrates upper platform: "+str(art.get_path()))
			_check(not station.has_node("DeviceArt"),"Generic receiver overlaps specialized task prop")
			var original: Vector2 = station.global_position
			var foot := _foot(art)
			var before: Dictionary = state.unlocked_shortcuts.duplicate(true)
			art.animate(1.7); art.rest()
			_check(before==state.unlocked_shortcuts,"Ambient motion awards task progress")
			for event_id in station.required_event_ids: state.unlock_shortcut(event_id)
			state.unlock_shortcut(station.shortcut_id)
			for tick in 2: await process_frame
			_check(station.is_active and art.states==["done"],"Native completion lost")
			_check(station.global_position==original and _foot(art).distance_to(foot)<.01,"Task activation moves station/foot")
			body_bounds = art.painted.global_transform*art.painted.get_rect()
			for ceiling in Support.floors(finish._members(room)):
				if ceiling.end.y<art.support.position.y-4:
					_check(not ceiling.intersects(body_bounds),"Completed task penetrates upper platform: "+str(art.get_path()))
			_check(station.get_node("CollisionShape2D").shape.radius==34,"Art changes activation reach")
			_check(station.get_node("InteractionPrompt").position.y<art.foot_y-50,"Prompt buried in floor")
			if art.kind in ["seedbed","beacon"]: _check(str(art.painted.get_meta("task_frame")).ends_with("_done"),"No completed raster variant")
			if art.glow!=null:
				art.animate(1); var tint: Color = art.glow.modulate
				art.animate(1.1); _check(art.glow.visible and tint!=art.glow.modulate,"Active beacon has no light motion")
		for index in range(ops.landmarks.size()):
			var art := ops.get_node("LandmarkArt%d" % index); _check_art(art); landmarks += 1
			if art.kind=="growth":
				var foot := _foot(art)
				_check(art.brush(.3),"First plant brush is not fresh")
				for tick in 8: art.advance_response(1.0/60)
				_check(absf(art.painted.skew)>.01 and _foot(art).distance_to(foot)<.01,"Plant fails to bend around rooted contact")
				for tick in 240: art.advance_response(1.0/60)
				_check(is_zero_approx(art.response.bend),"Plant spring never settles")
			if art.glow!=null: _check(art.glow.visible,"Restored lantern remains unlit")
		for event_id in dressing._events(): state.unlock_shortcut(event_id)
		await process_frame
		_check(register.states.all(func(value): return value=="done"),"Ledger omitted a finished objective")
	_check(registers==7 and controls==9 and landmarks==5,"Incomplete painted task coverage")
	game.free(); state.delete_save()
	if failures.is_empty():
		print("PAINTED TASKS TEST PASSED: 18 atlas cutouts; 7 registers, 9 stations, 5 landmarks; grounded states, no duplicate device, live G report, bounded glow and rooted response; physics/flags/reentry preserved")
		quit(0)
	else: quit(1)
