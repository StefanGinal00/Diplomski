extends SceneTree
## Offline alpha measurements only; no asset edits and no gameplay save.
func _initialize() -> void:
	var sources := []
	sources.append(["art/visual_slice/cache_opening_v1.png",6,3])
	for family in ["cave", "ash", "star"]:
		for role in ["female", "male"]: sources.append(["art/characters/resident_walk_%s_%s_v2.png" % [family, role], 4, 2])
	for kind in ["enemy", "fiend", "root"]:
		if FileAccess.file_exists("res://art/characters/mob_walk_%s_v1.png" % kind): sources.append(["art/characters/mob_walk_%s_v1.png" % kind, 4, 2])
	for args in sources:
		var image := Image.load_from_file("res://" + args[0])
		print(args[0], " COMPONENTS ",JSON.stringify(_components(image)))
		continue
		var cell := image.get_size() / Vector2i(args[1], args[2])
		var boxes: Array = []
		for i in args[1] * args[2]:
			var origin := Vector2i(i % args[1], i / args[1]) * cell
			var crop_left := maxi(0, origin.x - 28)
			var crop_right := mini(image.get_width(), origin.x + cell.x + 28)
			origin.x = crop_left
			var width := crop_right - crop_left
			var left := width
			var right := 0
			var top := cell.y
			var bottom := 0
			for y in cell.y:
				var count := 0
				for x in width:
					if image.get_pixelv(origin + Vector2i(x, y)).a < 0.65: continue
					count += 1
					left = mini(left, x)
					right = maxi(right, x)
				if count >= 3:
					top = mini(top, y)
					bottom = y
			var body_left := width
			var body_right := 0
			for y in range(top + int((bottom-top)*0.35), top + int((bottom-top)*0.46)):
				for x in width:
					if image.get_pixelv(origin + Vector2i(x,y)).a > 0.65:
						body_left = mini(body_left,x)
						body_right = maxi(body_right,x)
			boxes.append([origin.x+left, origin.y+top, right-left+1, bottom-top+1, (body_left+body_right)*0.5-left])
		print(args[0], " ", JSON.stringify(boxes))
	quit()

func _components(image: Image) -> Array:
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width*height)
	var parts := []
	for start in width*height:
		if visited[start] or data[start*4+3]<80: continue
		var queue := PackedInt32Array([start])
		visited[start] = 1
		var at := 0
		var left := width
		var right := 0
		var top := height
		var bottom := 0
		while at < queue.size():
			var p := queue[at]
			at += 1
			var x := p%width
			var y := p/width
			if data[p*4+3]>165:
				left=mini(left,x); right=maxi(right,x); top=mini(top,y); bottom=maxi(bottom,y)
			for next in [p-1 if x>0 else -1,p+1 if x<width-1 else -1,p-width,p+width]:
				if next<0 or next>=width*height or visited[next] or data[next*4+3]<80: continue
				visited[next]=1
				queue.append(next)
		if queue.size()<6000: continue
		var body_left := width
		var body_right := 0
		for y in range(top+int((bottom-top)*0.35),top+int((bottom-top)*0.46)):
			for x in range(left,right+1):
				if data[(y*width+x)*4+3]>165:
					body_left=mini(body_left,x); body_right=maxi(body_right,x)
		parts.append([left,top,right-left+1,bottom-top+1,(body_left+body_right)*0.5-left])
	parts.sort_custom(func(a,b): return a[0]<b[0] if absi(a[1]-b[1])<200 else a[1]<b[1])
	return parts
