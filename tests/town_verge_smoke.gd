extends "res://tests/route_richness_smoke.gd"
const Town := preload("res://TownVergeAtlas.gd")
const Detail := preload("res://RouteDetail.gd")

func _atlas_fixtures() -> void:
	var stage := Node2D.new(); root.add_child(stage); stage.position=Vector2(-700,500); stage.scale=Vector2(1.65,.75)
	var bytes := 0
	for family in Town.BOXES:
		var source: Texture2D=Town.texture(family,0).atlas
		var pixels := source.get_image(); bytes+=pixels.get_data_size()
		_check(source.get_width()==512 and pixels.has_mipmaps() and pixels.get_pixel(0,0).a<.01,"Town import alpha/mipmap budget")
		for index in 6:
			var atlas := Town.texture(family,index)
			_check(atlas==Town.texture(family,index) and atlas.filter_clip,"Town cutout is not cached/clipped")
			var box: Rect2=Town.BOXES[family][index]
			_check(Rect2(Vector2.ZERO,Town.SOURCE).encloses(box),"Town crop outside source")
			for other in 6:
				if other!=index: _check(not box.intersects(Town.BOXES[family][other]),"Neighboring town crops overlap")
			var prop := Detail.new(); stage.add_child(prop)
			prop.configure("cave","floor",index,75,22,Vector2(100,100.65),Rect2(0,100,500,20),false,family)
			_check(prop.footprint.size.y<=22.01 and prop.footprint.size.x<=75.01,"Oversized town object")
			_check(is_equal_approx(prop.global_scale.x,prop.global_scale.y),"Room transform distorts town cutout")
			var foot := prop.art.to_global(Vector2(0,prop.art.get_rect().position.y+Town.contact(family,index)))
			_check(absf(foot.y-100.65)<.01,"Town cutout floats")
			_check(not prop.is_processing() and not prop.is_physics_processing() and prop.get_child_count()==1,"Extra town callbacks/nodes")
			_check(prop.has_meta("player_reactive")==bool(index==5),"Rigid town supplies bend or soft grass is inert")
			if index==5:
				var envelope := prop.placement_bounds()
				for tilt in [-.445,.445]:
					prop.art.skew=tilt
					_check(envelope.grow(.01).encloses(prop.art.global_transform*prop.art.get_rect()),"Town flex escapes reservation")
				prop.rest()
				for direction in [-1,1]:
					prop.reset_response()
					for tick in 12: prop.brush(direction*.25); prop.advance_response(1.0/60)
					_check(prop.response.bend*direction>.08,"Town grass loses contact direction")
					_check(prop.global_position.is_equal_approx(Vector2(100,100.65)),"Town grass loses its fixed root")
					for tick in 220: prop.advance_response(1.0/60)
					_check(prop.response.bend==0,"Town grass never settles")
			prop.free()
	_check(bytes<3*1024*1024,"Town source imports exceed 3 MiB")
	print("TOWN_TEXTURE_BYTES ",bytes)
	var floor_shape := _solid(stage,Vector2(400,210),Vector2(800,20))
	var members: Array[Node]=[floor_shape]
	var ground_layer := Dressing.install(stage,"echo_haven",members)
	_check(not ground_layer.details.is_empty(),"Scaled town fixture lacks soft street verge")
	var first: Node2D=ground_layer.details[0]
	var wall := _solid(stage,stage.to_local(first.global_position)-Vector2(0,20),Vector2(8,80)); members.append(wall)
	# Finish snapshots include the previous decoration; rebuilding must safely
	# skip those now-freed references when inspecting neighborhood context.
	for prop in ground_layer.details: members.append(prop)
	ground_layer.refresh(members)
	for prop in ground_layer.details:
		if prop.kind!="floor":
			_check(Placement.clear(prop.footprint,Support.solids(members),prop.support),"Late wall cuts attached hanging foliage")
			continue
		var bounds: Rect2=prop.placement_bounds(); bounds.size.y=maxf(0,prop.support.position.y-.25-bounds.position.y)
		_check(Placement.clear(bounds,Support.solids(members)),"Late wall cuts bent town foliage")
	wall.disabled=true; ground_layer.refresh(members)
	_check(not ground_layer.details.is_empty(),"Town fixture does not restore after removed wall")
	stage.free()

func _run() -> void:
	var state := root.get_node("GameState"); state.save_path="res://_tmp_town_verge_smoke.json"; state.start_new_game("normal")
	_atlas_fixtures()
	var game: Node2D=load("res://Game.tscn").instantiate(); root.add_child(game); current_scene=game
	for frame in 5: await process_frame
	game.get_node("UI").story_player.cancel(); paused=false; game.process_mode=Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var total := 0; var variants := {}
	for id in ["echo_haven","ash_hearth","starfall_citadel","echo_haven_outskirts","sunken_shaft"]:
		state.set_current_room(id)
		for frame in 4: await process_frame
		finish.finish_room(id)
		var room: Node2D=game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node]=finish._members(room)
		var native := _collision_snapshot(nodes)
		var layer: Node2D=room.get_node("PathDressing")
		var town: String=Town.ROOMS.get(id,"")
		var reserved: Array[Rect2]=layer._reservations(nodes)
		var floors := Placement.floors(nodes); var solids := Support.solids(nodes)
		var hard := 0; var grass := 0; var count := 0
		var soft: Node2D
		var identities := []
		for prop in layer.details:
			identities.append(prop.get_instance_id())
			_check(prop.town_family==(town if prop.kind=="floor" else ""),"Town assets leak outside chosen floors")
			if prop.kind!="floor" or not prop.visible or town.is_empty(): continue
			var bounds: Rect2=prop.placement_bounds()
			_check(prop.support in floors and bounds.position.x>=prop.support.position.x and bounds.end.x<=prop.support.end.x,"Town art leaves ledge")
			_check(Placement.clear(bounds,reserved),"Town artwork covers door/device/actor")
			bounds.size.y=maxf(0,prop.support.position.y-.25-bounds.position.y)
			_check(Placement.clear(bounds,solids),"Town flex envelope cuts wall")
			if prop.variant<5:
				hard+=1
				_check(Town.near_home(prop.global_position,layer.home_zones),"Domestic supplies float away from a home tier")
			else: grass+=1; soft=prop
			variants[town+str(prop.variant)]=true; count+=1
		if not town.is_empty():
			_check(hard>=5 and grass>=10,"Town lost its inhabited/soft variety: "+id)
			var ambience: Node=finish.ambience
			ambience.sample_brushing(soft.global_position-Vector2(14,8),soft.global_position-Vector2(0,8),Vector2(160,0),1.0/60)
			_check(soft in ambience.brushing,"Town plant not wired into player contact")
			var device := Node2D.new(); room.add_child(device); device.add_to_group("town_service"); device.global_position=soft.global_position
			nodes.append(device); layer.refresh(nodes)
			_check(not soft.visible and soft.response.bend==0 and soft.response.speed==0,"Late service leaves reacting/occluding town grass")
			nodes.erase(device); device.free(); layer.refresh(nodes)
			_check(soft.visible,"Removing reservation leaves permanent town hole")
			for low in [false,true]:
				ambience.set_low_quality(low)
				_check(ambience.active.size()<=(8 if low else 18) and ambience.brushing.size()<=(6 if low else 12),"Town bypasses ambience caps")
		finish.finish_room(id)
		var after := []
		for prop in layer.details: after.append(prop.get_instance_id())
		_check(after==identities and _collision_snapshot(finish._members(room))==native,"Town revisit mutates native collision or duplicates art")
		print("TOWN_VERGE ",id," rigid=",hard," soft=",grass," zones=",layer.home_zones.size())
		total+=count
	_check(variants.size()==18,"Not all 18 town variants appear in the three homes")
	print("TOWN_VERGE_TOTAL ",total," variants=",variants.size())
	game.free(); state.delete_save()
	print("TOWN VERGE TEST PASSED" if failures.is_empty() else "TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
