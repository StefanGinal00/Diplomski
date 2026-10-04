extends "res://tests/visual_style_slice_smoke.gd"
const Art := preload("res://CityParallaxAtlas.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_city_parallax.json"
	state.start_new_game("normal")
	var bytes := 0
	for sheet in 2:
		var source: Texture2D = Art.SHEETS[sheet]
		var image := source.get_image()
		bytes += image.get_data_size()
		_check(source.get_size()==Vector2(1536,1024) and image.has_mipmaps() and image.get_pixel(0,0).a==0,"City source dimensions/mipmap/alpha")
		for index in 3:
			var texture := Art.texture_for(sheet,index)
			_check(texture==Art.texture_for(sheet,index) and texture.filter_clip,"Uncached/unclipped city crop")
			_check(Rect2(Vector2.ZERO,source.get_size()).encloses(texture.region),"City crop exceeds source")
	_check(bytes<17*1024*1024,"Two skyline sheets exceed 17 MiB decoded")
	print("CITY PARALLAX TEXTURE BYTES ",bytes)
	var city: Node2D = load("res://StarfallCitadel.tscn").instantiate()
	city.position = Vector2(49000,-6000)
	var art := city.get_node("ParallaxArchitecture")
	art.owner = null
	city.remove_child(art)
	root.add_child(city)
	for frame in 3: await process_frame
	city.process_mode = Node.PROCESS_MODE_DISABLED
	var before := _physics_snapshot(city)
	var originals := {}
	for node in city.find_children("*","Node2D",true,false): originals[node] = [node.global_transform,node.visible,node.z_index]
	city.add_child(art)
	for frame in 3: await process_frame
	_check(art.built and art.get_child_count()==0 and art.z_index==-8,"City architecture owner/depth")
	_check(art.retired.size()==230,"Old sky masks/trim remain: "+str(art.retired.size()))
	_check(_physics_snapshot(city)==before,"Parallax changed collision")
	for node in originals:
		_check(node.global_transform==originals[node][0] and node.z_index==originals[node][2],"Parallax moved a native scene object")
		_check(node.visible==(false if node in art.retired else originals[node][1]),"Parallax hid an unrelated actor/facade/route")
	for node in art.retired: _check(node.get_child_count()==0 and not node.visible,"Background retired a subtree or reappeared")
	var seen := {}
	for level in [false,true]:
		art.set_low_quality(level)
		for y in [350,-350,-1100,-1700,-2400,1200]:
			for x in [-150,0,1500,3150,5200,6450]:
				var center := Vector2(x,y)
				art.update_view(center,Vector2(800,450))
				_check(art.entries.size()<= (16 if level else 24),"Architecture draw budget exceeded")
				for entry in art.entries:
					seen[entry.sheet*3+entry.index] = true
					var texture := Art.texture_for(entry.sheet,entry.index)
					_check(entry.rect.position.is_finite() and entry.rect.size.is_finite(),"Nonfinite building projection")
					_check(is_equal_approx(entry.rect.size.x/texture.get_width(),entry.rect.size.y/texture.get_height()),"Stretched skyline")
					_check(Rect2(center-Vector2(400,225),Vector2(800,450)).grow(12).intersects(entry.rect),"Offscreen building submitted")
				var revision: int = art.revision
				art.update_view(center,Vector2(800,450))
				_check(art.revision==revision,"Idle camera redraws needlessly")
	_check(seen.size()==6,"Not all six original buildings are used")
	# Assert exact screen-relative displacement, including vertical climb.
	var start := Vector2(2700,350)
	var travel := Vector2(100,-150)
	for layer in 2:
		var a: Dictionary = art.building(layer,4,start)
		var b: Dictionary = art.building(layer,4,start+travel)
		var displacement: Vector2 = (b.rect.position-start-travel)-(a.rect.position-start)
		_check(displacement.is_equal_approx(-travel*art.LAYERS[layer].scroll),"Incorrect camera-relative parallax speed")
		_check(not displacement.is_equal_approx(-travel),"Background moves like solid foreground")
	# Returning to a camera position must not accumulate scrolling drift.
	art.update_view(start,Vector2(800,450),true)
	var snapshot: Array = art.entries.duplicate(true)
	art.update_view(start+Vector2(4000,-2000),Vector2(800,450))
	art.update_view(start,Vector2(800,450))
	_check(art.entries==snapshot,"Parallax drifts after return")
	var retired_count: int = art.retired.size()
	art._build()
	_check(art.retired.size()==retired_count,"Repeated parallax build")
	city.hide()
	_check(not art.is_processing() and not art.is_visible_in_tree(),"Hidden city retains active parallax")
	city.show()
	_check(art.is_processing(),"Returned city does not resume parallax")
	print("CITY PARALLAX RETIRED ",retired_count,"; variants ",seen.size())
	city.queue_free()
	await process_frame
	state.delete_save()
	print("CITY PARALLAX TEST PASSED" if failures.is_empty() else "CITY PARALLAX TEST FAILED")
	quit(0 if failures.is_empty() else 1)
