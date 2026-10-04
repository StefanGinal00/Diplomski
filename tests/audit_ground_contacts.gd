extends "res://tests/boss_combat_presentation_smoke.gd"
const Layout = preload("res://WorldLayout.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_audit_ground_contacts.json"
	state.start_new_game("normal")
	for path in ["wayfarer_v1", "wayfarer_movement_v1", "wayfarer_combat_v1"]:
		_rows("res://art/characters/%s.png" % path, 2 if path.contains("movement") else 3, 2)
	for path in ["shaft_crawler_v1", "echo_grazer_v1"]: _rows("res://art/characters/%s.png" % path, 3, 2)
	_rows("res://art/characters/stone_sentinel_v1.png", 2, 2)
	_rows("res://art/characters/combat_mobs_frames_v2.png", 6, 4)
	for species in ["skimmer", "crawler", "newt"]: _rows(preload("res://EchoFaunaAppearance.gd").SHEETS[species].resource_path, 2, 2)
	for tex in preload("res://EchoGuideAppearance.gd").SHEETS.values(): _rows(tex.resource_path, 2, 2)
	for source in [preload("res://CavernDressingArt.gd"), preload("res://OpeningResidentArt.gd")]:
		var pixels: Image = source.SHEET.get_image()
		var rects: Array = source.RECTS if source == preload("res://CavernDressingArt.gd") else source.REGIONS
		var rows := []
		for rect in rects: rows.append(_bottom(pixels, Rect2i(rect)))
		print("CONTACT_REGIONS ", source.SHEET.resource_path, " ", rows)
	if "--contacts-only" in OS.get_cmdline_user_args():
		state.delete_save()
		quit(0)
		return
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var rooms: Array = ["training_passage"] + Layout.ROOM_NODES.keys()
	var seen := {}
	for id in rooms:
		var room: Node2D = game if id == "training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		if seen.has(room.get_instance_id()): continue
		seen[room.get_instance_id()] = true
		state.set_current_room(id)
		await process_frame
		await process_frame
		var nodes: Array[Node] = finish._members(room)
		var floors: Array[Rect2] = []
		var left := INF
		var right := -INF
		for node in nodes:
			if not node is CollisionShape2D or not node.get_parent() is StaticBody2D or node.disabled or not node.shape is RectangleShape2D: continue
			if node.get_parent().is_in_group("breakable"): continue
			var rect: Rect2 = node.global_transform * Rect2(-node.shape.size / 2, node.shape.size)
			if rect.size.x <= rect.size.y: continue
			floors.append(rect)
			left = minf(left, rect.position.x)
			right = maxf(right, rect.end.x)
		for node in nodes:
			if not (node is LevelExit or node.is_in_group("room_door")): continue
			var floor_y: float = INF
			var support := Rect2()
			for rect in floors:
				if node.global_position.x < rect.position.x or node.global_position.x > rect.end.x: continue
				if rect.position.y >= node.global_position.y - 8 and rect.position.y < node.global_position.y + 100 and rect.position.y < floor_y:
					floor_y = rect.position.y
					support = rect
			print("DOOR_SUPPORT ", id, " ", node.name, " at=", node.global_position - room.global_position, " floor_delta=", floor_y - node.global_position.y, " room_edges=", Vector2(node.global_position.x-left,right-node.global_position.x), " support_width=", support.size.x)
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)

func _rows(path: String, columns: int, rows: int) -> void:
	var tex: Texture2D = load(path)
	var pixels := tex.get_image()
	var size := pixels.get_size() / Vector2i(columns, rows)
	var contacts := []
	for row in rows:
		for col in columns: contacts.append(_bottom(pixels, Rect2i(Vector2i(col, row) * size, size)))
	print("CONTACT_ROWS ", path, " ", contacts)

func _bottom(pixels: Image, rect: Rect2i) -> int:
	for y in range(rect.end.y-1, rect.position.y-1, -1):
		var count := 0
		for x in range(rect.position.x, rect.end.x):
			if pixels.get_pixel(x, y).a >= 0.65: count += 1
			if count >= 3: return y - rect.position.y + 1
	return rect.size.y
