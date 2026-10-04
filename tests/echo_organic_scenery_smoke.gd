extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_organic_scenery_save.json"
	state.start_new_game("normal")
	var script = load("res://EchoSceneryArt.gd")
	for key in script.ORGANIC:
		var texture: Texture2D = script.ORGANIC[key][0]
		var pixels := texture.get_image()
		var correct_size: bool = texture.get_height() >= 1100 if key != "stone" else texture.get_width() == 1024 and texture.get_height() in [682,683]
		print("ORGANIC SOURCE ",key," size=",texture.get_size()," mipmaps=",pixels.has_mipmaps()," corner_alpha=",pixels.get_pixel(0,0).a)
		_check(correct_size and pixels.has_mipmaps() and pixels.get_pixel(0, 0).a == 0, "Organic source resolution/alpha/mipmaps incorrect: " + key)
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	var routes := 0
	var total := {"fungus": 0, "crystal": 0, "stone": 0}
	var visible_total := {"fungus": 0, "crystal": 0, "stone": 0}
	for art in game.find_children("SceneryArt", "Node2D", true, false):
		if art.get_script() != script:
			continue
		routes += 1
		var physics := _physics_snapshot(art.get_parent())
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		var count: int = art.raster_props.size()
		art._build()
		_check(art.raster_props.size() == count and not art.is_processing() and art.get_child_count() == 0, "Organic decor duplicated or created per-prop processing/nodes")
		_check(count == art.counts.fungus + art.counts.crystal + art.counts.stone, "Not all previous decorative flora/minerals/ribs replaced")
		var placed: Array[Rect2] = []
		for prop in art.raster_props:
			total[prop.kind] += 1
			var rect: Rect2 = prop.rect
			var source: Rect2 = prop.source
			if prop.pieces > 0:
				for prior in placed:
					_check(not rect.intersects(prior.grow(2)), "Organic clusters overlap")
				placed.append(rect)
				visible_total[prop.kind] += 1
				_check(not prop.support.is_empty(), "Floating organic decoration")
				var support: Rect2 = prop.support.floor
				_check(absf(rect.end.y - support.position.y) < 0.01 and rect.position.x >= support.position.x and rect.end.x <= support.end.x, "Art lacks full-width floor support")
				_check(absf(prop.foot.x - prop.original_foot.x) <= 140.01 and absf(prop.foot.y - prop.original_foot.y) <= 12.01, "Art moved outside its local floor band")
				for obstacle in art.floor_rects:
					_check(not rect.grow(-0.05).intersects(obstacle), "Decoration crosses a platform")
			_check(is_equal_approx(rect.size.x / source.size.x, rect.size.y / source.size.y), "Organic art distorted")
			_check(Vector2(rect.get_center().x, rect.end.y).is_equal_approx(prop.foot), "Organic art moved its source foot")
			var height_budget: float = {"fungus":29.01, "crystal":100.01, "stone":32.01}[prop.kind]
			_check(rect.size.y <= height_budget, "Organic prop exceeds height budget")
			if prop.kind == "stone":
				_check(rect.size.x <= 72.01, "Rubble exceeds compact width budget")
				_check(source.end.x < script.ORGANIC.stone[0].get_width()/2.0 and source.end.y < script.ORGANIC.stone[0].get_height()/2.0, "Reduced import samples a neighbouring rubble cell")
		for shape in art.shapes:
			if not shape.has("raster"):
				continue
			var texture: Texture2D = script.ORGANIC[shape.raster][0]
			var prop: Dictionary = shape.prop
			_check(shape.uv.size() == shape.points.size(), "Clipped UV vertex count mismatch")
			for i in range(shape.points.size()):
				var fraction: Vector2 = (shape.points[i] - prop.rect.position) / prop.rect.size
				if prop.flip:
					fraction.x = 1.0 - fraction.x
				var expected: Vector2 = (prop.source.position + fraction * prop.source.size) / texture.get_size()
				_check(shape.uv[i].distance_to(expected) < 0.0001, "Clipping changed art scale/UV registration")
				_check(shape.uv[i].x >= 0 and shape.uv[i].x <= 1 and shape.uv[i].y >= 0 and shape.uv[i].y <= 1, "Organic UV samples beyond source")
		_check(_physics_snapshot(art.get_parent()) == physics and state.unlocked_shortcuts == flags, "Organic decor changed gameplay")
		print("ORGANIC ", art.theme, " fungus=", art.counts.fungus, " crystal=", art.counts.crystal)
	_check(routes == 8 and total.fungus >= 160 and total.crystal >= 120 and total.stone >= 120, "Eight-route organic coverage incomplete")
	print("ORGANIC TOTAL ", total)
	print("ORGANIC VISIBLE ", visible_total)
	_check(visible_total.fungus > 100 and visible_total.crystal > 60, "Insufficient grounded visible coverage")
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO ORGANIC SCENERY TEST PASSED: eight routes, alpha/mipmaps, clipped UVs, grounded uniform scale and unchanged physics")
		quit(0)
	else:
		quit(1)
