extends SceneTree
func _initialize() -> void:
	for family in ["haven", "hearth", "street"]:
		var file := "res://art/visual_slice/terrain_edge_%s_v1.png" % family
		var picture := Image.load_from_file(file)
		var strips := []
		for row in 4:
			var box := Rect2i()
			var first := -1
			var contact := -1
			for y in range(row*256, (row+1)*256):
				var occupied := 0
				for x in picture.get_width():
					if picture.get_pixel(x,y).a < 0.65: continue
					if first < 0: box=Rect2i(x,y,1,1); first=y
					box=box.expand(Vector2i(x,y)); occupied+=1
				if contact < 0 and occupied > 1200: contact=y
			strips.append({"crop":[box.position.x,box.position.y,box.size.x+1,box.size.y+1],"contact":contact})
		print("CITY_EDGE_SOURCE ",family," ",JSON.stringify(strips)," corner=",picture.get_pixel(0,0).a)
	for library in ["corridor_cave_clusters_v1","corridor_ash_clusters_v1","corridor_star_clusters_v1"]:
		var data: Dictionary=preload("res://CorridorAtlas.gd").DATA[library]
		var picture := Image.load_from_file("res://art/visual_slice/%s.png"%library)
		var contacts := []
		for b in data.boxes:
			var contact := -1
			for local_y in range(b[3]-1,-1,-1):
				var count:=0
				for local_x in b[2]:
					if picture.get_pixel(b[0]+local_x,b[1]+local_y).a>=0.65: count+=1
				if count>=maxi(4,int(b[2]*0.025)): contact=local_y;break
			contacts.append(contact)
		print("CORRIDOR_OPAQUE_CONTACT ",library," ",contacts)
	quit()
