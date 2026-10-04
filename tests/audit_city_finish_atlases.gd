extends SceneTree
## Read-only alpha inspection. Generated PNGs are never rewritten.
func _initialize() -> void:
	for family in ["arcade_spandrels", "facade_trim", "observatory_details"]:
		var image := Image.load_from_file("res://art/visual_slice/city_%s_v1.png" % family)
		var regions: Array[Rect2i] = []
		if family == "arcade_spandrels":
			for row in 3: regions.append(Rect2i(0, row * 341, 1536, 341))
		elif family == "facade_trim":
			for row in 2:
				for column in 3: regions.append(Rect2i(column * 512, 0 if row == 0 else 785, 512, 780 if row == 0 else 239))
		else:
			for column in 3: regions.append(Rect2i(column * 512, 0, 512, 512))
			# The star-chart tips extend slightly past the nominal first cell.
			regions.append_array([Rect2i(0,512,558,512),Rect2i(558,512,466,512),Rect2i(1024,512,512,512)])
		var crops := []
		for region in regions:
			var minimum := region.end
			var maximum := region.position
			for y in range(region.position.y, region.end.y):
				for x in range(region.position.x, region.end.x):
					if image.get_pixel(x, y).a > 0.1:
						minimum = minimum.min(Vector2i(x, y))
						maximum = maximum.max(Vector2i(x, y))
			crops.append([minimum.x, minimum.y, maximum.x - minimum.x + 1, maximum.y - minimum.y + 1])
		print(family, " ", JSON.stringify(crops), " corner=", image.get_pixel(0, 0).a, " arch_void=", image.get_pixel(768, 285).a)
	quit()
