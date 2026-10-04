extends "res://tests/visual_style_slice_smoke.gd"
const Art := preload("res://FacadeReliefAtlas.gd")
const Relief := preload("res://SettlementFacadeRelief.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_facade_context.json"
	state.start_new_game("normal")
	var windows := 0
	var detail_count := 0
	var pier_count := 0
	var bytes := 0
	var sources := {}
	var used := {}
	for sheet in 2:
		var image: Image = Art.SHEETS[sheet].get_image()
		bytes += image.get_data_size()
		_check(image.has_mipmaps() and image.get_width() <= 1024, "Relief texture budget/mipmaps")
		_check(image.get_pixel(0,0).a < 0.01, "Relief opaque background")
		for index in 6:
			var texture := Art.texture_for(sheet,index)
			_check(texture == Art.texture_for(sheet,index) and texture.filter_clip, "Relief regions not cached/clipped")
			_check(Rect2(Vector2.ZERO,Art.SHEETS[sheet].get_size()).encloses(texture.region), "Relief crop outside source")
			var digest := HashingContext.new()
			digest.start(HashingContext.HASH_SHA256)
			digest.update(texture.get_image().get_data())
			sources[digest.finish().hex_encode()] = true
	_check(sources.size() == 12 and bytes < 8*1024*1024, "Twelve distinct cutouts exceed 8MiB import budget")
	for named in ["EchoHaven", "EchoHavenOutskirts", "CinderHearth"]:
		var room: Node2D = load("res://%s.tscn" % named).instantiate()
		room.position = Vector2(13000, -6000)
		root.add_child(room)
		for frame in 5: await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var painter := room.get_node("PaintedBuildings")
		for entry in painter.window_art:
			windows += 1
			_check(entry.home != null, "Window has no owning facade: " + named + " " + str(entry.preferred))
			if entry.home == null: continue
			for corner in [entry.rect.position, Vector2(entry.rect.end.x, entry.rect.position.y), entry.rect.end, Vector2(entry.rect.position.x, entry.rect.end.y)]:
				_check(Geometry2D.is_point_in_polygon(entry.home.to_local(painter.to_global(corner)), entry.home.polygon), "Window moved outside its house")
		var relief := painter.get_node("FacadeRelief")
		_check(relief.built and not relief.is_processing() and not relief.is_physics_processing(), "Facade relief has frame work")
		_check(relief.find_children("*","CollisionObject2D",true,false).is_empty(), "Facade support adds fake collision")
		var before := _physics_snapshot(room)
		var transforms := {}
		for node in room.find_children("*","Marker2D",true,false): transforms[node] = node.global_transform
		var entries: int = relief.entries.size()
		var piers: int = relief.piers.size()
		_check(Relief.install(room,painter) == relief, "Duplicate relief on revisit")
		relief._build()
		_check(relief.entries.size() == entries and relief.piers.size() == piers and _physics_snapshot(room) == before, "Relief revisit changes native geometry")
		for node in transforms: _check(node.global_transform == transforms[node], "Relief moved a route marker")
		var kinds := {}
		for entry in relief.entries:
			detail_count += 1
			used[(6 if entry.kind=="ivy" else 0)+entry.index]=true
			kinds[entry.kind] = int(kinds.get(entry.kind,0)) + 1
			var points := PackedVector2Array()
			for point in entry.home.polygon: points.append(relief.to_local(entry.home.to_global(point)))
			for corner in [entry.rect.position,Vector2(entry.rect.end.x,entry.rect.position.y),entry.rect.end,Vector2(entry.rect.position.x,entry.rect.end.y)]:
				_check(Geometry2D.is_point_in_polygon(corner,points), "Decorative detail leaves its owning wall")
			var world: Rect2 = relief.global_transform * entry.rect
			for floor_rect in relief.floors: _check(not world.intersects(floor_rect), "Balcony slices facade detail")
			for window in painter.window_art: _check(not entry.rect.intersects(window.rect.grow(3)), "Facade detail covers window")
		for pier in relief.piers:
			pier_count += 1
			var world: Rect2 = relief.global_transform * pier.rect
			_check(absf(world.end.y-pier.bottom.position.y) < 0.01, "Rear pier has floating foot")
			_check(absf(world.position.y-(pier.top.end.y-2)) < 0.01, "Rear pier detaches from upper terrace")
			_check(world.size.y >= 35 and world.size.y <= 247 and world.size.x < 15, "Oversized rear structure")
			_check(pier.bottom.position.x <= world.position.x and pier.bottom.end.x >= world.end.x, "Rear pier not wholly supported")
		for piece in relief.pieces:
			_check(is_equal_approx(piece.rect.size.x / piece.source.size.x, piece.rect.size.y / piece.source.size.y), "Stretched architectural material")
			_check(Rect2(Vector2.ZERO,piece.texture.get_size()).encloses(piece.source), "Column crop leaves texture")
		_check(kinds.get("pilaster",0) >= 10 and kinds.get("ivy",0) >= 2, "Insufficient real facade detail coverage: " + named + " " + str(kinds))
		print("FACADE CONTEXT COVERAGE ",named," ",kinds," grounded rear piers=",piers)
		room.queue_free()
		await process_frame
	_check(windows == 91, "Facade context fixture coverage: " + str(windows))
	_check(used.size()==12,"Generated variants are not all placed in actual facades: " + str(used.keys()))
	state.delete_save()
	_check(pier_count >= 6, "Grounded lower-route pier fixture coverage: " + str(pier_count))
	print("FACADE CONTEXT TEST ", "PASSED" if failures.is_empty() else "FAILED", ": windows=", windows," details=",detail_count," piers=",pier_count," texture_bytes=",bytes)
	quit(0 if failures.is_empty() else 1)
