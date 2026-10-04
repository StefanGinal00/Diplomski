extends SceneTree
## Read-only registration of generated PNGs; never edits source pixels.
func _initialize() -> void:
	for sheet in ["starfall_task_stations_v1", "starfall_task_registers_v1", "starfall_route_furnishings_v1"]:
		var image := Image.load_from_file("res://art/visual_slice/%s.png" % sheet)
		var cells: Array[Rect2i] = [Rect2i(0,0,550,485), Rect2i(550,0,450,485), Rect2i(1000,0,536,485), Rect2i(0,485,550,539), Rect2i(550,485,480,539), Rect2i(1030,485,506,539)]
		if sheet.contains("registers"):
			cells = [Rect2i(0,0,532,480), Rect2i(532,0,483,480), Rect2i(1015,0,521,480), Rect2i(0,480,655,544), Rect2i(655,480,380,544), Rect2i(1035,480,501,544)]
		elif sheet.contains("furnishings"):
			cells = [Rect2i(0,0,515,520),Rect2i(515,0,535,520),Rect2i(1050,0,486,520),Rect2i(0,520,512,504),Rect2i(512,520,482,504),Rect2i(994,520,542,504)]
		var result := []
		for cell in cells:
			var first := cell.end
			var last := cell.position
			for y in range(cell.position.y, cell.end.y):
				for x in range(cell.position.x, cell.end.x):
					if image.get_pixel(x,y).a < 12.0/255: continue
					first = first.min(Vector2i(x,y)); last = last.max(Vector2i(x,y))
			var used := Rect2i(first,last-first+Vector2i.ONE)
			var foot := 0
			for y in range(used.position.y, used.end.y):
				var solid := 0
				for x in range(used.position.x, used.end.x):
					if image.get_pixel(x,y).a > .6: solid += 1
				if solid >= maxi(5, used.size.x/25): foot = y-used.position.y
			result.append({"box":[used.position.x,used.position.y,used.size.x,used.size.y],"foot":foot})
		print(sheet," ",JSON.stringify(result))
	quit()
