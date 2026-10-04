extends "res://tests/gameplay_review_smoke.gd"
const Motion := preload("res://ResidentMotion.gd")
const Paint := preload("res://ResidentPaintedArt.gd")
const Machine := preload("res://IndustrialLandmarkArt.gd")
const Support := preload("res://WorldSupport.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_resident_painted_art.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var identities := {}
	var residents := 0
	var fixtures := 0
	var visited := {}
	for id in ["training_passage"] + Layout.ROOM_NODES.keys():
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		if visited.has(room.get_instance_id()): continue
		visited[room.get_instance_id()] = true
		state.set_current_room(id)
		await process_frame
		await process_frame
		finish.finish_room(id)
		var nodes: Array[Node] = finish._members(room)
		var before := _collision_snapshot(nodes)
		for node in nodes:
			if node.has_meta("industrial_sketch_retired"): _check(not node.visible,"Bright industrial sketch returned")
			if node is Label and node.name in ["AreaSubtitle","RouteIdentity"]: _check(node.has_meta("world_readable") and node.modulate.a==0,"Ambient title bypasses reader")
			if node is Motion and node.is_visible_in_tree():
				residents += 1
				var actor: Node2D = node.get_parent()
				var art: Sprite2D = node.painted
				identities[Vector2i(art.family, art.role)] = true
				var floor_rect := Support.below(actor.global_position,node.surfaces,64)
				_check(floor_rect.has_area(), "No real support below resident: " + str(actor.get_path()))
				_check(not actor.get_node("Coat").visible and not actor.get_node("Face").visible and not actor.get_node("Accent").visible, "Primitive resident body remains")
				var at: Vector2 = actor.position
				var label_at: Vector2 = actor.get_node("NameLabel").position
				for direction in [-1.0,1.0]:
					for pose in 4:
						art.show_pose(pose,direction,node.foot_y,1.7)
						var boot := art.to_global(Vector2(0, -art.texture.get_height()*0.5+art.contact_row))
						_check(absf(boot.y-floor_rect.position.y) < 0.05, "Unplanted NPC pose: " + str(actor.get_path()))
						_check(art.texture is AtlasTexture and art.frames.size()==4 and art.flip_h==(direction<0), "Pose/facing art registration")
						_check(absf(art.scale.x-art.scale.y)<0.001 and art.texture.get_height()*art.scale.y<33, "Resident stretched/oversized")
				_check(actor.position==at and actor.get_node("NameLabel").position==label_at, "Visual changes native root/label")
				_check(not art.is_processing(), "Per-sprite frame callback added")
				node._update_paint()
			if node is Machine:
				fixtures += 1
				_check(node.has_meta("contact_floor"), "Industrial fixture lacks floor attachment: "+str(node.get_path()))
				if not node.has_meta("contact_floor"): continue
				var index := 0 if node.kind=="fan_model" else (2 if node.kind=="armour_rack" else 3)
				var row: float = Machine.CONTACTS[index] * Machine.SHEET.get_height()/1254.0
				var boot: Vector2 = node.body.to_global(Vector2(0,-node.body.texture.get_height()*0.5+row))
				_check(absf(boot.y-float(node.get_meta("contact_floor")))<0.05, "Industrial fixture floats")
				var supported: Rect2 = node.get_meta("support_rect")
				_check(boot.x>=supported.position.x and boot.x<=supported.end.x,"Industrial fixture sits outside its floor")
				for old in node.retired: _check(not old.visible,"Industrial sketch remains")
				_check(not node.is_processing() and node.find_children("*","CollisionObject2D",true,false).is_empty(),"Decorative machine has new physics/process")
				if node.kind=="fan_model":
					node.animate(2)
					_check(not node.enabled and node.rotor.rotation==0, "Offline fan moves")
					state.unlock_shortcut("ash_forge_fan")
					node.animate(3)
					_check(node.enabled and node.rotor.rotation!=0, "Native fan flag does not animate rotor")
					_check(finish.ambience.candidates.has(node), "Fan outside shared animation budget")
		finish.finish_room(id)
		_check(_collision_snapshot(finish._members(room))==before, "Art pass altered native physics: "+id)
	# Live population after a room has already been finished must be registered.
	state.set_current_room("echo_haven")
	await process_frame
	await process_frame
	var haven := game.get_node("EchoHaven")
	var resident: Node2D = load("res://TownResident.tscn").instantiate()
	resident.position = haven.get_node("Neris").position
	haven.add_child(resident)
	resident.set_process(false)
	for frame in range(4): await process_frame
	_check(not resident.get_node("ResidentMotion").surfaces.is_empty(),"Late resident contact not registered")
	_check(finish.focused_labels.has(resident.get_node("NameLabel")),"Late resident label bypassed proximity focus")
	var bytes := 0
	for sheet in Paint.SHEETS + [Machine.SHEET]:
		var pixels: Image = sheet.get_image()
		bytes += pixels.get_data_size()
		_check(sheet.get_width()<=1024 and pixels.has_mipmaps() and pixels.get_pixel(0,0).a<0.01,"Atlas alpha/mipmap/import bound")
	_check(bytes<17*1024*1024 and residents>=30 and identities.size()==6 and fixtures==18,"Missing artwork coverage or resource budget")
	print("PAINTED RESIDENT COVERAGE ",residents," actors, ",identities.size()," identities, ",fixtures," fixtures, ",visited.size()," rooms, ",bytes," decoded bytes")
	game.queue_free()
	await process_frame
	# Standalone town F6 also resolves the real floor without the world director.
	var town: Node2D = load("res://EchoHaven.tscn").instantiate()
	root.add_child(town)
	for frame in range(3): await process_frame
	var standalone := town.get_node("Neris/ResidentMotion")
	_check(not standalone.surfaces.is_empty(),"Standalone town has no ground survey")
	town.queue_free()
	await process_frame
	state.delete_save()
	print("RESIDENT PAINTED ART TEST PASSED" if failures.is_empty() else "RESIDENT PAINTED ART TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
