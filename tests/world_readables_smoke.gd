extends "res://tests/boss_combat_presentation_smoke.gd"
const Layout = preload("res://WorldLayout.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_readables.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var reader: CanvasLayer = finish.reader
	reader.set_process(false)
	var player := game.get_node("Player")
	var visited := {}
	var notices := 0
	var encounter_reports := 0
	var city_notices := 0
	var haven_notices := 0
	var gate_notices := 0
	var route_notices := 0
	var ids: Array = ["training_passage"]
	ids.append_array(Layout.ROOM_NODES.keys())
	for id in ids:
		var room: Node2D = game if id == "training_passage" else game.get_node(Layout.ROOM_NODES[id])
		if visited.has(room.get_instance_id()): continue
		visited[room.get_instance_id()] = true
		state.set_current_room(id)
		await process_frame
		await process_frame
		finish.finish_room(id)
		notices += reader.entries.size()
		for entry in reader.entries:
			_check(entry.text.modulate.a == 0 and entry.text.has_meta("world_readable"), "Large source text remains visible: " + str(entry.text.get_path()))
		for node in finish._members(room):
			if node.get_script()==preload("res://LocalizedEncounter.gd") and node.status_label!=null:
				encounter_reports += 1
				_check(reader.entries.any(func(entry): return entry.text==node.status_label),"Unregistered nested encounter report: "+str(node.get_path()))
			if node is Label and reader._is_city_notice(node):
				city_notices += 1
				_check(node.modulate.a==0 and node.has_meta("world_readable"),"City sign still covers facade")
			if node is Label and reader._is_haven_notice(node):
				haven_notices+=1
				_check(node.modulate.a==0 and reader.entries.any(func(entry):return entry.text==node),"Haven gate/quarter notice lost")
			if node is Label and (reader._is_gate_notice(node) or reader._is_route_notice(node)):
				if reader._is_gate_notice(node): gate_notices+=1
				else: route_notices+=1
				_check(node.modulate.a==0 and reader.entries.any(func(entry):return entry.text==node),"Guardhouse/depth notice missing")
		var count: int = reader.entries.size()
		finish.finish_room(id)
		_check(reader.entries.size() == count, "Repeated room entry lost/duplicated notices")
	state.set_current_room("shaft_drift")
	await process_frame
	await process_frame
	finish.finish_room("shaft_drift")
	var flywheel := -1
	for i in range(reader.entries.size()):
		if reader._title(reader.entries[i]) == "THE CROWN FLYWHEEL": flywheel = i
	_check(flywheel >= 0, "Screenshot's flywheel clue missing")
	if flywheel >= 0:
		var entry: Dictionary = reader.entries[flywheel]
		player.global_position = entry.at
		reader._refresh_nearest()
		_check(reader.nearest == flywheel and reader.prompt.visible and reader.marker.visible, "Nearby clue has no prompt")
		var before: Dictionary = state.unlocked_shortcuts.duplicate(true)
		reader.open_nearest()
		_check(reader.is_open() and paused and game.get_node("UI")._hud_menu_blocked(), "Reading fails to own modal pause")
		_check(reader.body.text.contains("BOTH PUMPS") and reader.heading.text == "THE CROWN FLYWHEEL", "Unreadable/truncated source content")
		var source_text: String = entry.text.text
		entry.text.text = "Test update: restored pressure."
		reader._refresh_text()
		_check(reader.body.text == entry.text.text, "Open notice shows stale progress")
		entry.text.text = source_text
		reader._refresh_text()
		for dimensions in [Vector2i(960, 540), Vector2i(640, 360), Vector2i(360, 640)]:
			root.size = dimensions
			root.content_scale_size = dimensions
			await process_frame
			reader._layout()
			await process_frame
			_check(root.get_visible_rect().encloses(reader.panel.get_rect()), "Reading panel exceeds viewport: " + str(dimensions))
			_check(reader.body.size.x <= reader.panel.size.x, "Notice text overflows horizontally")
		var cancel := InputEventAction.new()
		cancel.action = "ui_cancel"
		cancel.pressed = true
		reader._input(cancel)
		_check(not paused and not reader.is_open() and state.unlocked_shortcuts == before, "Close failed or reading changed quest state")
		paused = true
		reader.close()
		_check(paused, "Reader unpaused a modal it does not own")
		paused = false
		player.global_position += Vector2(10000, 0)
		reader.open_nearest()
		_check(not reader.is_open() and not reader.prompt.visible, "Distant notice still opens")
		player.global_position = entry.at
		player.is_dead = true
		reader.open_nearest()
		_check(not reader.is_open(), "Dead player opens reading panel")
		player.is_dead = false
	_check(notices > 100 and visited.size() == 39, "Incomplete world notice coverage")
	_check(encounter_reports>=20 and city_notices==11,"Nested encounter / upper city notice coverage incomplete")
	_check(haven_notices==13,"Missing Haven/approach notices: "+str(haven_notices))
	_check(gate_notices==5 and route_notices>=30,"Missing gate/route wayfinding")
	print("GATE / DEPTH NOTICES ",gate_notices," / ",route_notices," total=",notices)
	var haven_road: Node2D=game.get_node("EchoHavenOutskirts")
	var road_nodes: Array[Node]=finish._members(haven_road)
	var ward_notice: Label=haven_road.get_node("GateApproach/WardLabel")
	var ward_anchor: Vector2=reader._supported_anchor(ward_notice,road_nodes)
	for door in [haven_road.get_node("GateDoor"),haven_road.get_node("GateApproach/ApproachReturnDoor")]:
		_check(absf(ward_anchor.x+42-door.global_position.x)>=44,"Reading sign covers ward doorway")
	state.set_current_room("starfall_soul_crucible")
	for i in 3: await process_frame
	finish.finish_room("starfall_soul_crucible")
	var trial: Node
	var trial_entry := -1
	for i in reader.entries.size():
		var parent: Node = reader.entries[i].text.get_parent()
		if parent.get_script()==preload("res://LocalizedEncounter.gd") and str(parent.name)=="Containment0":
			trial=parent
			trial_entry=i
	_check(trial_entry>=0,"Missing screenshot containment report")
	if trial_entry>=0:
		player.global_position=reader.entries[trial_entry].at
		reader.open_nearest()
		_check(reader.current==trial_entry and reader.body.text.contains("CHANNEL FIRST"),"Containment report is not readable nearby")
		trial.triggered=true
		trial.required_event_ids=PackedStringArray()
		trial.remaining_foes={0:true,1:true}
		trial._refresh_status()
		reader._refresh_text()
		_check(reader.body.text.contains("GUARDIANS REMAINING: 2"),"Encounter report does not refresh while reading")
		reader.close()
		_check(not paused,"Encounter reader leaked pause")
	print("NESTED REPORT COVERAGE ",encounter_reports," encounters, ",city_notices," city notices")
	# Simulate streamed authoring nodes being replaced under the same room id.
	var temporary := Node2D.new()
	game.add_child(temporary)
	for generation in range(2):
		var source := Label.new()
		source.name = "RouteClue"
		source.text = "STREAMED NOTICE\nGeneration %d" % generation
		temporary.add_child(source)
		reader.register_room("test_stream", [source])
		_check(reader.entries.size() == 1 and reader.entries[0].text == source, "Streamed reentry retained stale notice")
		source.queue_free()
		await process_frame
	temporary.queue_free()
	print("READABLE COVERAGE: ", visited.size(), " rooms, ", notices, " notices")
	game.queue_free()
	await process_frame
	state.delete_save()
	print("WORLD READABLES TEST PASSED" if failures.is_empty() else "TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
