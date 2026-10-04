extends "res://tests/gameplay_review_smoke.gd"
const Joints := preload("res://WorldTerrainJoints.gd")
const Placement := preload("res://RouteDressingPlacement.gd")
const Support := preload("res://WorldSupport.gd")

func _solid(parent: Node2D,at: Vector2,size: Vector2) -> CollisionShape2D:
	var body := StaticBody2D.new(); parent.add_child(body); body.position = at
	var collision := CollisionShape2D.new(); collision.shape = RectangleShape2D.new(); collision.shape.size = size; body.add_child(collision)
	return collision

func _fixtures() -> void:
	var stage := Node2D.new(); root.add_child(stage); stage.position = Vector2(-600,730); stage.scale = Vector2(1.4,1.4)
	var ground := _solid(stage,Vector2(0,310),Vector2(700,20))
	var wall := _solid(stage,Vector2(-300,200),Vector2(30,200))
	var nodes: Array[Node] = [ground,wall]
	var native := _collision_snapshot(nodes)
	var layer := Joints.install(stage,"fixture",nodes)
	_check(layer.details.size()==2,"Both exposed feet of interior wall must be dressed")
	var first: int = layer.details[0].get_instance_id()
	Joints.install(stage,"fixture",nodes)
	_check(layer.details[0].get_instance_id()==first,"Stable corner regenerates every entry")
	wall.disabled = true; Joints.install(stage,"fixture",nodes)
	_check(layer.details.is_empty(),"Removed wall leaves a floating corner deposit")
	wall.disabled = false; Joints.install(stage,"fixture",nodes)
	_check(layer.details.size()==2 and _collision_snapshot(nodes)==native,"Restoring art mutates native geometry")
	var device := Node2D.new(); stage.add_child(device); device.global_position = layer.details[0].global_position
	var face := Sprite2D.new(); face.name = "FinishedDevice"; device.add_child(face); nodes.append(device)
	Joints.install(stage,"fixture",nodes)
	_check(not layer.details[0].visible,"Late interactive device buried by corner art")
	nodes.erase(device); device.free(); Joints.install(stage,"fixture",nodes)
	_check(layer.details[0].visible,"Removed interaction leaves a permanent hole")
	# A dynamic support changing type/one-way status must not crash the
	# relief refresh or leave a solid mound hanging on unsupported geometry.
	var contours := preload("res://WorldRouteRelief.gd").install(stage,"fixture",nodes)
	_check(not contours.patches.is_empty(),"Support replacement fixture lacks a contour")
	ground.shape = CircleShape2D.new()
	preload("res://WorldRouteRelief.gd").install(stage,"fixture",nodes)
	for patch in contours.patches: _check(not patch.visible,"Replaced floor shape retains unsupported terrain")
	stage.free()

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_terrain_joints.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate(); root.add_child(game); current_scene = game
	for tick in 5: await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var joints := 0; var caps := 0; var covered := 0; var backing_count := 0
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for tick in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D = game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node] = finish._members(room)
		var layer: Node2D = room.get_node("TerrainJoints")
		var solids := Support.solids(nodes); var reserved := Placement.reservations(nodes)
		var native := _collision_snapshot(nodes)
		for prop in layer.details:
			_check(prop.visible and prop.footprint.is_equal_approx(prop.art.global_transform*prop.art.get_rect()),"Stale/hidden corner bounds: "+id)
			var wall: Rect2 = prop.get_meta("joint_wall"); var side: int = prop.get_meta("joint_side")
			_check(wall in solids and prop.support in solids,"Corner has no physical wall/floor attachment: "+id)
			_check(absf(prop.footprint.position.x-wall.end.x-1)<.02 if side>0 else absf(wall.position.x-prop.footprint.end.x-1)<.02,"Corner floats beside wall: "+id)
			var bounds: Rect2 = prop.footprint; bounds.size.y = maxf(0,prop.support.position.y-.25-bounds.position.y)
			_check(Placement.clear(bounds,solids) and Placement.clear(prop.footprint,reserved),"Corner clips a solid/device: "+id)
			_check(prop.footprint.size.x<=51 and prop.footprint.size.y<=18,"Oversized wall deposit")
			_check(is_equal_approx(prop.global_scale.x,prop.global_scale.y) and not prop.is_processing(),"Corner stretched or runs idle callback")
			if prop.has_meta("joint_backing_bounds"):
				backing_count += 1
				var join: Rect2 = prop.get_meta("joint_backing_bounds")
				_check(join.is_equal_approx(prop.get_node("InsetRockJoin").global_transform*prop.get_node("InsetRockJoin").get_rect()),"Stale inset rock bounds")
				_check(wall.merge(prop.support).grow(2).encloses(join) and join.size.x<=35,"Inset rock escapes solid junction")
				var texture: AtlasTexture = prop.get_node("InsetRockJoin").texture
				_check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region),"Join samples outside texture")
			joints += 1
		for patch in room.get_node("RouteRelief").patches:
			var found := 0
			for plant in patch.plants:
				if not plant.has_meta("slope_join"): continue
				_check(absf(plant.global_position.y-patch.height_at(plant.global_position.x)-.8)<.02,"Slope join floats")
				_check(plant.footprint.position.x>=patch.global_position.x and plant.footprint.end.x<=patch.global_position.x+patch.plan.width,"Join escapes protected contour")
				found += 1; caps += 1
			_check(found==2,"Slope ends lack compact joining deposits")
		var count := nodes.size(); finish.finish_room(id)
		_check(finish._members(room).size()==count and _collision_snapshot(finish._members(room))==native,"Corner re-entry duplicates/changes physics: "+id)
		if not layer.details.is_empty(): covered += 1
		print("JOINT_ROOM ",id," wall_feet=",layer.details.size())
	print("TERRAIN_JOINTS wall_feet=",joints," rooms=",covered," slope_caps=",caps," inset_backings=",backing_count)
	_check(joints>=20 and covered>=8 and caps==268,"Insufficient audited terrain connections")
	_fixtures(); game.free(); state.delete_save()
	print("TERRAIN JOINTS TEST PASSED" if failures.is_empty() else "TERRAIN JOINTS TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
