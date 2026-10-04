extends SceneTree
const Atlas := preload("res://RouteDressingAtlas.gd")

func _initialize() -> void:
	var result := {}
	for family in ["cave","mine","ash","star"]:
		var sheet := "route_%s_ceiling_v1"%family
		var entry: Dictionary = Atlas.DATA[sheet]
		var source := Image.new()
		source.load_png_from_buffer(FileAccess.get_file_as_bytes("res://art/visual_slice/"+sheet+".png"))
		var tips := []
		for index in [3,4]:
			var box: Array = entry.boxes[index]
			var tip := Vector2i(-1,-1)
			for y in range(box[3]-1,-1,-1):
				var xs: Array[int] = []
				for x in range(box[2]):
					if source.get_pixel(box[0]+x,box[1]+y).a>=.65: xs.append(x)
				if xs.is_empty(): continue
				tip = Vector2i(xs[xs.size()/2],y); break
			tips.append([tip.x,tip.y])
			var old := Vector2i(box[2]/2,box[3]-1)
			print("TIP_PROBE ",family,"/",index," tip=",tip," old_alpha=",source.get_pixel(box[0]+old.x,box[1]+old.y).a)
		result[family] = tips
	print("DRIP_TIPS ",JSON.stringify(result))
	quit()
