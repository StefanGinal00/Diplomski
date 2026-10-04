extends "res://tests/visual_style_slice_smoke.gd"
const Paint := preload("res://CityStreetAtlas.gd")
const Support := preload("res://WorldSupport.gd")

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_city_street_painted.json"
	state.start_new_game("normal")
	state.set_current_room("starfall_citadel")
	var city: Node2D = load("res://StarfallCitadel.tscn").instantiate()
	root.add_child(city)
	for frame in 3: await process_frame
	city.process_mode = Node.PROCESS_MODE_DISABLED
	var nodes: Array[Node] = []
	nodes.assign(city.find_children("*","",true,false))
	var floors := Support.floors(nodes)
	var counts := {}
	for node in nodes:
		if not node.has_meta("city_painted_furnishing"): continue
		var index := int(node.get_meta("city_painted_furnishing"))
		counts[index] = int(counts.get(index,0))+1
		_check(node is Polygon2D and node.texture==Paint.SHEET,"Street asset not painted")
		var crop: Rect2 = Paint.texture_for(index).region
		_check(node.uv[0]==crop.position and node.uv[2]==crop.end,"Whole atlas leaked into furnishing UVs")
		_check(node.z_index<0 and node.get_child_count()==0,"Street furnishing blocks actors or adds hierarchy")
		var rect := Rect2(node.polygon[0],node.polygon[2]-node.polygon[0])
		_check(absf(rect.size.aspect()-Paint.texture_for(index).get_size().aspect())<0.01,"Stretched city furnishing")
		if index in [2,3,5]:
			var contact: Vector2 = node.to_global(rect.position+Vector2(rect.size.x/2,Paint.contact(index)*rect.size.y/Paint.texture_for(index).get_height()))
			var floor_rect := Support.below(contact,floors,3)
			_check(floor_rect.has_area() and absf(floor_rect.position.y-contact.y)<0.05,"City furnishing lacks actual support at "+str(contact)+" floors="+str(floors.size()))
	var market := city.get_node("CityDistrictDetails/MarketLifeDetails")
	_check(not market.get_node("DeliveryCart").visible,"Primitive cart remains behind painted cart")
	for node in market.get_children():
		if String(node.name).begins_with("CartWheel"): _check(not node.visible,"Prototype wheel remains")
	_check(city.get_node("UpperCity/CivicArt").windows.size()==40,"Upper city window coverage changed")
	_check(counts.get(2,0)==7 and counts.get(3,0)==8 and counts.get(5,0)==4,"Missing lamp/planter/bench replacements")
	_check(int(counts.get(0,0))+int(counts.get(1,0))==15,"Missing city facade windows")
	# The market uses five cached painted stalls, 18 windows, four lamps, three
	# planters and one cart in its static draw; no new scene/physics instances.
	var before := _physics_snapshot(city)
	city.get_node("VisualStyleSlice").queue_redraw()
	await process_frame
	_check(before==_physics_snapshot(city),"Scenery changed physics")
	var original: Color = city.lantern_glows[0].color
	city._process(0.2)
	_check(city.lantern_glows[0].modulate.a==1,"Painted architecture fades with glass-only alpha pulse")
	state.defeated_bosses["hollow_sovereign"] = true
	city._refresh_victory_lights()
	_check(city.lantern_glows[0].texture==Paint.SHEET and city.lantern_glows[0].color!=original,"Painted street light lost native dawn response")
	print("CITY PAINT COVERAGE ",counts," plus 40 upper windows and market static artwork")
	city.queue_free()
	await process_frame
	state.delete_save()
	print("CITY STREET PAINTED TEST PASSED" if failures.is_empty() else "CITY STREET PAINTED TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
