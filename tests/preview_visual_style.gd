extends SceneTree

# GPU-rendered in-engine evidence, isolated from the player's save.
func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_visual_style_preview_save.json"
	state.start_new_game("normal")
	var entries := [["EchoGrotto", Vector2(490, -35), 1.22, "grotto"], ["StarfallCitadel", Vector2(3580, 140), 0.96, "market"], ["EchoGrotto", Vector2(460, 65), 2.5, "grotto_gameplay"], ["StarfallCitadel", Vector2(4040, 285), 2.5, "apothecary"]]
	for entry in entries:
		var room: Node2D = load("res://%s.tscn" % entry[0]).instantiate()
		root.add_child(room)
		await process_frame
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var zoom: float = entry[2]
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(640, 360) - entry[1] * zoom)
		room.get_node("VisualStyleSlice")._process(0.1)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://art/visual_slice/preview_%s.png" % entry[3])
		print("ART PREVIEW ", entry[3], ": ", result)
		room.queue_free()
		await process_frame
	state.delete_save()
	quit(0)
