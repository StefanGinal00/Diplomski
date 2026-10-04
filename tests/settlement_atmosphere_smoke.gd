extends "res://tests/visual_style_slice_smoke.gd"
const Atlas := preload("res://SettlementDetailAtlas.gd")
const Dressing := preload("res://SettlementAtmosphere.gd")
const Support := preload("res://WorldSupport.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_atmosphere.json"
	state.start_new_game("normal")
	var bytes := 0
	for texture in Atlas.SHEETS:
		var image: Image = texture.get_image()
		_check(texture.get_width()<=1024 and image.has_mipmaps() and image.get_pixel(0,0).a<0.01,"Scenery import budget, alpha or mipmaps")
		bytes += image.get_data_size()
	_check(bytes<12*1024*1024,"Three new sheets exceed 12 MiB decoded")
	for sheet in 3:
		for index in Atlas.CROPS[sheet].size():
			var texture := Atlas.texture_for(sheet,index)
			_check(texture==Atlas.texture_for(sheet,index) and texture.filter_clip,"Atlas regions are not shared/clipped")
			_check(Rect2(Vector2.ZERO,Atlas.SHEETS[sheet].get_size()).encloses(texture.region),"Atlas outside source")
	var total_hangings := 0
	var total_landmarks := 0
	for scene_name in ["EchoHaven","EchoHavenOutskirts","CinderHearth","StarfallCitadel"]:
		var room: Node2D = load("res://%s.tscn" % scene_name).instantiate()
		room.position = Vector2(12000,-5000)
		var decor := room.get_node("SettlementAtmosphere")
		decor.owner = null
		room.remove_child(decor)
		root.add_child(room)
		for frame in 3: await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var before := _physics_snapshot(room)
		var transforms := {}
		for node in room.find_children("*","Node2D",true,false): transforms[node] = node.global_transform
		room.add_child(decor)
		for frame in 2: await process_frame
		_check(decor.built and not decor.is_processing(),"Static decorating pass not built")
		_check(_physics_snapshot(room)==before,"Decor changed collision")
		for node in transforms: _check(node.global_transform==transforms[node],"Decor moved original actor/marker")
		for old in decor.retired: _check(not old.visible,"Prototype remains behind painted object")
		for node in room.find_children("*","Line2D",true,false):
			if String(node.name).begins_with("LaundryLine") or String(node.name).begins_with("WardLaundry") or node.name==&"MarketClothesline":
				_check(node.width<=0.81 and node.default_color.r>node.default_color.b,"Laundry cable remains a luminous thick guide stripe")
		var expected := {"EchoHaven":32,"EchoHavenOutskirts":30,"CinderHearth":28,"StarfallCitadel":11}
		_check(decor.hangings.size()==expected[scene_name],"Missing hanging coverage "+scene_name+": "+str(decor.hangings.size()))
		for fixture in decor.fixtures:
			if fixture.kind=="post":
				_check(absf(decor.to_global(fixture.anchor).y-fixture.support.position.y)<0.01,"Post footing floats")
		for detail in decor.hangings:
			_check(not detail.is_processing() and detail.has_meta("ambient_motion"),"Unbudgeted hanging animation")
			_check(detail.art.texture is AtlasTexture and is_equal_approx(detail.art.scale.x,detail.art.scale.y),"Stretched/placeholder ornament")
			var old_anchor: Vector2 = detail.global_position
			detail.animate(2)
			_check(absf(detail.rotation)<0.025 and detail.global_position==old_anchor,"Suspension ring detached")
			detail.rest()
			_check(detail.rotation==0 and detail.skew==0,"Offscreen hanging keeps motion")
		for detail in decor.landmarks:
			_check(detail.global_position.y==detail.support.position.y,"Civic prop floats")
			var contact: Vector2 = detail.art.to_global(Vector2(0,-detail.art.texture.get_height()*0.5+Atlas.contact(0,detail.variant)))
			_check(absf(contact.y-detail.support.position.y)<0.01,"Opaque civic base misregistered")
			_check(is_equal_approx(detail.art.scale.x,detail.art.scale.y),"Civic art stretched")
			var bounds: Rect2 = detail.art.global_transform*detail.art.get_rect()
			_check(bounds.position.x>=detail.support.position.x and bounds.end.x<=detail.support.end.x,"Civic prop hangs over support edge")
			for ceiling in decor.floors:
				if ceiling.end.y<detail.support.position.y: _check(not bounds.intersects(ceiling),"Balcony slices through civic artwork")
		if scene_name=="StarfallCitadel": _check(decor.landmarks.size()==6,"City fountain/board/trellises/armillary not all supported: "+str(decor.landmarks.size()))
		var count: int = decor.get_child_count()
		decor._build()
		_check(count==decor.get_child_count(),"Repeated decor build duplicates objects")
		total_hangings += decor.hangings.size()
		total_landmarks += decor.landmarks.size()
		print("SETTLEMENT DETAIL COVERAGE ",scene_name," ",decor.hangings.size()," hanging; ",decor.landmarks.size()," civic; ",decor.fixtures.size()," supports")
		room.queue_free()
		await process_frame
	state.delete_save()
	print("SETTLEMENT ATMOSPHERE TEST PASSED" if failures.is_empty() else "TEST FAILED: "+str(failures))
	print("DETAIL TOTAL ",total_hangings," hanging; ",total_landmarks," civic; ",bytes," bytes decoded")
	quit(0 if failures.is_empty() else 1)
