extends SceneTree
## Read alpha only; generated originals are never modified.
func _initialize() -> void:
	for family in ["moss","shale","basalt","citadel"]:
		var image := Image.new()
		var error := image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://art/visual_slice/ground_dust_%s_v%d.png"%[family,2 if family=="moss" else 1]))
		if error!=OK: push_error("Missing dust source"); quit(1); return
		var cell := image.get_size()/Vector2i(3,2)
		var boxes: Array=[]; var gutter_alpha := 0.0; var transparent := 0
		for y in image.get_height():
			for x in image.get_width():
				var alpha := image.get_pixel(x,y).a
				if alpha<.01: transparent+=1
				if x%cell.x<8 or x%cell.x>=cell.x-8 or y%cell.y<8 or y%cell.y>=cell.y-8: gutter_alpha=maxf(gutter_alpha,alpha)
		for index in 6:
			var start := Vector2i(index%3,index/3)*cell
			var frames := []
			for threshold in [.02,.1,.3,.5]:
				var lo := cell; var hi := Vector2i.ZERO
				for y in cell.y:
					for x in cell.x:
						if image.get_pixelv(start+Vector2i(x,y)).a<threshold: continue
						lo=lo.min(Vector2i(x,y)); hi=hi.max(Vector2i(x,y))
				frames.append([start.x+lo.x,start.y+lo.y,hi.x-lo.x+1,hi.y-lo.y+1])
			boxes.append(frames)
		print("DUST_SOURCE ",JSON.stringify({"family":family,"size":[image.get_width(),image.get_height()],"boxes_by_alpha_02_10_30_50":boxes,"transparent_fraction":float(transparent)/(image.get_width()*image.get_height()),"gutter_alpha":gutter_alpha}))
	quit(0)
