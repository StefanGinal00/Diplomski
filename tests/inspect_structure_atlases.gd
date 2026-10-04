extends SceneTree
func _initialize() -> void:
	for spec in [["passage_facades_v1", 3, 1], ["lift_mechanisms_v1", 2, 2], ["ledge_supports_v1", 3, 1]]:
		var path: String = "res://art/visual_slice/%s.png" % spec[0]
		if not FileAccess.file_exists(path): continue
		var pixels := Image.load_from_file(path)
		var cell := pixels.get_size() / Vector2i(spec[1], spec[2])
		print("ATLAS ", spec[0], " size=", pixels.get_size())
		for row in int(spec[2]):
			for column in int(spec[1]):
				var region := Rect2i(Vector2i(column, row) * cell, cell)
				var used := pixels.get_region(region).get_used_rect()
				print("REGION ", Rect2i(region.position + used.position, used.size))
				var minimum := region.end
				var maximum := region.position
				for y in range(region.position.y, region.end.y):
					for x in range(region.position.x, region.end.x):
						if pixels.get_pixel(x, y).a < 0.65: continue
						minimum = minimum.min(Vector2i(x, y))
						maximum = maximum.max(Vector2i(x + 1, y + 1))
				print("OPAQUE ", Rect2i(minimum, maximum-minimum), " center-low ", pixels.get_pixel(region.position.x + cell.x/2, region.position.y + int(cell.y*.83)))
	quit(0)
