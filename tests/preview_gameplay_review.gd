extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_gameplay_review_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	# Preview-only loose drops beside the existing LostSigil. Never serialized.
	for scene_name in ["GoldPickup", "ItemPickup"]:
		var pickup: Node2D = load("res://%s.tscn" % scene_name).instantiate()
		if scene_name == "ItemPickup": pickup.configure("iron_arrow_bundle", "Supply pouch")
		game.add_child(pickup)
		pickup.position = Vector2(674 if scene_name == "GoldPickup" else 704, 280)
		pickup.get_node("Visual").scale = Vector2.ONE
	var player: Node2D = game.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	var finish := game.get_node("WorldPresentationFinish")
	for shot in [
		["training_passage", "", Vector2(184, 363), "camp"],
		["training_passage", "", Vector2(53, 367), "west_edge"],
		["training_passage", "", Vector2(610, 365), "lamp"],
		["training_passage", "", Vector2(648, 245), "loot"],
		["training_passage", "", Vector2(1330, 365), "exit"],
		["training_passage", "", Vector2(350, 130), "jump"],
		["sunken_shaft", "VerticalChamber", Vector2(112, 91), "lift"],
		["sunken_shaft", "VerticalChamber", Vector2(65, 361), "shaft_edge"],
		["sunken_shaft", "VerticalChamber", Vector2(515, 625), "shaft_floor"],
		["shaft_hollow", "ShaftHollow", Vector2(560, 317), "hollow"],
	]:
		state.set_current_room(shot[0])
		await process_frame
		await process_frame
		finish.finish_room(shot[0])
		game.get_node("UI")._dismiss_zone_title()
		var room: Node2D = game if shot[1] == "" else game.get_node(shot[1])
		player.global_position = room.to_global(shot[2])
		camera.reset_smoothing()
		camera.force_update_scroll()
		finish.background._process(0)
		finish._process(0.2)
		if shot[3] == "hollow":
			var view := Rect2(player.global_position - Vector2(200, 120), Vector2(400, 240))
			for node in finish._members(room):
				if not node is Polygon2D or node.texture != null or not node.is_visible_in_tree() or node.polygon.is_empty(): continue
				var bounds := Rect2(node.to_global(node.polygon[0]), Vector2.ZERO)
				for point in node.polygon: bounds = bounds.expand(node.to_global(point))
				if bounds.intersects(view): print("VISIBLE BASIC ", node.get_path(), " Z=", node.z_index, " ", bounds)
		await _capture("review_" + shot[3])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
