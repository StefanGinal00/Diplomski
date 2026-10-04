extends "res://tests/boss_combat_presentation_smoke.gd"
const Layout = preload("res://WorldLayout.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_gameplay_review.json"
	state.start_new_game("normal")
	for path in ["art/characters/opening_residents_v1.png", "art/visual_slice/cavern_dressing_atlas_v1.png", "art/visual_slice/pickups_hazard_atlas_v1.png", "art/visual_slice/loot_tokens_atlas_v1.png"]:
		var texture: Texture2D = load("res://" + path)
		var pixels := texture.get_image()
		_check(texture.get_width() >= 1500 and pixels.has_mipmaps() and pixels.get_pixel(0, 0).a < 0.01, "Raster quality/alpha/mipmaps missing: " + path)
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var rooms: Array = ["training_passage"]
	rooms.append_array(Layout.ROOM_NODES.keys())
	var seen := {}
	var surfaces := 0
	var devices := 0
	for id in rooms:
		var room: Node2D = game if id == "training_passage" else game.get_node_or_null(str(Layout.ROOM_NODES[id]))
		if room == null or seen.has(room.get_instance_id()): continue
		seen[room.get_instance_id()] = true
		state.set_current_room(id)
		await process_frame
		await process_frame
		game.get_node("UI")._update_objective_label()
		await process_frame
		var objective: Label = game.get_node("UI/ObjectivePanel/ObjectiveLabel")
		_check(objective.get_line_count() <= 2 and objective.get_minimum_size().y <= objective.get_parent().size.y, "Objective text overflows HUD: " + id)
		var before := _collision_snapshot(finish._members(room))
		finish.finish_room(id)
		var members: Array[Node] = finish._members(room)
		_check(_collision_snapshot(members) == before, "Presentation changed collisions: " + id)
		_check(finish.background.texture != null and finish.background.get_rect().size == root.get_visible_rect().size, "Camera painting does not cover viewport: " + id)
		for node in members:
			if node is StaticBody2D and node.has_meta("world_surface_finished"):
				surfaces += 1
				var textured := false
				for child in node.get_children():
					if child is Polygon2D and child.texture != null: textured = true
				_check(textured, "Untextured treated surface: " + str(node.get_path()))
			if node.has_node("FinishedDevice"):
				devices += 1
				_check(node.get_node("FinishedDevice").texture is AtlasTexture, "Placeholder device art: " + str(node.get_path()))
			if node is Line2D and node.name in ["SurfaceGlow", "MaterialRim", "ShaftRimLight"]:
				_check(not node.visible, "Prototype seam remains: " + str(node.get_path()))
		var count: int = members.size()
		finish.finish_room(id)
		_check(count == finish._members(room).size(), "Finish pass duplicates props: " + id)
	_check(surfaces > 500 and devices > 50, "Incomplete material/device coverage")
	var wall := game.get_node("OpeningWestWall")
	_check(is_equal_approx(wall.position.x + wall.get_node("CollisionShape2D").shape.size.x / 2, 36), "Opening left wall misses floor edge")
	_check(not game.get_node("Caretaker/Sprite2D").visible and not game.get_node("WayfarerMerchant/Cloak").visible, "Opening NPC placeholder remains")
	var relics := game.get_node("VerticalChamber/ArenaRelics")
	for point in relics.points:
		var dimensions: Vector2 = relics.REGIONS[relics.style].size
		dimensions *= relics.height / dimensions.y
		var bounds: Rect2 = relics.global_transform * Rect2(point - Vector2(dimensions.x * 0.5, dimensions.y), dimensions)
		for body in relics.get_parent().get_children():
			if not body is StaticBody2D: continue
			var col := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if col == null or col.disabled or not col.shape is RectangleShape2D: continue
			var terrain: Rect2 = col.global_transform * Rect2(-col.shape.size * 0.5, col.shape.size)
			_check(not bounds.grow(-0.1).intersects(terrain), "Shaft relic intersects platform or wall")
		for door_name in ["ArenaHubReturnDoor", "GrottoGate"]:
			var door := game.get_node("VerticalChamber/" + door_name)
			_check(absf(point.x - door.position.x) > 55, "Shaft relic overlaps the painted entrance")
	var bg: TextureRect = finish.background
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2.ZERO)
	bg._process(0)
	var first: Vector2 = bg.camera_uv
	root.canvas_transform.origin += Vector2(800, -900)
	bg._process(0)
	_check(first.distance_to(bg.camera_uv) > 0.01 and bg.view_uv.x < 1, "Parallax absent or painting overmagnified")
	for scene_name in ["XPOrb", "LifeBloom", "GoldPickup", "QuestItem", "ItemPickup"]:
		var pickup: Node = load("res://%s.tscn" % scene_name).instantiate()
		game.add_child(pickup)
		_check(pickup.find_child("PaintedPickup", true, false) != null, scene_name + " has no painted pickup")
		if scene_name == "ItemPickup":
			pickup.configure("memory_sigil_echo", "Echo memory")
			var art: Sprite2D = pickup.get_node("Visual/PaintedPickup")
			_check(art.texture.atlas == preload("res://PickupMaterialArt.gd").LOOT, "Late pickup configuration kept the old artwork")
		pickup.queue_free()
	print("GAMEPLAY REVIEW COVERAGE: ", seen.size(), " rooms, ", surfaces, " surfaces, ", devices, " devices")
	game.queue_free()
	await process_frame
	state.delete_save()
	print("GAMEPLAY REVIEW TEST PASSED" if failures.is_empty() else "TEST FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)

func _collision_snapshot(nodes: Array[Node]) -> Dictionary:
	var result := {}
	for node in nodes:
		if node is CollisionShape2D:
			result[str(node.get_path())] = [node.shape.get_instance_id() if node.shape != null else 0, node.transform, node.disabled, node.one_way_collision]
	return result
