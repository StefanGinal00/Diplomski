extends SceneTree

func _initialize() -> void:
	for family in ["cave", "ash", "star"]:
		var pixels := Image.load_from_file("res://art/characters/residents_%s_motion_v1.png" % family)
		var split := 485 if family == "cave" else (480 if family == "ash" else 467)
		print("SHEET ", family, " size=", pixels.get_size(), " corner=", pixels.get_pixel(0, 0))
		for row in 2:
			for col in 4:
				var region := Rect2i(col * 384, 0 if row == 0 else split, 384, split if row == 0 else 1024-split)
				var first := region.end
				var last := region.position
				var opaque := region.position
				for y in range(region.position.y, region.end.y):
					for x in range(region.position.x, region.end.x):
						var alpha := pixels.get_pixel(x, y).a
						if alpha > 0.03:
							first = first.min(Vector2i(x,y))
							last = last.max(Vector2i(x+1,y+1))
						if alpha >= 0.65: opaque = opaque.max(Vector2i(x+1,y+1))
				print("FRAME ",row*4+col," crop=",Rect2i(first,last-first)," foot=",opaque.y-first.y)
	var machinery := Image.load_from_file("res://art/visual_slice/ash_industrial_landmarks_v1.png")
	print("MACHINERY ", machinery.get_size(), " corner ", machinery.get_pixel(0,0))
	for region in [Rect2i(0,0,720,563), Rect2i(720,0,534,560), Rect2i(0,563,720,691), Rect2i(720,560,534,694)]:
		var first: Vector2i = region.end
		var last: Vector2i = region.position
		var contact := 0
		for y in range(region.position.y,region.end.y):
			for x in range(region.position.x,region.end.x):
				if machinery.get_pixel(x,y).a > 0.03:
					first = first.min(Vector2i(x,y))
					last = last.max(Vector2i(x+1,y+1))
				if machinery.get_pixel(x,y).a >= 0.65: contact = maxi(contact,y+1)
		print("PART ",Rect2i(first,last-first)," contact ",contact-first.y)
	quit()
