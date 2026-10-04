extends "res://tests/visual_style_slice_smoke.gd"
const Art := preload("res://FacadePropAtlas.gd")
const Support := preload("res://WorldSupport.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_residential_facade.json"
	state.start_new_game("normal")
	var bytes := 0
	for sheet in 2:
		var source: Texture2D = Art.SHEETS[sheet]
		var image := source.get_image()
		bytes += image.get_data_size()
		_check(source.get_width()<=1024 and image.has_mipmaps() and image.get_pixel(0,0).a==0,"Facade sheet import/alpha budget")
		for index in 6:
			var texture := Art.texture_for(sheet,index)
			_check(texture==Art.texture_for(sheet,index) and texture.filter_clip,"Facade regions not shared/clipped")
			_check(Rect2(Vector2.ZERO,source.get_size()).encloses(texture.region),"Bad facade crop")
			var anchor := Vector2(100,200)
			var rect := Art.contact_rect(sheet,index,anchor,64,45)
			var ratio := rect.size.y/texture.get_height()
			_check(absf(rect.position.y+Art.contact(sheet,index)*ratio-anchor.y)<0.001,"Lost opaque attachment row")
			_check(is_equal_approx(rect.size.x/texture.get_width(),ratio),"Stretched sprite")
	_check(bytes<8*1024*1024,"Two added sheets exceed 8 MiB decoded")
	print("FACADE TEXTURE BYTES ",bytes)
	for scene_name in ["EchoHaven","EchoHavenOutskirts","CinderHearth"]:
		var room: Node2D = load("res://%s.tscn"%scene_name).instantiate()
		room.position = Vector2(19000,-8000)
		var dressing := room.get_node("ResidentialFacadeDetails")
		dressing.owner = null
		room.remove_child(dressing)
		root.add_child(room)
		for frame in 3: await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var before := _physics_snapshot(room)
		var originals := {}
		for node in room.find_children("*","Node2D",true,false): originals[node] = [node.global_transform,node.visible,node.z_index]
		room.add_child(dressing)
		for frame in 2: await process_frame
		_check(dressing.built and not dressing.is_processing() and not dressing.is_physics_processing() and dressing.get_child_count()==0,"Scenery spawned runtime work")
		_check(_physics_snapshot(room)==before,"Facade changed native collision")
		for node in originals:
			_check(node.global_transform==originals[node][0] and node.z_index==originals[node][2],"Facade moved original actor/route/door")
			_check(node.visible==(false if node in dressing.retired else originals[node][1]),"Unexpected original visibility")
		var kinds := {}
		for entry in dressing.entries:
			kinds[entry.kind] = int(kinds.get(entry.kind,0))+1
			if entry.kind!="chimney":
				_check(absf(dressing.to_global(entry.at).y-entry.support.position.y)<0.01,"Floating doorstep/stall footing")
				_check(entry.support.has_area(),"No actual support")
			if entry.kind=="door":
				var index: int = dressing.family+(3 if entry.index%2 else 0)
				var rect := Art.contact_rect(0,index,entry.at,entry.height,entry.width)
				_check(rect.size.y>=40 and rect.size.y<=80,"Wrong residential door scale")
			if entry.kind=="canopy":
				var body := Rect2(dressing.to_global(entry.at)-Vector2(entry.width/2,entry.height),Vector2(entry.width,entry.height-1))
				for floor_rect in dressing.floors:
					_check(not body.intersects(floor_rect),"Canopy sliced by balcony")
		for node in dressing.retired:
			_check(node.get_child_count()==0 and (node is Polygon2D or node is Line2D),"Gameplay subtree was retired")
		var expected := {"EchoHaven":18,"EchoHavenOutskirts":16,"CinderHearth":13}
		_check(kinds.get("door",0)==expected[scene_name],"Residential coverage incomplete: "+scene_name)
		if scene_name=="EchoHavenOutskirts":
			var painter := room.get_node("PaintedBuildings")
			_check(painter.built and painter.window_frames.size()==32,"Approach houses missing painted windows")
			for plate in painter.painted: _check(plate.texture!=null and plate.uv.size()==plate.polygon.size(),"Approach facade remains flat")
		_check(kinds.get("canopy",0)==(0 if scene_name=="CinderHearth" else (2 if scene_name=="EchoHavenOutskirts" else 3)),"Safe gate awning coverage")
		var count: int = dressing.entries.size()
		dressing._build()
		_check(dressing.entries.size()==count,"Duplicate static dressing")
		print("FACADE COVERAGE ",scene_name," ",kinds)
		room.hide()
		_check(not dressing.is_visible_in_tree(),"Inactive facade is visible")
		room.queue_free()
		await process_frame
	var city: Node2D = load("res://StarfallCitadel.tscn").instantiate()
	root.add_child(city)
	for frame in 3: await process_frame
	city.process_mode = Node.PROCESS_MODE_DISABLED
	var door_count := 0
	for node in city.get_children():
		if node is Sprite2D and String(node.name).begins_with("ResidentialDoor"):
			door_count+=1
			_check(node.texture is AtlasTexture and node.z_index<0 and is_equal_approx(node.scale.x,node.scale.y),"City closed door art/depth/aspect")
	_check(door_count==6,"City street outside market has incorrect closed-door count: "+str(door_count))
	var upper := city.get_node("UpperCity/CivicArt")
	_check(not city.get_node("UpperCity/Workplace3/Tripod").visible,"Old telescope tripod remains")
	var nodes: Array[Node] = []
	nodes.assign(city.find_children("*","",true,false))
	var floors := Support.floors(nodes)
	_check(Support.below(upper.to_global(upper.telescope_base),floors,1).has_area(),"Telescope feet miss actual deck")
	for rect in upper.doors:
		_check(Support.below(upper.to_global(Vector2(rect.get_center().x,rect.end.y+3)),floors,1).has_area(),"Upper doorway threshold not grounded")
	city.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("RESIDENTIAL FACADE TEST PASSED: atlas budget, grounded doors/awnings, unchanged original actors/physics, translated rooms, static idempotent art, city and upper telescope")
		quit(0)
	else: quit(1)
