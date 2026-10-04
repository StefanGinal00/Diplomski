extends SceneTree
## Read-only original pixel audit; never modifies generated RGBA.
func _initialize() -> void:
	var names := ["compact_passages_echo_v1","compact_passages_cinder_v1","compact_passages_star_v1","starfall_watch_arch_v1","civic_battlements_v1","civic_reliefs_v1","watch_banners_v1"]
	for named in names:
		var picture := Image.load_from_file("res://art/visual_slice/%s.png"%named)
		var cells: Array[Rect2i] = []
		if named.begins_with("compact"):
			cells=[Rect2i(0,0,768,1024),Rect2i(768,0,768,1024)]
		elif named=="starfall_watch_arch_v1":
			cells=[Rect2i(0,0,1536,1024)]
		elif named=="civic_battlements_v1":
			cells=[Rect2i(0,0,1536,341),Rect2i(0,341,1536,341),Rect2i(0,682,1536,342)]
		elif named=="civic_reliefs_v1":
			cells=[Rect2i(0,0,542,471),Rect2i(542,0,513,451),Rect2i(1055,0,481,451),Rect2i(0,472,542,552),Rect2i(542,452,513,572),Rect2i(1055,452,481,572)]
		else:
			for row in 2:
				for column in 3: cells.append(Rect2i(column*512,row*512,512,512))
		var result := []
		for cell in cells:
			var low := cell.end
			var high := cell.position
			var contact := cell.position.y
			for y in range(cell.position.y,cell.end.y):
				var opaque := 0
				for x in range(cell.position.x,cell.end.x):
					var alpha := picture.get_pixel(x,y).a
					if alpha>0.1:
						low=low.min(Vector2i(x,y)); high=high.max(Vector2i(x,y))
					if alpha>0.65: opaque+=1
				if opaque>=8: contact=y
			result.append({"crop":[low.x,low.y,high.x-low.x+1,high.y-low.y+1],"contact":contact-low.y})
		print(named," ",JSON.stringify(result)," alpha=",picture.get_pixel(0,0).a," hole=",picture.get_pixel(768,700).a," format=",picture.get_format())
	quit()
