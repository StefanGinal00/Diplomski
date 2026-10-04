extends SceneTree

func _initialize() -> void:
	for path in ["art/characters/service_merchants_motion_v1.png", "art/characters/service_smiths_motion_v1.png", "art/visual_slice/service_workplaces_v1.png", "art/visual_slice/settlement_windows_v1.png", "art/visual_slice/starfall_street_furnishings_v1.png"]:
		var pixels := Image.load_from_file("res://"+path)
		print(path," ",pixels.get_size()," alpha=",pixels.get_pixel(0,0).a)
		for index in 6:
			var region := Rect2i(index%3*512, index/3*512,512,512)
			if "starfall_street" in path:
				region = Rect2i(index%3*512,0 if index<3 else 620,512,620 if index<3 else 404)
				if index==4: region = Rect2i(490,620,540,404)
			if "workplaces" in path:
				region = [Rect2i(0,0,625,605),Rect2i(625,0,415,605),Rect2i(1040,0,496,605),Rect2i(0,610,520,414),Rect2i(520,610,505,414),Rect2i(1025,610,511,414)][index]
			if "windows" in path:
				region = Rect2i(index%3*512,0 if index<3 else 504,512,504 if index<3 else 520)
			var first := region.end
			var last := region.position
			var contact := 0
			for y in range(region.position.y,region.end.y):
				for x in range(region.position.x,region.end.x):
					var alpha := pixels.get_pixel(x,y).a
					if alpha > 0.03:
						first = first.min(Vector2i(x,y))
						last = last.max(Vector2i(x+1,y+1))
					if alpha >= 0.65: contact = maxi(contact,y+1)
			print("PART ", index, " ",Rect2i(first,last-first)," foot=",contact-first.y)
	quit()
