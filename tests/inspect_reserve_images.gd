extends SceneTree


func _initialize() -> void:
	for kind in ["shaft", "ash", "starfall"]:
		var img := Image.load_from_file("res://art/visual_slice/%s_reserve_v1.png" % kind)
		print(kind, " size=", img.get_size(), " alpha=", img.detect_alpha(), " bounds=", img.get_used_rect())
		var low := img.get_size()
		var high := Vector2i.ZERO
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				if img.get_pixel(x, y).a > 0.1:
					low = Vector2i(mini(low.x, x), mini(low.y, y))
					high = Vector2i(maxi(high.x, x), maxi(high.y, y))
		print(kind, " solid bounds=", Rect2i(low, high - low + Vector2i.ONE))
	quit()
