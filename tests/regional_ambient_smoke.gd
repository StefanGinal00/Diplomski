extends "res://tests/gameplay_review_smoke.gd"
const Piece := preload("res://AmbientSetpiece.gd")
const Dressing := preload("res://RegionalAmbientDressing.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_regional_ambient.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var total := 0
	var moving := 0
	var retired := 0
	var retired_lines := 0
	var seen := {}
	var families := {}
	for id in ["training_passage"] + Layout.ROOM_NODES.keys():
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		if seen.has(room.get_instance_id()): continue
		seen[room.get_instance_id()] = true
		state.set_current_room(id)
		await process_frame
		await process_frame
		finish.finish_room(id)
		var dressing := room.get_node("AmbientCompositions")
		var backdrop := room.get_node_or_null("Backdrop")
		if backdrop is Polygon2D: _check(not backdrop.visible, "Old root background still covers the painting: " + id)
		if id == "ash_forge":
			_check(not room.get_node("FurnaceCore").visible and not room.get_node("VentDuct").visible, "Forge sketch overlays remain")
		if id == "echo_haven":
			_check(not room.get_node("CrystalCanopy").visible and not room.get_node("CrystalVeins").visible, "Haven sketch overlays remain")
		var before := _collision_snapshot(finish._members(room))
		var count: int = dressing.props.size()
		_check(count > 0 and count <= Dressing.MAX_CLUSTERS * 2 + Dressing.MAX_HANGING, "Empty/over-budget room dressing: " + id)
		families[dressing.biome] = true
		for prop in dressing.props:
			_check(not prop.is_processing() and prop.get_child_count() == 1 and prop.get_child(0) is Sprite2D, "Decoration adds independent frame work or gameplay nodes")
			_check(prop.art.texture is AtlasTexture and is_equal_approx(prop.art.scale.x, prop.art.scale.y), "Untextured or stretched ambient object")
			var ratio: Vector2 = Piece.SHEETS[prop.family].get_size() / Piece.SOURCE_SIZE
			var row: float = Piece.CONTACT[prop.family][prop.kind] * ratio.y
			var contact: Vector2 = prop.art.to_global(Vector2(0, -prop.art.texture.get_height()*0.5 + row))
			_check(contact.distance_to(prop.global_position) < 0.03, "Incorrect painted anchor contact")
			if prop.anchor_kind == "floor":
				_check(absf(contact.y - prop.support.position.y) < 0.03 and contact.x >= prop.support.position.x and contact.x <= prop.support.end.x, "Floating ground prop: " + id)
			elif prop.anchor_kind == "wall":
				_check(prop.support.has_point(contact), "Hanging decoration has no wall attachment")
			else:
				_check(absf(contact.y - prop.support.end.y + 1) < 0.03 and contact.x > prop.support.position.x and contact.x < prop.support.end.x, "Vine has no overhead attachment")
			for solid in dressing.solids:
				if solid != prop.support: _check(not prop.footprint.grow(-0.3).intersects(solid), "Decoration clips another platform: " + id)
			for reserved in dressing.protected:
				_check(not prop.footprint.intersects(reserved), "Decoration covers a protected interaction/hazard: " + id)
			if prop.motion != 0:
				moving += 1
				var at: Vector2 = prop.global_position
				prop.animate(1.5)
				var first: float = prop.rotation
				prop.animate(3.8)
				_check(not is_equal_approx(first, prop.rotation) and prop.global_position == at and absf(prop.rotation) < 0.04, "Wind is static, excessive or shifts the anchor")
				prop.rest()
		for old in dressing.retired:
			_check(not old.visible, "Retired scenery wedge returned")
		retired += dressing.retired.size()
		for line in dressing.retired_lines: _check(not line.visible, "Prototype cyan terrain line remains")
		retired_lines += dressing.retired_lines.size()
		total += count
		finish.finish_room(id)
		_check(dressing.props.size() == count and _collision_snapshot(finish._members(room)) == before, "Dressing duplicates or changes native collisions")
		var ambience: Node = finish.ambience
		ambience.set_low_quality(true)
		ambience.select_visible(Rect2(room.global_position - Vector2(5000,5000), Vector2(20000,20000)))
		_check(ambience.active.size() <= 8, "Combined low-cost animation cap exceeded")
		for node in ambience.active:
			if node.has_meta("ambient_motion"): node.animate(2)
		ambience.select_visible(Rect2(Vector2(1000000,1000000), Vector2.ONE))
		_check(ambience.active.is_empty(), "Offscreen animation stays selected")
		for prop in dressing.props:
			_check(is_zero_approx(prop.rotation) and is_zero_approx(prop.skew), "Deselected prop retains a bent pose")
	# Late native doors suppress only obstructing decoration, without reentry.
	state.set_current_room("training_passage")
	await process_frame
	await process_frame
	var detail: Node2D = game.get_node("AmbientCompositions").props[0]
	var door: Node2D = load("res://RoomDoor.tscn").instantiate()
	game.add_child(door)
	door.global_position = detail.global_position
	for frame in range(3): await process_frame
	_check(door.has_node("FinishedDevice") and not detail.visible, "Late terminal remains covered by decoration")
	var bytes := 0
	for texture in Piece.SHEETS:
		var pixels: Image = texture.get_image()
		bytes += pixels.get_data_size()
		_check(texture.get_width() <= 1024 and pixels.has_mipmaps() and pixels.get_pixel(0,0).a == 0, "Atlas budget/alpha/mipmaps")
	_check(bytes < 12*1024*1024 and families.size() == 3 and moving > 60 and retired > 0, "Missing regional variation or resource bound")
	_check(retired_lines > 0, "Old cyan scenery seams not addressed")
	print("REGIONAL AMBIENT COVERAGE: ", seen.size(), " rooms, ", total, " props, ", moving, " motion candidates, ", retired, " retired inert wedges, ", retired_lines, " retired scenery lines, ", bytes, " decoded bytes")
	game.queue_free()
	await process_frame
	state.delete_save()
	print("REGIONAL AMBIENT TEST PASSED" if failures.is_empty() else "REGIONAL AMBIENT TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
