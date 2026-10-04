extends "res://tests/gameplay_review_smoke.gd"
const Support := preload("res://WorldSupport.gd")

class FirstVisitFinish extends "res://WorldPresentationFinish.gd":
	var first_visit_checks := {}
	func finish_room(id: String) -> void:
		var already_finished := finished.has(id)
		super.finish_room(id)
		if already_finished or not finished.has(id): return
		# Inspect synchronously when the FIRST finish returns. Waiting another
		# frame or manually finishing again can mask a stale pre-vault anchor.
		var room := get_parent() if id=="training_passage" else get_parent().get_node(str(Layout.ROOM_NODES[id]))
		var nodes := _members(room)
		var stale: Array[String] = []
		for entry in reader.entries:
			if is_instance_valid(entry.get("physical_board")): continue
			var fit: Dictionary = reader._fit_near_sign(entry.sign_hint,nodes)
			if entry.sign_supported==fit.is_empty() or not entry.at.is_equal_approx(fit.get("at",entry.sign_hint)):
				stale.append(str(entry.text.get_path()))
		first_visit_checks[id] = stale

func _solid(parent: Node2D,title: String,at: Vector2,size: Vector2) -> CollisionShape2D:
	var body := StaticBody2D.new(); body.name=title; parent.add_child(body); body.position=at
	var shape := CollisionShape2D.new(); shape.shape=RectangleShape2D.new(); shape.shape.size=size
	body.add_child(shape); return shape

func _bounds(reader: CanvasLayer,entry: Dictionary) -> Rect2:
	return Rect2(entry.at+reader.sign_relative_bounds.position,reader.sign_relative_bounds.size)

func _check_footprint(reader: CanvasLayer,entry: Dictionary,nodes: Array[Node],context: String) -> void:
	_check(entry.sign_supported,"No supported pedestal: "+context)
	if not entry.sign_supported: return
	var support: Rect2 = entry.sign_support
	var bounds := _bounds(reader,entry)
	_check(support in reader._sign_supports(nodes),"Support disappeared: "+context)
	_check(bounds.position.x>=support.position.x+.9 and bounds.end.x<=support.end.x-.9,"Painted sign overhangs landing: "+context)
	_check(absf(bounds.end.y-support.position.y-.15)<.01,"Painted pedestal does not touch ground: "+context)
	var exposed := bounds; exposed.size.y=maxf(0,support.position.y-.25-bounds.position.y)
	for solid in Support.solids(nodes): _check(not exposed.intersects(solid),"Painted sign intersects terrain: "+context)
	for node in nodes:
		if (node is LevelExit or node.is_in_group("room_door")) and absf(node.global_position.y-support.position.y)<85:
			var art := node.get_node_or_null("FinishedDevice") as Sprite2D
			_check(absf(bounds.get_center().x-(art.global_position.x if art!=null else node.global_position.x))>=44,"Painted sign covers door: "+context)

func _fixtures(reader: CanvasLayer,player: Node2D) -> void:
	var stage := Node2D.new(); root.add_child(stage); stage.position=Vector2(-2300,700); stage.scale=Vector2(1.5,1.3)
	var narrow := _solid(stage,"NarrowLanding",Vector2(100,100),Vector2(28,10))
	var notice := Label.new(); notice.name="RoomSignFixture"; notice.text="SMALL LANDING"; stage.add_child(notice)
	notice.position=Vector2(100,45)
	var nodes: Array[Node]=[narrow,notice]
	var snapshot := _collision_snapshot(nodes)
	reader.register_room("sign_fixture",nodes)
	_check(reader.entries.size()==1,"Fixture notice not registered")
	_check_footprint(reader,reader.entries[0],nodes,"no-door scaled narrow landing")
	var initial_at: Vector2=reader.entries[0].at
	reader.register_room("sign_fixture",nodes)
	_check(reader.entries.size()==1 and reader.entries[0].at.is_equal_approx(initial_at),"Stable reentry moves/duplicates readable")
	narrow.disabled=true
	reader.register_room("sign_fixture",nodes)
	_check(not reader.entries[0].sign_supported and reader.entries[0].at.is_equal_approx(initial_at),"Removed support moves clue to unrelated route")
	player.global_position=reader.entries[0].at; reader._refresh_nearest()
	_check(reader.nearest==0 and reader.prompt.visible and not reader.marker_art.visible,"Unsupported clue loses reading or keeps floating pedestal")
	reader.open_nearest()
	_check(reader.is_open(),"Unsupported clue can no longer be read")
	reader.close()
	narrow.disabled=false; reader.register_room("sign_fixture",nodes)
	_check_footprint(reader,reader.entries[0],nodes,"restored support")
	player.global_position=reader.entries[0].at; reader._refresh_nearest()
	_check(reader.marker_art.visible,"Restoring real support does not restore pedestal")
	# A new roof that cuts through the sign cannot move the reading location
	# to the distant lower floor. Keep only the cue until the roof clears.
	var roof := _solid(stage,"Ceiling",Vector2(100,80),Vector2(90,10)); nodes.append(roof)
	var lower := _solid(stage,"UnrelatedLowerFloor",Vector2(100,220),Vector2(300,10)); nodes.append(lower)
	reader.register_room("sign_fixture",nodes)
	_check(not reader.entries[0].sign_supported and reader.entries[0].at.is_equal_approx(initial_at),"Blocked footprint jumps to another tier")
	roof.disabled=true; reader.register_room("sign_fixture",nodes)
	_check_footprint(reader,reader.entries[0],nodes,"removed ceiling")
	_check(_collision_snapshot([narrow,notice])==snapshot,"Sign fitting changes native collision")
	stage.free()
	var street := Node2D.new(); root.add_child(street); street.position=Vector2(2300,700)
	var floor_shape := _solid(street,"Street",Vector2(180,110),Vector2(360,16))
	var title := Label.new(); title.name="RoomSignDoor"; title.text="GATE"; street.add_child(title); title.position=Vector2(120,65)
	var door := Node2D.new(); street.add_child(door); door.position=Vector2(180,102); door.add_to_group("room_door")
	var street_nodes: Array[Node]=[floor_shape,title,door]
	reader.register_room("door_fixture",street_nodes)
	_check_footprint(reader,reader.entries[0],street_nodes,"door-present street")
	street.free()

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_readable_support_footprint.json"; state.start_new_game("normal")
	var game: Node2D=load("res://Game.tscn").instantiate()
	game.get_node("WorldPresentationFinish").set_script(FirstVisitFinish)
	root.add_child(game); current_scene=game
	for tick in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused=false
	game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var reader: CanvasLayer=finish.reader; reader.set_process(false)
	var totals := {"rooms":0,"entries":0,"pedestals":0,"supported":0,"fallback":0,"gallery_depth5":0,"hearth_report":0}
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for tick in 3: await process_frame
		_check(finish.first_visit_checks.has(id),"Native first-visit finish never ran: "+id)
		_check(finish.first_visit_checks.get(id,[]).is_empty(),"First-visit readables use stale geometry: "+id+" "+str(finish.first_visit_checks.get(id,[])))
		var room: Node2D=game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node]=finish._members(room)
		var before := _collision_snapshot(nodes)
		var signature: Array[Vector2]=[]
		for entry in reader.entries:
			totals.entries+=1; signature.append(entry.at)
			if is_instance_valid(entry.get("physical_board")): continue
			totals.pedestals+=1
			if entry.sign_supported:
				totals.supported+=1; _check_footprint(reader,entry,nodes,id+":"+str(entry.text.name))
			else:
				totals.fallback+=1
				_check(entry.at==entry.sign_hint,"Unsupported notice moves away from reading anchor")
				print("READABLE_FALLBACK ",id," ",entry.text.get_path()," ",entry.text.text.get_slice("\n",0))
			if id=="shaft_gallery" and entry.text.name==&"DepthMarker3":
				totals.gallery_depth5+=1; _check_footprint(reader,entry,nodes,"screenshot Gallery DEPTH 5")
			if id=="ash_hearth" and entry.text.name==&"ReadingSource":
				totals.hearth_report+=1; _check_footprint(reader,entry,nodes,"provider's formerly raised pedestal")
		finish.finish_room(id)
		_check(reader.entries.size()==signature.size(),"Reentry lost/duplicated notices: "+id)
		for index in reader.entries.size(): _check(reader.entries[index].at.is_equal_approx(signature[index]),"Reentry drifted sign: "+id)
		_check(_collision_snapshot(finish._members(room))==before,"Readables alter physical room: "+id)
		totals.rooms+=1
	_check(totals.entries==596 and totals.gallery_depth5==1 and totals.hearth_report==1,"Lost world-readable coverage")
	_check(finish.first_visit_checks.size()==39,"First-visit regression did not cover every room")
	_fixtures(reader,game.get_node("Player"))
	print("READABLE_SUPPORT_COUNTS ",JSON.stringify(totals))
	game.free(); state.delete_save()
	print("READABLE SUPPORT FOOTPRINT TEST PASSED" if failures.is_empty() else "READABLE SUPPORT FOOTPRINT TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
