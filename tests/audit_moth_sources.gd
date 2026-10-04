extends SceneTree
## Read-only source-alpha/crop registration; never rewrites generated PNGs.
func _initialize() -> void:
	for family in ["cave","mine","ash","star"]:
		var image := Image.new()
		var error := image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://art/visual_slice/ambient_moth_%s_v1.png"%family))
		if error!=OK: push_error("Missing moth source"); quit(1); return
		var cell := image.get_size()/Vector2i(3,2)
		var boxes: Array = []; var gutter_alpha := 0.0; var transparent := 0
		for y in image.get_height():
			for x in image.get_width():
				var alpha := image.get_pixel(x,y).a
				if alpha<.01: transparent += 1
				if x%cell.x<8 or x%cell.x>=cell.x-8 or y%cell.y<8 or y%cell.y>=cell.y-8: gutter_alpha=maxf(gutter_alpha,alpha)
		for index in 6:
			var start := Vector2i(index%3,index/3)*cell
			var lo := cell; var hi := Vector2i.ZERO
			for y in cell.y:
				for x in cell.x:
					if image.get_pixelv(start+Vector2i(x,y)).a<.02: continue
					lo=lo.min(Vector2i(x,y)); hi=hi.max(Vector2i(x,y))
			boxes.append([start.x+lo.x,start.y+lo.y,hi.x-lo.x+1,hi.y-lo.y+1])
		print("MOTH_SOURCE ",JSON.stringify({"family":family,"size":[image.get_width(),image.get_height()],"boxes":boxes,"transparent_fraction":float(transparent)/(image.get_width()*image.get_height()),"gutter_alpha":gutter_alpha}))
	quit(0)
