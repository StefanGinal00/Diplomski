extends SceneTree
## Read-only bounds/contact audit of original generated alpha.
func _initialize() -> void:
	for named in ["haven_court_gate_v1","haven_ward_gate_v1","haven_road_ruin_v1","gate_buttress_modules_v1","portal_threshold_dressing_v1"]:
		var picture := Image.load_from_file("res://art/visual_slice/%s.png"%named)
		var cells: Array[Rect2i] = []
		if named.begins_with("haven"):
			cells.append(Rect2i(0,0,1536,1024))
		else:
			var split := 700 if named.begins_with("gate") else 512
			for row in 2:
				for column in 3:
					cells.append(Rect2i(column*512,0 if row==0 else split,512,split if row==0 else 1024-split))
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
		print(named," ",JSON.stringify(result)," alpha=",picture.get_pixel(0,0).a," hole=",picture.get_pixel(768,700).a)
	quit()
