extends SceneTree
func _initialize() -> void:
	var report := {}
	for family in ["cave","ash","star"]:
		for kind in ["clusters","overhangs"]:
			var id: String="corridor_%s_%s_v1"%[family,kind]
			var image:=Image.load_from_file("res://art/visual_slice/%s.png"%id)
			image.convert(Image.FORMAT_RGBA8)
			var bytes:=image.get_data()
			var width:=image.get_width()
			var height:=image.get_height()
			var cols:=3 if kind=="clusters" else 2
			var cw:=width/cols
			var ch:=height/2
			var boxes:=[]
			for row in 2:
				for col in cols:
					var left:=width
					var top:=height
					var right:=0
					var bottom:=0
					for y in range(row*ch,(row+1)*ch):
						for x in range(col*cw,(col+1)*cw):
							if bytes[(y*width+x)*4+3]<64: continue
							left=mini(left,x);top=mini(top,y);right=maxi(right,x);bottom=maxi(bottom,y)
					boxes.append([left,top,right-left+1,bottom-top+1])
			var corner_alpha:=bytes[3]
			report[id]={"size":[width,height],"boxes":boxes,"corner_alpha":corner_alpha}
	print("CORRIDOR_ASSETS ",JSON.stringify(report))
	quit()
