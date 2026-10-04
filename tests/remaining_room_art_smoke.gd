extends "res://tests/visual_style_slice_smoke.gd"

const ROOMS := ["VerticalChamber","ShaftHollow","DrownedCrossing","FloodedGallery","WardenApproach","EchoGallery","TideWell","EchoNest","CrystalCauseway","UndertowVault","ResonanceSanctum","BrokenCauseway","EmberBarracks","SlagReservoir","AshChapel","AshArena","CastellanThrone","StarfallCitadel","EchoHavenOutskirts","CinderHearthOutskirts"]
var textures := {}


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_remaining_room_art_save.json"
	state.start_new_game("normal")
	for named in ROOMS:
		var room: Node2D = load("res://%s.tscn" % named).instantiate()
		var arts: Array[Node] = [room.get_node("RemainingArt")]
		if named == "VerticalChamber":
			arts.append(room.get_node("WardenArt"))
		for art in arts:
			art.owner = null
			room.remove_child(art)
		root.add_child(room)
		await process_frame
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var before := _physics_snapshot(room)
		var originals := {}
		for node in room.find_children("*", "Node2D", true, false):
			originals[node] = [node.transform, node.visible, node.z_index, node.polygon.duplicate() if node is Polygon2D else null]
		for art in arts:
			room.add_child(art)
		await process_frame
		_check(_physics_snapshot(room) == before, "Background changed collision: " + named)
		for node in originals:
			var old: Array = originals[node]
			var retired := false
			for art in arts:
				retired = retired or node in art.retired
			_check(node.transform == old[0] and node.z_index == old[2], "Art moved an existing node: " + str(node.name))
			_check(node.visible == old[1] or retired, "Art hid a gameplay node")
			if node is Polygon2D:
				_check(node.polygon == old[3], "Art changed existing silhouette")
		# Lifecycle probes deliberately hide the room, which now also cancels boss
		# poses/warnings. Audit the material build before those explicit mutations.
		for art in arts:
			_check_art(art, room)
		room.queue_free()
		await process_frame
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for named in ["EchoDepths", "AshEmberspine", "TrainingPassageDecor"]:
		var room: Node2D = game.get_node(named)
		room.show()
		_check_art(room.get_node("RemainingArt"), room)
	_check(textures.size() == 24, "Expected 24 distinct new room images, got " + str(textures.size()))
	game.queue_free()
	await process_frame
	root.canvas_transform = Transform2D.IDENTITY
	state.delete_save()
	if failures.is_empty():
		print("REMAINING ROOM ART TEST PASSED: 24 distinct images, masked backgrounds, unchanged collision/silhouettes, two-axis parallax, hidden-room sleep, texture budget")
		quit(0)
	else:
		quit(1)


func _check_art(art: Node2D, room: Node2D) -> void:
	_check(art.built and not art.plates.is_empty(), "Missing background: " + art.artwork)
	if not art.built:
		return
	if art.layout in ["hub", "shaft", "echo", "ash", "district", "expedition"]:
		_check(art.plates.size() >= 10, "Expanded route lacks backgrounds: " + art.artwork)
	for plate in art.plates:
		textures[plate.texture.resource_path] = true
		_check(plate.material == art.material_shared and plate.z_index < 0, "Background overlaps actors")
		_check(plate.texture.get_width() == 1536 and plate.texture.get_image().has_mipmaps(), "Source detail/mipmaps incorrect")
		_check(plate.uv.size() == plate.polygon.size(), "Invalid background UVs")
		for index in range(plate.polygon.size()):
			var point: Vector2 = art.to_local(plate.to_global(plate.polygon[index]))
			var expected: Vector2 = (point - art.art_bounds.position) / art.art_bounds.size * plate.texture.get_size()
			_check(plate.uv[index].distance_to(expected) < 0.01, "Discontinuous background coordinates")
	room.show()
	var center: Vector2 = art.to_global(art.art_bounds.get_center())
	for zoom in [0.8, 1.5]:
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), root.get_visible_rect().size * 0.5 - center * zoom)
		art._process(0.1)
		var initial: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
		root.canvas_transform.origin -= Vector2(160, 80) * zoom
		art._process(0.1)
		var moved: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
		var haze: Vector2 = art.material_shared.get_shader_parameter("haze_shift")
		_check(moved.x < initial.x and moved.y < initial.y, "Parallax does not oppose movement: " + art.artwork)
		_check(moved.length() > haze.length(), "Depth speeds are identical")
	var updates: int = art.update_count
	room.hide()
	art._process(1)
	_check(art.update_count == updates, "Hidden background updates")
	room.show()
	var count: int = art.plates.size()
	art._build()
	_check(art.plates.size() == count, "Duplicate background build")
	print("REMAINING COVERAGE ", art.artwork, ": ", count)
