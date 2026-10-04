extends SceneTree

func _initialize() -> void:
	for family in ["cave", "ash", "star"]:
		var pixels := Image.load_from_file("res://art/visual_slice/ambient_%s_props_v1.png" % family)
		var columns := [0, 584, 1016, 1536] if family == "cave" else ([0, 521, 1020, 1536] if family == "ash" else [0, 535, 1027, 1536])
		var split := 463 if family == "cave" else 430
		print("ATLAS ", family, " size=", pixels.get_size())
		for row in 2:
			for col in 3:
				var region := Rect2i(columns[col], 0 if row == 0 else split, columns[col+1]-columns[col], split if row == 0 else 1024-split)
				var first := region.end
				var last := region.position
				var opaque_first := region.end
				var opaque_last := region.position
				for y in range(region.position.y, region.end.y):
					for x in range(region.position.x, region.end.x):
						var a := pixels.get_pixel(x, y).a
						if a > 0.03:
							first = first.min(Vector2i(x,y))
							last = last.max(Vector2i(x+1,y+1))
						if a >= 0.65:
							opaque_first = opaque_first.min(Vector2i(x,y))
							opaque_last = opaque_last.max(Vector2i(x+1,y+1))
				print("CELL ", row*3+col, " bounds=", Rect2i(first,last-first), " opaque=", Rect2i(opaque_first,opaque_last-opaque_first))
	quit(0)
