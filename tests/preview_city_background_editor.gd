@tool
extends SceneTree
## Run with --editor --script; a SubViewport isolates art from editor chrome.

func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	if not Engine.is_editor_hint():
		push_error("This preview requires --editor")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for combined in [false, true]:
		var scene: Node2D = load("res://Game.tscn" if combined else "res://StarfallCitadel.tscn").instantiate()
		edited_scene_root = scene
		viewport.add_child(scene)
		await process_frame
		await process_frame
		await process_frame
		var city: Node2D = scene.get_node("StarfallCitadel") if combined else scene
		if city.has_node("VisualStyleSlice/MarketSkyPainting"):
			push_error("Duplicate background in editor")
			quit(1)
			return
		var sky := city.get_node("Sky") as Polygon2D
		var architecture := city.get_node("ParallaxArchitecture")
		if not architecture.built or architecture.retired.size()!=230 or architecture.get_child_count()!=0:
			push_error("Editor city architecture missing or duplicates native objects")
			quit(1)
			return
		if sky.texture == null or sky.material.shader.resource_path != "res://art/visual_slice/city_panorama.gdshader":
			push_error("Editor background missing")
			quit(1)
			return
		for data in [["whole", Vector2(3125, -650), 0.20], ["street", Vector2(3125, 30), 0.20]]:
			var zoom: float = data[2]
			viewport.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(640, 360) - city.to_global(data[1]) * zoom)
			architecture.update_view(data[1],Vector2(viewport.size)/zoom,true)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var path := "res://art/characters/preview_city_single_editor_%s_%s.png" % ["world" if combined else "scene", data[0]]
			print("EDITOR CITY CAPTURE ", path, ": ", viewport.get_texture().get_image().save_png(path))
		edited_scene_root = null
		scene.queue_free()
		await process_frame
	viewport.queue_free()
	await process_frame
	print("EDITOR CITY TEST PASSED: single background in standalone and combined-world editor contexts")
	quit(0)
