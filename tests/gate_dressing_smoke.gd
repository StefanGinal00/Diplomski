extends "res://tests/visual_style_slice_smoke.gd"
const Gates := preload("res://GateDressingAtlas.gd")
const GateArt := preload("res://ApproachGateArt.gd")
const Support := preload("res://WorldSupport.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path="res://_tmp_gate_dressing.json"
	state.start_new_game("normal")
	var bytes := 0
	for sheet in Gates.SHEETS.size():
		var picture: Image=Gates.SHEETS[sheet].get_image()
		bytes+=picture.get_data_size()
		_check(picture.has_mipmaps() and picture.get_pixel(0,0).a<0.01,"Atlas lost alpha or mipmaps")
		_check(Gates.SHEETS[sheet].get_width()<=1024,"Oversized runtime sheet")
		if sheet<3: _check(picture.get_pixel(512,466).a<0.01,"Arch hole is opaque")
		for frame in Gates.CROPS[sheet].size():
			var texture:=Gates.texture_for(sheet,frame)
			_check(texture==Gates.texture_for(sheet,frame) and texture.filter_clip,"Uncached atlas")
			_check(Rect2(Vector2.ZERO,Gates.SHEETS[sheet].get_size()).encloses(texture.region),"Crop outside image")
	_check(bytes<19*1024*1024,"Gate sheet decoded budget exceeded")
	for named in ["EchoHaven","EchoHavenOutskirts"]:
		var room: Node2D=load("res://%s.tscn"%named).instantiate()
		var ambience:=room.get_node("SettlementAtmosphere")
		ambience.owner=null; room.remove_child(ambience)
		room.position=Vector2(12000,-3500)
		root.add_child(room)
		for frame in 3: await process_frame
		room.process_mode=Node.PROCESS_MODE_DISABLED
		var before:=_physics_snapshot(room)
		var nodes: Array[Node]=[]
		nodes.assign(room.find_children("*","",true,false))
		var floors:=Support.floors(nodes)
		var art:=GateArt.install(room,floors)
		_check(art.built and not art.is_processing(),"Unbuilt/processing gate art")
		_check(_physics_snapshot(room)==before,"Gate changed gameplay geometry")
		for old in art.retired: _check(not old.visible,"Old gate remains visible")
		for piece in art.pieces:
			_check(is_equal_approx(piece.scale.x,piece.scale.y),"Distorted gate piece")
			var support: Rect2=piece.get_meta("support_rect")
			var contact: Vector2=piece.to_global(Vector2(0,-piece.texture.get_height()*0.5+float(piece.get_meta("contact_row"))))
			_check(absf(contact.y-support.position.y)<0.01,"Gate floats")
			print("GATE PIECE ",named," ",piece.name," foot=",room.to_local(contact)," size=",piece.texture.get_size()*piece.scale)
		var route:=room.get_node("GateApproach" if named=="EchoHavenOutskirts" else "NewDistricts")
		_check(art.pieces.size()==(5 if named=="EchoHavenOutskirts" else 6),"Missing gate compositions")
		for original in ["QuarterGateTowerL","QuarterGateTowerR","QuarterGateArch"]: _check(not route.get_node(original).visible,"Original lower gate remains")
		if named=="EchoHavenOutskirts":
			_check(art.plants.size()>=20 and art.plants.size()<=30,"Ward vegetation coverage/budget")
			for plant in art.plants:
				_check(not plant.is_processing() and plant.has_meta("ambient_motion"),"Unbudgeted plant motion")
				var plant_foot: Vector2=plant.art.to_global(Vector2(0,-plant.art.texture.get_height()*0.5+preload("res://AmbientSetpiece.gd").CONTACT[0][1]*plant.art.texture.atlas.get_height()/1024.0))
				_check(absf(plant_foot.y-plant.support.position.y)<0.01,"Plant floats")
			for old in route.get_children():
				if old is Polygon2D and String(old.name).begins_with("Garden"): _check(not old.visible,"Ward garden wedge survived")
			print("WARD VEGETATION ",art.plants.size()," supported plants")
			for original in ["GrandGateLeft","GrandGateRight","GrandGateLintel"]: _check(not route.get_node(original).visible,"Original ward gate remains")
			var door:=room.get_node("GateDoor") as Node2D
			print("WARD FLOOR ",room.to_local(door.global_position)," ",Support.below(door.global_position,floors))
			for floor_rect in floors:
				if absf(floor_rect.position.y-room.to_global(Vector2(0,-941)).y)<30 and floor_rect.end.x>room.to_global(Vector2(3200,0)).x: print("WARD NEARBY ",floor_rect)
		_check(GateArt.install(room,floors)==art,"Reentry duplicated gates")
		room.add_child(ambience)
		for frame in 2: await process_frame
		room.queue_free(); await process_frame
	state.delete_save()
	print("GATE DRESSING TEST PASSED; decoded bytes=",bytes) if failures.is_empty() else print("GATE TEST FAILED ",failures)
	quit(0 if failures.is_empty() else 1)
