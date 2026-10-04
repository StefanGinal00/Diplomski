extends SceneTree

func _initialize() -> void:
	var results := {}
	for family in ["shale", "moss", "basalt", "citadel", "iron", "timber"]:
		var image := Image.load_from_file("res://art/visual_slice/terrain_edge_%s_v1.png" % family)
		var rows := []
		for limits in [Vector2i(0, 280), Vector2i(280, 512), Vector2i(512, 760), Vector2i(760, 1024)]:
			var bounds := Rect2i()
			var found := false
			var tops: Array[int] = []
			for x in image.get_width():
				var first := -1
				for y in range(limits.x, limits.y):
					if image.get_pixel(x,y).a < 0.5: continue
					if first < 0: first = y
					if not found:
						bounds = Rect2i(x,y,1,1)
						found = true
					else: bounds = bounds.expand(Vector2i(x,y))
				if first >= 0 and x > 100 and x < 1430: tops.append(first)
			tops.sort()
			rows.append({"rect": [bounds.position.x-2,bounds.position.y-2,bounds.size.x+5,bounds.size.y+5], "surface_y":tops[tops.size()/2], "top_min": tops[0], "top_max":tops[-1]})
		results[family]=rows
	print("TERRAIN_EDGE_DATA ", JSON.stringify(results))
	quit()
