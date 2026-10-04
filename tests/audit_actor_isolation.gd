extends SceneTree
## Read-only connected-alpha registration. Row spans keep adjacent hands/capes
## out of another frame without changing any generated image pixels.
func _initialize() -> void:
	var sources:=[]
	for id in ["void_sentinel","abyss_warden","echo_matriarch","ash_castellan","ember_marshal","starfall_guardian","hollow_sovereign"]:
		sources.append("boss_%s_attack_v%d"%[id,3 if id=="ember_marshal" else 5])
		sources.append("boss_%s_motion_v%d"%[id,6 if id=="echo_matriarch" else 7])
	for id in ["enemy","fiend","root","sentry"]: sources.append("mob_attack_%s_v1"%id)
	for kit in ["cave_relics","waterworks","ash_architecture","star_relics"]: sources.append("dressing_%s_v%d"%[kit,2 if kit=="cave_relics" else 1])
	for family in ["cave","ash","star"]: sources.append("resident_gestures_%s_v%d"%[family,2 if family=="star" else 1])
	var report: Dictionary={}
	for id in sources:
		var path: String="res://art/visual_slice/%s.png"%id
		if not FileAccess.file_exists(path): continue
		var picture:=Image.load_from_file(path)
		picture.convert(Image.FORMAT_RGBA8)
		var pixels:=picture.get_data()
		var width:=picture.get_width()
		var height:=picture.get_height()
		if pixels[3]>0:
			print("ISOLATION_REJECT ",id," opaque background")
			continue
		var visited:=PackedByteArray()
		visited.resize(width*height)
		var mains:=[]
		var islands:=[]
		for start in width*height:
			if visited[start] or pixels[start*4+3]<65: continue
			var queue:=PackedInt32Array([start])
			visited[start]=1
			var at:=0
			var bounds:=Rect2i(start%width,start/width,1,1)
			while at<queue.size():
				var p:=queue[at]
				at+=1
				var x:=p%width
				var y:=p/width
				bounds=bounds.expand(Vector2i(x,y))
				for next in [p-1 if x>0 else -1,p+1 if x<width-1 else -1,p-width,p+width]:
					if next<0 or next>=width*height or visited[next] or pixels[next*4+3]<65: continue
					visited[next]=1
					queue.append(next)
			if queue.size()<30: continue
			var part: Dictionary={"pixels":queue,"bounds":bounds}
			if queue.size()>6000: mains.append(part)
			else: islands.append(part)
		if mains.size()!=8:
			print("ISOLATION_REJECT ",id," expected8 bodies got",mains.size())
			continue
		mains.sort_custom(func(a,b):
			var row_a:=int(a.bounds.get_center().y/(height*0.5))
			var row_b:=int(b.bounds.get_center().y/(height*0.5))
			return a.bounds.position.x<b.bounds.position.x if row_a==row_b else row_a<row_b)
		for island in islands:
			var nearest:=0
			var best:=INF
			var center: Vector2=Vector2(island.bounds.get_center())
			for index in mains.size():
				var b: Rect2=Rect2(mains[index].bounds)
				var closest:=Vector2(clampf(center.x,b.position.x,b.end.x),clampf(center.y,b.position.y,b.end.y))
				var distance:=center.distance_squared_to(closest)+pow(center.x-b.get_center().x,2)*0.08
				if distance<best: best=distance;nearest=index
			if best<16000:
				mains[nearest].pixels.append_array(island.pixels)
				mains[nearest].bounds=mains[nearest].bounds.merge(island.bounds)
		var boxes:=[]
		var masks:=[]
		for part in mains:
			var b: Rect2i=part.bounds
			var min_x:=PackedInt32Array()
			var max_x:=PackedInt32Array()
			min_x.resize(64);min_x.fill(width)
			max_x.resize(64);max_x.fill(-1)
			var feet_sum:=0.0
			var feet_count:=0
			var torso_left:=width
			var torso_right:=0
			for p in part.pixels:
				var x: int=p%width
				var y: int=p/width
				var band:=clampi(int(float(y-b.position.y)/maxi(1,b.size.y)*64),0,63)
				min_x[band]=mini(min_x[band],x)
				max_x[band]=maxi(max_x[band],x)
				if y>b.position.y+b.size.y*0.9 and pixels[p*4+3]>165: feet_sum+=x;feet_count+=1
				if y>b.position.y+b.size.y*0.35 and y<b.position.y+b.size.y*0.48:
					torso_left=mini(torso_left,x);torso_right=maxi(torso_right,x)
			var spans:=[]
			for band in 64:
				var left:=min_x[band]
				var right:=max_x[band]
				# Neighbor bands conservatively retain thin antialiased contours.
				for neighbor in [maxi(0,band-1),mini(63,band+1)]:
					left=mini(left,min_x[neighbor]);right=maxi(right,max_x[neighbor])
				spans.append([left-3,right+3])
			boxes.append([b.position.x,b.position.y,b.size.x+1,b.size.y+1,(torso_left+torso_right)*0.5-b.position.x,feet_sum/maxi(1,feet_count)-b.position.x])
			masks.append(spans)
		report[id]={"path":path,"size":[width,height],"boxes":boxes,"spans":masks}
	print("ACTOR_ISOLATION ",JSON.stringify(report))
	quit()
