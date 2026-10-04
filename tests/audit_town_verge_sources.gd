extends SceneTree
func _initialize() -> void:
	for family in ["echo","ash","star"]:
		var path := "res://art/visual_slice/town_verge_%s_v1.png"%family
		var pixels := Image.load_from_file(path)
		var entry := {"family":family,"size":[pixels.get_width(),pixels.get_height()],"boxes":[],"transparent":0,"gutter_alpha":0.0}
		for y in pixels.get_height():
			for x in pixels.get_width():
				var alpha := pixels.get_pixel(x,y).a
				if alpha<.01: entry.transparent+=1
				if x%512<8 or x%512>503 or y%512<8 or y%512>503: entry.gutter_alpha=maxf(entry.gutter_alpha,alpha)
		var cuts: Array=[]
		for row in 2:
			var row_cuts := [0]
			for ideal in [512,1024]:
				var best := INF
				var cut: int = ideal
				for x in range(ideal-70,ideal+70):
					var sum := 0.0
					for y in range(row*512,(row+1)*512): sum+=pixels.get_pixel(x,y).a
					if sum<best: best=sum; cut=x
				row_cuts.append(cut)
			row_cuts.append(1536); cuts.append(row_cuts)
		entry["cuts"]=cuts
		for cell in 6:
			var bounds := Rect2i(0,0,0,0)
			for y in range(cell/3*512,(cell/3+1)*512):
				for x in range(cuts[cell/3][cell%3],cuts[cell/3][cell%3+1]):
					if pixels.get_pixel(x,y).a<.02: continue
					if not bounds.has_area(): bounds=Rect2i(x,y,1,1)
					else: bounds=bounds.merge(Rect2i(x,y,1,1))
			entry.boxes.append([bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y])
		entry.transparent=float(entry.transparent)/(pixels.get_width()*pixels.get_height())
		print("TOWN_SOURCE ",JSON.stringify(entry))
	quit()
