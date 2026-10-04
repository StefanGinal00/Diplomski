extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_prop_scale_audit.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	for i in 5: await process_frame
	game.get_node("UI").story_player.cancel()
	paused = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var layout := preload("res://WorldLayout.gd")
	var rows := []
	var ids: Array = ["training_passage"] + layout.ROOM_NODES.keys()
	for id in ids:
		state.set_current_room(id)
		for i in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D = game if id == "training_passage" else game.get_node(layout.ROOM_NODES[id])
		for node in finish._members(room):
			if not node is Sprite2D or not node.visible or node.texture == null: continue
			var excluded := false
			var ancestor: Node = node
			while ancestor != room and ancestor != null:
				if ancestor.is_in_group("enemy") or ancestor.is_in_group("player") or String(ancestor.name) in ["TerrainEnvelope", "PortalContext", "ParallaxArchitecture"]: excluded = true; break
				ancestor = ancestor.get_parent()
			if excluded: continue
			var bounds: Rect2 = node.global_transform * node.get_rect()
			if bounds.size.x <= 130 and bounds.size.y <= 64: continue
			rows.append({"room":id, "node":str(room.get_path_to(node)),"size":str(bounds.size),"texture":node.texture.resource_path if not node.texture is AtlasTexture else node.texture.atlas.resource_path})
	print("PROP_SCALE_AUDIT ", JSON.stringify(rows))
	state.delete_save()
	quit()
