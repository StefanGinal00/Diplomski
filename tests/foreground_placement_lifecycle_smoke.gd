extends "res://tests/gameplay_review_smoke.gd"

const Dressing := preload("res://WorldForegroundDressing.gd")
const Placement := preload("res://RouteDressingPlacement.gd")
const Support := preload("res://WorldSupport.gd")
const Atlas := preload("res://LivingSpriteAtlas.gd")

func _solid(parent: Node2D, title: String, at: Vector2, size: Vector2) -> CollisionShape2D:
	var body := StaticBody2D.new(); body.name = title; parent.add_child(body); body.position = at
	var shape := CollisionShape2D.new(); shape.shape = RectangleShape2D.new(); shape.shape.size = size
	body.add_child(shape); return shape

func _audit(layer: Node2D, nodes: Array[Node]) -> Dictionary:
	var totals := {"plants":0,"unsupported":0,"solid_overlap":0,"frame_bounds":0,"flex_bounds":0,"scale":0,"reservation_overlap":0}
	var floors := Placement.floors(nodes)
	var solids := Support.solids(nodes)
	var reserved := Placement.reservations(nodes)
	for plant in layer.plants:
		if not plant.visible: continue
		totals.plants += 1
		plant.reset_response(); plant.rest()
		if not plant.global_scale.is_equal_approx(Vector2.ONE): totals.scale += 1
		var envelope := Rect2()
		for frame in 4:
			Atlas.show(plant.art,plant.atlas_id,plant.kind*4+frame,plant.height,0,1,plant.reference_height,"root")
			var actual: Rect2 = plant.art.global_transform*plant.art.get_rect()
			envelope = actual if not envelope.has_area() else envelope.merge(actual)
		if not envelope.is_equal_approx(plant.footprint): totals.frame_bounds += 1
		var bounds: Rect2 = plant.placement_bounds() if plant.has_method("placement_bounds") else envelope
		var flex_outside := false
		for direction in [-1.0,1.0]:
			plant.skew = direction*.445
			for frame in 4:
				Atlas.show(plant.art,plant.atlas_id,plant.kind*4+frame,plant.height,0,1,plant.reference_height,"root")
				var flexed: Rect2 = plant.art.global_transform*plant.art.get_rect()
				if not bounds.grow(.01).encloses(flexed): flex_outside = true
		plant.skew = 0
		if flex_outside: totals.flex_bounds += 1
		if plant.support not in floors or bounds.position.x<plant.support.position.x or bounds.end.x>plant.support.end.x: totals.unsupported += 1
		if not Placement.clear(bounds,reserved): totals.reservation_overlap += 1
		bounds.size.y = maxf(0,plant.support.position.y-.25-bounds.position.y)
		if not Placement.clear(bounds,solids): totals.solid_overlap += 1
		plant.rest()
	return totals

func _fixtures() -> void:
	var stage := Node2D.new(); root.add_child(stage)
	stage.position = Vector2(-470,380); stage.scale = Vector2(1.65,1.3)
	var ground := _solid(stage,"Ground",Vector2(420,220),Vector2(840,20))
	var roof := _solid(stage,"Ceiling",Vector2(420,0),Vector2(840,20))
	var nodes: Array[Node] = [ground,roof]
	var original := _collision_snapshot(nodes)
	var layer := Dressing.install(stage,"fixture_cave",nodes)
	var initial: int = layer.plants.size()
	_check(initial>=10,"Scaled fixture lost all ordinary foliage")
	var initial_id: int = layer.plants[0].get_instance_id()
	Dressing.install(stage,"fixture_cave",nodes)
	_check(layer.plants[0].get_instance_id()==initial_id,"Stable terrain recreates grass")
	var first: Node2D = layer.plants[0]
	var source_response: RefCounted = first.response
	for tick in 12: first.brush(.3); first.advance_response(1.0/60)
	_check(absf(source_response.bend)>.05,"Fixture never bent its plant")
	var wall := _solid(stage,"NarrowWall",stage.to_local(first.global_position)-Vector2(0,20),Vector2(12,90)); nodes.append(wall)
	Dressing.install(stage,"fixture_cave",nodes)
	_check(source_response.bend==0 and source_response.speed==0,"Retired foliage retains its brush response")
	var audit := _audit(layer,nodes)
	for key in ["unsupported","solid_overlap","frame_bounds","flex_bounds","scale","reservation_overlap"]:
		_check(audit[key]==0,"Scaled/late-wall fixture: "+key+"="+str(audit[key]))
	_check(layer.plants.size()<initial,"Late narrow wall did not clear foreground")
	wall.disabled = true; Dressing.install(stage,"fixture_cave",nodes)
	_check(layer.plants.size()==initial,"Disabled wall leaves a permanent grass gap")
	var device := Node2D.new(); stage.add_child(device); device.global_position = layer.plants[0].global_position
	var face := Sprite2D.new(); face.name = "FinishedDevice"; face.texture = layer.plants[0].art.texture
	device.add_child(face); face.global_transform = Transform2D(0,Vector2.ONE*170/face.texture.get_width(),0,device.global_position-Vector2(0,12))
	nodes.append(device)
	for tick in 12: layer.plants[0].brush(.3); layer.plants[0].advance_response(1.0/60)
	Dressing.install(stage,"fixture_cave",nodes)
	var hidden := 0
	for plant in layer.plants:
		if not plant.visible:
			hidden += 1
			_check(plant.response.bend==0 and plant.response.speed==0,"Occluded foliage retains brush response")
	_check(hidden>0,"Late device fails to reserve its painted silhouette")
	audit = _audit(layer,nodes)
	_check(audit.reservation_overlap==0,"Wide device overlaps visible animated grass")
	nodes.erase(device); device.free(); Dressing.install(stage,"fixture_cave",nodes)
	for plant in layer.plants: _check(plant.visible,"Removed device leaves grass hidden")
	ground.disabled = true; Dressing.install(stage,"fixture_cave",nodes)
	_check(layer.plants.is_empty(),"Removed floor leaves floating grass or roof-top grass")
	ground.disabled = false; Dressing.install(stage,"fixture_cave",nodes)
	_check(layer.plants.size()==initial,"Restored floor fails to restore grass")
	_check(_collision_snapshot([ground,roof])==original,"Foreground lifecycle changes native collisions")
	_check(layer.find_children("*","CollisionObject2D",true,false).is_empty(),"Foreground repair adds physics")
	stage.free()

func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_foreground_placement_lifecycle.json"; state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game); current_scene = game
	for tick in 5: await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var finish := game.get_node("WorldPresentationFinish")
	var totals := {"rooms":0,"plants":0,"unsupported":0,"solid_overlap":0,"frame_bounds":0,"flex_bounds":0,"scale":0,"reservation_overlap":0}
	for id in ["training_passage"]+Layout.ROOM_NODES.keys():
		state.set_current_room(id)
		for tick in 3: await process_frame
		finish.finish_room(id)
		var room: Node2D = game if id=="training_passage" else game.get_node(str(Layout.ROOM_NODES[id]))
		var nodes: Array[Node] = finish._members(room)
		var layer := room.get_node("ForegroundGrowth")
		var native := _collision_snapshot(nodes)
		var count: int = layer.plants.size()
		var snapshot := _audit(layer,nodes)
		for key in snapshot: totals[key] += snapshot[key]
		totals.rooms += 1
		finish.finish_room(id)
		_check(layer.plants.size()==count,"Reentry changes foreground density: "+id)
		_check(_collision_snapshot(finish._members(room))==native,"Foreground changes room collisions: "+id)
		_check(count<=180,"Foreground budget exceeded: "+id)
	print("FOREGROUND_PLACEMENT_COUNTS ",JSON.stringify(totals))
	for key in ["unsupported","solid_overlap","frame_bounds","flex_bounds","scale","reservation_overlap"]:
		_check(totals[key]==0,"World foreground placement: "+key+"="+str(totals[key]))
	game.free()
	_fixtures()
	state.delete_save()
	print("FOREGROUND PLACEMENT LIFECYCLE TEST PASSED" if failures.is_empty() else "FOREGROUND PLACEMENT LIFECYCLE TEST FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
