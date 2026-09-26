extends SceneTree

# Run with a rendering display driver (not --headless) to review the complete
# native city blockout. No editor or player save is modified.
func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	root.size = Vector2i(1500, 650)
	root.content_scale_size = Vector2i(1500, 650)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_city_preview_save.json"
	state.start_new_game("normal")
	var city := load("res://StarfallCitadel.tscn").instantiate() as Node2D
	root.add_child(city)
	city.process_mode = Node.PROCESS_MODE_DISABLED
	root.canvas_transform = Transform2D(Vector2(0.22, 0), Vector2(0, 0.22), Vector2(62, 470))
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var result := screenshot.save_png("res://_tmp_starfall_city_preview.png")
	print("CITY PREVIEW RESULT: ", result)
	state.delete_save()
	city.queue_free()
	await process_frame
	quit(result)
