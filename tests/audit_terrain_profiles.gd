extends SceneTree
## Offline terrain contour measurement, no image edits or runtime readbacks.
func _initialize() -> void:
	var result: Dictionary={}
	for family in ["cave","ash","star"]:
		var path: String="res://art/visual_slice/terrain_segments_%s_v1.png"%family
		var picture:=Image.load_from_file(path)
		var entry:=[]
		for column in 3:
			var points:=[]
			for step in 33:
				var x:=column*512+int(511.0*step/32.0)
				var samples:=[]
				for dx in range(-3,4):
					var sample:=447 if family=="cave" else (446 if family=="ash" else 403)
					for y in range(200,480):
						if picture.get_pixel(clampi(x+dx,column*512,column*512+511),y).a>0.8:
							sample=y;break
					samples.append(sample)
				samples.sort()
				points.append([x-column*512,samples[3]])
			entry.append(points)
		result[family]=entry
	print("TERRAIN_PROFILES ",JSON.stringify(result))
	quit()
